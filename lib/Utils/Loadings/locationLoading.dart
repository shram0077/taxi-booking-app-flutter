import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi/Constant/colors.dart';

class LocationLoading extends StatefulWidget {
  final String title;

  const LocationLoading({super.key, required this.title});

  @override
  State<LocationLoading> createState() => _LocationLoadingState();
}

class _LocationLoadingState extends State<LocationLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkTheme();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadDarkTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getString('mapTheme') == 'dark');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

    final bgColor = isDark
        ? const Color(0xFF013220)
        : Theme.of(context).scaffoldBackgroundColor;
    final primary = isDark ? const Color(0xFF01A86B) : primaryColor;
    final textColor = isDark ? Colors.greenAccent.shade100 : primaryColor;
    final textColorSecondary = textColor.withOpacity(0.4);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.6)
                  : primaryColor.withOpacity(0.15),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.green.shade900.withOpacity(0.7)
                  : Colors.white.withOpacity(0.7),
              offset: const Offset(-8, -8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPulsingLocation(primary),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: Tween<double>(begin: 0.6, end: 1.0).animate(
                CurvedAnimation(
                    parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please wait while we find your location",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: _isDarkMode ? Colors.grey[350] : textColorSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingLocation(Color primary) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primary.withOpacity(0.3),
                  primary.withOpacity(0.05),
                ],
                stops: const [0.4, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.25),
                  blurRadius: 16,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: primary,
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.6),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}
