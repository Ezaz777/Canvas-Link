import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/pinterest_theme.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _boards = [];
  Map<String, dynamic> _selectedBoards = {};

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _logout();
        return;
      }

      final api = ApiService(token);
      final res = await api.getBoards();

      setState(() {
        _boards = res['boards'] ?? [];
        _selectedBoards = res['selected_boards'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _setBoard(String? boardId, String target) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final api = ApiService(token);
      await api.setSelectedBoard(boardId: boardId, target: target);

      // Refresh state
      await _loadBoards();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            boardId == null
                ? 'Unset board for ${target.toUpperCase()}'
                : 'Assigned board to ${target.toUpperCase()}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _logout() async {
    await AuthService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Target Boards',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadBoards,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: PinterestTheme.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBoards,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_boards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dashboard_customize_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No boards found',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a board on Pinterest to sync wallpapers to your phone and PC.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _boards.length,
      itemBuilder: (context, index) {
        final board = _boards[index];
        final boardId = board['id'] as String;
        final name = board['name'] as String? ?? 'Untitled';
        final pinCount = board['pin_count'] as int? ?? 0;
        final media = board['media'] as Map<String, dynamic>?;
        final imageCover = media?['image_cover_url'] as String?;

        final isMobile = _selectedBoards['mobile_board_id'] == boardId;
        final isDesktop = _selectedBoards['desktop_board_id'] == boardId;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageCover != null
                          ? Image.network(
                              imageCover,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported_rounded),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.photo_library_rounded, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$pinCount pins',
                            style: GoogleFonts.inter(
                              color: PinterestTheme.getMute(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setBoard(isMobile ? null : boardId, 'mobile'),
                        icon: Icon(
                          isMobile ? Icons.check_circle_rounded : Icons.phone_android_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isMobile ? 'Mobile Active' : 'Set for Mobile',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: isMobile
                            ? PinterestTheme.primaryButtonStyle(context: context, height: 38)
                            : PinterestTheme.secondaryButtonStyle(context: context, height: 38),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setBoard(isDesktop ? null : boardId, 'desktop'),
                        icon: Icon(
                          isDesktop ? Icons.check_circle_rounded : Icons.monitor_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isDesktop ? 'PC Active' : 'Set for PC',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: isDesktop
                            ? PinterestTheme.primaryButtonStyle(context: context, height: 38)
                            : PinterestTheme.secondaryButtonStyle(context: context, height: 38),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
