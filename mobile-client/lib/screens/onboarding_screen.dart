import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/pinterest_theme.dart';
import '../utils/settings.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Interactive sliding onboarding walkthrough for Pinterest Auto Wallpaper.
/// Showcases authentic in-app screenshots in a large, immersive phone mockup
/// that highlights saving pins on Pinterest, board selection, gallery browsing,
/// and automated / instant wallpaper setting.
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),

            // Sliding Pages
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Slide 1: Save on Pinterest
                      _buildSlide(
                        constraints: constraints,
                        imagePath: 'assets/onboarding/onboarding_pinterest.jpg',
                        badgeText: '📌 Step 1: Browse & Save',
                        badgeColor: PinterestTheme.primary,
                        title: 'Find Pins You Love\n& Tap "Save"',
                        subtitle:
                            'Browse Pinterest normally! Whenever you see an aesthetic picture or wallpaper you like, simply tap "Save" to add it to your board.',
                        isDark: isDark,
                        inkColor: inkColor,
                        muteColor: muteColor,
                      ),

                      // Slide 2: Board Feature
                      _buildSlide(
                        constraints: constraints,
                        imagePath: 'assets/onboarding/onboarding_boards.jpg',
                        badgeText: '📋 Step 2: Board Feature',
                        badgeColor: const Color(0xFF6366F1),
                        title: 'Select Your\nWallpaper Board',
                        subtitle:
                            'Pick which Pinterest board to sync with your phone. The app connects directly to your board and syncs all your saved pins automatically.',
                        isDark: isDark,
                        inkColor: inkColor,
                        muteColor: muteColor,
                      ),

                      // Slide 3: Gallery Feature
                      _buildSlide(
                        constraints: constraints,
                        imagePath: 'assets/onboarding/onboarding_gallery.jpg',
                        badgeText: '🖼️ Step 3: Gallery Feature',
                        badgeColor: const Color(0xFFF59E0B),
                        title: 'Explore Your\nVisual Gallery',
                        subtitle:
                            'Browse all your saved wallpapers in a rich, high-resolution masonry grid. Tap any image to preview in full screen before applying.',
                        isDark: isDark,
                        inkColor: inkColor,
                        muteColor: muteColor,
                      ),

                      // Slide 4: How It Works & Auto Rotation
                      _buildSlide(
                        constraints: constraints,
                        imagePath: 'assets/onboarding/onboarding_active.jpg',
                        badgeText: '⚡ Step 4: How It Works',
                        badgeColor: const Color(0xFF10B981),
                        title: 'One-Tap Set\nor Auto-Rotate',
                        subtitle:
                            'Tap "Set as Wallpaper" to apply immediately to Home, Lock, or Both screens. Or set an auto-rotation schedule for fresh wallpapers hands-free!',
                        isDark: isDark,
                        inkColor: inkColor,
                        muteColor: muteColor,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom Navigation & Page Indicators
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
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

  /// Standardized, immersive slide layout with a large, prominent phone frame mockup.
  Widget _buildSlide({
    required BoxConstraints constraints,
    required String imagePath,
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color inkColor,
    required Color muteColor,
  }) {
    // Dynamically calculate mockup height and width to dominate 52-56% of available height
    final double availHeight = constraints.maxHeight;
    final double mockupHeight = (availHeight * 0.54).clamp(320.0, 450.0);
    final double mockupWidth = mockupHeight * 0.53; // ~170dp to 240dp wide (ideal 9:17 aspect ratio)

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large Hero Phone Mockup with Original High-Res App Screenshot
          _buildDeviceMockup(
            imagePath: imagePath,
            width: mockupWidth,
            height: mockupHeight,
            badgeColor: badgeColor,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Feature Step Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: badgeColor.withOpacity(0.28),
                width: 1,
              ),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                color: badgeColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Headline Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: inkColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Explanatory Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: muteColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sleek, aesthetic smartphone mockup frame with modern rounded corners,
  /// dark chassis bezel, camera notch, and ambient color glow shadow.
  Widget _buildDeviceMockup({
    required String imagePath,
    required double width,
    required double height,
    required Color badgeColor,
    required bool isDark,
  }) {
    const double borderRadius = 32.0;
    const double borderWidth = 3.5;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.22) : Colors.black87,
          width: borderWidth,
        ),
        boxShadow: [
          // Ambient theme glow
          BoxShadow(
            color: badgeColor.withOpacity(isDark ? 0.30 : 0.16),
            blurRadius: 36,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
          // Deep drop shadow
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.60 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // High-Resolution In-App Screenshot
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),

          // Top Camera / Speaker Notch Pill (Dynamic Island)
          Positioned(
            top: 6,
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
