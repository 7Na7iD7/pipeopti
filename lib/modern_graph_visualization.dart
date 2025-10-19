import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'kruskal.dart';
import 'room_and_connection_painter.dart';
import 'grid_painter.dart';
import 'dart:math';


class ModernGraphVisualization extends StatefulWidget {
  final List<Room> rooms;
  final List<Connection> connections;
  final bool isDetailedView;

  const ModernGraphVisualization({
    super.key,
    required this.rooms,
    required this.connections,
    required this.isDetailedView,
  });

  @override
  State<ModernGraphVisualization> createState() =>
      _ModernGraphVisualizationState();
}

class _ModernGraphVisualizationState extends State<ModernGraphVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TransformationController _transformationController =
  TransformationController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  final List<Color> _floorColors = [
    const Color(0xFF1E40AF),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF6366F1),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF0EA5E9),
    const Color(0xFF84CC16),
  ];
  double _currentScale = 1.0;
  bool _isZooming = false;

  Room? _selectedRoom;
  OverlayEntry? _sizeSliderOverlayEntry;
  int? _selectedFloor;
  String _searchQuery = '';
  Room? _highlightedRoom;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    )..addListener(() {
      if (mounted) setState(() {});
    });
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.rooms.isNotEmpty && mounted) _centerAndZoom();
    });

    _transformationController.addListener(() {
      if (mounted) {
        setState(() {
          _currentScale = _transformationController.value.getMaxScaleOnAxis();
        });
      }
    });
  }

  List<Room> get _filteredRooms {
    List<Room> filtered = widget.rooms;

    if (_selectedFloor != null) {
      filtered = filtered.where((room) => room.floor == _selectedFloor).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((room) =>
      room.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.id.toString().contains(_searchQuery)
      ).toList();
    }

    return filtered;
  }

  Set<int> get _availableFloors {
    return widget.rooms.map((room) => room.floor).toSet();
  }

  void _zoomToRoom(Room room) {
    if (!mounted) return;

    setState(() {
      _highlightedRoom = room;
    });

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final viewSize = renderBox.size;

    final painterForSizing = RoomAndConnectionPainter(
        rooms: widget.rooms,
        connections: [],
        isDetailedView: false,
        animationValue: 1.0,
        floorColors: _floorColors,
        maxFloor: widget.rooms.isEmpty ? 0 : widget.rooms.map((r) => r.floor).reduce(max),
        isDarkMode: false);

    final Size dummyPainterSize = Size(viewSize.width * 2, viewSize.height * 2);
    final roomPosition = painterForSizing.getCanvasPositionForTap(room, dummyPainterSize, widget.rooms);

    const double targetScale = 1.5;
    final double dx = (viewSize.width / 2) - (roomPosition.dx * targetScale);
    final double dy = (viewSize.height / 2) - (roomPosition.dy * targetScale);

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(targetScale);

    // Clear highlight after animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _highlightedRoom = null;
        });
      }
    });

    // Close drawer
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _zoomIn() {
    if (!mounted) return;
    setState(() {
      _isZooming = true;
    });
    final newScale = (_currentScale * 1.2).clamp(0.05, 5.0);
    final center = MediaQuery.of(context).size.center(Offset.zero);
    final newMatrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(newScale / _currentScale)
      ..translate(-center.dx, -center.dy);
    _transformationController.value =
        _transformationController.value.multiplied(newMatrix);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {
        _isZooming = false;
      });
    });
  }

  void _zoomOut() {
    if (!mounted) return;
    setState(() {
      _isZooming = true;
    });
    final newScale = (_currentScale / 1.2).clamp(0.05, 5.0);
    final center = MediaQuery.of(context).size.center(Offset.zero);
    final newMatrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(newScale / _currentScale)
      ..translate(-center.dx, -center.dy);
    _transformationController.value =
        _transformationController.value.multiplied(newMatrix);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() {
        _isZooming = false;
      });
    });
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    _centerAndZoom();
    _removeSizeSliderOverlay();
  }

  void _centerAndZoom() {
    if (widget.rooms.isEmpty || !mounted || !context.mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final viewSize = renderBox.size;

    double minLogicalX = widget.rooms.map((r) => r.x).reduce(min);
    double maxLogicalX = widget.rooms.map((r) => r.x).reduce(max);
    double minLogicalY = widget.rooms.map((r) => r.y).reduce(min);
    double maxLogicalY = widget.rooms.map((r) => r.y).reduce(max);

    const double logicalPadding = 20.0;
    minLogicalX -= logicalPadding;
    maxLogicalX += logicalPadding;
    minLogicalY -= logicalPadding;
    maxLogicalY += logicalPadding;

    double minVisualY = double.infinity;
    double maxVisualY = double.negativeInfinity;

    final painterForSizing = RoomAndConnectionPainter(
        rooms: widget.rooms,
        connections: [],
        isDetailedView: false,
        animationValue: 1.0,
        floorColors: _floorColors,
        maxFloor:
        widget.rooms.isEmpty ? 0 : widget.rooms.map((r) => r.floor).reduce(max),
        isDarkMode: false);

    final Size dummyPainterSize = Size(viewSize.width * 2, viewSize.height * 2);

    for (var room in widget.rooms) {
      final pos =
      painterForSizing.getCanvasPositionForTap(room, dummyPainterSize, widget.rooms);
      minLogicalX = min(minLogicalX, room.x);
      maxLogicalX = max(maxLogicalX, room.x);
      minVisualY = min(minVisualY, pos.dy);
      maxVisualY = max(maxVisualY, pos.dy);
    }

    if (minLogicalX == double.infinity ||
        maxLogicalX == double.negativeInfinity ||
        minVisualY == double.infinity ||
        maxVisualY == double.negativeInfinity) return;

    final contentWidth = (maxLogicalX - minLogicalX) *
        painterForSizing.getEffectiveScale(dummyPainterSize, widget.rooms);
    final contentHeight = maxVisualY - minVisualY;

    if (contentWidth <= 0 || contentHeight <= 0) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    final double canvasPaddingForCentering = dummyPainterSize.width * 0.1;

    double scaleX =
        viewSize.width / (contentWidth + (canvasPaddingForCentering * 0.5));
    double scaleY =
        viewSize.height / (contentHeight + (canvasPaddingForCentering * 0.5));
    double scale = min(scaleX, scaleY) * 0.9;
    scale = scale.clamp(0.1, 2.5);

    final double contentCenterX =
        ((minLogicalX + (maxLogicalX - minLogicalX) / 2) *
            painterForSizing.getEffectiveScale(dummyPainterSize, widget.rooms)) +
            canvasPaddingForCentering;
    final double contentCenterY = minVisualY + contentHeight / 2;

    final double dx = (viewSize.width / 2) - (contentCenterX * scale);
    final double dy = (viewSize.height / 2) - (contentCenterY * scale);

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _handleTap(Offset sceneTapPosition, Size painterCanvasSize) {
    if (widget.rooms.isEmpty || !mounted) return;

    Room? tappedRoomCandidate;
    double minDistanceSq = double.infinity;

    final painterForHitTest = RoomAndConnectionPainter(
        rooms: widget.rooms,
        connections: widget.connections,
        isDetailedView: widget.isDetailedView,
        animationValue: _animation.value,
        floorColors: _floorColors,
        maxFloor:
        widget.rooms.isEmpty ? 0 : widget.rooms.map((r) => r.floor).reduce(max),
        isDarkMode: Theme.of(context).brightness == Brightness.dark);

    final double effectiveScaleForTap =
    painterForHitTest.getEffectiveScale(painterCanvasSize, widget.rooms);

    for (var room in widget.rooms) {
      final Offset roomCenterInScene =
      painterForHitTest.getCanvasPositionForTap(room, painterCanvasSize, widget.rooms);
      final double roomVisualRadius = room.displayRadius *
          effectiveScaleForTap.clamp(0.7, 1.8) *
          Curves.elasticOut.transform(_animation.value);

      final double dx = sceneTapPosition.dx - roomCenterInScene.dx;
      final double dy = sceneTapPosition.dy - roomCenterInScene.dy;
      final double distanceSq = dx * dx + dy * dy;

      if (distanceSq < roomVisualRadius * roomVisualRadius) {
        if (distanceSq < minDistanceSq) {
          minDistanceSq = distanceSq;
          tappedRoomCandidate = room;
        }
      }
    }

    _removeSizeSliderOverlay();

    if (tappedRoomCandidate != null) {
      setState(() {
        _selectedRoom = tappedRoomCandidate;
      });
      final Matrix4 currentTransform = _transformationController.value;
      final Offset roomCenterInScene = painterForHitTest.getCanvasPositionForTap(
          _selectedRoom!, painterCanvasSize, widget.rooms);
      final Offset roomCenterInViewport =
      MatrixUtils.transformPoint(currentTransform, roomCenterInScene);

      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final Offset globalRoomCenter = renderBox.localToGlobal(roomCenterInViewport);

      _showSizeSliderOverlay(globalRoomCenter);
    }
  }

  void _showSizeSliderOverlay(Offset globalPosition) {
    if (_selectedRoom == null || !mounted) return;
    _removeSizeSliderOverlay();

    _sizeSliderOverlayEntry = OverlayEntry(
      builder: (context) {
        final roomColor = _floorColors[_selectedRoom!.floor % _floorColors.length];
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        double left = globalPosition.dx - 125;
        double top = globalPosition.dy + 30;

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        if (left < 10) left = 10;
        if (left + 250 > screenWidth - 10) left = screenWidth - 260;
        if (top < 50) top = 50;
        if (top + 160 > screenHeight - 10) top = screenHeight - 170;

        return Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: roomColor.withOpacity(0.5))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Edit: ${_selectedRoom!.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: roomColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: _removeSizeSliderOverlay,
                        tooltip: "Close",
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'Radius: ${_selectedRoom!.displayRadius.toStringAsFixed(1)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700])),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: roomColor,
                      inactiveTrackColor: roomColor.withOpacity(0.3),
                      thumbColor: roomColor,
                      overlayColor: roomColor.withOpacity(0.2),
                      valueIndicatorColor: roomColor,
                      valueIndicatorTextStyle:
                      TextStyle(color: isDark ? Colors.black : Colors.white),
                    ),
                    child: Slider(
                      value: _selectedRoom!.displayRadius,
                      min: 5,
                      max: 30,
                      divisions: 50,
                      label: _selectedRoom!.displayRadius.toStringAsFixed(1),
                      onChanged: (newValue) {
                        if (!mounted || _selectedRoom == null) return;
                        int roomIndex =
                        widget.rooms.indexWhere((r) => r.id == _selectedRoom!.id);
                        if (roomIndex != -1) {
                          setState(() {
                            widget.rooms[roomIndex].displayRadius = newValue;
                            _selectedRoom = widget.rooms[roomIndex];
                          });
                          _sizeSliderOverlayEntry?.markNeedsBuild();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_sizeSliderOverlayEntry!);
  }

  void _removeSizeSliderOverlay() {
    _sizeSliderOverlayEntry?.remove();
    _sizeSliderOverlayEntry = null;
    if (mounted && _selectedRoom != null) {
      setState(() {
        _selectedRoom = null;
      });
    }
  }

  Widget _buildDrawer() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sortedFloors = _availableFloors.toList()..sort();

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_tree_rounded,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E40AF),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Building Configuration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: isDarkMode ? 1.0 : 2.0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isDarkMode ? const Color(0xFF293647) : Colors.white,
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: const PageStorageKey<String>('building_stats_expansion_tile'),
                    backgroundColor: Colors.transparent,
                    collapsedBackgroundColor: Colors.transparent,
                    iconColor: isDarkMode ? Colors.blue[300] : const Color(0xFF1E40AF),
                    collapsedIconColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    title: Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: isDarkMode ? Colors.blue[300] : const Color(0xFF1E40AF),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Building Overview',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    initiallyExpanded: true,
                    childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                    children: <Widget>[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.layers,
                              label: 'floors',
                              value: _availableFloors.length.toString(),
                              color: const Color(0xFF1E40AF),
                              isDark: isDarkMode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.room,
                              label: 'rooms',
                              value: widget.rooms.length.toString(),
                              color: const Color(0xFF10B981),
                              isDark: isDarkMode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search rooms...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Floor Filter
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFloorChip(
                      label: 'All Floors',
                      isSelected: _selectedFloor == null,
                      onTap: () {
                        setState(() {
                          _selectedFloor = null;
                        });
                      },
                      color: Colors.grey,
                      isDark: isDarkMode,
                    ),
                    const SizedBox(width: 8),
                    ...sortedFloors.map((floor) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFloorChip(
                        label: 'Floor $floor',
                        isSelected: _selectedFloor == floor,
                        onTap: () {
                          setState(() {
                            _selectedFloor = floor;
                          });
                        },
                        color: _floorColors[floor % _floorColors.length],
                        isDark: isDarkMode,
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Rooms List
              Expanded(
                child: _filteredRooms.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rooms found',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredRooms.length,
                  itemBuilder: (context, index) {
                    final room = _filteredRooms[index];
                    return _buildRoomTile(room, isDarkMode);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF374151) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTile(Room room, bool isDarkMode) {
    final roomColor = _floorColors[room.floor % _floorColors.length];
    final isHighlighted = _highlightedRoom?.id == room.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? roomColor.withOpacity(0.1)
            : (isDarkMode ? const Color(0xFF374151) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? roomColor
              : (isDarkMode ? Colors.grey[700]! : Colors.grey[200]!),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: roomColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: roomColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              room.floor.toString(),
              style: TextStyle(
                color: roomColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          room.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          'Floor ${room.floor} • Radius: ${room.displayRadius.toStringAsFixed(1)}',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.gps_fixed,
          color: roomColor,
          size: 20,
        ),
        onTap: () => _zoomToRoom(room),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    _searchController.dispose();
    _removeSizeSliderOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(ModernGraphVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rooms.hashCode != oldWidget.rooms.hashCode ||
        widget.connections.hashCode != oldWidget.connections.hashCode) {
      _animationController.forward(from: 0.0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.rooms.isNotEmpty && mounted) _centerAndZoom();
      });
      _removeSizeSliderOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (widget.rooms.isEmpty) {
      return const Center(
        child: Text(
          'No data to visualize',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    int maxFloor = widget.rooms.isNotEmpty
        ? widget.rooms.map((r) => r.floor).reduce(max)
        : 0;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final painterCanvasSize =
              Size(constraints.maxWidth * 2, constraints.maxHeight * 2);
              return GestureDetector(
                onDoubleTap: _resetZoom,
                onTapUp: (details) {
                  final Offset sceneTapPosition =
                  _transformationController.toScene(details.localPosition);
                  _handleTap(sceneTapPosition, painterCanvasSize);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.05,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    panEnabled: true,
                    scaleEnabled: true,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: painterCanvasSize.width,
                        height: painterCanvasSize.height,
                        child: CustomPaint(
                          painter: GridPainter(
                            isDarkMode: isDarkMode,
                            currentMatrix: _transformationController.value,
                          ),
                          foregroundPainter: RoomAndConnectionPainter(
                            rooms: widget.rooms,
                            connections: widget.connections,
                            isDetailedView: widget.isDetailedView,
                            animationValue: _animation.value,
                            floorColors: _floorColors,
                            maxFloor: maxFloor,
                            isDarkMode: isDarkMode,
                            selectedRoomId: _selectedRoom?.id,
                            hoveredRoomId: _highlightedRoom?.id, // changed from selectedRoomId to highlightedRoomId based on original file.
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Menu Button
          Positioned(
            top: 40,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'menuBtn',
              mini: true,
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              tooltip: 'Open Menu',
              backgroundColor: isDarkMode
                  ? const Color(0xFF374151)
                  : Colors.white,
              foregroundColor: isDarkMode
                  ? Colors.white
                  : const Color(0xFF1E293B),
              child: const Icon(Icons.menu),
            ),
          ),

          // Zoom Controls
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomInBtn',
                  mini: true,
                  onPressed: _zoomIn,
                  tooltip: 'Zoom In',
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOutBtn',
                  mini: true,
                  onPressed: _zoomOut,
                  tooltip: 'Zoom Out',
                  child: const Icon(Icons.zoom_out),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'resetZoomBtn',
                  mini: true,
                  onPressed: _resetZoom,
                  tooltip: 'Reset Zoom',
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (_isZooming)
            Positioned.fill(
              child: Center(
                child: SpinKitFadingCircle(
                  color: Theme.of(context).colorScheme.primary,
                  size: 50.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}