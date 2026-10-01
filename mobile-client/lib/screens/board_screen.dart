import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/wallpaper_service.dart';
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Board Gallery',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5CF6),
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
                  color: (isNoPins ? const Color(0xFFE60023) : const Color(0xFF8B5CF6)).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isNoPins ? const Color(0xFFE60023) : const Color(0xFF8B5CF6)).withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  isNoPins ? Icons.collections_bookmark_rounded : Icons.dashboard_customize_rounded,
                  color: isNoPins ? const Color(0xFFE60023) : const Color(0xFF8B5CF6),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isNoPins ? 'No Wallpapers in Board' : isNoBoard ? 'No Board Selected' : 'Failed to Load Gallery',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isNoPins
                    ? 'Your selected Pinterest board has no saved wallpapers or images yet. Save some pins on Pinterest and check back!'
                    : _errorMessage ?? 'Please choose a Pinterest board in Your Boards first.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (isNoPins) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('https://www.pinterest.com'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 20),
                    label: const Text('Open Pinterest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE60023),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  ).then((_) => _loadPins()),
                  icon: const Icon(Icons.dashboard_customize_rounded, size: 20),
                  label: const Text('Manage Boards', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadPins,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65, // Taller aspect ratio for Pinterest pins
      ),
      itemCount: _pins.length,
      itemBuilder: (context, index) {
        final pin = _pins[index];
        return _buildPinCard(pin);
      },
    );
  }

  Widget _buildPinCard(Map<String, dynamic> pin) {
    return InkWell(
      onTap: () => _showPinOptions(pin),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                      color: Color(0xFF8B5CF6),
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
                      errorBuilder: (ctx2, err2, stack2) => Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.white.withOpacity(0.3), size: 32),
                      ),
                    );
                  }
                  return Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white.withOpacity(0.3), size: 32),
                  );
                },
              ),
              if (pin['title'] != null && pin['title'].toString().isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      pin['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
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
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.wallpaper_rounded, color: Colors.white),
                title: const Text('Set as Wallpaper', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Choose Home, Lock, or Both screens', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                onTap: () {
                  Navigator.pop(context);
                  _showSetTargetSheet(pin['image_url']);
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
                title: const Text('Delete from Board', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                subtitle: Text('Permanently remove from Pinterest', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                onTap: () async {
                  Navigator.pop(context);
                  _deletePin(pin['id']);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSetTargetSheet(String imageUrl) {
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
                  'Choose which screen to apply this wallpaper to',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
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
        color: const Color(0x0CFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFC4B5FD), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
        onTap: () {
          Navigator.pop(context);
          _setAsWallpaper(imageUrl, location: location, targetLabel: targetLabel);
        },
      ),
    );
  }

  Future<void> _setAsWallpaper(String url, {required int location, required String targetLabel}) async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Setting wallpaper to $targetLabel...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      final success = await WallpaperService.setWallpaperFromUrl(url, location: location);
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Wallpaper set to $targetLabel!')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set wallpaper: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  Future<void> _deletePin(String pinId) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Pin?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently delete the image from your Pinterest board. This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final api = ApiService(token);
      await api.deletePin(pinId);

      // Remove from local list
      setState(() {
        _pins.removeWhere((p) => p['id'] == pinId);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pin deleted successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
