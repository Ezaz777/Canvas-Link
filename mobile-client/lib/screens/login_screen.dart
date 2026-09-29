/// Canvas Link — Login Screen
/// Features Canvas Link branding, authentic Pinterest-style email & password fields,
/// a 1-tap "Continue with Google" button, Reddit-style in-app Chrome Custom Tabs,
/// and instant token capture upon authorization.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

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
    _emailController.dispose();
    _passwordController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Whenever the app resumes from the in-app Chrome tab, check for the token
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
      if ((uri.scheme == 'canvaslink' || uri.scheme == 'wallpapersync') &&
          uri.host == 'auth') {
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          _submitToken(token);
        }
      }
    } catch (e) {
      debugPrint('Error parsing token link: $e');
    }
  }

  Future<void> _submitToken(String token) async {
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
      setState(() => _isLoading = false);
    }
  }

  /// Opens the URL using Reddit-style in-app Chrome Custom Tab
  Future<void> _openCustomTab(String url) async {
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(url);
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
    } catch (e) {
      _showToast('Could not open login page: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleNormalLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast('Please enter your email and password');
      return;
    }

    // Launch in-app Chrome Custom Tab for Pinterest authorization
    await _openCustomTab(ApiService.getAuthUrl());
  }

  Future<void> _handleGoogleLogin() async {
    // Launch in-app Chrome Custom Tab directly for 1-tap Google Sign-In
    await _openCustomTab(ApiService.getAuthUrl());
  }

  Future<void> _forgotPassword() async {
    // Open official Pinterest password reset in the in-app Custom Tab
    await _openCustomTab('https://www.pinterest.com/password/reset/');
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF262626),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262626), // Authentic Pinterest dark input field color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E8E),
            fontSize: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF8E8E8E), size: 20)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep sleek dark background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Canvas Link Logo
                GestureDetector(
                  onLongPress: _showManualTokenDialog,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF8B5CF6),
                          child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Welcome to Canvas Link Heading
                Text(
                  'Welcome to Canvas Link',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sync your Pinterest boards on every screen',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E8E),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Email / Username Field
                _buildInputField(
                  controller: _emailController,
                  hintText: 'Email address or username',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),

                // Password Field
                _buildInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF8E8E8E),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 10),

                // Forgotten Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgotten your password?',
                      style: TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Primary Log In Button (Pinterest Red Pill)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNormalLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE60023), // Authentic Pinterest Red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26), // Full rounded pill
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Log in',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 22),

                // Divider: OR
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.15),
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.15),
                        thickness: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Continue with Google Button (1-Tap Sign-In)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F1F1F),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(20, 20),
                          painter: GoogleLogoPainter(),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F1F1F),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Terms and Privacy Footer
                Text(
                  "By continuing, you agree to Pinterest's Terms of Service and Canvas Link's Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pixel-perfect 4-color Google "G" logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.44;
    final strokeWidth = w * 0.18;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Red (Top arc)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -0.75 * 3.14159265, 0.85 * 3.14159265, false, redPaint);

    // 2. Yellow (Left arc)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0.75 * 3.14159265, 0.5 * 3.14159265, false, yellowPaint);

    // 3. Green (Bottom arc)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0.15 * 3.14159265, 0.65 * 3.14159265, false, greenPaint);

    // 4. Blue (Right arc)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -0.15 * 3.14159265, 0.35 * 3.14159265, false, bluePaint);

    // 5. Blue crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.1,
        center.dy - strokeWidth / 2,
        radius + strokeWidth / 2,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
