/// WallpaperSync — Login Screen
/// A premium-styled login screen with gradient background and glassmorphism.

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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isLoading = false;
  bool _isAwaitingAuth = false;
  final _tokenController = TextEditingController();

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
    // Do NOT auto-read clipboard on startup so users can freely switch accounts or log in fresh
  }

  @override
  void dispose() {
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
        await _submitToken();
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
        // Launch external browser so user can choose account or app
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.inAppBrowserView);
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
      await launchUrl(logoutUrl, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Opened Pinterest logout page in browser. Once logged out, tap "Connect with Pinterest" to sign into your other account!'),
            backgroundColor: const Color(0xFF8B5CF6),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showError('Could not open logout page: $e');
    }
  }

  Future<void> _submitToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showError('Please paste your authentication token.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.saveToken(token);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showError('Invalid token. Please try again.');
      await AuthService.deleteToken();
    }

    setState(() => _isLoading = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon
                      Container(
                        width: 96,
                        height: 96,
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
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

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
                      const SizedBox(height: 8),
                      Text(
                        'Your Pinterest boards, on every screen.',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Glass Card
                      Container(
                        padding: const EdgeInsets.all(28),
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
                            // Pinterest Login Button
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
                                  elevation: 0,
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
                                          Icon(Icons.push_pin_rounded, size: 20),
                                          SizedBox(width: 12),
                                          Text(
                                            'Connect with Pinterest',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _isLoading ? null : _switchPinterestAccount,
                              icon: const Icon(Icons.switch_account_rounded, size: 16, color: Color(0xFF94A3B8)),
                              label: const Text(
                                'Switch Pinterest Account',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'then paste your token',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Token Input
                            TextField(
                              controller: _tokenController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Paste your JWT token here...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitToken,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Activate',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
