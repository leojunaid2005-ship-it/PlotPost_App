import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Official PlotPost visual identity: Emerald Green, Forest Green, and Pitch Black.
const String _themePreferenceKey = 'plotpost_theme_mode';

final ValueNotifier<ThemeMode> plotPostThemeMode = ValueNotifier(
  ThemeMode.system,
);

/// Loads the user's saved theme preference before the app is displayed.
Future<void> loadPlotPostThemePreference() async {
  final preferences = await SharedPreferences.getInstance();
  final savedMode = preferences.getString(_themePreferenceKey);

  switch (savedMode) {
    case 'light':
      plotPostThemeMode.value = ThemeMode.light;
      break;
    case 'dark':
      plotPostThemeMode.value = ThemeMode.dark;
      break;
    case 'system':
    default:
      plotPostThemeMode.value = ThemeMode.system;
  }
}

/// Updates the app theme immediately and stores the selection for next launch.
Future<void> setPlotPostThemeMode(ThemeMode mode) async {
  plotPostThemeMode.value = mode;
  final preferences = await SharedPreferences.getInstance();
  final value = switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  await preferences.setString(_themePreferenceKey, value);
}

Color plotPostTextAccent(BuildContext context, Color lightModeColor) {
  final colorScheme = Theme.of(context).colorScheme;
  return colorScheme.brightness == Brightness.dark
      ? colorScheme.onSurfaceVariant
      : lightModeColor;
}

ThemeData? _cachedLightTheme;
ThemeData? _cachedDarkTheme;

ThemeData buildPlotPostTheme(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return _cachedDarkTheme ??= _createTheme(Brightness.dark);
  } else {
    return _cachedLightTheme ??= _createTheme(Brightness.light);
  }
}

ThemeData _createTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  // Emerald Green Palette
  const emeraldGreen = Color(0xFF174B3A); // PlotPost logo emerald
  const forestGreen = Color(0xFF0E3B2E);
  const darkEmerald = Color(0xFFD6A33D);

  // Dark Mode (Pitch Black & Emerald Charcoal)
  const darkBackground = Color(0xFF000000); // Pure Pitch Black
  const darkSurface = Color(0xFF121212); // Off-black Surface
  const darkCard = Color(0xFF1A1A1A); // Post Card Container
  const darkField = Color(0xFF242826); // Input Field / Search Fill
  const darkBorder = Color(0xFF2E3834); // Divider & Outline

  // Light Mode (Clean White & Mint Tint)
  const lightBackground = Color(0xFFFFFFFF); // Pure White
  const lightSurface = Color(0xFFFFFEFB); // Soft White Surface
  const lightField = Color(0xFFF1F6F2); // Light Mint Field
  const lightBorder = Color(0xFFDCE8E0); // Subtle Border

  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? emeraldGreen : const Color(0xFF174B3A),
    onPrimary: Colors.white,
    secondary: dark ? forestGreen : const Color(0xFFD6A33D),
    onSecondary: Colors.white,
    tertiary: dark ? darkEmerald : const Color(0xFFD6A33D),
    onTertiary: Colors.white,
    error: const Color(0xFFED4956),
    onError: Colors.white,
    surface: dark ? darkSurface : lightSurface,
    onSurface: dark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A),
    onSurfaceVariant: dark ? const Color(0xFFA8A8A8) : const Color(0xFF6B7280),
    outline: dark ? darkBorder : lightBorder,
    outlineVariant: dark ? const Color(0xFF242826) : const Color(0xFFEFEFEF),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? const Color(0xFFF5F5F5) : darkSurface,
    onInverseSurface: dark ? darkBackground : const Color(0xFFF5F5F5),
    inversePrimary: emeraldGreen,
    surfaceTint: Colors.transparent,
  );

  final bg = dark ? darkBackground : lightBackground;
  final fieldColor = dark ? darkField : lightField;
  final border = dark ? darkBorder : lightBorder;
  final card = dark ? darkCard : lightBackground;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Manrope',
    visualDensity: VisualDensity.standard,
    canvasColor: bg,
    cardColor: card,
    dividerColor: border,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    textTheme: Typography.material2021().black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldColor,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? emeraldGreen : scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: dark ? emeraldGreen : scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: border),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? darkField : lightField,
      selectedColor: dark
          ? emeraldGreen.withValues(alpha: 0.22)
          : const Color(0xFFD6A33D).withValues(alpha: 0.18),
      disabledColor: dark ? darkSurface : const Color(0xFFEFEFEF),
      side: BorderSide(color: border),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      secondaryLabelStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: dark ? darkBackground : lightBackground,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? darkBackground : lightBackground,
      indicatorColor: dark ? const Color(0xFF242826) : const Color(0xFFEAF1EB),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? darkCard : lightBackground,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? darkCard : lightBackground,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? darkCard : lightBackground,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: scheme.onSurface),
    ),
  );
}
