import '../client/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../auth/login_screen.dart';
import '../../providers/booking_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/banner_service.dart';
import 'cp_help_support_screen.dart';
import '../client/construction_screen.dart';
import 'cp_payouts_screen.dart';
import 'cp_leaderboard_screen.dart';
import 'cp_training_screen.dart';
import 'cp_marketing_collateral_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});
  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  VideoPlayerController? _drawerVideoCtrl;

  @override
  void initState() {
    super.initState();
    _initDrawerVideo();
  }

  Future<void> _initDrawerVideo() async {
    try {
      _drawerVideoCtrl = VideoPlayerController.asset('assets/videos/drawer_bg.mp4');
      await _drawerVideoCtrl!.initialize();
      _drawerVideoCtrl!.setLooping(true);
      _drawerVideoCtrl!.setVolume(0);
      _drawerVideoCtrl!.play();
      if (mounted) setState(() {});
    } catch (e) { debugPrint('Video error: $e'); }
  }

  @override
  void dispose() {
    _drawerVideoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingProvider = Provider.of<BookingProvider>(context);
    final cpName = (bookingProvider.cpDashboardData?['cpName'] as String?)?.trim();
    final cpDisplayName = (cpName != null && cpName.isNotEmpty) ? cpName : 'Channel Partner';
    final cpMahaRera = bookingProvider.mahaRERA ?? '--';
    final screens = [
      CPDashboardScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      CPLeadsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      CPBookingsScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      CPTrainingScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      CPProfileScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1A0A00) : const Color(0xFFF0F8FF),
        child: Column(children: [
          // Header with video
          SizedBox(height: 180,
            child: Stack(children: [
              if (_drawerVideoCtrl != null && _drawerVideoCtrl!.value.isInitialized)
                Positioned.fill(child: FittedBox(fit: BoxFit.cover,
                  child: SizedBox(width: _drawerVideoCtrl!.value.size.width,
                    height: _drawerVideoCtrl!.value.size.height,
                    child: VideoPlayer(_drawerVideoCtrl!))))
              else
                Positioned.fill(child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6B4A1E), Color(0xFF543813)])))),
              Positioned.fill(child: Container(color: Colors.black.withOpacity(0.45))),
              Positioned.fill(child: Column(mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: 60, height: 60,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 2)),
                    child: const Icon(Icons.person, color: Color(0xFFD4AF37), size: 32)),
                  const SizedBox(height: 8),
                  Text(cpDisplayName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(cpMahaRera, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
                ])),
            ])),
          // Menu items
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            _drawerItem(context, Icons.dashboard_outlined, 'Dashboard', () { setState(() => _currentIndex = 0); Navigator.pop(context); }, isDark, active: _currentIndex == 0),
            _drawerItem(context, Icons.people_outlined, 'My Visit', () { setState(() => _currentIndex = 1); Navigator.pop(context); }, isDark, active: _currentIndex == 1),
            _drawerItem(context, Icons.assignment_outlined, 'My Bookings', () { setState(() => _currentIndex = 2); Navigator.pop(context); }, isDark, active: _currentIndex == 2),
            _drawerItem(context, Icons.construction_outlined, 'Construction Updates', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConstructionScreen()));
            }, isDark),
            _drawerItem(context, Icons.calculate_outlined, 'Pay-out', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CPPayoutsScreen()));
            }, isDark),
            _drawerItem(context, Icons.campaign_outlined, 'Marketing Collateral', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CPMarketingCollateralScreen()));
            }, isDark),
            _drawerItem(context, Icons.support_agent_outlined, 'Assistance', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CPAssistanceScreen()));
            }, isDark),
            Divider(color: isDark ? Colors.white12 : const Color(0xFF543813).withOpacity(0.15)),
            _drawerItem(context, Icons.person_outlined, 'My Profile', () { setState(() => _currentIndex = 4); Navigator.pop(context); }, isDark, active: _currentIndex == 4),
            _drawerItem(context, Icons.settings_outlined, 'Settings', () => Navigator.pop(context), isDark),
            _drawerItem(context, Icons.help_outline, 'Help & Support', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CPHelpSupportScreen()));
            }, isDark),
            Consumer<ThemeProvider>(
              builder: (ctx, theme, _) => ListTile(dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                leading: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? Colors.white70 : const Color(0xFF543813), size: 20),
                title: Text(theme.isDarkMode ? 'Light Mode' : 'Dark Mode',
                    style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF543813), fontSize: 14)),
                trailing: Switch(value: theme.isDarkMode, onChanged: (_) => theme.toggleTheme(),
                    activeColor: const Color(0xFFD4AF37),
                    activeTrackColor: const Color(0xFFD4AF37).withOpacity(0.3)),
                onTap: () => theme.toggleTheme())),
          ])),
          // Sign out
          _drawerItem(context, Icons.logout, 'Sign Out',
            () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
            isDark, color: Colors.red),
          const SizedBox(height: 16),
        ]),
      ),
            body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0A00) : const Color(0xFF543813),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, -3))]),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', isDark),
            _navItem(1, Icons.directions_walk_outlined, Icons.directions_walk, 'Visits', isDark),
            _navItem(2, Icons.assignment_outlined, Icons.assignment, 'Bookings', isDark),
            _navItem(3, Icons.play_circle_outline, Icons.play_circle, 'Training', isDark),
            _navItem(4, Icons.person_outlined, Icons.person, 'Profile', isDark),
          ]),
      ),
    );
  }


  Widget _drawerItem(BuildContext context, IconData icon, String label, VoidCallback onTap, bool isDark, {Color? color, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active
            ? const Color(0xFFD4AF37).withOpacity(isDark ? 0.15 : 0.12)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
              ? Colors.white.withOpacity(isDark ? 0.2 : 0.6)
              : Colors.transparent,
            width: 1),
          boxShadow: active ? [
            BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 10),
            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 4, offset: const Offset(-1,-1)),
          ] : null),
        child: Row(children: [
          Icon(icon, color: color ?? (isDark ? const Color(0xFFF5F5F5) : const Color(0xFF543813)), size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(
            color: color ?? (isDark ? const Color(0xFFF5F5F5) : const Color(0xFF543813)),
            fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          if (active) ...[
              Container(width: 6, height: 6,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD4AF37))),
          ],
        ])));
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? const Color(0xFFD4AF37).withOpacity(0.5) : Colors.transparent)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFFD4AF37) : Colors.white60, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? const Color(0xFFD4AF37) : Colors.white60)),
        ]),
      ),
    );
  }
}

// ── CP DASHBOARD ──────────────────────────────────────────────
class CPDashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CPDashboardScreen({super.key, this.onOpenDrawer});
  @override
  State<CPDashboardScreen> createState() => _CPDashboardScreenState();
}

class _CPDashboardScreenState extends State<CPDashboardScreen> {
  int _currentBanner = 0;
  final PageController _bannerController = PageController();
  String _selectedProject = 'All Projects';
  static const _projectOptions = ['All Projects', 'Roswalt Zaiden', 'Roswalt Ryla', 'Roswalt Raya', 'Roswalt Zeya', 'Roswalt Zyon'];

  List<Map<String, dynamic>> _banners = [
    {'label': 'ROSWALT ZAIDEN', 'remoteImage': null, 'image': 'assets/images/banner_zaiden.jpg', 'gradientColors': <Color>[const Color(0xFF1A0A0A), const Color(0xFF3D0000)], 'tag': 'HOT PROJECT', 'title': 'ROSWALT ZAIDEN', 'subtitle': 'Premium 2 & 3 BHK', 'progress': 0.0, 'progressLabel': '', 'accentColor': const Color(0xFFD4AF37), 'linkUrl': ''},
    {'label': 'ROSWALT RYLA', 'remoteImage': null, 'image': 'assets/images/banner_ryla.jpg', 'gradientColors': <Color>[const Color(0xFF1A0A0A), const Color(0xFF3D0000)], 'tag': 'NEW LAUNCH', 'title': 'ROSWALT RYLA', 'subtitle': 'Luxury Residences', 'progress': 0.0, 'progressLabel': '', 'accentColor': const Color(0xFFD4AF37), 'linkUrl': ''},
    {'label': 'CONSTRUCTION UPDATE', 'remoteImage': null, 'image': 'assets/images/banner_construction.jpg', 'gradientColors': <Color>[const Color(0xFF1A0A0A), const Color(0xFF3D0000)], 'tag': 'JUNE 2026', 'title': 'CONSTRUCTION UPDATE', 'subtitle': 'Latest Progress', 'progress': 0.0, 'progressLabel': '', 'accentColor': const Color(0xFFD4AF37), 'linkUrl': ''},
    {'label': 'ROSWALT ZEYA', 'remoteImage': null, 'image': 'assets/images/banner_zeya.png', 'gradientColors': <Color>[const Color(0xFF1A0A0A), const Color(0xFF3D0000)], 'tag': 'COMING SOON', 'title': 'ROSWALT ZEYA', 'subtitle': 'Smart Living', 'progress': 0.0, 'progressLabel': '', 'accentColor': const Color(0xFFD4AF37), 'linkUrl': ''},
  ];

  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _fetchRemoteBanners();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchRemoteBanners() async {
    try {
      final remote = await BannerService.fetchBanners();
      if (remote.isNotEmpty && mounted) {
        setState(() => _banners = remote.map((b) => b.toSlideMap()).toList());
      }
    } catch (e) {
      debugPrint('CP Banner error: $e');
    }
  }

  Widget _buildBannerSlide(Map<String, dynamic> b) {
    final colors = b['gradientColors'] as List<Color>;
    final accent = b['accentColor'] as Color;
    final remoteImage = b['remoteImage'] as String?;
    final image = b['image'] as String?;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Stack(children: [
        if (remoteImage != null && remoteImage.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: remoteImage,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF1A0A0A)),
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A0A0A)),
            ),
          )
        else if (image != null)
          Positioned.fill(
            child: Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
          ),
        if (remoteImage != null || image != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.65)]),
              ),
            ),
          ),
        Positioned(right: -30, top: -30, child: Container(width: 180, height: 180,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
        Positioned(left: -40, bottom: -40, child: Container(width: 140, height: 140,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.08)))),
        Positioned(
          bottom: 40, left: 20, right: 20,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text((b['tag'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
            const SizedBox(height: 8),
            Text((b['title'] ?? '').toString(), style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text((b['subtitle'] ?? '').toString(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cpData = Provider.of<BookingProvider>(context).cpDashboardData;
    final _projectWiseData = (cpData?['projectWiseData'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];
    final _displayedWalkIns = _selectedProject == 'All Projects'
        ? (cpData?['totalWalkIns'] ?? 0)
        : _projectWiseData
            .where((p) => (p['projectName'] as String? ?? '').toUpperCase() == _selectedProject.toUpperCase())
            .fold<int>(0, (sum, p) => sum + ((p['walkIns'] as num?)?.toInt() ?? 0));
    final _walkIns = (cpData?['totalWalkIns'] as num?)?.toDouble() ?? 0;
    final _bookingsCount = (cpData?['totalBookings'] as num?)?.toDouble() ?? 0;
    final amountLoss = (_walkIns - _bookingsCount) * (603 * 26500);
    final brokerage = amountLoss * 0.02;
    final List<Map<String, dynamic>> _leaderboard = []; // No leaderboard API yet - stays empty until wired
    String _fmtRevenue(dynamic v) {
      final n = (v is num) ? v.toDouble() : (double.tryParse(v?.toString() ?? '0') ?? 0);
      if (n >= 10000000) return '₹' + (n / 10000000).toStringAsFixed(2) + 'Cr';
      if (n >= 100000) return '₹' + (n / 100000).toStringAsFixed(2) + 'L';
      return '₹' + n.toStringAsFixed(0);
    }
    return Scaffold(
      backgroundColor: bg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CPPayoutsScreen()));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bronze,
                boxShadow: [BoxShadow(color: _bronze.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text('PAYOUTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: _bronze)),
          ],
        ),
      ),
      body: Column(children: [
        // Banner
        Container(
          height: 260,
          child: Stack(children: [
            PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _currentBanner = i),
              itemCount: _banners.length,
              itemBuilder: (_, i) => _buildBannerSlide(_banners[i]),
            ),
            // Dots
            Positioned(bottom: 12, left: 0, right: 0,
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentBanner ? 18 : 6, height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentBanner ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3)))))),
            // Top bar
            Positioned(top: 0, left: 0, right: 0,
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  GestureDetector(
                    onTap: () => widget.onOpenDrawer?.call(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 8)]),
                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22))),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                    IconButton(icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false)),
                  ]),
                ]))))
          ])),
        // Scrollable content
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.3))),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
                const SizedBox(width: 6),
                Text('May 2024', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.grey[600])),
              ])),
          ]),
          const SizedBox(height: 12),
          _buildProjectFilterDropdown(isDark),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
            children: [
              _stat('Total Walk-Ins', _displayedWalkIns.toString(), _bronze, isDark),
              _stat('Total Leads', (cpData?['totalLeads'] ?? 0).toString(), _bronze, isDark),
              _stat('Total Bookings', (cpData?['totalBookings'] ?? 0).toString(), Colors.green, isDark),
              _amountLossCard(isDark, amountLoss, brokerage),
              _stat('Active Projects', (cpData?['totalActiveProjects'] ?? 0).toString(), _bronze, isDark),
              _stat('Total Revenue', _fmtRevenue(cpData?['totalRevenue'] ?? 0), Colors.green, isDark),
            ],
          ),
          const SizedBox(height: 16),
          
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('By Walk-ins', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CPLeaderboardScreen()));
                },
                child: Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _bronze)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_leaderboard.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withOpacity(0.15)),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events_outlined, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Leaderboard data not available yet', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            )
          else
            const SizedBox.shrink(), // TODO: render real leaderboard entries via _leader(...) once API is available
          const SizedBox(height: 12),
          Stack(children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF543813).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 24, spreadRadius: 2),
                ]),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFD4AF37), Color(0xFFFFD700)]).createShader(bounds),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('View Full Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ])))),
            // Shine streak
            Positioned(top: 0, left: 24, child: Container(
              width: 80, height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.4), Colors.transparent]),
                borderRadius: BorderRadius.circular(1)))),
          ]),
          const SizedBox(height: 24),
          ]),
        )),
      ]),
    );
  }

  Widget _amountLossCard(bool isDark, double amountLoss, double brokerage) {
    String _fmtLoss(double v) {
      final sign = v < 0 ? '-' : '';
      final abs = v.abs();
      String formatted;
      if (abs >= 10000000) { formatted = (abs / 10000000).toStringAsFixed(2) + 'Cr'; }
      else if (abs >= 100000) { formatted = (abs / 100000).toStringAsFixed(2) + 'L'; }
      else { formatted = abs.toStringAsFixed(0); }
      return sign + '₹' + formatted;
    }
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF6B1A1A), Color(0xFF8B0000), Color(0xFF543813)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B0000).withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4)),
          BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 20, spreadRadius: 1),
        ]),
      child: Stack(children: [
        Positioned(top: 0, left: 0, right: 0, child: Container(height: 1.5,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.5), Colors.transparent])))),
        Padding(padding: const EdgeInsets.all(10),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
              child: const Text('Brokerage Loss', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3))),
            const SizedBox(height: 5),
            Text(_fmtLoss(brokerage), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          ])),
      ]));
  }

  Widget _buildProjectFilterDropdown(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF543813).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: _gold.withOpacity(0.12), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProject,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF3A2509),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          selectedItemBuilder: (context) => _projectOptions
              .map((p) => Row(children: [
                    Icon(Icons.apartment_rounded, size: 16, color: _gold),
                    const SizedBox(width: 8),
                    Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]))
              .toList(),
          items: _projectOptions
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(children: [
                      Icon(Icons.apartment_outlined, size: 16, color: _gold),
                      const SizedBox(width: 8),
                      Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedProject = value);
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE3DDD5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFD4AF37).withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, letterSpacing: 0.2,
            color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF888888))),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(
            fontSize: value.length > 5 ? 13 : 19,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF2A1A05))),
      ]));
  }

  Widget _statHighlight(String label, String value, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.7), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.3,
            color: isDark ? Colors.white38 : Colors.grey[500])),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: value.length > 5 ? 14 : 20,
            fontWeight: FontWeight.w800, color: color)),
      ]));
  }

  Widget _leader(String rank, String name, String tag, String walkins, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4))),
          child: Center(child: Text(rank, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green[500])),
            const SizedBox(width: 4),
            Text(tag, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[500])),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(walkins, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          Text('Walk-ins', style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey[400])),
        ]),
      ]));
  }
}

// ── CP LEADS ──────────────────────────────────────────────────
class CPLeadsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const CPLeadsScreen({super.key, this.onOpenDrawer});
  @override
  State<CPLeadsScreen> createState() => _CPLeadsScreenState();
}

class _CPLeadsScreenState extends State<CPLeadsScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  String _fmtVisitDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso.isEmpty ? '--' : iso;
    }
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return '--';
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, 2)}${'*' * (phone.length - 4)}${phone.substring(phone.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cpData = Provider.of<BookingProvider>(context).cpDashboardData;
    final projectWiseData = (cpData?['projectWiseData'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];

    final visits = <Map<String, String>>[];
    for (final p in projectWiseData) {
      final projectName = (p['projectName'] as String?) ?? '--';
      final customers = (p['walkInCustomers'] as List<dynamic>?) ?? const [];
      for (final c in customers) {
        final m = c as Map<String, dynamic>;
        final rawDate = (m['visitDate'] as String?) ?? '';
        visits.add({
          'name': (m['customerName'] as String?) ?? '--',
          'phone': (m['mobileNo'] as String?) ?? '',
          'project': projectName,
          'rawDate': rawDate,
          'date': _fmtVisitDate(rawDate),
          // 'visitId' is not yet returned by the SFDC cpDashboard API
          // (walkInCustomers only has visitDate/mobileNo/email/customerName) —
          // shows '--' until the backend adds a site visit ID field.
          'visitId': (m['visitId'] as String?) ?? '--',
        });
      }
    }
    visits.sort((a, b) => b['rawDate']!.compareTo(a['rawDate']!));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: _bronze,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => widget.onOpenDrawer?.call()),
        title: const Text('My Visits', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () => _showAddLeadSheet(context)),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
        ],
      ),
      body: visits.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.directions_walk_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No walk-ins yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ]),
            )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visits.length,
        itemBuilder: (_, i) {
          final v = visits[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _bronze.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.directions_walk, color: _bronze, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v['name']!, style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                  Text(_maskPhone(v['phone']!), style: TextStyle(fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey[500])),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _gold.withOpacity(0.3))),
                  child: Text('Visit ID: ${v['visitId']}', style: const TextStyle(
                      color: _bronze, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _leadDetail(Icons.location_city_outlined, v['project']!, isDark),
                const SizedBox(width: 16),
                _leadDetail(Icons.calendar_today_outlined, v['date']!, isDark),
              ]),
              const SizedBox(height: 12),
              _actionBtn(Icons.phone, 'Call', Colors.green,
                  onTap: v['phone']!.isEmpty ? null : () => launchUrl(Uri.parse('tel:${v['phone']}'))),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLeadSheet(context),
        backgroundColor: _bronze,
        icon: const Icon(Icons.directions_walk, color: _gold),
        label: const Text('Log Walk-In', style: TextStyle(color: _gold, fontWeight: FontWeight.w600)),
      ),
    );
  }


  void _showAddLeadSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectCtrl = TextEditingController();
    final clientNameCtrl = TextEditingController();
    final clientNoCtrl = TextEditingController();
    final configCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final cpFirmCtrl = TextEditingController();
    final cpNameCtrl = TextEditingController();
    final smCtrl = TextEditingController();
    String? selectedStatus = 'Hot';
    bool submitting = false;
    String? formError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: _gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.directions_walk, color: _gold, size: 20)),
                const SizedBox(width: 10),
                Text('Log Walk-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              ]),
              const SizedBox(height: 20),
              _formField(projectCtrl, 'Project', 'e.g. Roswalt Zaiden', isDark, icon: Icons.apartment_outlined),
              _formField(clientNameCtrl, 'Client Name', 'Full name', isDark, icon: Icons.person_outline),
              _formField(clientNoCtrl, 'Client No', 'Mobile number', isDark, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
              _formField(configCtrl, 'Configuration', 'e.g. 2BHK / 2+2 Jodi', isDark, icon: Icons.grid_view_outlined),
              _formField(budgetCtrl, 'Budget', 'e.g. Rs. 1.2 Cr', isDark, icon: Icons.currency_rupee_outlined),
              _formField(cpFirmCtrl, 'CP Firm', 'Channel partner firm name', isDark, icon: Icons.business_outlined),
              _formField(cpNameCtrl, 'CP Name', 'Channel partner name', isDark, icon: Icons.badge_outlined),
              _formField(smCtrl, 'SM (Sales Manager)', 'Sales manager name', isDark, icon: Icons.support_agent_outlined),
              const SizedBox(height: 8),
              Text('Lead Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700])),
              const SizedBox(height: 8),
              Row(children: ['Hot', 'Warm', 'Cold'].map((s) {
                final colors = {'Hot': Colors.red, 'Warm': Colors.orange, 'Cold': Colors.blue};
                final isSelected = selectedStatus == s;
                return GestureDetector(
                  onTap: () => setModalState(() => selectedStatus = s),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colors[s]!.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? colors[s]! : Colors.grey[300]!)),
                    child: Text(s, style: TextStyle(
                        color: isSelected ? colors[s]! : Colors.grey,
                        fontWeight: FontWeight.w600))));
              }).toList()),
              if (formError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(formError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                  ])),
              ],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bronze,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: submitting ? null : () async {
                    if (projectCtrl.text.trim().isEmpty ||
                        clientNameCtrl.text.trim().isEmpty ||
                        clientNoCtrl.text.trim().isEmpty) {
                      setModalState(() => formError = 'Project, Client Name and Client No are required.');
                      return;
                    }
                    setModalState(() { submitting = true; formError = null; });
                    final provider = Provider.of<BookingProvider>(context, listen: false);
                    final ok = await provider.submitCPWalkIn(
                      project: projectCtrl.text.trim(),
                      clientName: clientNameCtrl.text.trim(),
                      clientPhone: clientNoCtrl.text.trim(),
                      configuration: configCtrl.text.trim(),
                      budget: budgetCtrl.text.trim(),
                      cpFirm: cpFirmCtrl.text.trim(),
                      cpName: cpNameCtrl.text.trim(),
                      sourcingManager: smCtrl.text.trim(),
                      status: selectedStatus,
                    );
                    if (!context.mounted) return;
                    if (!ok) {
                      setModalState(() {
                        submitting = false;
                        formError = provider.cpWalkInError ?? 'Could not save this walk-in. Please try again.';
                      });
                      return;
                    }
                    Navigator.pop(ctx);
                    provider.refreshCPDashboard();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Walk-in logged!'), backgroundColor: _bronze));
                  },
                  child: submitting
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Submit Walk-In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                )),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _formField(TextEditingController ctrl, String label, String hint, bool isDark,
      {IconData? icon, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700])),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: icon != null ? Icon(icon, color: _gold, size: 18) : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8F1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _gold, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
        ),
      ]),
    );
  }
  Widget _leadDetail(IconData icon, String text, bool isDark) {
    return Row(children: [
      Icon(icon, size: 12, color: Colors.grey[400]),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
    ]);
  }

  Widget _actionBtn(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: enabled ? color : Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: enabled ? color : Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── CP BOOKINGS ───────────────────────────────────────────────
class CPBookingsScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const CPBookingsScreen({super.key, this.onOpenDrawer});
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso.isEmpty ? '--' : iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cpData = Provider.of<BookingProvider>(context).cpDashboardData;
    final projectWiseData = (cpData?['projectWiseData'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];

    final bookings = <Map<String, String>>[];
    for (final p in projectWiseData) {
      final projectName = (p['projectName'] as String?) ?? '--';
      final customers = (p['bookingCustomers'] as List<dynamic>?) ?? const [];
      for (final c in customers) {
        final m = c as Map<String, dynamic>;
        bookings.add({
          'client': (m['customerName'] as String?) ?? '--',
          'project': projectName,
          'unit': (m['unitNo'] as String?) ?? '--',
          'bookingNumber': (m['bookingNumber'] as String?) ?? '--',
          'date': _fmtDate((m['bookingDate'] as String?) ?? ''),
        });
      }
    }
    bookings.sort((a, b) => b['date']!.compareTo(a['date']!));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: _bronze,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => onOpenDrawer?.call()),
        title: const Text('My Bookings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))],
      ),
      body: bookings.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('No bookings yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ]),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (_, i) {
                final b = bookings[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF543813), Color(0xFF3A2509)]),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(b['project']!, style: const TextStyle(color: _gold,
                            fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.4))),
                          child: const Text('Booked', style: TextStyle(
                              color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                      ])),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        Row(children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b['client']!, style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          _bookingDetail('Unit', b['unit']!, isDark),
                          _bookingDetail('Booking No.', b['bookingNumber']!, isDark),
                          _bookingDetail('Date', b['date']!, isDark),
                        ]),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }

  Widget _bookingDetail(String label, String value, bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[500])),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A0A00))),
    ]);
  }
}


// ── CP PROFILE ────────────────────────────────────────────────
class CPProfileScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const CPProfileScreen({super.key, this.onOpenDrawer});
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;

    final bookingProvider = Provider.of<BookingProvider>(context);
    final cpData = bookingProvider.cpDashboardData;
    String field(String key) {
      final v = cpData?[key];
      if (v == null) return '--';
      final s = v.toString().trim();
      return s.isEmpty ? '--' : s;
    }
    final cpName = field('cpName');
    final mahaRera = bookingProvider.mahaRERA ?? '--';

    final details = [
      {'icon': Icons.badge_outlined, 'label': 'PARTNER ID', 'value': field('cpId')},
      {'icon': Icons.phone_outlined, 'label': 'MOBILE NUMBER', 'value': field('Phone')},
      {'icon': Icons.email_outlined, 'label': 'EMAIL ADDRESS', 'value': field('Email')},
      {'icon': Icons.corporate_fare_outlined, 'label': 'COMPANY NAME', 'value': cpName},
      {'icon': Icons.receipt_long_outlined, 'label': 'GST NUMBER', 'value': field('GstNumber')},
      {'icon': Icons.credit_card_outlined, 'label': 'PAN NUMBER', 'value': field('PanNumber')},
      {'icon': Icons.location_on_outlined, 'label': 'REGION', 'value': field('Location')},
      {'icon': Icons.verified_outlined, 'label': 'MAHA RERA NO.', 'value': mahaRera},
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => onOpenDrawer?.call()),
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Profile header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _bronze.withOpacity(0.1),
                      border: Border.all(color: _gold.withOpacity(0.4), width: 2.5),
                      boxShadow: [BoxShadow(color: _bronze.withOpacity(0.2), blurRadius: 12)]),
                    child: const Icon(Icons.person, color: _bronze, size: 48)),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF543813), Color(0xFF3A2509)]),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)]),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Text(cpName == '--' ? 'Channel Partner' : cpName, style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              const SizedBox(height: 4),
              Text('Channel Partner', style: TextStyle(
                  fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[600])),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.35))),
                child: Text(mahaRera, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: _gold, letterSpacing: 1.5))),
            ]),
          ),
          const SizedBox(height: 16),

          // Business info card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text('BUSINESS INFORMATION', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    color: isDark ? Colors.white38 : Colors.grey[500]))),
              const Divider(height: 1),
              ...details.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _bronze.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(d['icon'] as IconData, color: _bronze, size: 20)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d['label'] as String, style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                            color: isDark ? Colors.white38 : Colors.grey[500])),
                        const SizedBox(height: 2),
                        Text(d['value'] as String, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                      ])),
                      if (d['label'] == 'MOBILE NUMBER')
                        Icon(Icons.verified, color: Colors.green[600], size: 18),
                    ])),
                  if (i < details.length - 1) const Divider(height: 1, indent: 70),
                ]);
              }).toList(),
            ]),
          ),
          const SizedBox(height: 20),

          // Sign out button
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.35))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.logout, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                const Text('Sign Out', style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
              ])),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── CP ASSISTANCE (concerned Sourcing Manager) ──────────────────
class CPAssistanceScreen extends StatelessWidget {
  const CPAssistanceScreen({super.key});
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);

  Future<void> _launch(BuildContext context, String? uri, String missingMessage) async {
    if (uri == null || uri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(missingMessage)));
      return;
    }
    final ok = await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $uri')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final cpData = Provider.of<BookingProvider>(context).cpDashboardData;
    final projectWiseData = (cpData?['projectWiseData'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];

    // Group projects by their assigned Sourcing Manager (SFDC: cpPointOfContact).
    final Map<String, Map<String, dynamic>> managers = {};
    for (final p in projectWiseData) {
      final name = (p['cpPointOfContact'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      final entry = managers.putIfAbsent(name, () => {
            'name': name,
            'phone': p['cpPointOfContactPhone'] as String?,
            'email': p['cpPointOfContactEmail'] as String?,
            'projects': <String>[],
          });
      final projectName = (p['projectName'] as String?)?.trim();
      final projects = entry['projects'] as List<String>;
      if (projectName != null && projectName.isNotEmpty && !projects.contains(projectName)) {
        projects.add(projectName);
      }
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Assistance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: managers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.support_agent_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No Sourcing Manager assigned yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ]),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Your concerned Sourcing Manager for each project', style: TextStyle(
                    fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
                const SizedBox(height: 14),
                ...managers.values.map((m) {
                  final phone = m['phone'] as String?;
                  final email = m['email'] as String?;
                  final projects = (m['projects'] as List<String>).join(', ');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _gold.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: _bronze.withOpacity(0.1)),
                          child: const Icon(Icons.person, color: _bronze, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m['name'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                          const SizedBox(height: 2),
                          Text('Sourcing Manager • $projects', style: TextStyle(fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey[600])),
                        ])),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _contactBtn(context, Icons.call, 'Call', Colors.green,
                            phone != null && phone.isNotEmpty ? 'tel:$phone' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: _contactBtn(context, Icons.chat, 'WhatsApp', const Color(0xFF25D366),
                            phone != null && phone.isNotEmpty ? 'https://wa.me/$phone' : null)),
                        const SizedBox(width: 10),
                        Expanded(child: _contactBtn(context, Icons.email_outlined, 'Email', Colors.blue,
                            email != null && email.isNotEmpty ? 'mailto:$email' : null)),
                      ]),
                      if ((phone == null || phone.isEmpty) && (email == null || email.isEmpty)) ...[
                        const SizedBox(height: 10),
                        Text('Contact details not available yet', style: TextStyle(fontSize: 11,
                            color: Colors.orange[700], fontStyle: FontStyle.italic)),
                      ],
                    ]),
                  );
                }),
              ],
            ),
    );
  }

  Widget _contactBtn(BuildContext context, IconData icon, String label, Color color, String? uri) {
    final enabled = uri != null;
    return GestureDetector(
      onTap: () => _launch(context, uri, '$label not available yet'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: enabled ? color : Colors.grey, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: enabled ? color : Colors.grey)),
        ]),
      ),
    );
  }
}
