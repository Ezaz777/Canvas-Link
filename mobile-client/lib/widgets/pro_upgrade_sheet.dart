import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/purchase_service.dart';

class ProUpgradeSheet extends StatefulWidget {
  const ProUpgradeSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ProUpgradeSheet(),
    );
  }

  @override
  State<ProUpgradeSheet> createState() => _ProUpgradeSheetState();
}

class _ProUpgradeSheetState extends State<ProUpgradeSheet> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purchaseService = PurchaseService.instance;
    final priceString = purchaseService.proProduct?.price ?? '₹199';

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E1E24), Color(0xFF121214)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF9F9FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Container(
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header badge & crown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFA500).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'CANVAS LINK PRO',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Headline
          Text(
            'Unlock Ultimate 4K Wallpapers',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'One-time lifetime unlock. No recurring subscriptions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 22),

          // Feature List
          _buildFeatureRow(
            icon: Icons.timer_outlined,
            title: '1-Hour & 6-Hour Rotations',
            subtitle: 'Keep your screens fresh all day with rapid automatic wallpaper cycles.',
            isDark: isDark,
          ),
          _buildFeatureRow(
            icon: Icons.screen_lock_portrait_rounded,
            title: 'Lock Screen & Dual Sync',
            subtitle: 'Set custom wallpapers independently on Home, Lock, or both simultaneously.',
            isDark: isDark,
          ),
          _buildFeatureRow(
            icon: Icons.laptop_windows_rounded,
            title: 'Windows PC Wallpaper Sync',
            subtitle: 'Auto-sync your Pinterest boards directly to your computer desktop.',
            isDark: isDark,
          ),
          _buildFeatureRow(
            icon: Icons.hd_rounded,
            title: 'Pure 4K Master Original Quality',
            subtitle: 'Direct uncompressed pin resolution straight from Pinterest CDN.',
            isDark: isDark,
          ),
          _buildFeatureRow(
            icon: Icons.dashboard_customize_rounded,
            title: 'Independent Boards',
            subtitle: 'Assign different Pinterest aesthetic boards for your Phone and PC.',
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // Purchase CTA Button
          ElevatedButton(
            onPressed: _isPurchasing ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60023),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: const Color(0xFFE60023).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isPurchasing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Unlock Pro for $priceString',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Restore purchases & Maybe later row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _isPurchasing ? null : _handleRestore,
                child: Text(
                  'Restore Purchase',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              Text(
                '•',
                style: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFFE60023),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => _isPurchasing = true);
    final purchaseService = PurchaseService.instance;

    final started = await purchaseService.buyPro();
    if (!mounted) return;

    if (!started && purchaseService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseService.errorMessage!),
          backgroundColor: const Color(0xFFE60023),
        ),
      );
      setState(() => _isPurchasing = false);
    } else {
      // Listen for activation
      purchaseService.isProNotifier.addListener(_onProStatusChanged);
      // Timeout fallback
      Future.delayed(const Duration(seconds: 45), () {
        if (mounted && _isPurchasing) {
          setState(() => _isPurchasing = false);
          purchaseService.isProNotifier.removeListener(_onProStatusChanged);
        }
      });
    }
  }

  void _onProStatusChanged() {
    if (PurchaseService.instance.isProNotifier.value) {
      PurchaseService.instance.isProNotifier.removeListener(_onProStatusChanged);
      if (mounted) {
        setState(() => _isPurchasing = false);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Canvas Link Pro unlocked successfully! Enjoy full 4K sync.'),
            backgroundColor: Color(0xFF00875A),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isPurchasing = true);
    await PurchaseService.instance.restorePurchases();
    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (PurchaseService.instance.isProNotifier.value) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase restored successfully! Welcome back to Pro.'),
          backgroundColor: Color(0xFF00875A),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No previous Canvas Link Pro purchases found on this Google account.'),
        ),
      );
    }
  }
}

