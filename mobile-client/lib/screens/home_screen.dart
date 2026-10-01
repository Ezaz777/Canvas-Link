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

      // 3. Check if today's wallpaper needs automatic sync
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lastSync = await Settings.getLastSyncDate();

      if (lastSync != todayStr) {
        print('HomeScreen: New day detected ($lastSync -> $todayStr). Auto-applying today wallpaper...');
        WallpaperService.syncWallpaper().then((success) {
          if (success && mounted) {
            _loadCurrentWallpaper();
          }
        }).catchError((e) {
          print('HomeScreen: Auto-sync on launch notice: $e');
        });
      }
    } catch (e) {
      print('HomeScreen: Error initializing background sync: $e');
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

      final api = ApiService(token);
      final data = await api.getWallpaper();
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
                child: Text('Wallpaper synced to ${Settings.getScreenTargetDisplayString(_screenTarget)}!'),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOut,
            ),
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.wallpaper_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Canvas Link',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Daily Pinterest Magic',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
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
                          color: Colors.white.withOpacity(0.6),
                        ),
                        tooltip: 'Settings',
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Wallpaper Preview Card
                        _buildPreviewCard(),
                        const SizedBox(height: 20),

                        // Sync Button
                        _buildSyncButton(),

                        const SizedBox(height: 20),

                        // Stats Card
                        if (_totalPins != null) _buildStatsCard(),

                        const SizedBox(height: 20),

                        // View Board Gallery Button
                        if (_totalPins != null)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const BoardScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xB31E293B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color: Colors.white.withOpacity(0.1)),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_rounded, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'View Board Gallery',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Manage Boards Dashboard Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const DashboardScreen(),
                                ),
                              ).then((_) => _loadCurrentWallpaper());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0x0CFFFFFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.dashboard_customize_rounded, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  'Manage Boards',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSetWallpaperSheet(Map<String, dynamic> pin) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set as Wallpaper',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose where to apply this wallpaper on your device',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
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
        color: isCurrent ? const Color(0x268B5CF6) : const Color(0x0CFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFF8B5CF6).withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent
                ? const Color(0xFF8B5CF6).withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isCurrent ? const Color(0xFFC4B5FD) : Colors.white70,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: isCurrent
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF8B5CF6), size: 22)
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
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B5CF6),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_pins.isEmpty && _currentImageUrl == null) {
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 380),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: _buildEmptyOrErrorGuide(),
      );
    }

    final totalCount = _pins.isNotEmpty ? _pins.length : 1;
    final isActive = _currentIndex == _activeWallpaperIndex;

    return Container(
      width: double.infinity,
      height: 440,
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981).withOpacity(0.5)
              : Colors.white.withOpacity(0.12),
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFF10B981).withOpacity(0.18)
                : Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                            color: Color(0xFF8B5CF6),
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
                                      color: Colors.white.withOpacity(0.3), size: 48),
                                  const SizedBox(height: 12),
                                  Text('Failed to load image',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4))),
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
                                  color: Colors.white.withOpacity(0.3), size: 48),
                              const SizedBox(height: 12),
                              Text('Failed to load image',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4))),
                            ],
                          ),
                        );
                      },
                    ),
                    // Gradient shading for readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.22, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Top Header: Date badge on left, Active indicator on right
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: Color(0xFF8B5CF6), size: 13),
                        const SizedBox(width: 6),
                        Text(
                          _currentDate ?? 'Today',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF10B981).withOpacity(0.25)
                          : Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF10B981).withOpacity(0.6)
                            : Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? Icons.check_circle_rounded
                              : Icons.collections_rounded,
                          color: isActive
                              ? const Color(0xFF34D399)
                              : const Color(0xFF94A3B8),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive
                              ? 'Active on Device'
                              : '${_currentIndex + 1} of $totalCount',
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
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
                  left: 10,
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
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),
              if (_currentIndex < totalCount - 1)
                Positioned(
                  right: 10,
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
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 24),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 6,
                            shadowColor: const Color(0xFF8B5CF6).withOpacity(0.6),
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
                                    const Icon(Icons.flash_on_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Set as Wallpaper',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
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
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.arrow_drop_down_rounded, size: 16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Current Wallpaper',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // Satisfying Central Burst Animation on Wallpaper Set
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xF00F172A),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF10B981), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Wallpaper Set!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Settings.getScreenTargetDisplayString(_screenTarget),
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE60023).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE60023).withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: Color(0xFFE60023),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Wallpapers in Board',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t saved any wallpapers in this Pinterest board yet! Follow these quick steps to get started:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0CFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
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
                    label: const Text('Open Pinterest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE60023),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    ).then((_) => _loadCurrentWallpaper()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Change Board', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: Color(0xFF8B5CF6),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Board Selected',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t linked a Pinterest board to your Mobile yet. Choose a board so Canvas Link can sync daily wallpapers to your phone.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
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
                label: const Text('Choose a Board', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
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
            const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Session Expired',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Pinterest connection has expired. Please log in again to continue syncing wallpapers.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
          Icon(Icons.collections_bookmark_outlined, color: Colors.white.withOpacity(0.2), size: 52),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'No wallpaper loaded yet',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadCurrentWallpaper,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xB31E293B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          decoration: BoxDecoration(
            color: const Color(0xFFE60023).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFFE60023),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
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
            height: 60,
            child: ElevatedButton(
              onPressed: isBusy ? null : _skipNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xB31E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.skip_next_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Skip',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isBusy ? null : _onSetWallpaperPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: isBusy
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Setting...',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wallpaper_rounded, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Set as Wallpaper',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Board Pins', '$_totalPins', Icons.grid_view_rounded),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.08),
          ),
          InkWell(
            onTap: _showSettingsModal,
            borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.08),
          ),
          _buildStat('Next Sync', Settings.getFrequencyDisplayString(_syncFrequency), Icons.schedule_rounded),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallpaper Screen Target',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose which screen(s) new wallpapers are applied to',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
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
                          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8),
                        ),
                        title: Text(
                          Settings.getScreenTargetDisplayString(target),
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF8B5CF6))
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
                    const Divider(color: Color(0x1FFFFFFF), height: 32),
                    const Text(
                      'Auto-Sync Frequency',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...Settings.availableFrequencies.map((freq) {
                      final isSelected = freq == _syncFrequency;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          Settings.getFrequencyDisplayString(freq),
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF8B5CF6))
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
