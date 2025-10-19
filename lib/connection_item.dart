import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'kruskal.dart';

class ConnectionItem extends StatefulWidget {
  final Connection connection;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? customColor;

  const ConnectionItem({
    super.key,
    required this.connection,
    this.onTap,
    this.isSelected = false,
    this.customColor,
  });

  @override
  State<ConnectionItem> createState() => _ConnectionItemState();
}

class _ConnectionItemState extends State<ConnectionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.customColor ?? Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: _buildDecoration(isDarkMode, surfaceColor),
                child: _buildContent(context, primaryColor, tertiaryColor, isDarkMode),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildDecoration(bool isDarkMode, Color surfaceColor) {
    final baseColor = isDarkMode ? Colors.grey[800] : Colors.grey[50];
    final borderColor = isDarkMode ? Colors.grey[600] : Colors.grey[300];

    return BoxDecoration(
      color: widget.isSelected
          ? (isDarkMode ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.08))
          : _isHovered
          ? baseColor?.withOpacity(0.8)
          : baseColor?.withOpacity(0.6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: widget.isSelected
            ? (isDarkMode ? Colors.blue.withOpacity(0.5) : Colors.blue.withOpacity(0.3))
            : borderColor?.withOpacity(_isHovered ? 0.8 : 0.4) ?? Colors.transparent,
        width: widget.isSelected ? 2.0 : 1.0,
      ),
      boxShadow: [
        if (_isHovered || widget.isSelected)
          BoxShadow(
            color: widget.isSelected
                ? Colors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: widget.isSelected ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: widget.isSelected ? 2 : 0,
          ),
        BoxShadow(
          color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, Color primaryColor, Color tertiaryColor, bool isDarkMode) {
    return Column(
      children: [
        // Header با distance
        _buildHeader(primaryColor, tertiaryColor, isDarkMode),
        const SizedBox(height: 16),

        // Connection line با animation
        _buildAnimatedConnectionLine(primaryColor, tertiaryColor),
        const SizedBox(height: 16),

        // Room circles و نام‌ها
        _buildRoomSection(context, primaryColor, tertiaryColor, isDarkMode),
      ],
    );
  }

  Widget _buildHeader(Color primaryColor, Color tertiaryColor, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.compare_arrows_rounded,
          size: 20,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.2),
                tertiaryColor.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${widget.connection.distance.toStringAsFixed(1)} units',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedConnectionLine(Color primaryColor, Color tertiaryColor) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.8),
                tertiaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.6),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.4 * _glowAnimation.value),
                blurRadius: 8 * _glowAnimation.value,
                spreadRadius: 1 * _glowAnimation.value,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3 * _glowAnimation.value),
                  Colors.transparent,
                  Colors.white.withOpacity(0.2 * _glowAnimation.value),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomSection(BuildContext context, Color primaryColor, Color tertiaryColor, bool isDarkMode) {
    return Row(
      children: [
        // From Room
        Expanded(
          child: _buildRoomInfo(
            context,
            widget.connection.from,
            primaryColor,
            isDarkMode,
            isLeft: true,
          ),
        ),

        // Center connector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: 20,
                color: (isDarkMode ? Colors.grey[400] : Colors.grey[600])?.withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        // To Room
        Expanded(
          child: _buildRoomInfo(
            context,
            widget.connection.to,
            tertiaryColor,
            isDarkMode,
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomInfo(BuildContext context, Room room, Color color, bool isDarkMode, {required bool isLeft}) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        // Room Circle
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                color,
                color.withOpacity(0.8),
              ],
              stops: const [0.0, 0.7, 1.0],
              center: const Alignment(-0.3, -0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  room.name.isNotEmpty ? room.name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Room Name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isDarkMode ? Colors.grey[800] : Colors.grey[100])?.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            room.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
            ),
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Floor info
        if (room.floor > 0) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Floor ${room.floor}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );
  }
}