import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Future<void> _setBoard(String boardId, String deviceType) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final api = ApiService(token);
      await api.setBoard(boardId, deviceType);

      setState(() {
        _selectedBoards[deviceType] = boardId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Board set for $deviceType!'),
            backgroundColor: const Color(0xFF10B981),
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
            content: Text('Failed to set board: $e'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize_rounded,
                color: Colors.white.withOpacity(0.2), size: 56),
            const SizedBox(height: 16),
            Text(
              'No boards found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
            label: isMobile ? 'Active on Mobile' : 'Set for Mobile',
            icon: Icons.smartphone_rounded,
            isActive: isMobile,
            onPressed: () => _setBoard(boardId, 'mobile'),
          ),
          const SizedBox(height: 12),
          _buildDeviceButton(
            label: isDesktop ? 'Active on PC' : 'Set for PC',
            icon: Icons.monitor_rounded,
            isActive: isDesktop,
            onPressed: () => _setBoard(boardId, 'desktop'),
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
              isActive ? activeColor.withOpacity(0.2) : const Color(0x0CFFFFFF),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
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
