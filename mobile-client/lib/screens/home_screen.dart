import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/wallpaper_service.dart';
import '../workers/wallpaper_worker.dart';
import '../utils/settings.dart';
import '../utils/image_utils.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'board_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import '../utils/pinterest_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _burstAnimController;
  late Animation<double> _burstScaleAnimation;
  late Animation<double> _burstFadeAnimation;
  late PageController _pageController;
  bool _isSyncing = false;
  bool _isApplyingPin = false;
  bool _isLoadingPreview = true;
  String? _currentImageUrl;
  String? _currentPinId;
  String? _currentDate;
  String? _errorMessage;
  String? _errorCode;
  int? _totalPins;
  int _syncFrequency = 24;
  String _screenTarget = 'both';
  List<Map<String, dynamic>> _pins = [];
  int _currentIndex = 0;
  int _activeWallpaperIndex = 0;
  int? _flaggedCount;
  int? _unflaggedCount;
  bool _isUnflaggedCycle = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _burstAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _burstScaleAnimation = CurvedAnimation(
      parent: _burstAnimController,
      curve: Curves.elasticOut,
    );
    _burstFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _burstAnimController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _loadCurrentWallpaper();
    _loadSettings();
    _ensureBackgroundWorkerAndAutoSync();
  }

  Future<void> _ensureBackgroundWorkerAndAutoSync() async {
    try {
      // 1. Pre-cache physical screen dimensions for background isolates
      await ImageUtils.getScreenResolution();

      // 2. Register periodic background WorkManager task
      await WallpaperWorker.registerPeriodicSync();

      // 3. Check if current interval's wallpaper needs automatic change
      final freq = await Settings.getSyncFrequency();
      if (freq > 0) {
        final now = DateTime.now();
        final currentIntervalKey = Settings.getIntervalKey(now, freq);
        final lastInterval = await Settings.getLastSyncIntervalKey();

        if (lastInterval != currentIntervalKey) {
          print('HomeScreen: New interval detected ($lastInterval -> $currentIntervalKey). Auto-applying wallpaper...');
          WallpaperService.syncWallpaper(frequency: freq, hour: now.hour).then((success) {
            if (success && mounted) {
              _loadCurrentWallpaper();
            }
          }).catchError((e) {
            print('HomeScreen: Auto-change on launch notice: $e');
          });
        }
      }
    } catch (e) {
      print('HomeScreen: Error initializing background worker: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _burstAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final freq = await Settings.getSyncFrequency();
    final target = await Settings.getScreenTarget();
    if (mounted) {
      setState(() {
        _syncFrequency = freq;
        _screenTarget = target;
      });
    }
  }

  Future<void> _loadCurrentWallpaper() async {
    setState(() {
      _isLoadingPreview = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _logout();
        return;
      }

      final freq = await Settings.getSyncFrequency();
      final currentHour = DateTime.now().hour;
      final api = ApiService(token);
      final data = await api.getWallpaper(frequency: freq, hour: currentHour);
      final currentImg = data['image_url'] as String?;
      final currentPin = data['pin_id'] as String?;

      List<Map<String, dynamic>> loadedPins = [];
      try {
        loadedPins = await api.getBoardPins();
      } catch (_) {}

      if (loadedPins.isEmpty && currentImg != null) {
        loadedPins = [
          {
            'id': currentPin ?? 'current',
            'image_url': currentImg,
            'title': data['title'] ?? 'Pinterest Wallpaper',
          }
        ];
      }

      int activeIdx = 0;
      if (currentPin != null && loadedPins.isNotEmpty) {
        final found = loadedPins.indexWhere(
            (p) => p['id'] == currentPin || p['image_url'] == currentImg);
        if (found != -1) activeIdx = found;
      }

      setState(() {
        _currentImageUrl = currentImg;
        _currentPinId = currentPin;
        _currentDate = data['date'];
        _totalPins = data['total_pins'] ?? loadedPins.length;
        _flaggedCount = data['flagged_count'] as int?;
        _unflaggedCount = data['unflagged_count'] as int?;
        _isUnflaggedCycle = data['is_unflagged_cycle'] as bool? ?? false;
        _pins = loadedPins;
        _activeWallpaperIndex = activeIdx;
        _currentIndex = activeIdx;
        _isLoadingPreview = false;
        _errorMessage = null;
        _errorCode = null;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(activeIdx);
      } else {
        _pageController = PageController(initialPage: activeIdx);
      }
    } on UnauthorizedException {
      setState(() {
        _errorMessage = 'Session expired. Please log in again.';
        _errorCode = 'auth_expired';
        _currentImageUrl = null;
        _pins = [];
        _totalPins = null;
        _isLoadingPreview = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _errorCode = e.code;
        _currentImageUrl = null;
        _pins = [];
        _totalPins = null;
        _isLoadingPreview = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wallpaper preview.';
        _errorCode = 'unknown';
        _currentImageUrl = null;
        _pins = [];
        _totalPins = null;
        _isLoadingPreview = false;
      });
    }
  }

  Future<void> _applyPinAsWallpaper(
    Map<String, dynamic> pin, {
    String? target,
    bool notify = true,
  }) async {
    final effectiveTarget = target ?? _screenTarget;
    if (target != null && target != _screenTarget) {
      await Settings.setScreenTarget(target);
      if (mounted) setState(() => _screenTarget = target);
    }

    setState(() => _isApplyingPin = true);
    HapticFeedback.mediumImpact();

    try {
      int? location;
      if (effectiveTarget == 'home') {
        location = AsyncWallpaper.HOME_SCREEN;
      } else if (effectiveTarget == 'lock') {
        location = AsyncWallpaper.LOCK_SCREEN;
      } else {
        location = AsyncWallpaper.BOTH_SCREENS;
      }

      final success = await WallpaperService.setWallpaperFromUrl(
        pin['image_url'],
        location: location,
      );
      if (!mounted) return;

      if (success) {
        setState(() {
          _activeWallpaperIndex = _currentIndex;
          _currentImageUrl = pin['image_url'];
          _currentPinId = pin['id'];
        });

        HapticFeedback.heavyImpact();
        _burstAnimController.forward(from: 0.0);

        if (notify) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Wallpaper set to ${Settings.getScreenTargetDisplayString(effectiveTarget)}!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set wallpaper: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplyingPin = false);
      }
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);

    try {
      await WallpaperWorker.runOnce();
      await WallpaperService.syncWallpaper();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Wallpaper set to ${Settings.getScreenTargetDisplayString(_screenTarget)}!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await _loadCurrentWallpaper();
    } on ApiException catch (e) {
      if (!mounted) return;
      final isNoPins = e.code == 'no_pins_found';
      final isNoBoard = e.code == 'no_board_selected';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isNoPins
                    ? Icons.collections_bookmark_rounded
                    : isNoBoard
                        ? Icons.dashboard_customize_rounded
                        : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.message,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE11D48),
          duration: const Duration(seconds: 5),
          action: isNoPins
              ? SnackBarAction(
                  label: 'Open Pinterest',
                  textColor: Colors.white,
                  onPressed: () => launchUrl(
                    Uri.parse('https://www.pinterest.com'),
                    mode: LaunchMode.externalApplication,
                  ),
                )
              : isNoBoard
                  ? SnackBarAction(
                      label: 'Pick Board',
                      textColor: Colors.white,
                      onPressed: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                                builder: (_) => const DashboardScreen()),
                          )
                          .then((_) => _loadCurrentWallpaper()),
                    )
                  : null,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await _loadCurrentWallpaper();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await _loadCurrentWallpaper();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _skipNow() async {
    if (_pins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallpapers in this board to skip.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_pins.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ℹ️ Only 1 wallpaper in your board. Save more pins on Pinterest to skip between them!'),
          backgroundColor: Color(0xFF3B82F6),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();

    try {
      // Advance to the next unique pin in the carousel - GUARANTEED NOT THE SAME
      final nextIdx = (_currentIndex + 1) % _pins.length;

      // Animate smoothly with satisfying cubic curve
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          nextIdx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      } else {
        setState(() => _currentIndex = nextIdx);
      }

      // Apply this next pin immediately
      final nextPin = _pins[nextIdx];
      await _applyPinAsWallpaper(nextPin, notify: false);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Switched to next wallpaper (${nextIdx + 1} of ${_pins.length})!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }

      // Tell backend to increment skip_offset in background
      try {
        final token = await AuthService.getToken();
        if (token != null) {
          final api = ApiService(token);
          await api.skipWallpaper();
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skip failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.clearAll();
    await WallpaperWorker.cancelAll();
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PinterestTheme.isDark(context);
    final inkColor = PinterestTheme.getInk(context);
    final muteColor = PinterestTheme.getMute(context);
    final surfaceSoft = PinterestTheme.getSurfaceSoft(context);

    return Scaffold(
      backgroundColor: surfaceSoft,
      body: SafeArea(
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOut,
          ),
          child: Column(
            children: [
              // Pinterest Style Header Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: PinterestTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'P',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Canvas Link',
                          style: GoogleFonts.inter(
                            color: inkColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Daily Pinterest Wallpapers',
                          style: GoogleFonts.inter(
                            color: muteColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showSettingsModal,
                      icon: Icon(
                        Icons.settings_rounded,
                        color: inkColor,
                      ),
                      tooltip: 'Settings',
                    ),
                    IconButton(
                      onPressed: _logout,
                      icon: Icon(
                        Icons.logout_rounded,
                        color: muteColor,
                      ),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),

                      // Wallpaper Preview Card
                      _buildPreviewCard(),
                      const SizedBox(height: 16),

                      // Sync Button
                      _buildSyncButton(),

                      const SizedBox(height: 16),

                      // Stats Card
                      if (_totalPins != null) _buildStatsCard(),

                      const SizedBox(height: 16),

                      // View Board Gallery Button per DESIGN.md
                      if (_totalPins != null)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BoardScreen(),
                                ),
                              ).then((_) => _loadCurrentWallpaper());
                            },
                            style: PinterestTheme.secondaryButtonStyle(context: context, height: 48),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'View Board Gallery',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Manage Boards Dashboard Button per DESIGN.md
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DashboardScreen(),
                              ),
                            ).then((_) => _loadCurrentWallpaper());
                          },
                          style: PinterestTheme.secondaryButtonStyle(context: context, height: 48),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dashboard_customize_rounded, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Manage Boards',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetWallpaperSheet(Map<String, dynamic> pin) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: PinterestTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PinterestTheme.radiusLg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: PinterestTheme.getHairline(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set as Wallpaper',
                  style: GoogleFonts.inter(
                    color: PinterestTheme.getInk(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose where to apply this wallpaper on your device',
                  style: GoogleFonts.inter(
                    color: PinterestTheme.getMute(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                _buildWallpaperTargetTile(
                  icon: Icons.devices_rounded,
                  title: 'Home & Lock Screens',
                  subtitle: 'Set on both your home screen and lock screen',
                  target: 'both',
                  pin: pin,
                ),
                const SizedBox(height: 10),
                _buildWallpaperTargetTile(
                  icon: Icons.home_rounded,
                  title: 'Home Screen Only',
                  subtitle: 'Set only on your main home screen',
                  target: 'home',
                  pin: pin,
                ),
                const SizedBox(height: 10),
                _buildWallpaperTargetTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Lock Screen Only',
                  subtitle: 'Set only on your device lock screen',
                  target: 'lock',
                  pin: pin,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWallpaperTargetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String target,
    required Map<String, dynamic> pin,
  }) {
    final isCurrent = _screenTarget == target;
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? PinterestTheme.getSurfaceCard(context) : PinterestTheme.getCanvas(context),
        borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
        border: Border.all(
          color: isCurrent
              ? PinterestTheme.primary
              : PinterestTheme.getHairlineSoft(context),
          width: 1.5,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PinterestTheme.getSurfaceElevated(context),
            borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
            border: Border.all(color: PinterestTheme.getHairlineSoft(context)),
          ),
          child: Icon(
            icon,
            color: isCurrent ? PinterestTheme.primary : PinterestTheme.getInk(context),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: PinterestTheme.getInk(context),
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            color: PinterestTheme.getMute(context),
            fontSize: 12,
          ),
        ),
        trailing: isCurrent
            ? const Icon(Icons.check_circle_rounded, color: PinterestTheme.primary, size: 20)
            : null,
        onTap: () {
          Navigator.pop(context);
          _applyPinAsWallpaper(pin, target: target);
        },
      ),
    );
  }

  Widget _buildPreviewCard() {
    if (_isLoadingPreview) {
      return Container(
        width: double.infinity,
        height: 440,
        decoration: PinterestTheme.cardDecoration(soft: true),
        child: const Center(
          child: CircularProgressIndicator(
            color: PinterestTheme.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_pins.isEmpty && _currentImageUrl == null) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 380),
        decoration: PinterestTheme.cardDecoration(soft: true),
        child: _buildEmptyOrErrorGuide(),
      );
    }

    final totalCount = _pins.isNotEmpty ? _pins.length : 1;
    final isActive = _currentIndex == _activeWallpaperIndex;

    return Container(
      width: double.infinity,
      height: 440,
      decoration: BoxDecoration(
        color: PinterestTheme.surfaceCard,
        borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
        border: Border.all(
          color: isActive
              ? PinterestTheme.primary
              : PinterestTheme.hairlineSoft,
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Swipeable Gallery PageView
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: totalCount,
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) {
                final pin = _pins.isNotEmpty ? _pins[index] : null;
                final imageUrl = pin != null ? (pin['image_url'] as String?) : _currentImageUrl;
                final fallbackUrl = pin != null ? (pin['fallback_url'] as String?) : null;

                if (imageUrl == null) {
                  return _buildEmptyOrErrorGuide();
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36'
                      },
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: PinterestTheme.primary,
                            strokeWidth: 2.5,
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, stack) {
                        if (fallbackUrl != null && fallbackUrl != imageUrl) {
                          return Image.network(
                            fallbackUrl,
                            headers: const {
                              'User-Agent':
                                  'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36'
                            },
                            fit: BoxFit.cover,
                            errorBuilder: (ctx2, err2, stack2) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded,
                                      color: PinterestTheme.mute, size: 48),
                                  const SizedBox(height: 12),
                                  Text('Failed to load image',
                                      style: TextStyle(color: PinterestTheme.mute)),
                                ],
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded,
                                  color: PinterestTheme.mute, size: 48),
                              const SizedBox(height: 12),
                              Text('Failed to load image',
                                  style: TextStyle(color: PinterestTheme.mute)),
                            ],
                          ),
                        );
                      },
                    ),
                    // Subtle bottom gradient for readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.2, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Top Header: Date badge on left, Active indicator on right (Pills on image per DESIGN.md)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: PinterestTheme.pillOnImageDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: PinterestTheme.ink,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentDate ?? 'Today',
                          style: GoogleFonts.inter(
                            color: PinterestTheme.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: PinterestTheme.pillOnImageDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.collections_rounded,
                          color: isActive
                              ? PinterestTheme.primary
                              : PinterestTheme.mute,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive
                              ? 'Active on Device'
                              : '${_currentIndex + 1} of $totalCount',
                          style: GoogleFonts.inter(
                            color: isActive ? PinterestTheme.primary : PinterestTheme.ink,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Left / Right Navigation Chevrons
            if (totalCount > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          border: Border.all(color: PinterestTheme.hairlineSoft),
                          boxShadow: PinterestTheme.overlayShadow,
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: PinterestTheme.ink, size: 22),
                      ),
                    ),
                  ),
                ),
              if (_currentIndex < totalCount - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          border: Border.all(color: PinterestTheme.hairlineSoft),
                          boxShadow: PinterestTheme.overlayShadow,
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: PinterestTheme.ink, size: 22),
                      ),
                    ),
                  ),
                ),
            ],

            // Bottom Action: If NOT active, display "Set as Wallpaper Now" button!
            Positioned(
              bottom: 18,
              left: 20,
              right: 20,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                child: !isActive
                    ? Center(
                        key: ValueKey('set_button_${_currentIndex}'),
                        child: ElevatedButton(
                          onPressed: (_isApplyingPin || _pins.isEmpty)
                              ? null
                              : () => _showSetWallpaperSheet(_pins[_currentIndex]),
                          style: PinterestTheme.primaryButtonStyle(
                            height: 46,
                            radius: PinterestTheme.radiusFull,
                          ),
                          child: _isApplyingPin
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.wallpaper_rounded, size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Set as Wallpaper',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _screenTarget == 'home'
                                                ? 'Home'
                                                : _screenTarget == 'lock'
                                                    ? 'Lock'
                                                    : 'Both',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )
                    : Center(
                        key: const ValueKey('active_pill'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: PinterestTheme.pillOnImageDecoration(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: PinterestTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Current Wallpaper',
                                style: GoogleFonts.inter(
                                  color: PinterestTheme.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // Central Burst Notification on Wallpaper Set
            Center(
              child: AnimatedBuilder(
                animation: _burstAnimController,
                builder: (context, child) {
                  if (_burstAnimController.value == 0.0 || _burstAnimController.value == 1.0) {
                    return const SizedBox.shrink();
                  }
                  return FadeTransition(
                    opacity: _burstFadeAnimation,
                    child: ScaleTransition(
                      scale: _burstScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        decoration: BoxDecoration(
                          color: PinterestTheme.canvas,
                          borderRadius: BorderRadius.circular(PinterestTheme.radiusLg),
                          border: Border.all(color: PinterestTheme.hairline, width: 1.5),
                          boxShadow: PinterestTheme.overlayShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: PinterestTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Wallpaper Set!',
                              style: GoogleFonts.inter(
                                color: PinterestTheme.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Settings.getScreenTargetDisplayString(_screenTarget),
                              style: GoogleFonts.inter(
                                color: PinterestTheme.mute,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrErrorGuide() {
    if (_errorCode == 'no_pins_found') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: PinterestTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Wallpapers in Board',
              style: GoogleFonts.inter(
                color: PinterestTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t saved any wallpapers in this Pinterest board yet! Follow these quick steps to get started:',
              style: GoogleFonts.inter(
                color: PinterestTheme.mute,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: PinterestTheme.cardDecoration(soft: false),
              child: Column(
                children: [
                  _buildGuideStep('1', 'Open Pinterest & search for wallpapers you love'),
                  const SizedBox(height: 8),
                  _buildGuideStep('2', 'Save (Pin) them to your selected board'),
                  const SizedBox(height: 8),
                  _buildGuideStep('3', 'Return here and tap "Sync Now" below'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.pinterest.com'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open Pinterest', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: PinterestTheme.primaryButtonStyle(height: 44),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    ).then((_) => _loadCurrentWallpaper()),
                    style: PinterestTheme.secondaryButtonStyle(height: 44),
                    child: const Text('Change Board', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_errorCode == 'no_board_selected') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: PinterestTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Board Selected',
              style: GoogleFonts.inter(
                color: PinterestTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t linked a Pinterest board to your Mobile yet. Choose a board so Canvas Link can automatically change daily wallpapers on your phone.',
              style: GoogleFonts.inter(
                color: PinterestTheme.mute,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ).then((_) => _loadCurrentWallpaper()),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Choose a Board', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: PinterestTheme.primaryButtonStyle(height: 48),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorCode == 'auth_expired') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock_rounded, color: PinterestTheme.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Session Expired',
              style: GoogleFonts.inter(
                color: PinterestTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Pinterest connection has expired. Please log in again to continue syncing wallpapers.',
              style: GoogleFonts.inter(color: PinterestTheme.mute, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _logout,
              style: PinterestTheme.primaryButtonStyle(height: 48),
              child: const Text('Log In Again'),
            ),
          ],
        ),
      );
    }

    // Default error / empty fallback
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.collections_bookmark_outlined, color: PinterestTheme.mute, size: 52),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'No wallpaper loaded yet',
            style: GoogleFonts.inter(color: PinterestTheme.ink, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadCurrentWallpaper,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: PinterestTheme.secondaryButtonStyle(height: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: PinterestTheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: PinterestTheme.ink,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton() {
    final bool isBusy = _isSyncing || _isApplyingPin;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isBusy ? null : _skipNow,
              style: PinterestTheme.secondaryButtonStyle(context: context, height: 52),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.skip_next_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Skip',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isBusy ? null : _onSetWallpaperPressed,
              style: PinterestTheme.primaryButtonStyle(height: 52),
              child: isBusy
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Setting...',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wallpaper_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Set as Wallpaper',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onSetWallpaperPressed() async {
    if (_pins.isNotEmpty && _currentIndex < _pins.length) {
      await _applyPinAsWallpaper(_pins[_currentIndex], target: _screenTarget, notify: true);
    } else {
      await _syncNow();
    }
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: PinterestTheme.cardDecoration(context: context, soft: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 1. Board Pins: Clickable, opens BoardScreen
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BoardScreen()),
                    ).then((_) => _loadCurrentWallpaper());
                  },
                  borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildStat(
                      'Board Pins',
                      '$_totalPins',
                      Icons.grid_view_rounded,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: PinterestTheme.getHairline(context),
              ),
              // 2. Screen Target: Clickable, opens Screen Target modal
              Expanded(
                child: InkWell(
                  onTap: _showScreenTargetModal,
                  borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildStat(
                      'Target',
                      _screenTarget == 'home'
                          ? 'Home'
                          : _screenTarget == 'lock'
                              ? 'Lock'
                              : 'Both',
                      _screenTarget == 'home'
                          ? Icons.home_rounded
                          : _screenTarget == 'lock'
                              ? Icons.lock_outline_rounded
                              : Icons.devices_rounded,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: PinterestTheme.getHairline(context),
              ),
              // 3. Change Timer: Clickable, opens Frequency modal
              Expanded(
                child: InkWell(
                  onTap: _showFrequencyModal,
                  borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildStat(
                      'Timer',
                      Settings.getFrequencyShortString(_syncFrequency),
                      Icons.schedule_rounded,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Smart Queue Status Bar (visual confirmation of the flagging & priority algorithm)
          if (_flaggedCount != null && _totalPins != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: PinterestTheme.getSurfaceElevated(context),
                borderRadius: BorderRadius.circular(PinterestTheme.radiusSm),
                border: Border.all(color: PinterestTheme.getHairlineSoft(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUnflaggedCycle ? Icons.restart_alt_rounded : Icons.flag_rounded,
                    size: 16,
                    color: _isUnflaggedCycle ? const Color(0xFF3B82F6) : PinterestTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isUnflaggedCycle
                          ? 'All shown once · Unflagging sequence active'
                          : (_unflaggedCount != null && _unflaggedCount! > 0)
                              ? '$_flaggedCount of $_totalPins shown · $_unflaggedCount unflagged prioritized'
                              : 'All $_totalPins shown · Cycling in queue order',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PinterestTheme.getInk(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: PinterestTheme.primary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            color: PinterestTheme.getInk(context),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: PinterestTheme.getMute(context),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showScreenTargetModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PinterestTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PinterestTheme.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PinterestTheme.getHairline(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wallpaper Screen Target',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getInk(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose which screen(s) new wallpapers are applied to',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getMute(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...Settings.availableScreenTargets.map((target) {
                      final isSelected = target == _screenTarget;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          target == 'both'
                              ? Icons.devices_rounded
                              : target == 'home'
                                  ? Icons.home_rounded
                                  : Icons.lock_outline_rounded,
                          color: isSelected ? PinterestTheme.primary : PinterestTheme.getMute(context),
                        ),
                        title: Text(
                          Settings.getScreenTargetDisplayString(target),
                          style: GoogleFonts.inter(
                            color: PinterestTheme.getInk(context),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: PinterestTheme.primary)
                            : null,
                        onTap: () async {
                          await Settings.setScreenTarget(target);
                          if (mounted) {
                            setState(() {
                              _screenTarget = target;
                            });
                          }
                          setModalState(() {});
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Target updated to ${Settings.getScreenTargetDisplayString(target)}'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFrequencyModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PinterestTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PinterestTheme.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PinterestTheme.getHairline(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wallpaper Change Frequency',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getInk(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how often Canvas Link automatically changes your wallpaper',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getMute(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...Settings.availableFrequencies.map((freq) {
                      final isSelected = freq == _syncFrequency;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          freq == 1
                              ? Icons.update_rounded
                              : freq == 6
                                  ? Icons.timelapse_rounded
                                  : freq == 12
                                      ? Icons.access_time_rounded
                                      : freq == 24
                                          ? Icons.calendar_today_rounded
                                          : Icons.pause_circle_outline_rounded,
                          color: isSelected ? PinterestTheme.primary : PinterestTheme.getMute(context),
                        ),
                        title: Text(
                          Settings.getFrequencyDisplayString(freq),
                          style: GoogleFonts.inter(
                            color: PinterestTheme.getInk(context),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: PinterestTheme.primary)
                            : null,
                        onTap: () async {
                          await Settings.setSyncFrequency(freq);
                          await WallpaperWorker.registerPeriodicSync();
                          if (mounted) {
                            setState(() {
                              _syncFrequency = freq;
                            });
                          }
                          setModalState(() {});
                          Navigator.pop(context);
                          _loadCurrentWallpaper();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Wallpaper change set to: ${Settings.getFrequencyDisplayString(freq)}'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PinterestTheme.getSurfaceElevated(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PinterestTheme.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PinterestTheme.getHairline(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wallpaper Screen Target',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getInk(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose which screen(s) new wallpapers are applied to',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getMute(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...Settings.availableScreenTargets.map((target) {
                      final isSelected = target == _screenTarget;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          target == 'both'
                              ? Icons.devices_rounded
                              : target == 'home'
                                  ? Icons.home_rounded
                                  : Icons.lock_outline_rounded,
                          color: isSelected ? PinterestTheme.primary : PinterestTheme.getMute(context),
                        ),
                        title: Text(
                          Settings.getScreenTargetDisplayString(target),
                          style: GoogleFonts.inter(
                            color: PinterestTheme.getInk(context),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: PinterestTheme.primary)
                            : null,
                        onTap: () async {
                          await Settings.setScreenTarget(target);
                          if (mounted) {
                            setState(() {
                              _screenTarget = target;
                            });
                          }
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                    Divider(color: PinterestTheme.getHairline(context), height: 32),
                    Text(
                      'Wallpaper Change Frequency',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getInk(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how often Canvas Link automatically changes your wallpaper',
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getMute(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...Settings.availableFrequencies.map((freq) {
                      final isSelected = freq == _syncFrequency;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          Settings.getFrequencyDisplayString(freq),
                          style: GoogleFonts.inter(
                            color: PinterestTheme.getInk(context),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: PinterestTheme.primary)
                            : null,
                        onTap: () async {
                          await Settings.setSyncFrequency(freq);
                          await WallpaperWorker.registerPeriodicSync();
                          if (mounted) {
                            setState(() {
                              _syncFrequency = freq;
                            });
                          }
                          setModalState(() {});
                          Navigator.pop(context);
                          _loadCurrentWallpaper();
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
