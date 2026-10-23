import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/wallpaper_service.dart';
import '../utils/pinterest_theme.dart';
import 'dashboard_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _errorCode;
  List<Map<String, dynamic>> _pins = [];

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final api = ApiService(token);
      final pins = await api.getBoardPins();

      setState(() {
        _pins = pins;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _errorCode = e.code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _errorCode = 'unknown';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PinterestTheme.getSurfaceSoft(context),
      appBar: AppBar(
        title: Text(
          'Board Gallery',
          style: GoogleFonts.inter(
            color: PinterestTheme.getInk(context),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: PinterestTheme.getInk(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: PinterestTheme.getSurfaceSoft(context),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: PinterestTheme.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null || _pins.isEmpty) {
      final isNoPins = _errorCode == 'no_pins_found' || _pins.isEmpty;
      final isNoBoard = _errorCode == 'no_board_selected';

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: PinterestTheme.getSurfaceCard(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: PinterestTheme.getHairline(context)),
                ),
                child: const Icon(
                  Icons.collections_bookmark_rounded,
                  color: PinterestTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isNoPins ? 'No Wallpapers in Board' : isNoBoard ? 'No Board Selected' : 'Failed to Load Gallery',
                style: GoogleFonts.inter(
                  color: PinterestTheme.getInk(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isNoPins
                    ? 'Your selected Pinterest board has no saved wallpapers or images yet. Save some pins on Pinterest and check back!'
                    : _errorMessage ?? 'Please choose a Pinterest board in Your Boards first.',
                style: GoogleFonts.inter(
                  color: PinterestTheme.getMute(context),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (isNoPins) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.pinterest.com'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open Pinterest'),
                    style: PinterestTheme.primaryButtonStyle(context: context, height: 44),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  ).then((_) => _loadPins()),
                  icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                  label: const Text('Manage Boards'),
                  style: PinterestTheme.secondaryButtonStyle(context: context, height: 44),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadPins,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: PinterestTheme.getMute(context)),
              ),
            ],
          ),
        ),
      );
    }

    // Tight 8px gutter Pinterest Masonry style grid with 3-button navigation clearance
    final bottomNavPadding = MediaQuery.of(context).padding.bottom;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        PinterestTheme.spaceSm,
        PinterestTheme.spaceSm,
        PinterestTheme.spaceSm,
        bottomNavPadding + 48,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: PinterestTheme.spaceSm,
        crossAxisSpacing: PinterestTheme.spaceSm,
        childAspectRatio: 0.68, // Vertical portrait ratio
      ),
      itemCount: _pins.length,
      itemBuilder: (context, index) {
        final pin = _pins[index];
        return _buildPinCard(pin);
      },
    );
  }

  Widget _buildPinCard(Map<String, dynamic> pin) {
    final isFlagged = pin['is_flagged'] == true;

    return InkWell(
      onTap: () => _showPinOptions(pin),
      borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: PinterestTheme.getSurfaceCard(context),
          borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
          border: Border.all(color: PinterestTheme.getHairline(context)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                pin['image_url'],
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
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (ctx, err, stack) {
                  final fallbackUrl = pin['fallback_url'] as String?;
                  if (fallbackUrl != null && fallbackUrl != pin['image_url']) {
                    return Image.network(
                      fallbackUrl,
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36'
                      },
                      fit: BoxFit.cover,
                      errorBuilder: (ctx2, err2, stack2) => const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: PinterestTheme.ash, size: 32),
                      ),
                    );
                  }
                  return const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: PinterestTheme.ash, size: 32),
                  );
                },
              ),

              // Priority / Flagged Status Badge matching DESIGN.md
              Positioned(
                top: 8,
                left: 8,
                child: isFlagged
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
                        decoration: BoxDecoration(
                          color: (PinterestTheme.isDark(context) ? Colors.black : Colors.black87)
                              .withOpacity(0.75),
                          borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                          border: Border.all(
                            color: PinterestTheme.isDark(context) ? PinterestTheme.hairlineDark : Colors.white24,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 11,
                              color: Color(0xFF48BB78),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SEEN',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
                        decoration: BoxDecoration(
                          color: PinterestTheme.primary,
                          borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                          boxShadow: [
                            BoxShadow(
                              color: PinterestTheme.primary.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'NEW',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              // Corner overlay pill matching DESIGN.md
              if (pin['title'] != null && pin['title'].toString().isNotEmpty)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: PinterestTheme.getCanvas(context).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                      border: Border.all(color: PinterestTheme.getHairline(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      pin['title'],
                      style: GoogleFonts.inter(
                        color: PinterestTheme.getInk(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinOptions(Map<String, dynamic> pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PinterestTheme.getCanvas(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PinterestTheme.radiusLg)),
      ),
      builder: (context) {
        final bottomNavPadding = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomNavPadding + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: PinterestTheme.getHairline(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PinterestTheme.getSurfaceCard(context),
                      borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                    ),
                    child: const Icon(Icons.wallpaper_rounded, color: PinterestTheme.primary, size: 20),
                  ),
                  title: Text(
                    'Set as Wallpaper',
                    style: GoogleFonts.inter(color: PinterestTheme.getInk(context), fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Choose Home, Lock, or Both screens',
                    style: GoogleFonts.inter(color: PinterestTheme.getMute(context), fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: PinterestTheme.ash),
                  onTap: () {
                    Navigator.pop(context);
                    _showSetTargetSheet(pin['image_url']);
                  },
                ),
                Divider(color: PinterestTheme.getHairline(context)),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: PinterestTheme.getSurfaceCard(context),
                      borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: PinterestTheme.error, size: 20),
                  ),
                  title: Text(
                    'Delete from Board',
                    style: GoogleFonts.inter(color: PinterestTheme.error, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Permanently remove from Pinterest',
                    style: GoogleFonts.inter(color: PinterestTheme.getMute(context), fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    _deletePin(pin['id']);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSetTargetSheet(String imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PinterestTheme.getCanvas(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PinterestTheme.radiusLg)),
      ),
      builder: (context) {
        final bottomNavPadding = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomNavPadding + 16),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which screen to apply this wallpaper to',
                  style: GoogleFonts.inter(
                    color: PinterestTheme.getMute(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                _buildGalleryTargetTile(
                  icon: Icons.devices_rounded,
                  title: 'Home & Lock Screens',
                  subtitle: 'Set on both your home screen and lock screen',
                  location: AsyncWallpaper.BOTH_SCREENS,
                  imageUrl: imageUrl,
                  targetLabel: 'Home & Lock Screens',
                ),
                const SizedBox(height: 10),
                _buildGalleryTargetTile(
                  icon: Icons.home_rounded,
                  title: 'Home Screen Only',
                  subtitle: 'Set only on your main home screen',
                  location: AsyncWallpaper.HOME_SCREEN,
                  imageUrl: imageUrl,
                  targetLabel: 'Home Screen Only',
                ),
                const SizedBox(height: 10),
                _buildGalleryTargetTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Lock Screen Only',
                  subtitle: 'Set only on your device lock screen',
                  location: AsyncWallpaper.LOCK_SCREEN,
                  imageUrl: imageUrl,
                  targetLabel: 'Lock Screen Only',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryTargetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int location,
    required String imageUrl,
    required String targetLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: PinterestTheme.getSurfaceCard(context),
        borderRadius: BorderRadius.circular(PinterestTheme.radiusMd),
        border: Border.all(color: PinterestTheme.getHairline(context)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PinterestTheme.getCanvas(context),
            borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
            border: Border.all(color: PinterestTheme.getHairline(context)),
          ),
          child: Icon(icon, color: PinterestTheme.getInk(context), size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: PinterestTheme.getInk(context),
            fontWeight: FontWeight.w600,
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
        onTap: () {
          Navigator.pop(context);
          _applyWallpaper(imageUrl, location, targetLabel);
        },
      ),
    );
  }

  Future<void> _applyWallpaper(String imageUrl, int location, String targetLabel) async {
    final snackBarBg = PinterestTheme.isDark(context)
        ? const Color(0xFF262622)
        : PinterestTheme.charcoal;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Setting wallpaper on $targetLabel...', style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: snackBarBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
      ),
    );

    try {
      String target = 'both';
      if (location == AsyncWallpaper.HOME_SCREEN) target = 'home';
      if (location == AsyncWallpaper.LOCK_SCREEN) target = 'lock';
      final success = await WallpaperService.setWallpaperFromUrl(
        imageUrl,
        target: target,
        location: location,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (success) {
          // Report the applied pin to backend so it gets flagged as 'seen'
          final matchingPin = _pins.firstWhere(
            (p) => p['image_url'] == imageUrl,
            orElse: () => <String, dynamic>{},
          );
          final pinId = matchingPin['id'] as String?;
          if (pinId != null) {
            try {
              final token = await AuthService.getToken();
              if (token != null) {
                final api = ApiService(token);
                await api.setActiveWallpaper(pinId);
                print('BoardScreen: Reported pin $pinId as active wallpaper to backend');
              }
            } catch (e) {
              print('BoardScreen: Failed to report active wallpaper (non-fatal): $e');
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wallpaper updated on $targetLabel!', style: const TextStyle(color: Colors.white)),
              backgroundColor: snackBarBg,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to set wallpaper.', style: TextStyle(color: Colors.white)),
              backgroundColor: PinterestTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: PinterestTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
          ),
        );
      }
    }
  }

  Future<void> _deletePin(String pinId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PinterestTheme.getCanvas(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusLg)),
        title: Text('Delete Pin?', style: GoogleFonts.inter(color: PinterestTheme.getInk(ctx), fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this pin from your Pinterest board?', style: GoogleFonts.inter(color: PinterestTheme.getMute(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: PinterestTheme.getMute(ctx))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PinterestTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final api = ApiService(token);
      await api.deletePin(pinId);

      setState(() {
        _pins.removeWhere((p) => p['id'] == pinId);
      });

      if (mounted) {
        final snackBarBg = PinterestTheme.isDark(context)
            ? const Color(0xFF262622)
            : PinterestTheme.charcoal;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pin deleted from board.', style: TextStyle(color: Colors.white)),
            backgroundColor: snackBarBg,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete pin: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: PinterestTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
          ),
        );
      }
    }
  }
}
