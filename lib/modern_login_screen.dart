import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' show pi, sin, cos;
import 'main.dart';
import 'dart:math';
import 'pipe_layout_screen.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  int _selectedAuthMethod = 0;

  // Animation controllers
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late final AnimationController _particlesController;
  late final AnimationController _loadingAnimationController;
  late final AnimationController _backgroundController;

  // Animations
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _iconRotationAnimation;

  // List to store particle animations
  final List<Particle> _particles = [];
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Main animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Pulse animation for the logo
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Icon rotation animation
    _iconRotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.linear,
      ),
    );

    _initializeParticles();

    // Start animations
    _animationController.forward();

    HapticFeedback.mediumImpact();
  }


  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 8 + 2,
          speed: random.nextDouble() * 0.005 + 0.001,
          opacity: random.nextDouble() * 0.6 + 0.2,
          color: [
            Colors.blueAccent,
            Colors.tealAccent,
            Colors.purpleAccent,
            Colors.cyanAccent,
          ][random.nextInt(4)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    _loadingAnimationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      _loadingAnimationController.repeat();

      HapticFeedback.mediumImpact();

      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;

      _loadingAnimationController.stop();

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) {
            return FadeTransition(
              opacity: animation,
              child: const PipeLayoutScreen(),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                      const Color(0xFF0A192F),
                      const Color(0xFF112240),
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ]
                        : [
                      const Color(0xFF3B82F6),
                      const Color(0xFF2563EB),
                      const Color(0xFF10B981),
                      const Color(0xFF0EA5E9),
                    ],
                    begin: Alignment(
                      cos(_backgroundController.value * 2 * pi) * 0.5 + 0.5,
                      sin(_backgroundController.value * 2 * pi) * 0.5 + 0.5,
                    ),
                    end: Alignment(
                      cos(_backgroundController.value * 2 * pi + pi) * 0.5 + 0.5,
                      sin(_backgroundController.value * 2 * pi + pi) * 0.5 + 0.5,
                    ),
                    stops: const [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
              );
            },
          ),

          // Particle effects
          CustomPaint(
            painter: ParticlesPainter(
              particles: _particles,
              animation: _particlesController,
            ),
            size: Size.infinite,
          ),

          // Floating light spheres
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + 0.05 * sin(_pulseController.value * 2 * pi),
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDarkMode
                              ? Colors.indigo.withOpacity(0.4)
                              : Colors.blue.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDarkMode ? Colors.indigo : Colors.blue).withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom left sphere
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.1,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + 0.08 * sin(_pulseController.value * 2 * pi + pi/3),
                  child: Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDarkMode
                              ? Colors.teal.withOpacity(0.3)
                              : Colors.teal.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Additional atmosphere sphere
          Positioned(
            top: size.height * 0.3,
            left: -size.width * 0.15,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + 0.06 * sin(_pulseController.value * 2 * pi + pi/2),
                  child: Container(
                    width: size.width * 0.4,
                    height: size.width * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDarkMode
                              ? Colors.purple.withOpacity(0.2)
                              : Colors.purple.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle pattern overlay with rotation
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _backgroundController.value * 2 * pi * 0.25,
                    child: Image.asset(
                      'assets/images/pattern.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Main Content with enhanced frosted glass effect
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo section with enhanced animation
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.6),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDarkMode
                                                ? Colors.tealAccent.withOpacity(0.4)
                                                : Colors.blueAccent.withOpacity(0.4),
                                            blurRadius: 25,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Lottie.asset(
                                          'assets/animations/welcome_pipes.json',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.engineering, size: 60, color: colorScheme.primary),
                                        ),
                                      ),
                                    ).animate(
                                      onPlay: (controller) => controller.repeat(),
                                    ).shimmer(
                                      duration: 3.seconds,
                                      color: Colors.white30,
                                    ),
                                  );
                                },
                              ),

                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    'ورود به سیستم',
                                    style: GoogleFonts.vazirmatn(
                                      textStyle: textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: isDarkMode
                                                ? Colors.tealAccent.withOpacity(0.5)
                                                : Colors.blueAccent.withOpacity(0.5),
                                            offset: const Offset(0, 2),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 600.ms).slideY(
                                begin: 0.3,
                                end: 0,
                                curve: Curves.easeOutCubic,
                                duration: 800.ms,
                              ),

                              const SizedBox(height: 8),
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    'لطفاً اطلاعات خود را وارد کنید',
                                    style: GoogleFonts.vazirmatn(
                                      textStyle: textTheme.titleMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(
                                delay: 300.ms,
                                begin: 0.3,
                                end: 0,
                                curve: Curves.easeOutCubic,
                                duration: 800.ms,
                              ),

                              const SizedBox(height: 30),

                              // Authentication method selector
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildAuthMethodButton(
                                            icon: Icons.password_rounded,
                                            label: 'رمز عبور',
                                            isSelected: _selectedAuthMethod == 0,
                                            onTap: () {
                                              setState(() {
                                                _selectedAuthMethod = 0;
                                              });
                                              HapticFeedback.selectionClick();
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildAuthMethodButton(
                                            icon: Icons.fingerprint,
                                            label: 'اثر انگشت',
                                            isSelected: _selectedAuthMethod == 1,
                                            onTap: () {
                                              setState(() {
                                                _selectedAuthMethod = 1;
                                              });
                                              HapticFeedback.selectionClick();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(
                                delay: 400.ms,
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1, 1),
                                duration: 600.ms,
                              ),

                              // Username field with animation
                              if (_selectedAuthMethod == 0)
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(-0.2, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
                                      ),
                                    ),
                                    child: _buildTextField(
                                      controller: _usernameController,
                                      labelText: 'نام کاربری',
                                      prefixIcon: Icons.person,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'لطفاً نام کاربری را وارد کنید';
                                        }
                                        return null;
                                      },
                                      hintText: 'نام کاربری خود را وارد کنید',
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideX(
                                  delay: 500.ms,
                                  begin: -0.2,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                  duration: 800.ms,
                                ),

                              if (_selectedAuthMethod == 0) const SizedBox(height: 24),

                              // Password field with animation OR Fingerprint widget
                              _selectedAuthMethod == 0
                                  ? FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.2, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: _buildTextField(
                                    controller: _passwordController,
                                    labelText: 'رمز عبور',
                                    prefixIcon: Icons.lock,
                                    obscureText: !_isPasswordVisible,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'لطفاً رمز عبور را وارد کنید';
                                      } else if (value.length < 6) {
                                        return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                                      }
                                      return null;
                                    },
                                    hintText: 'رمز عبور خود را وارد کنید',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideX(
                                delay: 600.ms,
                                begin: 0.2,
                                end: 0,
                                curve: Curves.easeOutCubic,
                                duration: 800.ms,
                              )
                                  : FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildFingerprintSection(isDarkMode),
                              ).animate().fadeIn(delay: 500.ms, duration: 800.ms).scale(
                                delay: 500.ms,
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 800.ms,
                              ),

                              if (_selectedAuthMethod == 0) const SizedBox(height: 8),

                              // Remember me & Forgot password row
                              if (_selectedAuthMethod == 0)
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Remember me checkbox
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Transform.scale(
                                                  scale: 0.9,
                                                  child: Checkbox(
                                                    value: _rememberMe,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _rememberMe = value!;
                                                      });
                                                      HapticFeedback.selectionClick();
                                                    },
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    checkColor: isDarkMode ? Colors.black : Colors.white,
                                                    fillColor: MaterialStateProperty.resolveWith<Color>(
                                                          (Set<MaterialState> states) {
                                                        if (states.contains(MaterialState.selected)) {
                                                          return isDarkMode ? Colors.tealAccent : Colors.blueAccent;
                                                        }
                                                        return Colors.white.withOpacity(0.3);
                                                      },
                                                    ),
                                                    side: BorderSide(
                                                      color: Colors.white.withOpacity(0.6),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'مرا به خاطر بسپار',
                                                style: GoogleFonts.vazirmatn(
                                                  textStyle: TextStyle(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Forgot password link
                                          TextButton(
                                            onPressed: () {
                                              HapticFeedback.selectionClick();
                                              // Handle forgot password
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: isDarkMode ? Colors.tealAccent : Colors.blueAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'فراموشی رمز عبور؟',
                                              style: GoogleFonts.vazirmatn(
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 700.ms, duration: 600.ms).slideY(
                                  delay: 700.ms,
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                ),

                              const SizedBox(height: 32),

                              // Login button with enhanced animation
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDarkMode ? Colors.tealAccent : Colors.blueAccent,
                                        foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 8,
                                        shadowColor: isDarkMode
                                            ? Colors.tealAccent.withOpacity(0.6)
                                            : Colors.blueAccent.withOpacity(0.6),
                                      ),
                                      child: _isLoading
                                          ? AnimatedBuilder(
                                        animation: _iconRotationAnimation,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: _iconRotationAnimation.value,
                                            child: const SpinKitRing(
                                              color: Colors.white,
                                              size: 24.0,
                                              lineWidth: 2.0,
                                            ),
                                          );
                                        },
                                      )
                                          : Text(
                                        _selectedAuthMethod == 0 ? 'ورود به سامانه' : 'ورود با اثر انگشت',
                                        style: GoogleFonts.vazirmatn(
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 800.ms, duration: 600.ms).scale(
                                delay: 800.ms,
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1, 1),
                                duration: 800.ms,
                              ),

                              const SizedBox(height: 24),

                              // Sign up link
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'حساب کاربری ندارید؟',
                                        style: GoogleFonts.vazirmatn(
                                          textStyle: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          // Handle sign up navigation
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDarkMode ? Colors.tealAccent : Colors.blueAccent,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'ثبت نام کنید',
                                          style: GoogleFonts.vazirmatn(
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 900.ms, duration: 600.ms).slideY(
                                delay: 900.ms,
                                begin: 0.2,
                                end: 0,
                                duration: 600.ms,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.vazirmatn(
        textStyle: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 15,
        ),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: GoogleFonts.vazirmatn(
          textStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        hintStyle: GoogleFonts.vazirmatn(
          textStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.white.withOpacity(0.7),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.tealAccent,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.redAccent.withOpacity(0.8),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.redAccent.withOpacity(0.8),
            width: 2,
          ),
        ),
        errorStyle: GoogleFonts.vazirmatn(
          textStyle: TextStyle(
            color: Colors.redAccent.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  // Helper method to build authentication method selection buttons
  Widget _buildAuthMethodButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.vazirmatn(
                textStyle: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build fingerprint authentication section
  Widget _buildFingerprintSection(bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: isDarkMode ? Colors.tealAccent.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + 0.2 * sin(_pulseController.value * 2 * pi),
                child: Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'برای ورود، اثر انگشت خود را اسکن کنید',
          style: GoogleFonts.vazirmatn(
            textStyle: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Particle class for background effects
class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

// Particle painter for custom animation
class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;

  ParticlesPainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      particle.y = (particle.y + particle.speed) % 1.0;

      // Draw the particle
      paint.color = particle.color.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );

      paint.color = particle.color.withOpacity(particle.opacity * 0.3);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size * 1.5,
        paint,
      );

      paint.maskFilter = null;
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}