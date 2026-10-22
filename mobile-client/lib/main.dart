import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'workers/wallpaper_worker.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/pinterest_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set transparent status bar to allow theme-based adaptive icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialize WorkManager for background tasks
  await WallpaperWorker.initialize();

  // Check if user is logged in
  final isLoggedIn = await AuthService.isLoggedIn();

  // Register periodic sync if logged in
  if (isLoggedIn) {
    await WallpaperWorker.registerPeriodicSync();
  }

  runApp(WallpaperSyncApp(isLoggedIn: isLoggedIn));
}

class WallpaperSyncApp extends StatelessWidget {
  final bool isLoggedIn;

  const WallpaperSyncApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canvas Link',
      debugShowCheckedModeBanner: false,
      theme: PinterestTheme.lightTheme,
      darkTheme: PinterestTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically matches user's system default
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}

