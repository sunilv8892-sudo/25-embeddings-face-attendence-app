import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application constants and theming
class AppConstants {
  AppConstants._();

  static const String appName = 'FAS';
  static const String appVersion = '18.4.0';
  static const String subtitle =
      'Offline Mobile Face Recognition Attendance System Using Face Embedding and Similarity Matching';

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4B3FD8);
  static const Color primaryLight = Color(0xFFE8E6FF);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color accentDark = Color(0xFF009FC2);

  static const Color secondaryColor = Color(0xFF1B2A49);
  static const Color surfaceColor = Color(0xFF243354);

  static const Color successColor = Color(0xFF00E096);
  static const Color successLight = Color(0xFF52FFB8);
  static const Color warningColor = Color(0xFFFFB830);
  static const Color errorColor = Color(0xFFFF4D4D);
  static const Color errorLight = Color(0xFFFF8080);

  static const Color backgroundColor = Color(0xFF0D1B2A);
  static const Color cardColor = Color(0xFF1B2A49);
  static const Color cardBorder = Color(0x40FFFFFF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCDD5E0);
  static const Color textTertiary = Color(0xFF8B9BB4);

  static const Color inputFill = Color(0xFF1B2A49);
  static const Color inputBorder = Color(0x44FFFFFF);

  static const Color dividerColor = Color(0x1AFFFFFF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2A49), Color(0xFF243354)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF9B59F5)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4FF), Color(0xFF00A878)],
  );

  static const double glassOpacity = 0.08;
  static const double glassBorderOpacity = 0.15;
  static const double glassBlur = 12.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 16.0;

  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x40000000),
    blurRadius: 24.0,
    offset: Offset(0, 8),
  );

  static const BoxShadow buttonShadow = BoxShadow(
    color: Color(0x506C63FF),
    blurRadius: 20.0,
    offset: Offset(0, 8),
  );

  static const double similarityThreshold = 0.75;
  static const int requiredEnrollmentSamples = 25;
  static const int recommendedEnrollmentSamples = 15;
  static const int embeddingDimension = 128;

  static const String routeHome = '/';
  static const String routeEnroll = '/enroll';
  static const String routeAttendance = '/attendance';
  static const String routeDatabase = '/database';
  static const String routeExport = '/export';
  static const String routeSettings = '/settings';
  static const String routeExpressionDetection = '/expression_detection';

  static const String dbName = 'attendance.db';
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          surface: AppConstants.cardColor,
          background: AppConstants.backgroundColor,
          error: AppConstants.errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppConstants.textPrimary,
          onBackground: AppConstants.textPrimary,
          onError: Colors.white,
        );

    final baseTheme = ThemeData.from(colorScheme: colorScheme);
    final textTheme = GoogleFonts.outfitTextTheme(baseTheme.textTheme).apply(
      bodyColor: AppConstants.textPrimary,
      displayColor: AppConstants.textPrimary,
    );

    return baseTheme.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      canvasColor: AppConstants.backgroundColor,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppConstants.textPrimary),
        titleTextStyle: TextStyle(
          color: AppConstants.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.cardColor.withValues(alpha: 0.82),
        shadowColor: AppConstants.cardShadow.color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          side: const BorderSide(color: AppConstants.cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppConstants.buttonShadow.color,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.textPrimary,
          side: const BorderSide(color: AppConstants.cardBorder, width: 1.2),
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.accentColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.inputFill.withValues(alpha: 0.95),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          borderSide: const BorderSide(color: AppConstants.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          borderSide: const BorderSide(color: AppConstants.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          borderSide: const BorderSide(
            color: AppConstants.accentColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        hintStyle: const TextStyle(
          color: AppConstants.textTertiary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppConstants.textSecondary,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.cardColor.withValues(alpha: 0.72),
        disabledColor: AppConstants.cardColor.withValues(alpha: 0.36),
        selectedColor: AppConstants.primaryColor.withValues(alpha: 0.24),
        secondarySelectedColor: AppConstants.accentColor.withValues(
          alpha: 0.22,
        ),
        labelStyle: const TextStyle(color: AppConstants.textPrimary),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppConstants.cardBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.dividerColor,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppConstants.textPrimary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.cardColor.withValues(alpha: 0.95),
        contentTextStyle: GoogleFonts.outfit(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          side: const BorderSide(color: AppConstants.cardBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.cardColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          color: AppConstants.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: AppConstants.textSecondary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppConstants.cardBorder),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppConstants.backgroundColor.withValues(alpha: 0.92),
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: AppConstants.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppConstants.backgroundColor.withValues(alpha: 0.92),
        indicatorColor: AppConstants.primaryColor.withValues(alpha: 0.24),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppConstants.accentColor,
        unselectedLabelColor: AppConstants.textTertiary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.accentColor,
      ),
    );
  }
}

class ColorSchemes {
  static const Color presentColor = Color(0xFF4CAF50);
  static const Color absentColor = Color(0xFFE53935);
  static const Color lateColor = Color(0xFFFFA726);
  static const Color pendingColor = Color(0xFF1E88E5);
}
