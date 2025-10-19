import 'package:flutter/material.dart';
import 'dart:math'; // Added import

class GridPainter extends CustomPainter {
  final bool isDarkMode;
  final Matrix4 currentMatrix;

  GridPainter({required this.isDarkMode, required this.currentMatrix});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: isDarkMode
            ? [const Color(0xFF0A101C), const Color(0xFF121A2A)]
            : [const Color(0xFFFDFEFF), Colors.grey.shade50],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final Matrix4 inverseMatrix =
        Matrix4.tryInvert(currentMatrix) ?? Matrix4.identity();

    final Offset topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final Offset topRight =
    MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, 0));
    final Offset bottomLeft =
    MatrixUtils.transformPoint(inverseMatrix, Offset(0, size.height));

    final double minVisibleX = min(topLeft.dx, bottomLeft.dx);
    final double maxVisibleX = max(
        topRight.dx,
        MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height))
            .dx);
    final double minVisibleY = min(topLeft.dy, topRight.dy);
    final double maxVisibleY = max(
        bottomLeft.dy,
        MatrixUtils.transformPoint(inverseMatrix, Offset(size.width, size.height))
            .dy);

    const double baseSpacing = 60.0;
    final double scale = currentMatrix.getMaxScaleOnAxis();
    final double dynamicSpacing = (baseSpacing / scale.clamp(0.1, 5.0)).clamp(20.0, 200.0);

    if (dynamicSpacing.isInfinite || dynamicSpacing.isNaN || dynamicSpacing <= 0) {
      return;
    }

    for (double x = (minVisibleX ~/ dynamicSpacing) * dynamicSpacing;
    x <= maxVisibleX;
    x += dynamicSpacing) {
      final Offset p1 = MatrixUtils.transformPoint(
        currentMatrix,
        Offset(x, minVisibleY),
      );
      final Offset p2 = MatrixUtils.transformPoint(
        currentMatrix,
        Offset(x, maxVisibleY),
      );
      canvas.drawLine(p1, p2, gridPaint);
    }

    for (double y = (minVisibleY ~/ dynamicSpacing) * dynamicSpacing;
    y <= maxVisibleY;
    y += dynamicSpacing) {
      final Offset p1 = MatrixUtils.transformPoint(
        currentMatrix,
        Offset(minVisibleX, y),
      );
      final Offset p2 = MatrixUtils.transformPoint(
        currentMatrix,
        Offset(maxVisibleX, y),
      );
      canvas.drawLine(p1, p2, gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.currentMatrix != currentMatrix;
  }
}