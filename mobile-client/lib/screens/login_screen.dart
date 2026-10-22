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
import '../utils/pinterest_theme.dart';
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
        });
      }
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: PinterestTheme.ink)),
        backgroundColor: PinterestTheme.canvas,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
          side: const BorderSide(color: PinterestTheme.hairlineSoft),
        ),
      ),
    );
  }

  // Developer easter-egg: long press the logo to open manual token entry if ever needed
  void _showManualTokenDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PinterestTheme.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PinterestTheme.radiusLg),
        ),
        title: const Text('Developer Token Entry', style: TextStyle(color: PinterestTheme.ink, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: PinterestTheme.ink, fontSize: 13, fontFamily: 'monospace'),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Paste JWT token here...',
            hintStyle: const TextStyle(color: PinterestTheme.ash),
            filled: true,
            fillColor: PinterestTheme.surfaceCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
              borderSide: const BorderSide(color: PinterestTheme.ash),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
              borderSide: const BorderSide(color: PinterestTheme.ink, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: PinterestTheme.mute)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final token = controller.text.trim();
              if (token.isNotEmpty) {
                _submitToken(token);
              }
            },
            style: PinterestTheme.primaryButtonStyle(height: 40),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inkColor = PinterestTheme.getInk(context);
    final muteColor = PinterestTheme.getMute(context);
    final surfaceSoft = PinterestTheme.getSurfaceSoft(context);
    final hairlineSoft = PinterestTheme.getHairlineSoft(context);

    return Scaffold(
      backgroundColor: surfaceSoft,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Canvas Link Logo / Pinterest Badge
                GestureDetector(
                  onLongPress: _showManualTokenDialog,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: PinterestTheme.primary,
                      borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: PinterestTheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'P',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // App Title
                Text(
                  'Canvas Link',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: inkColor,
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Your daily Pinterest wallpapers, synchronized.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: muteColor,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Feature Highlights Card (Theme adaptive surface card, 16px radius per DESIGN.md)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: PinterestTheme.cardDecoration(context: context, soft: true),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: PinterestTheme.primary,
                        title: 'Automatic Daily Sync',
                        subtitle: 'Fresh wallpaper applies silently every morning',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: hairlineSoft, height: 1),
                      ),
                      _buildFeatureRow(
                        icon: Icons.collections_bookmark_rounded,
                        iconColor: PinterestTheme.primary,
                        title: 'Curated Pinterest Boards',
                        subtitle: 'Directly syncs high-resolution pins you save',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: hairlineSoft, height: 1),
                      ),
                      _buildFeatureRow(
                        icon: Icons.battery_charging_full_rounded,
                        iconColor: PinterestTheme.primary,
                        title: 'Battery & WorkManager Friendly',
                        subtitle: 'Zero idle background battery or CPU drain',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Action: Connect with Pinterest Button per DESIGN.md
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _connectWithPinterest,
                    style: PinterestTheme.primaryButtonStyle(height: 48),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _statusMessage.isNotEmpty
                                    ? _statusMessage
                                    : 'Connecting...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.link_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Connect with Pinterest',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Seamless explanation note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 14, color: muteColor),
                    const SizedBox(width: 6),
                    Text(
                      'Official OAuth 2.0. No passwords stored.',
                      style: GoogleFonts.inter(
                        color: muteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: PinterestTheme.getSurfaceElevated(context),
            borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
            border: Border.all(color: PinterestTheme.getHairlineSoft(context)),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: PinterestTheme.getInk(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: PinterestTheme.getMute(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

