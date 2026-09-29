import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/wallpaper_service.dart';
import '../workers/wallpaper_worker.dart';
import '../utils/settings.dart';
import 'board_screen.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isSyncing = false;
  bool _isLoadingPreview = true;
  String? _currentImageUrl;
  String? _currentPinId;
  String? _currentDate;
  String? _errorMessage;
  String? _errorCode;
  int? _totalPins;
  int _syncFrequency = 24;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadCurrentWallpaper();
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final freq = await Settings.getSyncFrequency();
    if (mounted) {
      setState(() {
        _syncFrequency = freq;
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

      setState(() {
        _currentImageUrl = data['image_url'];
        _currentPinId = data['pin_id'];
        _currentDate = data['date'];
        _totalPins = data['total_pins'];
        _isLoadingPreview = false;
        _errorMessage = null;
        _errorCode = null;
      });
    } on UnauthorizedException {
      setState(() {
        _errorMessage = 'Session expired. Please log in again.';
        _errorCode = 'auth_expired';
        _currentImageUrl = null;
        _totalPins = null;
        _isLoadingPreview = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _errorCode = e.code;
        _currentImageUrl = null;
        _totalPins = null;
        _isLoadingPreview = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wallpaper preview.';
        _errorCode = 'unknown';
        _currentImageUrl = null;
        _totalPins = null;
        _isLoadingPreview = false;
      });
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
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Wallpaper synced successfully!')),
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
    setState(() => _isSyncing = true);

    try {
      final token = await AuthService.getToken();
      if (token != null) {
        final api = ApiService(token);
        await api.skipWallpaper();
        
        await WallpaperWorker.runOnce();
        await WallpaperService.syncWallpaper();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Wallpaper skipped! New wallpaper applied.')),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          await _loadCurrentWallpaper();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _loadCurrentWallpaper();
      }
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

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380),
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _isLoadingPreview
            ? const SizedBox(
                height: 380,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : _currentImageUrl != null
                ? SizedBox(
                    height: 380,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _currentImageUrl!,
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
                          errorBuilder: (ctx, err, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_rounded,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 48),
                                const SizedBox(height: 12),
                                Text('Failed to load preview',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4))),
                              ],
                            ),
                          ),
                        ),
                        // Date overlay
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    color: Color(0xFF8B5CF6), size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  _currentDate ?? 'Today',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildEmptyOrErrorGuide(),
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
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: _isSyncing ? null : _skipNow,
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
              ),
              child: ElevatedButton(
                onPressed: _isSyncing ? null : _syncNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: _isSyncing
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
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync_rounded, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Sync Now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          _buildStat('Status', 'Active', Icons.check_circle_rounded),
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
      backgroundColor: const Color(0xFF24243E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Auto-Sync Frequency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...Settings.availableFrequencies.map((freq) {
                    final isSelected = freq == _syncFrequency;
                    return ListTile(
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
            );
          },
        );
      },
    );
  }
}
