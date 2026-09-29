/// WallpaperSync — Login Screen
/// A premium-styled login screen with gradient background and glassmorphism.
/// Supports 1-tap Google login via in-app Custom Tabs and instant deep-link return.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isLoading = false;
  bool _isAwaitingAuth = false;
  final _tokenController = TextEditingController();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // 1. Listen for real-time deep links while app is running or resumed
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('AppLinks stream error: $err');
      },
    );

    // 2. Check if launched cold from a deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }).catchError((err) {
      debugPrint('Initial AppLinks error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    if ((uri.scheme == 'canvaslink' || uri.scheme == 'wallpapersync') &&
        uri.host == 'auth') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _tokenController.text = token;
        _submitTokenWithToken(token);
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isAwaitingAuth) {
      _checkClipboardForToken();
    }
  }

  Future<void> _checkClipboardForToken() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null &&
          text.startsWith('eyJ') &&
          text.split('.').length >= 3 &&
          _tokenController.text.isEmpty) {
        _tokenController.text = text;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Detected Pinterest token! Connecting...')),
                ],
              ),
              backgroundColor: const Color(0xFF8B5CF6),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        await _submitTokenWithToken(text);
      }
    } catch (_) {}
  }

  Future<void> _openPinterestAuth() async {
    setState(() {
      _isLoading = true;
      _isAwaitingAuth = true;
    });

    try {
      final url = Uri.parse(ApiService.getAuthUrl());
      bool launched = false;
      try {
        // Open secure in-app Custom Tab (Chrome Custom Tab):
        // 1. Keeps user inside Canvas Link (never kicks them out to separate browser app)
        // 2. Full support for native "Continue with Google" 1-tap account picker
        // 3. Auto-redirects back to Canvas Link via custom scheme canvaslink://auth?token=...
        launched = await launchUrl(
          url,
          mode: LaunchMode.inAppBrowserView,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          _showError('Could not open browser for authentication.');
        }
      }
    } catch (e) {
      _showError('Failed to open authentication page: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _switchPinterestAccount() async {
    await Clipboard.setData(const ClipboardData(text: ''));
    _tokenController.clear();
    setState(() => _isAwaitingAuth = false);

    final logoutUrl = Uri.parse('https://www.pinterest.com/logout/');
    try {
      // Open in inAppBrowserView to clear Custom Tab cookies
      bool launched = false;
      try {
        launched = await launchUrl(logoutUrl, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        launched = false;
      }
      if (!launched) {
        await launchUrl(logoutUrl, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Pinterest logout page opened. Tap "Connect with Pinterest" to sign into another Google/Pinterest account.'),
            backgroundColor: const Color(0xFF8B5CF6),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showError('Could not open logout page: $e');
    }
  }

  Future<void> _submitTokenWithToken(String token) async {
    setState(() => _isLoading = true);

    try {
      await AuthService.saveToken(token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Connected to Pinterest! Loading your boards...')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showError('Invalid token. Please try again.');
      await AuthService.deleteToken();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showError('Please paste your authentication token.');
      return;
    }
    await _submitTokenWithToken(token);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.wallpaper_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        'Canvas Link',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your Pinterest boards, on every screen.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Glass Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xB31E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Main Pinterest Connect Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _openPinterestAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE60023),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: const Color(0xFFE60023).withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.push_pin_rounded, size: 22),
                                          SizedBox(width: 10),
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
                            const SizedBox(height: 12),

                            // 1-Tap Google Login Hint Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.g_mobiledata_rounded, color: Color(0xFF38BDF8), size: 22),
                                  SizedBox(width: 4),
                                  Text(
                                    'Supports 1-Tap Google Sign-In',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Switch Account Button
                            TextButton.icon(
                              onPressed: _isLoading ? null : _switchPinterestAccount,
                              icon: const Icon(Icons.switch_account_rounded, size: 16, color: Color(0xFF94A3B8)),
                              label: const Text(
                                'Switch Pinterest / Google Account',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Expandable Manual Token Section (Kept discreet for clean UX)
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: false,
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  'Enter Token Manually',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                iconColor: Colors.white38,
                                collapsedIconColor: Colors.white24,
                                children: [
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _tokenController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Paste JWT token...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.25),
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(14),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submitToken,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B5CF6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Activate Token'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer
                      Text(
                        'Seamless daily Pinterest wallpaper synchronization',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
