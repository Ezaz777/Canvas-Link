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
      final data = await api.getBoards();

      setState(() {
        _boards = data['items'] ?? [];
        _selectedBoards = data['selected_boards'] ?? {};
        _isLoading = false;
      });
    } on UnauthorizedException {
      _logout();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setBoard(String? boardId, String deviceType) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final api = ApiService(token);
      await api.setBoard(boardId, deviceType);

      setState(() {
        _selectedBoards[deviceType] = boardId;
        if (boardId == null) {
          _selectedBoards['fallback'] = null;
        }
      });

      if (mounted) {
        final deviceName = deviceType == 'mobile' ? 'Mobile' : 'PC';
        final isDeactivated = boardId == null;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isDeactivated
                      ? Icons.remove_circle_outline_rounded
                      : Icons.check_circle_rounded,
                  color: PinterestTheme.canvas,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDeactivated
                        ? 'Board removed from $deviceName.'
                        : 'Board activated for $deviceName!',
                    style: GoogleFonts.inter(
                      color: PinterestTheme.canvas,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: PinterestTheme.charcoal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update board: $e', style: const TextStyle(color: PinterestTheme.canvas)),
            backgroundColor: PinterestTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PinterestTheme.radiusMd)),
          ),
        );
      }
    }
  }

  void _logout() async {
    await AuthService.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PinterestTheme.surfaceSoft,
      appBar: AppBar(
        title: Text(
          'Your Boards',
          style: GoogleFonts.inter(
            color: PinterestTheme.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: PinterestTheme.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: PinterestTheme.surfaceSoft,
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

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: PinterestTheme.error, size: 44),
              const SizedBox(height: 16),
              Text(
                'Failed to load boards',
                style: GoogleFonts.inter(
                  color: PinterestTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  color: PinterestTheme.mute,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBoards,
                style: PinterestTheme.secondaryButtonStyle(height: 40),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_boards.isEmpty) {
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
                  color: PinterestTheme.surfaceCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: PinterestTheme.hairline),
                ),
                child: const Icon(
                  Icons.collections_bookmark_rounded,
                  color: PinterestTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Pinterest Boards Found',
                style: GoogleFonts.inter(
                  color: PinterestTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'You don\'t have any boards in your Pinterest account yet. Create a board on Pinterest, save some wallpapers into it, and come back here to link it!',
                style: GoogleFonts.inter(
                  color: PinterestTheme.mute,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
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
                  style: PinterestTheme.primaryButtonStyle(height: 44),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _loadBoards,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh Boards'),
                  style: PinterestTheme.secondaryButtonStyle(height: 44),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBoards,
      color: PinterestTheme.primary,
      backgroundColor: PinterestTheme.canvas,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          final board = _boards[index];
          final boardId = board['id'] as String;
          final boardName = board['name'] as String;
          final pinCount = board['pin_count'] as int?;

          final isMobile = _selectedBoards['mobile'] == boardId ||
              (_selectedBoards['mobile'] == null && _selectedBoards['fallback'] == boardId);
          final isDesktop = _selectedBoards['desktop'] == boardId ||
              (_selectedBoards['desktop'] == null && _selectedBoards['fallback'] == boardId);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: PinterestTheme.cardDecoration(soft: false),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          boardName,
                          style: GoogleFonts.inter(
                            color: PinterestTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (pinCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: PinterestTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(PinterestTheme.radiusFull),
                          ),
                          child: Text(
                            '$pinCount pins',
                            style: GoogleFonts.inter(
                              color: PinterestTheme.mute,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _setBoard(isMobile ? null : boardId, 'mobile'),
                          icon: Icon(
                            isMobile ? Icons.check_circle_rounded : Icons.smartphone_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isMobile ? 'Mobile Active' : 'Set for Mobile',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: isMobile
                              ? PinterestTheme.primaryButtonStyle(height: 38)
                              : PinterestTheme.secondaryButtonStyle(height: 38),
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
                              ? PinterestTheme.primaryButtonStyle(height: 38)
                              : PinterestTheme.secondaryButtonStyle(height: 38),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
