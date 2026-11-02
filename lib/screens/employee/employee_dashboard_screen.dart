import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/banner_service.dart';
import '../client/notifications_screen.dart';
import 'employee_training_videos_screen.dart';
import 'employee_live_map_screen.dart';
import 'employee_tagged_leads_screen.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFF3EBDF);

// Soft background color-orbs behind the glass content, matching the
// "Champagne" theme treatment used across the premium screens.
const _orb1 = Color(0xFFD4AF37);
const _orb2 = Color(0xFFE8A77A);
const _orb3 = Color(0xFFC98E5A);

class EmployeeDashboardScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final String employeeName;
  final ValueChanged<int>? onNavigate;
  const EmployeeDashboardScreen({super.key, this.onOpenDrawer, required this.employeeName, this.onNavigate});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label coming soon.'), backgroundColor: _bronze));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final firstName = employeeName.split(' ').first;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        if (!isDark) ...[
          Positioned(left: -90, top: 180, child: _orb(_orb1, 320, 0.5)),
          Positioned(right: -120, top: 420, child: _orb(_orb2, 340, 0.4)),
          Positioned(left: 40, bottom: -80, child: _orb(_orb3, 300, 0.35)),
        ],
        Column(children: [
          SizedBox(
            height: 260,
            child: Stack(children: [
              const _EmployeeBannerCarousel(),
              Positioned(top: 0, left: 0, right: 0,
                child: SafeArea(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    GestureDetector(
                      onTap: onOpenDrawer,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 0, offset: const Offset(0, 1))]),
                            child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22)),
                        ),
                      ),
                    ),
                    Stack(clipBehavior: Clip.none, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.4))),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                            ),
                          ),
                        ),
                      ),
                      if (Provider.of<NotificationProvider>(context).unreadCount > 0)
                        Positioned(right: 8, top: 8, child: Container(
                          width: 9, height: 9,
                          decoration: BoxDecoration(color: _gold, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _gold.withOpacity(0.7), blurRadius: 6)]))),
                    ]),
                  ]),
                )),
              ),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 110),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Welcome back', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : _bronze.withOpacity(0.65))),
                    const SizedBox(height: 2),
                    Text('Hello, $firstName', style: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w900,
                        letterSpacing: -0.5, color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                  ]),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _FieldDutyCard(attendance: attendance, isDark: isDark),
                ),
                if (attendance.fieldDutyActive)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: EmployeeFieldDutyMapCard()),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                  child: Text('Quick access', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _GlassPanel(
                    isDark: isDark,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                    child: GridView.count(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 16, childAspectRatio: 0.82,
                      children: [
                        _quickAccess(context, isDark, Icons.play_circle_outline, 'Training', const [Color(0xFFC98E5A), Color(0xFF8F5A2C)],
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeTrainingVideosScreen()))),
                        _quickAccess(context, isDark, Icons.receipt_long_outlined, 'Payslip', const [Color(0xFFA8875F), Color(0xFF6B5948)],
                            () => _comingSoon(context, 'Payslip')),
                        _quickAccess(context, isDark, Icons.campaign_outlined, 'Announcements', const [Color(0xFFB89B5E), Color(0xFF7D6430)],
                            () => _comingSoon(context, 'Announcements')),
                        _quickAccess(context, isDark, Icons.description_outlined, 'Documents', const [Color(0xFF9C8670), Color(0xFF5C4C3E)],
                            () => _comingSoon(context, 'Documents')),
                        _quickAccess(context, isDark, Icons.local_offer_outlined, 'Tagged Leads', const [Color(0xFFD9A441), Color(0xFFA06E12)],
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeTaggedLeadsScreen()))),
                        _quickAccessGlass(context, isDark, Icons.more_horiz, 'More', () => _comingSoon(context, 'More')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                  child: Text("${_monthLabel()} summary", style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(children: [
                    _summaryStat(isDark, 'Present Days', '${attendance.presentDaysThisMonth}', const Color(0xFF8A6516)),
                    const SizedBox(width: 10),
                    _summaryStat(isDark, 'Leaves', '${attendance.leavesThisMonth}', const Color(0xFFA8613A)),
                    const SizedBox(width: 10),
                    _summaryStat(isDark, 'Total Hours', attendance.totalHoursThisMonth, const Color(0xFF6B5948)),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  String _monthLabel() {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return months[DateTime.now().month - 1];
  }

  Widget _orb(Color color, double size, double opacity) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withOpacity(opacity), color.withOpacity(0)])),
        ),
      ),
    );
  }

  Widget _quickAccess(BuildContext context, bool isDark, IconData icon, String label, List<Color> gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.45)),
              boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))]),
          child: Icon(icon, color: Colors.white, size: 21)),
        const SizedBox(height: 7),
        Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : _bronze.withOpacity(0.85))),
      ]),
    );
  }

  Widget _quickAccessGlass(BuildContext context, bool isDark, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.5))),
          child: Icon(icon, color: isDark ? Colors.white70 : _bronze, size: 21)),
        const SizedBox(height: 7),
        Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : _bronze.withOpacity(0.85))),
      ]),
    );
  }

  Widget _summaryStat(bool isDark, String label, String value, Color accent) {
    return Expanded(
      child: _GlassPanel(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5,
              color: isDark ? Colors.white : accent)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : _bronze.withOpacity(0.55))),
        ]),
      ),
    );
  }
}

class _FieldDutyCard extends StatelessWidget {
  final EmployeeAttendanceProvider attendance;
  final bool isDark;
  const _FieldDutyCard({required this.attendance, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final active = attendance.fieldDutyActive;
    return GestureDetector(
      onTap: () async {
        final provider = Provider.of<EmployeeAttendanceProvider>(context, listen: false);
        if (active) {
          await provider.endFieldDuty();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Field Duty ended.'), backgroundColor: _bronze));
          }
        } else {
          await provider.startFieldDuty();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Field Duty started — your TL can now see your live route.'), backgroundColor: _bronze));
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: active
                      ? [const Color(0xFF1D9A6C).withOpacity(0.9), const Color(0xFF0F5A46).withOpacity(0.8)]
                      : [const Color(0xFFB0862A).withOpacity(0.92), const Color(0xFF6B5948).withOpacity(0.85)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.45)),
              boxShadow: [BoxShadow(color: (active ? Colors.green : _gold).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.4))),
                child: Icon(active ? Icons.pause_circle_outline : Icons.directions_walk, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(active ? 'On field duty' : 'Start field duty',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 3),
                Text(active ? 'Sharing live route with your TL. Tap to end.' : 'Share your live route with your TL while out on visits.',
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.85), height: 1.3)),
              ])),
              const SizedBox(width: 8),
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)]),
                child: Icon(active ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: active ? const Color(0xFF0F5A46) : const Color(0xFF6B4F10), size: 22)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Reusable frosted-glass panel used for Quick Access + stat cards.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  const _GlassPanel({required this.child, required this.isDark, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                    : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.3)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.85)),
            boxShadow: [BoxShadow(color: _bronze.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Employee knowledge/update banners (same carousel pattern as CP/Client
// and the Collateral screen) — fetched with project: 'Employee' so these
// can be managed as their own audience on the same SmartCue banners
// backend, separate from per-project (Zaiden/Ryla/...) banners.
class _EmployeeBannerCarousel extends StatefulWidget {
  const _EmployeeBannerCarousel();
  @override
  State<_EmployeeBannerCarousel> createState() => _EmployeeBannerCarouselState();
}

class _EmployeeBannerCarouselState extends State<_EmployeeBannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;
  List<Map<String, dynamic>> _banners = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_controller.hasClients && _banners.isNotEmpty) {
        final next = (_current + 1) % _banners.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _fetch() async {
    try {
      final remote = await BannerService.fetchBanners(project: 'Employee');
      if (mounted) setState(() => _banners = remote.map((b) => b.toSlideMap()).toList());
    } catch (e) {
      debugPrint('Employee dashboard banner error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _slide(Map<String, dynamic> b) {
    final remoteImage = b['remoteImage'] as String?;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)]),
      ),
      child: Stack(children: [
        if (remoteImage != null && remoteImage.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(imageUrl: remoteImage, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: _bronze),
                errorWidget: (_, __, ___) => Container(color: _bronze)),
          ),
        Positioned.fill(
          child: Container(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.55)]))),
        ),
        Positioned(
          bottom: 28, left: 18, right: 18,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((b['tag'] ?? '').toString().isNotEmpty)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text((b['tag'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
            const SizedBox(height: 8),
            Text((b['title'] ?? '').toString(), style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            if ((b['subtitle'] ?? '').toString().isNotEmpty)
              Text((b['subtitle'] ?? '').toString(), style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: _banners.isEmpty
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)]),
                ),
                child: const Center(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('New updates coming soon', style: TextStyle(color: Colors.white70, fontSize: 13)),
                )),
              )
            : PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _banners.length,
                itemBuilder: (_, i) => _slide(_banners[i]),
              ),
      ),
      if (_banners.isNotEmpty)
        Positioned(bottom: 12, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 16 : 6, height: 6,
                decoration: BoxDecoration(color: i == _current ? _gold : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3)))))),
    ]);
  }
}
