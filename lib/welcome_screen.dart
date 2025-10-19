import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';

class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String? routeName;
  final bool showProgressOnTap;

  const EnhancedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.primaryColor,
    this.secondaryColor,
    this.routeName,
    this.showProgressOnTap = false,
  }) : super(key: key);

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton> with SingleTickerProviderStateMixin {
  bool _isButtonPressed = false;
  bool _isLoading = false;
  double _progressValue = 0.0;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveAnimation = Tween<double>(begin: 0.7, end: 2.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _simulateProgress() {
    // تنها زمانی اجرا می‌شود که showProgressOnTap فعال باشد
    if (widget.showProgressOnTap) {
      setState(() {
        _isLoading = true;
        _progressValue = 0.0;
      });

      const totalSteps = 100;
      const stepDuration = Duration(milliseconds: 20);

      for (int i = 1; i <= totalSteps; i++) {
        Future.delayed(stepDuration * i, () {
          if (mounted) {
            setState(() {
              _progressValue = i / totalSteps;
              if (i == totalSteps) {
                _isLoading = false;
                _navigateToRoute();
              }
            });
          }
        });
      }
    } else {
      _navigateToRoute();
    }
  }

  void _navigateToRoute() {
    if (widget.routeName != null) {
      Navigator.of(context).pushReplacementNamed(widget.routeName!);
    } else {
      widget.onPressed();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isButtonPressed = true);
    HapticFeedback.lightImpact(); // بازخورد لمسی خفیف
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isButtonPressed = false);
    HapticFeedback.mediumImpact(); // بازخورد لمسی متوسط
    _simulateProgress();
  }

  void _handleTapCancel() {
    setState(() => _isButtonPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // رنگ‌بندی بر اساس تم و رنگ‌های سفارشی
    final primaryColor = widget.primaryColor ??
        (isDarkMode ? const Color(0xFF0CC7B4) : const Color(0xFF1E40AF));
    final secondaryColor = widget.secondaryColor ??
        (isDarkMode ? Colors.tealAccent : Colors.blueAccent);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
        builder: (context, pulseValue, child) {
          return Transform.scale(
            // اثر فشرده شدن با فشار دکمه
            scale: _isButtonPressed ? 0.95 : pulseValue,
            child: Container(
              width: size.width * 0.85,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withBlue((primaryColor.blue + 20).clamp(0, 255)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  // سایه اصلی
                  BoxShadow(
                    color: primaryColor.withOpacity(0.5),
                    blurRadius: _isButtonPressed ? 10 : 20,
                    spreadRadius: _isButtonPressed ? 0 : 2,
                    offset: _isButtonPressed
                        ? const Offset(0, 2)
                        : const Offset(0, 5),
                  ),
                  // سایه درونی برای عمق بیشتر
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 1,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // افکت موج (ریپل) بر روی دکمه
                  if (!_isButtonPressed)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: AnimatedBuilder(
                          animation: _waveAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (2.0 - _waveAnimation.value) * 0.2,
                              child: Transform.scale(
                                scale: _waveAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // افکت موج دوم (محو شونده از مرکز)
                  if (!_isButtonPressed)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            // این موج با فاز مخالف حرکت می‌کند
                            final phase = (_waveController.value + 0.5) % 1.0;
                            final waveValue = Curves.easeInOut.transform(phase) * 1.3 + 0.7;

                            return Opacity(
                              opacity: (2.0 - waveValue) * 0.15,
                              child: Transform.scale(
                                scale: waveValue,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: secondaryColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // نشانگر پیشرفت دایره‌ای
                  if (_isLoading)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ProgressArcPainter(
                          progress: _progressValue,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),

                  // محتوای دکمه
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.text,
                            style: GoogleFonts.vazirmatn(
                              textStyle: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: 4),
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(-sin(value) * 5, 0),
                                child: child,
                              );
                            },
                            child: Icon(
                              widget.icon ?? Icons.arrow_back_ios_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// کامپوننت کمکی برای نمایش پیشرفت دایره‌ای
class ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressArcPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // کشیدن دایره نامحسوس پشت زمینه
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(0.2)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
    );

    // کشیدن کمان پیشرفت
    canvas.drawArc(
      rect,
      -pi / 2, // شروع از بالا
      2 * pi * progress, // زاویه بر اساس پیشرفت
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ProgressArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// دکمه ثانویه با طراحی ساده‌تر
class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? textColor;
  final Color? borderColor;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.borderColor,
  }) : super(key: key);

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    // رنگ‌های پیش‌فرض
    final textColor = widget.textColor ??
        (isDarkMode ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.9));
    final borderColor = widget.borderColor ??
        (isDarkMode ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.3));

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size.width * 0.85,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          color: Colors.transparent,
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: borderColor.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: GoogleFonts.vazirmatn(
                  textStyle: textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// کلاس اصلی صفحه خوش‌آمدگویی
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isButtonPressed = false;

  // کلید برای دکمه - برای انیمیشن انتقال صفحه
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    // استفاده از انیمیشن انتقال صفحه
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateToAbout() {
    // انتقال به صفحه درباره ما
    Navigator.pushNamed(context, '/about');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // تعریف رنگ‌های اصلی با توجه به حالت تاریک/روشن
    final primaryColor = isDarkMode ? const Color(0xFF0CC7B4) : const Color(0xFF1E40AF);
    final secondaryColor = isDarkMode ? Colors.tealAccent : Colors.blueAccent;
    final bgGradientColors = isDarkMode
        ? [const Color(0xFF0A192F), const Color(0xFF112240), const Color(0xFF1E293B)]
        : [const Color(0xFF3B82F6), const Color(0xFF2563EB), const Color(0xFF10B981)];

    return Directionality(
      // تنظیم RTL برای پشتیبانی بهتر از زبان فارسی
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated Background
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradientColors,
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  stops: const [0.1, 0.5, 0.9],
                ),
              ),
              child: Stack(
                children: [
                  // Animated particles/bubbles for background effect
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white.withOpacity(0.1)],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.srcOver,
                      child: Lottie.asset(
                        'assets/animations/welcome_pipes.json',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        // بهینه‌سازی برای جلوگیری از لود غیرضروری
                        frameRate: FrameRate(30),
                        repeat: true,
                      ),
                    ),
                  ),

                  // Floating circular shapes in background
                  Positioned(
                    top: size.height * 0.1,
                    left: -size.width * 0.2,
                    child: Container(
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondaryColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: -size.width * 0.1,
                    right: -size.width * 0.1,
                    child: Container(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            isDarkMode ? Colors.teal.withOpacity(0.2) : Colors.teal.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Animation Container
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: size.width * 0.8,
                          height: size.width * 0.8,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glowing circle behind animation
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.95, end: 1.05),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      width: size.width * 0.65,
                                      height: size.width * 0.65,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: secondaryColor.withOpacity(0.4),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(),
                              ),

                              // Main animation
                              ClipRRect(
                                borderRadius: BorderRadius.circular(size.width * 0.3),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    width: size.width * 0.6,
                                    height: size.width * 0.6,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Lottie.asset(
                                      'assets/animations/welcome_pipes.json',
                                      fit: BoxFit.contain,
                                      frameRate: FrameRate(30),
                                      repeat: true,
                                      errorBuilder: (context, error, stackTrace) => SpinKitPulse(
                                        color: colorScheme.primary,
                                        size: 100.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Rotating loading indicator
                              Positioned.fill(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 2 * pi),
                                  duration: const Duration(seconds: 10),
                                  builder: (context, value, child) {
                                    return Transform.rotate(
                                      angle: value,
                                      child: child,
                                    );
                                  },
                                  child: CustomPaint(
                                    painter: DashedCirclePainter(
                                      color: secondaryColor,
                                      strokeWidth: 1.5,
                                      dashWidth: 5,
                                      dashSpace: 3,
                                      opacity: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Title and description with animations
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'به دنیای بهینه‌سازی هوشمند',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.vazirmatn(
                              textStyle: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: secondaryColor.withOpacity(0.5),
                                    offset: const Offset(0, 2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'با استفاده از فناوری پیشرفته، بهترین طراحی شبکه لوله‌کشی را تجربه کنید.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.vazirmatn(
                              textStyle: textTheme.titleMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      // استفاده از دکمه پیشرفته
                      EnhancedButton(
                        key: _buttonKey,
                        text: 'شروع کنید',
                        icon: Icons.arrow_back_ios_rounded,
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                        showProgressOnTap: true, // نمایش نشانگر پیشرفت
                        routeName: '/login', // تعیین مسیر مستقیم برای ناوبری
                        onPressed: _navigateToLogin,
                      ),

                      // دکمه جدید - درباره ما
                      const SizedBox(height: 15),
                      SecondaryButton(
                        text: 'درباره ما',
                        icon: Icons.info_outline_rounded,
                        onPressed: _navigateToAbout,
                      ),

                      // کپی‌رایت یا متن اضافه در پایین صفحه
                      Padding(
                        padding: EdgeInsets.only(top: size.height * 0.05),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'نسخه ۲.۰.۵',
                            style: GoogleFonts.vazirmatn(
                              textStyle: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for dashed circle
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double opacity;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Paint paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double startAngle = 0;
    final double sweepAngle = dashWidth / radius;
    final double totalAngle = 2 * pi;
    final int dashCount = (totalAngle / (sweepAngle + dashSpace / radius)).floor();

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + (dashSpace / radius);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter oldDelegate) => false;
}