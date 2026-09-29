import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(boardId == null
                ? '⚪ Board deactivated for $deviceName.'
                : '✅ Board activated for $deviceName!'),
            backgroundColor: boardId == null
                ? const Color(0xFF475569)
                : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update board: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Your Boards',
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

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load boards',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBoards,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xB31E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE60023).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE60023).withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.collections_bookmark_rounded,
                  color: Color(0xFFE60023),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Pinterest Boards Found',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You don\'t have any boards in your Pinterest account yet. Create a board on Pinterest, save some wallpapers into it, and come back here to link it!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loadBoards,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Refresh Boards', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBoards,
      color: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _boards.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final board = _boards[index];
          return _buildBoardCard(board);
        },
      ),
    );
  }

  Widget _buildBoardCard(dynamic board) {
    final String boardId = board['id'];
    final bool isMobile = _selectedBoards['mobile'] == boardId ||
        (_selectedBoards['mobile'] == null &&
            _selectedBoards['fallback'] == boardId);
    final bool isDesktop = _selectedBoards['desktop'] == boardId ||
        (_selectedBoards['desktop'] == null &&
            _selectedBoards['fallback'] == boardId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            board['name'] ?? 'Unknown Board',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildDeviceButton(
            label: isMobile ? 'Active on Mobile • Tap to Remove' : 'Set for Mobile',
            icon: Icons.smartphone_rounded,
            isActive: isMobile,
            onPressed: () => _setBoard(isMobile ? null : boardId, 'mobile'),
          ),
          const SizedBox(height: 12),
          _buildDeviceButton(
            label: isDesktop ? 'Active on PC • Tap to Remove' : 'Set for PC',
            icon: Icons.monitor_rounded,
            isActive: isDesktop,
            onPressed: () => _setBoard(isDesktop ? null : boardId, 'desktop'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final Color activeColor = icon == Icons.smartphone_rounded
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF10B981);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isActive ? activeColor.withOpacity(0.18) : const Color(0x0CFFFFFF),
          foregroundColor: isActive ? Colors.white : Colors.white.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive ? activeColor : Colors.white.withOpacity(0.1),
            ),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? activeColor : null),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 18, color: activeColor),
            ],
          ],
        ),
      ),
    );
  }
}
