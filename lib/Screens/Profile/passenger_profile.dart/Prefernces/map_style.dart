import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi/Constant/colors.dart';

// Enum for type-safe map styles.
enum MapThemeMode { light, dark }

class MapStyleScreen extends StatefulWidget {
  const MapStyleScreen({super.key});

  @override
  State<MapStyleScreen> createState() => _MapStyleScreenState();
}

class _MapStyleScreenState extends State<MapStyleScreen> {
  MapThemeMode _selectedMode = MapThemeMode.light; // Default to light

  // UI constants
  static const _cardPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const _cardBorderRadius = 14.0;
  static const _animationDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _loadSelectedMapMode();
  }

  Future<void> _loadSelectedMapMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('mapTheme') ?? MapThemeMode.light.name;
    debugPrint('Loaded mapTheme from prefs: $themeName');
    if (mounted) {
      setState(() {
        _selectedMode = MapThemeMode.values.byName(themeName);
      });
    }
  }

  Future<void> _saveSelectedMapMode(MapThemeMode mode) async {
    debugPrint('Saving mapTheme to prefs: ${mode.name}');
    if (_selectedMode == mode) return;

    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString('mapTheme', mode.name);
    debugPrint('Save successful: $success');
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Map Style",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _selectedMode == MapThemeMode.dark
                ? Colors.greenAccent.shade100
                : null,
          ),
        ),
        centerTitle: true,
        backgroundColor: _selectedMode == MapThemeMode.dark
            ? const Color(0xFF013220) // your dark green
            : theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _selectedMode == MapThemeMode.dark
              ? Colors.greenAccent.shade100
              : null,
        ),
      ),

      // Use a Stack to layer the map preview behind the controls
      body: Stack(
        children: [
          // The animated map preview fills the background
          _MapPreview(selectedMode: _selectedMode),

          // The scrollable sheet contains the options
          _StyleSelectionSheet(
            selectedMode: _selectedMode,
            onModeSelected: _saveSelectedMapMode,
          ),
        ],
      ),
    );
  }
}

/// A widget that displays the interactive style selection options.
class _StyleSelectionSheet extends StatelessWidget {
  const _StyleSelectionSheet({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final MapThemeMode selectedMode;
  final ValueChanged<MapThemeMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose your preferred map appearance.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: selectedMode == MapThemeMode.dark
                  ? Colors.greenAccent.shade100.withOpacity(0.9)
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
              shadows: [
                Shadow(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...AnimateList(
            interval: 100.ms,
            effects: [
              FadeEffect(duration: 400.ms, curve: Curves.easeOut),
              SlideEffect(
                  begin: const Offset(0, 0.1),
                  duration: 400.ms,
                  curve: Curves.easeOut),
            ],
            children: [
              _buildMapStyleOption(
                theme: theme,
                currentMode: selectedMode,
                targetMode: MapThemeMode.light,
                onTap: () => onModeSelected(MapThemeMode.light),
                icon: CupertinoIcons.sun_max_fill,
                label: 'Light',
                color: Colors.orange,
              ),
              _buildMapStyleOption(
                theme: theme,
                currentMode: selectedMode,
                targetMode: MapThemeMode.dark,
                onTap: () => onModeSelected(MapThemeMode.dark),
                icon: CupertinoIcons.moon_stars_fill,
                label: 'Dark',
                color: darkGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapStyleOption({
    required ThemeData theme,
    required MapThemeMode currentMode,
    required MapThemeMode targetMode,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = currentMode == targetMode;
    final textColor =
        isSelected ? Colors.white : theme.textTheme.bodyLarge!.color!;

    // Use a frosted glass effect for the cards
    final cardColor = isSelected ? color : theme.cardColor.withOpacity(0.85);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _MapStyleScreenState._animationDuration,
          curve: Curves.easeInOutCubic,
          padding: _MapStyleScreenState._cardPadding,
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.5)
                  : theme.dividerColor.withOpacity(0.5),
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius:
                BorderRadius.circular(_MapStyleScreenState._cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.3)
                    : theme.shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: isSelected ? Colors.white : color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: _MapStyleScreenState._animationDuration,
                transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child)),
                child: isSelected
                    ? Icon(Icons.check_circle,
                        color: Colors.white,
                        size: 26,
                        key: const ValueKey('selected'))
                    : Icon(Icons.circle_outlined,
                        color: theme.dividerColor,
                        size: 26,
                        key: const ValueKey('unselected')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays a stylized, animated map preview.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.selectedMode});

  final MapThemeMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final bool isLight = selectedMode == MapThemeMode.light;

    // Define color palettes for light and dark modes
    final landColor = isLight
        ? const Color(0xFFF2F2F2)
        : const Color(0xFF013220); // dark green
    final waterColor = isLight
        ? const Color(0xFFA6D9F7)
        : const Color(0xFF014d3c); // greenish water
    final roadColor =
        isLight ? Colors.white : const Color(0xFF016645); // contrast road
    final parkColor = isLight
        ? const Color(0xFFC8EDD2)
        : const Color(0xFF025e3e); // muted green

    return AnimatedContainer(
      duration: _MapStyleScreenState._animationDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(color: landColor),
      child: Stack(
        children: [
          // Water body
          Positioned(
            top: 100,
            left: -50,
            child: _MapShape(
                color: waterColor, width: 200, height: 250, rotation: 0.5),
          ),
          // Park
          Positioned(
            bottom: 50,
            right: -20,
            child: _MapShape(
                color: parkColor, width: 150, height: 150, rotation: -0.2),
          ),
          // Roads
          Positioned(
              top: -100,
              left: 150,
              child: _MapShape(
                  color: roadColor, width: 80, height: 500, rotation: 0.8)),
          Positioned(
              top: 150,
              left: -20,
              child: _MapShape(
                  color: roadColor, width: 60, height: 400, rotation: -0.3)),
        ],
      ),
    ).animate().fade(duration: 600.ms);
  }
}

/// A simple rotated container to create varied shapes on the map.
class _MapShape extends StatelessWidget {
  const _MapShape({
    required this.color,
    this.width = 100,
    this.height = 100,
    this.rotation = 0,
  });

  final Color color;
  final double width;
  final double height;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: AnimatedContainer(
        duration: _MapStyleScreenState._animationDuration,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
