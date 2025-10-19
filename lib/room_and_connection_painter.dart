import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'kruskal.dart';
import 'extensions.dart';

class RoomAndConnectionPainter extends CustomPainter {
  final List<Room> rooms;
  final List<Connection> connections;
  final bool isDetailedView;
  final double animationValue;
  final List<Color> floorColors;
  final int maxFloor;
  final bool isDarkMode;
  final String? selectedRoomId;
  final String? hoveredRoomId;

  late final double _effectiveScale;
  late final Offset _minLogicalPoint;
  late final double _canvasPadding;

  RoomAndConnectionPainter({
    required this.rooms,
    required this.connections,
    required this.isDetailedView,
    required this.animationValue,
    required this.floorColors,
    required this.maxFloor,
    required this.isDarkMode,
    this.selectedRoomId,
    this.hoveredRoomId,
  });

  double getEffectiveScale(Size canvasSize, List<Room> allRooms) {
    if (allRooms.isEmpty) return 1.0;
    double minLogicalX = allRooms.map((r) => r.x).reduce(min);
    double maxLogicalX = allRooms.map((r) => r.x).reduce(max);
    double minLogicalY = allRooms.map((r) => r.y).reduce(min);
    double maxLogicalY = allRooms.map((r) => r.y).reduce(max);

    const double logicalPadding = 15.0;
    minLogicalX -= logicalPadding;
    maxLogicalX += logicalPadding;
    minLogicalY -= logicalPadding;
    maxLogicalY += logicalPadding;

    final double logicalWidth = maxLogicalX - minLogicalX;
    final double logicalHeight = maxLogicalY - minLogicalY;

    final double canvasPaddingRatio = 0.12;
    final double canvasPaddingValue = canvasSize.width * canvasPaddingRatio;
    final double availableCanvasWidth = canvasSize.width - (2 * canvasPaddingValue);
    final double availableCanvasHeight = canvasSize.height - (2 * canvasPaddingValue);

    final double scaleX = logicalWidth > 0 ? availableCanvasWidth / logicalWidth : 1.0;
    final double scaleY = logicalHeight > 0 ? availableCanvasHeight / logicalHeight : 1.0;
    return min(scaleX, scaleY) * 0.85;
  }

  void _initializeCache(Size size) {
    _effectiveScale = getEffectiveScale(size, rooms);
    _canvasPadding = size.width * 0.12;

    double minLogicalXVal = rooms.map((r) => r.x).reduce(min);
    double minLogicalYVal = rooms.map((r) => r.y).reduce(min);
    const double logicalPaddingVal = 15.0;
    _minLogicalPoint = Offset(
      minLogicalXVal - logicalPaddingVal,
      minLogicalYVal - logicalPaddingVal,
    );
  }

  Offset _getCanvasPosition(Room room) {
    double canvasX = ((room.x - _minLogicalPoint.dx) * _effectiveScale) + _canvasPadding;
    double canvasY = ((room.y - _minLogicalPoint.dy) * _effectiveScale) + _canvasPadding;
    canvasY += room.floor * 35 * _effectiveScale;
    return Offset(canvasX, canvasY);
  }

  Offset getCanvasPositionForTap(Room room, Size canvasSize, List<Room> allRooms) {
    if (allRooms.isEmpty) {
      return Offset.zero;
    }

    final double effectiveScale = getEffectiveScale(canvasSize, allRooms);
    final double canvasPadding = canvasSize.width * 0.12;

    double minLogicalXVal = allRooms.map((r) => r.x).reduce(min);
    double minLogicalYVal = allRooms.map((r) => r.y).reduce(min);
    const double logicalPaddingVal = 15.0;
    final Offset minLogicalPoint = Offset(
      minLogicalXVal - logicalPaddingVal,
      minLogicalYVal - logicalPaddingVal,
    );

    double canvasX = ((room.x - minLogicalPoint.dx) * effectiveScale) + canvasPadding;
    double canvasY = ((room.y - minLogicalPoint.dy) * effectiveScale) + canvasPadding;
    canvasY += room.floor * 35 * effectiveScale; //
    return Offset(canvasX, canvasY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (rooms.isEmpty) return;

    _initializeCache(size);

    _drawConnections(canvas);

    _drawRooms(canvas);
  }

  void _drawConnections(Canvas canvas) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (isDetailedView ? 4.0 : 3.5) * animationValue.clamp(0.1, 1.0); //

    for (var connection in connections) {
      final fromPos = _getCanvasPosition(connection.from);
      final toPos = _getCanvasPosition(connection.to);

      final startColor = floorColors[connection.from.floor % floorColors.length];
      final endColor = floorColors[connection.to.floor % floorColors.length];

      linePaint.shader = LinearGradient(
        colors: [
          startColor.withOpacity(0.85 * animationValue), //
          endColor.withOpacity(0.85 * animationValue), //
          startColor.withOpacity(0.4 * animationValue), //
        ],
        stops: const [0.0, 0.6, 1.0], //
      ).createShader(Rect.fromPoints(fromPos, toPos));

      final path = Path()..moveTo(fromPos.dx, fromPos.dy);
      path.lineTo(toPos.dx, toPos.dy);

      final animatedPath = _extractAnimatedPath(path, animationValue);
      if (animatedPath.computeMetrics().isNotEmpty) {
        canvas.drawShadow(
          animatedPath,
          Colors.black.withOpacity(0.35 * animationValue), //
          (isDetailedView ? 5.0 : 4.0) * animationValue, //
          false,
        );
        canvas.drawPath(animatedPath, linePaint);
      }

      if (isDetailedView && animationValue > 0.9) { //
        final midPoint = Offset((fromPos.dx + toPos.dx) / 2, (fromPos.dy + toPos.dy) / 2);
        _drawAnimatedText(
          canvas,
          '${connection.distance.toStringAsFixed(1)} u', //
          midPoint,
          fontSize: (9.0 + _effectiveScale * 0.5).clamp(8.0, 14.0), //
          color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.8), //
          backgroundColor: isDarkMode
              ? Colors.black.withOpacity(0.6) //
              : Colors.white.withOpacity(0.75), //
        );
      }
    }
  }

  void _drawRooms(Canvas canvas) {
    for (var room in rooms) {
      _drawRoomShadow(canvas, room);
    }

    for (var room in rooms) {
      _drawRoom(canvas, room);
    }

    if (isDetailedView) {
      for (var room in rooms) {
        _drawRoomLabel(canvas, room);
      }
    }
  }

  void _drawRoomShadow(Canvas canvas, Room room) {
    final roomPos = _getCanvasPosition(room);
    final double currentLogicalRadius = room.displayRadius;
    final double scaledRadius = currentLogicalRadius * _effectiveScale.clamp(0.6, 2.2); 
    final animatedRadius = scaledRadius * Curves.elasticOut.transform(animationValue.clamp(0.1, 1.0)); 

    if (animatedRadius <= 0.5) return; 

    final bool isSelected = room.id == selectedRoomId;
    final bool isHovered = room.id == hoveredRoomId;

    final shadowRadius = animatedRadius * 1.15; 
    final shadowOpacity = isSelected ? 0.7 : (isHovered ? 0.5 : 0.35); 
    final shadowBlur = isSelected ? 12.0 : (isHovered ? 8.0 : 6.0);

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: roomPos, radius: shadowRadius)),
      Colors.black.withOpacity(shadowOpacity * animationValue), 
      shadowBlur * animationValue, 
      false,
    );
  }

  void _drawRoom(Canvas canvas, Room room) {
    final roomPos = _getCanvasPosition(room);
    final roomColor = floorColors[room.floor % floorColors.length];
    final bool isSelected = room.id == selectedRoomId;
    final bool isHovered = room.id == hoveredRoomId;

    final double currentLogicalRadius = room.displayRadius;
    final double scaledRadius = currentLogicalRadius * _effectiveScale.clamp(0.6, 2.2); 
    final animatedRadius = scaledRadius * Curves.elasticOut.transform(animationValue.clamp(0.1, 1.0));

    if (animatedRadius <= 0.5) return; 

    final double time = animationValue * pi * 2; 
    final pulseFactor = isSelected
        ? (1.0 + 0.3 * sin(time * 2.5))
        : isHovered
        ? (1.0 + 0.2 * sin(time * 1.8))
        : (1.0 + 0.1 * sin(time * 1.2));

    final pulseRadius = animatedRadius * pulseFactor;

    _drawOuterGlow(canvas, roomPos, pulseRadius, roomColor, isSelected, isHovered);

    _drawMainCircle(canvas, roomPos, animatedRadius, roomColor, isSelected, isHovered);

    _drawInnerHighlight(canvas, roomPos, animatedRadius, roomColor, isSelected, isHovered);

    _drawRoomBorder(canvas, roomPos, animatedRadius, roomColor, isSelected, isHovered);

    if (isDetailedView && animationValue > 0.7) { 
      _drawCenterDot(canvas, roomPos, animatedRadius, roomColor, isSelected, isHovered);
    }
  }

  void _drawOuterGlow(Canvas canvas, Offset center, double radius, Color baseColor,
      bool isSelected, bool isHovered) {
    final glowPaint = Paint();
    final glowRadius = radius * (isSelected ? 1.4 : isHovered ? 1.25 : 1.15); 
    final glowOpacity = isSelected ? 0.6 : isHovered ? 0.4 : 0.25; 

    glowPaint.shader = RadialGradient(
      colors: [
        baseColor.withOpacity(glowOpacity * animationValue), 
        baseColor.withOpacity(glowOpacity * 0.7 * animationValue), 
        baseColor.withOpacity(glowOpacity * 0.3 * animationValue), 
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0], 
      radius: 1.0,
    ).createShader(Rect.fromCircle(center: center, radius: glowRadius));

    canvas.drawCircle(center, glowRadius, glowPaint);
  }

  void _drawMainCircle(Canvas canvas, Offset center, double radius, Color baseColor,
      bool isSelected, bool isHovered) {
    final mainPaint = Paint();
    final opacity = isSelected ? 1.0 : isHovered ? 0.95 : 0.9; 

    final lightColor = _lightenColor(baseColor, 0.3); 
    final darkColor = _darkenColor(baseColor, 0.2); 

    mainPaint.shader = RadialGradient(
      colors: [
        lightColor.withOpacity(opacity * animationValue), 
        baseColor.withOpacity(opacity * animationValue), 
        darkColor.withOpacity(opacity * 0.8 * animationValue), 
        darkColor.withOpacity(opacity * 0.6 * animationValue), 
      ],
      stops: const [0.0, 0.4, 0.8, 1.0], 
      radius: 0.95, 
      center: const Alignment(-0.3, -0.3), 
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, mainPaint);
  }

  void _drawInnerHighlight(Canvas canvas, Offset center, double radius, Color baseColor,
      bool isSelected, bool isHovered) {
    final highlightPaint = Paint();
    final highlightRadius = radius * 0.6; 
    final highlightOpacity = isSelected ? 0.8 : isHovered ? 0.6 : 0.4;

    highlightPaint.shader = RadialGradient(
      colors: [
        Colors.white.withOpacity(highlightOpacity * animationValue), 
        baseColor.withOpacity(highlightOpacity * 0.3 * animationValue), 
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0], 
    ).createShader(Rect.fromCircle(center: center, radius: highlightRadius));

    final highlightCenter = Offset(center.dx - radius * 0.15, center.dy - radius * 0.15); 
    canvas.drawCircle(highlightCenter, highlightRadius, highlightPaint);
  }

  void _drawRoomBorder(Canvas canvas, Offset center, double radius, Color baseColor,
      bool isSelected, bool isHovered) {
    final borderPaint = Paint()..style = PaintingStyle.stroke;

    final borderColor = isSelected
        ? _lightenColor(baseColor, 0.4) 
        : isHovered
        ? _lightenColor(baseColor, 0.2) 
        : baseColor;

    final borderWidth = isSelected ? 3.5 : isHovered ? 2.5 : 2.0; 

    borderPaint.color = borderColor.withOpacity(animationValue); 
    borderPaint.strokeWidth = borderWidth * _effectiveScale.clamp(0.8, 2.0) * animationValue; 

    borderPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 1.0 : 0.5); 

    canvas.drawCircle(center, radius, borderPaint);
  }

  void _drawCenterDot(Canvas canvas, Offset center, double radius, Color baseColor,
      bool isSelected, bool isHovered) {
    final dotPaint = Paint();
    final dotRadius = radius * (isSelected ? 0.15 : 0.12); 
    final dotOpacity = isSelected ? 1.0 : isHovered ? 0.8 : 0.6; 

    dotPaint.color = isDarkMode
        ? Colors.white.withOpacity(dotOpacity * animationValue) 
        : _darkenColor(baseColor, 0.4).withOpacity(dotOpacity * animationValue); 

    canvas.drawCircle(center, dotRadius, dotPaint);
  }

  void _drawRoomLabel(Canvas canvas, Room room) {
    final roomPos = _getCanvasPosition(room);
    final double currentLogicalRadius = room.displayRadius;
    final double scaledRadius = currentLogicalRadius * _effectiveScale.clamp(0.6, 2.2); 
    final animatedRadius = scaledRadius * Curves.elasticOut.transform(animationValue.clamp(0.1, 1.0)); 

    final labelOffset = Offset(
        roomPos.dx,
        roomPos.dy - animatedRadius - (8 * _effectiveScale.clamp(0.5, 1.5)) 
    );

    _drawAnimatedText(
      canvas,
      room.name,
      labelOffset,
      color: isDarkMode
          ? Colors.white.withOpacity(0.95 * animationValue) 
          : Colors.black.withOpacity(0.9 * animationValue), 
      fontSize: (10.0 + _effectiveScale * 0.6).clamp(9.0, 16.0), 
      backgroundColor: isDarkMode
          ? Colors.black.withOpacity(0.7) 
          : Colors.white.withOpacity(0.85), 
    );
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor(); 
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor(); 
  }

  Path _extractAnimatedPath(Path originalPath, double animationPercent) {
    if (animationPercent <= 0.0) return Path(); 
    if (animationPercent >= 1.0) return originalPath; 

    final Path animatedPath = Path();
    try {
      final pathMetrics = originalPath.computeMetrics();
      if (pathMetrics.isEmpty) return Path(); 

      for (PathMetric metric in pathMetrics) {
        if (metric.length == 0) continue; 
        final Path extracted = metric.extractPath(0.0, metric.length * animationPercent); 
        animatedPath.addPath(extracted, Offset.zero);
      }
    } catch (e) {
      return Path(); 
    }
    return animatedPath;
  }

  void _drawAnimatedText(
      Canvas canvas,
      String text,
      Offset position, {
        Color? color,
        double fontSize = 10.0, 
        Color? backgroundColor,
      }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? (isDarkMode ? Colors.white70 : Colors.black87), 
          fontSize: fontSize.clamp(6.0, 20.0), 
          fontWeight: FontWeight.w600, 
          shadows: [
            Shadow(
              blurRadius: 2.0, 
              color: Colors.black.withOpacity(0.4), 
              offset: const Offset(0.5, 0.5), 
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr, 
      textAlign: TextAlign.center, 
    );
    textPainter.layout();

    final Offset textOffset = Offset(
        position.dx - textPainter.width / 2, position.dy - textPainter.height / 2); 

    if (backgroundColor != null) {
      final backgroundRect = Rect.fromLTWH(
        textOffset.dx - 6, 
        textOffset.dy - 3, 
        textPainter.width + 12, 
        textPainter.height + 6, 
      );
      final backgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, const Radius.circular(6)), 
        backgroundPaint,
      );
    }
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant RoomAndConnectionPainter oldDelegate) {
    return oldDelegate.rooms != rooms ||
        oldDelegate.connections != connections ||
        oldDelegate.isDetailedView != isDetailedView ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.hoveredRoomId != hoveredRoomId || 
        !listEquals(oldDelegate.rooms.map((r) => r.displayRadius).toList(), 
            rooms.map((r) => r.displayRadius).toList()); 
  }
}