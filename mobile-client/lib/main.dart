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

  // Load saved theme mode
  try {
    final savedMode = await Settings.getThemeMode();
    PinterestTheme.themeModeNotifier.value = PinterestTheme.stringToThemeMode(savedMode);
  } catch (_) {}

  // Set transparent system navigation bar and status bar for edge-to-edge support
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize WorkManager for background tasks
  await WallpaperWorker.initialize();

  // Initialize AdMob Mobile Ads
  await AdService.instance.initialize();

  // Check onboarding and login status
  final hasSeenOnboarding = await Settings.hasSeenOnboarding();
  final isLoggedIn = await AuthService.isLoggedIn();

  // Register periodic sync if logged in
  if (isLoggedIn) {
    await WallpaperWorker.registerPeriodicSync();
  }

  runApp(WallpaperSyncApp(
    isLoggedIn: isLoggedIn,
    hasSeenOnboarding: hasSeenOnboarding,
  ));
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
