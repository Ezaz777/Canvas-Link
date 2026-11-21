import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/pinterest_theme.dart';
import '../utils/settings.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Interactive sliding onboarding walkthrough for Pinterest Auto Wallpaper.
/// Explains the core workflow in simple, visual, and beginner-friendly steps.
class OnboardingScreen extends StatefulWidget {
  /// When true, user opened this from inside the app (Settings / Help) to review instructions.
  final bool isReviewMode;

  const OnboardingScreen({super.key, this.isReviewMode = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    await Settings.setHasSeenOnboarding(true);
    if (!mounted) return;

    if (widget.isReviewMode) {
      Navigator.of(context).pop();
      return;
    }

    final isLoggedIn = await AuthService.isLoggedIn();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PinterestTheme.isDark(context);
    final surfaceColor = PinterestTheme.getSurfaceSoft(context);
    final inkColor = PinterestTheme.getInk(context);
    final muteColor = PinterestTheme.getMute(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pinterest Auto Wallpaper',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: inkColor,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.isReviewMode && _currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: muteColor,
                        ),
                      ),
                    )
                  else if (widget.isReviewMode)
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: inkColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            // Sliding Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSlide1(isDark, inkColor, muteColor),
                  _buildSlide2(isDark, inkColor, muteColor),
                  _buildSlide3(isDark, inkColor, muteColor),
                  _buildSlide4(isDark, inkColor, muteColor),
                ],
              ),
            ),

            // Bottom Navigation & Page Indicators
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Smooth Indicator Dots
                  Row(
                    children: List.generate(_totalPages, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? PinterestTheme.primary
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Action Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PinterestTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _totalPages - 1
                              ? (widget.isReviewMode ? 'Got it!' : 'Get Started')
                              : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentPage == _totalPages - 1
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 1: Welcome & Auto Rotation
  Widget _buildSlide1(bool isDark, Color inkColor, Color muteColor) {
    return _buildSlideContainer(
      visual: _buildPhoneMockupVisual(
        isDark: isDark,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Wallpaper Gradient simulation
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFFE60023)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Floating Clock & Daily Badge
            Positioned(
              top: 36,
              child: Column(
                children: [
                  Text(
                    '08:00',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'Wednesday, November 21',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Floating Auto Sync Badge
            Positioned(
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-Updated Today',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      badgeText: '✨ Automatic & Effortless',
      badgeColor: const Color(0xFF10B981),
      title: 'Fresh Pinterest Wallpapers\nEvery Single Day',
      subtitle:
          'Never get bored of your phone wallpaper again. Connect your Pinterest account and let the app automatically refresh your background with your favorite pins.',
      inkColor: inkColor,
      muteColor: muteColor,
    );
  }

  // Slide 2: Save on Pinterest
  Widget _buildSlide2(bool isDark, Color inkColor, Color muteColor) {
    return _buildSlideContainer(
      visual: Container(
        width: 260,
        height: 280,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinterest Header Mockup
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: PinterestTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pinterest App',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: inkColor,
                    ),
                  ),
                ),
                // Prominent Save Button with Tap Finger Graphic
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: PinterestTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: PinterestTheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pin Image simulation
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2), Color(0xFFFF416C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📌 Aesthetic 4K Wallpaper Board',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Animated Tap Gesture Arrow
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.touch_app_rounded,
                            color: PinterestTheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      badgeText: '📌 Step 1: Browse Pinterest',
      badgeColor: PinterestTheme.primary,
      title: 'Just Tap "Save" on Pinterest',
      subtitle:
          'Browse Pinterest normally! Whenever you see an aesthetic picture you want as your background, just tap "Save" to your board. No downloading files or cropping required.',
      inkColor: inkColor,
      muteColor: muteColor,
    );
  }

  // Slide 3: Set Instantly or Auto Sync
  Widget _buildSlide3(bool isDark, Color inkColor, Color muteColor) {
    return _buildSlideContainer(
      visual: Container(
        width: 270,
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instant Apply Mockup
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: PinterestTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PinterestTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: PinterestTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wallpaper_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set as Wallpaper',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: inkColor,
                          ),
                        ),
                        Text(
                          'One-tap instant apply',
                          style: GoogleFonts.inter(fontSize: 11, color: muteColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.touch_app_rounded, color: PinterestTheme.primary, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Target Selector Mockup
            Row(
              children: [
                _buildTargetBadge(Icons.home_rounded, 'Home Screen', isDark),
                const SizedBox(width: 8),
                _buildTargetBadge(Icons.lock_rounded, 'Lock Screen', isDark),
                const SizedBox(width: 8),
                _buildTargetBadge(Icons.devices_rounded, 'Both', isDark, isSelected: true),
              ],
            ),
            const SizedBox(height: 14),
            // Frequency Mockup
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Color(0xFF3B82F6), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Rotate Schedule:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: inkColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Every 1h / Daily',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      badgeText: '⚡ Step 2: Instant or Automatic',
      badgeColor: const Color(0xFF3B82F6),
      title: 'One-Tap Set or Auto-Rotate',
      subtitle:
          'Open the app and tap "Set as Wallpaper" on any pin to apply it immediately, or sit back and let the app rotate your wallpaper automatically on your favorite schedule.',
      inkColor: inkColor,
      muteColor: muteColor,
    );
  }

  // Slide 4: 100% Free & PC Sync
  Widget _buildSlide4(bool isDark, Color inkColor, Color muteColor) {
    return _buildSlideContainer(
      visual: Container(
        width: 270,
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big 100% Free Ribbon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '100% FREE & UNLIMITED',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Multi-Device Sync Illustration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDeviceCard(Icons.phone_android_rounded, 'Mobile Phone', isDark),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.sync_alt_rounded, color: PinterestTheme.primary, size: 24),
                ),
                _buildDeviceCard(Icons.laptop_chromebook_rounded, 'Windows PC', isDark),
              ],
            ),
            const SizedBox(height: 16),
            // 4K Ultra-HD Quality Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hd_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Original Uncompressed 4K Quality',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      badgeText: '🎉 Step 3: Enjoy Ad-Supported Freedom',
      badgeColor: const Color(0xFF10B981),
      title: 'All Features Unlocked For Free',
      subtitle:
          'No subscriptions or paid tiers! Enjoy rapid 1h & 6h sync, independent Lock & Home screen targeting, and Windows PC sync completely free.',
      inkColor: inkColor,
      muteColor: muteColor,
    );
  }

  // Reusable visual helpers
  Widget _buildSlideContainer({
    required Widget visual,
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required Color inkColor,
    required Color muteColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Visual Showcase
          visual,
          const SizedBox(height: 28),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: inkColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle / Description
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: muteColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneMockupVisual({required bool isDark, required Widget child}) {
    return Container(
      width: 170,
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262622) : Colors.black,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white24, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: child,
      ),
    );
  }

  Widget _buildTargetBadge(IconData icon, String label, bool isDark, {bool isSelected = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? PinterestTheme.primary.withOpacity(0.15)
              : (isDark ? Colors.black26 : const Color(0xFFF3F3F3)),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: PinterestTheme.primary, width: 1.2)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? PinterestTheme.primary : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? PinterestTheme.primary : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(IconData icon, String name, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: PinterestTheme.primary),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
