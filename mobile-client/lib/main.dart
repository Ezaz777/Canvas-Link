import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'services/ad_service.dart';
import 'workers/wallpaper_worker.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/pinterest_theme.dart';
import 'utils/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent system navigation bar and status bar for edge-to-edge support
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Fast parallel read of essential local storage values only
  final results = await Future.wait([
    Settings.getThemeMode(),
    Settings.hasSeenOnboarding(),
    AuthService.isLoggedIn(),
  ]);

  final savedMode = results[0] as String;
  final hasSeenOnboarding = results[1] as bool;
  final isLoggedIn = results[2] as bool;

  try {
    PinterestTheme.themeModeNotifier.value = PinterestTheme.stringToThemeMode(savedMode);
  } catch (_) {}

  // Launch UI immediately — zero startup lag!
  runApp(WallpaperSyncApp(
    isLoggedIn: isLoggedIn,
    hasSeenOnboarding: hasSeenOnboarding,
  ));

  // Initialize heavy services (AdMob SDK & WorkManager) in the background
  // without blocking the user interface or app cold launch.
  Future.microtask(() async {
    try {
      await AdService.instance.initialize();
    } catch (_) {}

    try {
      await WallpaperWorker.initialize();
      if (isLoggedIn) {
        await WallpaperWorker.registerPeriodicSync();
      }
    } catch (_) {}
  });
}

class WallpaperSyncApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasSeenOnboarding;

  const WallpaperSyncApp({
    super.key,
    required this.isLoggedIn,
    required this.hasSeenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PinterestTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Pinterest Auto Wallpaper',
          debugShowCheckedModeBanner: false,
          theme: PinterestTheme.lightTheme,
          darkTheme: PinterestTheme.darkTheme,
          themeMode: themeMode,
          home: !hasSeenOnboarding
              ? const OnboardingScreen()
              : (isLoggedIn ? const HomeScreen() : const LoginScreen()),
        );
      },
    );
  }
}
