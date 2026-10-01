/// Canvas Link — Login Screen
/// Clean, single-tap "Connect with Pinterest" authorization flow.
/// Automatically detects deep-link token or clipboard fallback with no manual copy/pasting.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../workers/wallpaper_worker.dart';
import '../utils/image_utils.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  String _statusMessage = '';

  static const _deepLinkChannel = EventChannel('com.wallpapersync.app/auth_deep_link');
  static const _methodChannel = MethodChannel('com.wallpapersync.app/auth_deep_link_method');
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Whenever the app resumes from the browser/custom tab, check for token
      _checkPendingToken();
    }
  }

  void _initDeepLinks() {
    // 1. Real-time stream from MainActivity onNewIntent / onCreate
    _linkSubscription = _deepLinkChannel.receiveBroadcastStream().listen(
      (dynamic link) {
        if (link is String && link.isNotEmpty) {
          _handleTokenLink(link);
        }
      },
      onError: (err) {
        debugPrint('EventChannel error: $err');
      },
    );

    // 2. Immediate check for pending token
    _checkPendingToken();
  }

  Future<void> _checkPendingToken() async {
    try {
      final link = await _methodChannel.invokeMethod<String>('getLatestToken');
      if (link != null && link.isNotEmpty) {
        await _methodChannel.invokeMethod('clearLatestToken');
        _handleTokenLink(link);
        return;
      }
    } catch (_) {}

    // Fallback: clipboard token detection
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clip?.text?.trim();
      if (text != null && text.startsWith('eyJ') && text.split('.').length >= 3) {
        await Clipboard.setData(const ClipboardData(text: ''));
        _submitToken(text);
      }
    } catch (_) {}
  }

  void _handleTokenLink(String link) {
    try {
      final uri = Uri.parse(link);
      String? token = uri.queryParameters['token'];

      if (token == null && uri.fragment.contains('token=')) {
        token = Uri.splitQueryString(uri.fragment)['token'];
      }

      if (token == null) {
        final match = RegExp(r'[?&#]token=([^&#]+)').firstMatch(link);
        if (match != null) {
          token = Uri.decodeComponent(match.group(1)!);
        }
      }

      if (token != null && token.isNotEmpty) {
        _submitToken(token);
      }
    } catch (e) {
      debugPrint('Error parsing token link: $e');
    }
  }

  Future<void> _submitToken(String token) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting account...';
    });

    try {
      await AuthService.saveToken(token);

      // Register background periodic wallpaper sync immediately upon login
      await WallpaperWorker.registerPeriodicSync();

      // Pre-cache screen resolution for background isolate
      await ImageUtils.getScreenResolution();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Logged in successfully! Loading your pins...')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showToast('Invalid authentication. Please try again.');
      await AuthService.deleteToken();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _statusMessage = '';
      });
    }
  }

  Future<void> _connectWithPinterest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening Pinterest...';
    });

    try {
      final authUrl = ApiService.getAuthUrl();
      final uri = Uri.parse(authUrl);

      bool opened = false;
      try {
        opened = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(showTitle: true),
        );
      } catch (_) {
        opened = false;
      }

      if (!opened) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'Authorize in browser to connect...';
        });
      }
    } catch (e) {
      _showToast('Could not open Pinterest: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Developer easter-egg: long press the logo to open manual token entry if ever needed
  void _showManualTokenDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Developer Token Entry', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Paste JWT token here...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final token = controller.text.trim();
              if (token.isNotEmpty) {
                _submitToken(token);
              }
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep sleek background
      body: Stack(
        children: [
          // Background ambient gradient glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE60023).withOpacity(0.12),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Canvas Link Logo
                    GestureDetector(
                      onLongPress: _showManualTokenDialog,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF8B5CF6),
                              child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // App Title
                    Text(
                      'Canvas Link',
                      style: GoogleFonts.outfit(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      'Daily Pinterest Wallpapers for your phone',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Feature Highlights Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0x661E293B),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            title: 'Automatic Daily Wallpapers',
                            subtitle: 'Fresh lock & home screens automatically',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white10, height: 1),
                          ),
                          _buildFeatureRow(
                            icon: Icons.collections_bookmark_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            title: 'Sync from Pinterest Boards',
                            subtitle: 'Choose any of your aesthetic boards',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white10, height: 1),
                          ),
                          _buildFeatureRow(
                            icon: Icons.phone_android_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Home & Lock Screen Control',
                            subtitle: 'Perfect vertical crop tailored to your device',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Primary Action: Connect with Pinterest Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _connectWithPinterest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE60023), // Authentic Pinterest Red
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0xFFE60023).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    _statusMessage.isNotEmpty
                                        ? _statusMessage
                                        : 'Connecting...',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.link_rounded, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Connect with Pinterest',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Seamless explanation note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined,
                            size: 14, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 6),
                        Text(
                          'Opens Pinterest in-app. Log in to connect automatically.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
