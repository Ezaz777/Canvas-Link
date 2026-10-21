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

  // Set system UI overlay style matching Pinterest design
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: PinterestTheme.surfaceSoft,
      systemNavigationBarIconBrightness: Brightness.dark,
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: PinterestTheme.primary,
        scaffoldBackgroundColor: PinterestTheme.surfaceSoft,
        canvasColor: PinterestTheme.canvas,
        cardColor: PinterestTheme.surfaceCard,
        dividerColor: PinterestTheme.hairline,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: PinterestTheme.body,
          displayColor: PinterestTheme.ink,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: PinterestTheme.surfaceSoft,
          foregroundColor: PinterestTheme.ink,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.inter(
            color: PinterestTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: PinterestTheme.primaryButtonStyle(),
        ),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}

