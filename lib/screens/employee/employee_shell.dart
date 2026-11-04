import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/otp_email_service.dart';
import '../../services/banner_service.dart';
import '../../providers/employee_attendance_provider.dart';
import '../../providers/notification_provider.dart';
import '../client/notifications_screen.dart';
import '../auth/login_screen.dart';
import 'employee_dashboard_screen.dart';
import 'employee_attendance_flow.dart';
import 'employee_team_field_screen.dart';
import 'employee_tagged_leads_screen.dart';
import 'employee_personal_details_screen.dart';
import 'employee_bank_details_screen.dart';
import 'employee_documents_screen.dart';
import 'employee_training_videos_screen.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

/// Frosted "liquid glass" container: blurred backdrop + translucent tint +
/// hairline border, used for the floating top-bar controls and search bar.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  const _GlassPanel({required this.child, required this.borderRadius, required this.isDark, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.white).withOpacity(isDark ? 0.08 : 0.55),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.12 : 0.6)),
            boxShadow: [BoxShadow(color: _bronze.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ),
    );
  }
}

const _projectOptions = [
  'All Projects',
  'Roswalt Zaiden',
  'Roswalt Ryla',
  'Roswalt Raya',
  'Roswalt Zeya',
  'Roswalt Zyon',
];

const Map<String, List<Color>> _projectTileColors = {
  'Roswalt Zaiden': [Color(0xFFD4AF37), Color(0xFF9C7A14)],
  'Roswalt Ryla': [Color(0xFFC98E5A), Color(0xFF8F5A2C)],
  'Roswalt Raya': [Color(0xFFA8875F), Color(0xFF6B5948)],
  'Roswalt Zyon': [Color(0xFFE0A17A), Color(0xFFA8613A)],
};

// Employee collateral for each project lives in a shared Google Drive
// folder (no CMS/API backend for this exists) — the app embeds the
// folder's public "embeddedfolderview" so employees can browse/open files.
const Map<String, String> _employeeCollateralFolderIds = {
  'Roswalt Zaiden': '133NcfSZ1sHbzqtCzh_O1KcSIhxJh1JVE',
  'Roswalt Ryla': '16mGte_eq5A4HyHA-yRc7myUYW4Y8XhSr',
  'Roswalt Raya': '1RL0xvs8ssK49dB10Op1T9uzwXMSKKUW-',
  'Roswalt Zyon': '1xBrALHU0j8jCL9VBTrUXGTEaqJA7hCUQ',
};

String _driveEmbedUrl(String folderId) => 'https://drive.google.com/embeddedfolderview?id=$folderId#grid';
String _driveOpenUrl(String folderId) => 'https://drive.google.com/drive/folders/$folderId';

/// Employee module shell: drawer + bottom nav across Dashboard, Collateral,
/// Smart Band and Profile. No employee collateral/CMS, attendance, or
/// band-hardware backend exists yet, so every screen here runs on
/// placeholder data — swap in real endpoints once they exist, the
/// UI/navigation is already wired.
class EmployeeShell extends StatefulWidget {
  final String employeeName;
  final String? employeeId;
  final String? designation;
  const EmployeeShell({super.key, required this.employeeName, this.employeeId, this.designation});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  String _selectedProject = 'All Projects';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<EmployeeAttendanceProvider>(context, listen: false)
          .load(employeeName: widget.employeeName, employeeId: widget.employeeId);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        Provider.of<NotificationProvider>(context, listen: false).syncFromFirestore(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employeeId = widget.employeeId;

    final screens = [
      EmployeeDashboardScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        employeeName: widget.employeeName,
        onNavigate: (i) => setState(() => _currentIndex = i),
      ),
      EmployeeCollateralScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        selectedProject: _selectedProject,
        onProjectChanged: (p) => setState(() => _selectedProject = p),
      ),
      EmployeeSmartBandScreen(onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
      EmployeeProfileScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        employeeName: widget.employeeName,
        employeeId: employeeId,
        designation: widget.designation,
        onNavigate: (i) => setState(() => _currentIndex = i),
      ),
    ];

    return PopScope(
      // Prevents the system back gesture/button from popping this route
      // straight back to the login/verification screen (which looked
      // indistinguishable from being logged out). Back instead returns to
      // the Dashboard tab first, matching standard bottom-nav app behavior;
      // signing out is only ever done explicitly via the drawer.
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _currentIndex = 0);
      },
      child: Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: isDark
                    ? LinearGradient(colors: [const Color(0xFF1A0A00).withOpacity(0.92), const Color(0xFF1A0A00).withOpacity(0.86)])
                    : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.86), _cream.withOpacity(0.72)]),
                border: Border.all(color: Colors.white.withOpacity(0.6)),
              ),
              child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF8A6516), Color(0xFF5C4C3E)]),
            ),
            child: Stack(children: [
              Positioned(right: -60, top: -60, child: Container(width: 200, height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [_gold.withOpacity(0.35), _gold.withOpacity(0)])))),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 60, height: 60, padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFFF5D97A), _gold, Color(0xFF8A6516)]),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle,
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF6B4F10), Color(0xFF3F342B)])),
                      alignment: Alignment.center,
                      child: Text(_initials(widget.employeeName),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.employeeName, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 3),
                    Text((widget.designation?.isNotEmpty ?? false) ? widget.designation! : 'Employee',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ])),
                ]),
                if (employeeId != null && employeeId.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.35))),
                    child: Text('ID · $employeeId', style: const TextStyle(color: Color(0xFFF5D97A), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ],
              ]),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
            _drawerItem(context, Icons.dashboard_outlined, 'Dashboard', () { setState(() => _currentIndex = 0); Navigator.pop(context); }, isDark, active: _currentIndex == 0),
            _drawerItem(context, Icons.campaign_outlined, 'Collateral', () { setState(() => _currentIndex = 1); Navigator.pop(context); }, isDark, active: _currentIndex == 1),
            _drawerItem(context, Icons.play_circle_outline, 'Training Videos', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeTrainingVideosScreen()));
            }, isDark),
            _drawerItem(context, Icons.groups_outlined, 'My Team', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeTeamFieldScreen()));
            }, isDark),
            _drawerItem(context, Icons.local_offer_outlined, 'My Tagged Leads', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeTaggedLeadsScreen()));
            }, isDark),
            _drawerItem(context, Icons.help_outline, 'Help & Support', () {
              Navigator.pop(context);
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Help & Support'),
                content: const Text('For assistance, contact HR at hr@roswalt.com or call the office front desk.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ));
            }, isDark),
            Divider(color: isDark ? Colors.white12 : _bronze.withOpacity(0.15)),
            _drawerItem(context, Icons.person_outlined, 'Profile', () { setState(() => _currentIndex = 3); Navigator.pop(context); }, isDark, active: _currentIndex == 3),
          ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
            child: GestureDetector(
              onTap: () async {
                Provider.of<EmployeeAttendanceProvider>(context, listen: false).reset();
                await OtpEmailService.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.logout, size: 19, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Text('Sign out', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.red[700])),
                ]),
              ),
            ),
          ),
        ]),
              ),
            ),
          ),
        ),
          ),
        ),
      extendBody: true,
      body: screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1A0A00) : Colors.white).withOpacity(isDark ? 0.45 : 0.55),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.85)),
                boxShadow: [BoxShadow(color: _bronze.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 10))]),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _navItem(1, Icons.campaign_outlined, Icons.campaign, 'Collateral'),
                _navItem(3, Icons.person_outlined, Icons.person, 'Profile'),
              ]),
            ),
          ),
        ),
        ),
      ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, VoidCallback onTap, bool isDark, {Color? color, bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? _gold.withOpacity(isDark ? 0.15 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.white.withOpacity(isDark ? 0.2 : 0.6) : Colors.transparent, width: 1),
        ),
        child: Row(children: [
          Icon(icon, color: color ?? (isDark ? const Color(0xFFF5F5F5) : _bronze), size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color ?? (isDark ? const Color(0xFFF5F5F5) : _bronze),
              fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          if (active) ...[
            const Spacer(),
            Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: _gold)),
          ],
        ]),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _currentIndex == index;
    final inactiveColor = isDark ? Colors.white60 : _bronze.withOpacity(0.55);
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [_gold, Color(0xFF9C7A14)]) : null,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isActive ? [BoxShadow(color: _gold.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))] : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isActive ? activeIcon : icon, color: isActive ? Colors.white : inactiveColor, size: 21),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? Colors.white : inactiveColor)),
        ]),
      ),
    );
  }
}

// ── HOME / COLLATERAL ─────────────────────────────────────────
class EmployeeCollateralScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final String selectedProject;
  final ValueChanged<String>? onProjectChanged;
  const EmployeeCollateralScreen({super.key, this.onOpenDrawer, required this.selectedProject, this.onProjectChanged});

  @override
  State<EmployeeCollateralScreen> createState() => _EmployeeCollateralScreenState();
}

class _EmployeeCollateralScreenState extends State<EmployeeCollateralScreen> {
  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  List<Map<String, dynamic>> _banners = [];
  Timer? _bannerTimer;

  late final WebViewController _driveController;
  bool _driveLoading = true;
  String? _driveError;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients && _banners.isNotEmpty) {
        final next = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
    _driveController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() { _driveLoading = true; _driveError = null; });
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _driveLoading = false);
        },
        onWebResourceError: (error) {
          if (mounted) setState(() { _driveLoading = false; _driveError = error.description; });
        },
      ));
    _loadDriveFolder(widget.selectedProject);
  }

  void _loadDriveFolder(String project) {
    if (project == 'All Projects') {
      setState(() { _driveLoading = false; _driveError = null; });
      return;
    }
    final folderId = _employeeCollateralFolderIds[project];
    if (folderId == null) {
      setState(() { _driveLoading = false; _driveError = 'No collateral folder configured for this project.'; });
      return;
    }
    setState(() { _driveLoading = true; _driveError = null; });
    _driveController.loadRequest(Uri.parse(_driveEmbedUrl(folderId)));
  }

  @override
  void didUpdateWidget(covariant EmployeeCollateralScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedProject != widget.selectedProject) {
      _loadDriveFolder(widget.selectedProject);
      _fetchBanners();
    }
  }

  Future<void> _fetchBanners() async {
    try {
      final project = widget.selectedProject == 'All Projects' ? null : widget.selectedProject;
      final remote = await BannerService.fetchBanners(project: project);
      if (mounted) setState(() => _banners = remote.map((b) => b.toSlideMap()).toList());
    } catch (e) {
      debugPrint('Employee banner error: $e');
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildBannerSlide(Map<String, dynamic> b) {
    final colors = b['gradientColors'] as List<Color>;
    final remoteImage = b['remoteImage'] as String?;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors)),
      child: Stack(children: [
        if (remoteImage != null && remoteImage.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: remoteImage,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: _bronze),
              errorWidget: (_, __, ___) => Container(color: _bronze),
            ),
          ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.6)]),
            ),
          ),
        ),
        Positioned(right: -20, top: -20, child: Container(width: 130, height: 130,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
        Positioned(
          bottom: 18, left: 18, right: 18,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text((b['tag'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
            const SizedBox(height: 8),
            Text((b['title'] ?? '').toString(), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            if ((b['subtitle'] ?? '').toString().isNotEmpty)
              Text((b['subtitle'] ?? '').toString(), style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final showingAll = widget.selectedProject == 'All Projects';
    final folderId = _employeeCollateralFolderIds[widget.selectedProject];

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        if (!isDark) ...[
          Positioned(left: -90, top: 340, child: _champagneOrb(const Color(0xFFD4AF37), 300, 0.45)),
          Positioned(right: -110, top: 560, child: _champagneOrb(const Color(0xFFE8A77A), 320, 0.35)),
        ],
        Column(children: [
        // Full-bleed hero banner (same size/treatment as Client & CP)
        SizedBox(
          height: 260,
          child: Stack(children: [
            _banners.isEmpty
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)])),
                    child: Stack(children: [
                      Positioned(right: -30, top: -30, child: Container(width: 180, height: 180,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
                      Positioned(
                        bottom: 40, left: 20, right: 20,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.campaign, color: _gold, size: 26),
                          const SizedBox(height: 8),
                          const Text('New collateral drops every week', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(widget.selectedProject, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        ]),
                      ),
                    ]),
                  )
                : PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (i) => setState(() => _currentBanner = i),
                    itemCount: _banners.length,
                    itemBuilder: (_, i) => _buildBannerSlide(_banners[i]),
                  ),
            if (_banners.isNotEmpty)
              Positioned(bottom: 12, left: 0, right: 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_banners.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentBanner ? 18 : 6, height: 6,
                      decoration: BoxDecoration(
                          color: i == _currentBanner ? _gold : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3)))))),
            Positioned(top: 0, left: 0, right: 0,
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  GestureDetector(
                    onTap: widget.onOpenDrawer,
                    child: _GlassPanel(
                      isDark: isDark,
                      borderRadius: BorderRadius.circular(10),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    child: Stack(clipBehavior: Clip.none, children: [
                      _GlassPanel(
                        isDark: isDark,
                        borderRadius: BorderRadius.circular(10),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                      ),
                      if (Provider.of<NotificationProvider>(context).unreadCount > 0)
                        Positioned(right: -2, top: -2, child: Container(
                          width: 9, height: 9,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
                    ]),
                  ),
                ]),
              )),
            ),
          ]),
        ),
        // Header: title + project selector (not scrollable — the Drive
        // embed below takes the remaining space directly).
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Employee Collateral', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              if (!showingAll)
                IconButton(
                  icon: Icon(Icons.open_in_new, color: isDark ? Colors.white70 : _bronze, size: 20),
                  tooltip: 'Open in Drive',
                  onPressed: folderId == null ? null : () => launchUrl(Uri.parse(_driveOpenUrl(folderId)), mode: LaunchMode.externalApplication),
                ),
            ]),
            const SizedBox(height: 8),
            _projectDropdown(isDark),
          ]),
        ),
        // Drive folder for the selected project, or a picker across all of
        // them when "All Projects" is selected.
        Expanded(
          child: showingAll
              ? ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: _employeeCollateralFolderIds.keys.map((p) {
                    final tile = _projectTileColors[p] ?? const [Color(0xFFA8875F), Color(0xFF6B5948)];
                    return GestureDetector(
                      onTap: () => widget.onProjectChanged?.call(p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: isDark ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Colors.white.withOpacity(0.72), Colors.white.withOpacity(0.32)]),
                          color: isDark ? cardBg : null,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: isDark ? _gold.withOpacity(0.15) : Colors.white.withOpacity(0.85)),
                          boxShadow: isDark ? null : [BoxShadow(color: const Color(0xFF6B5948).withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: Row(children: [
                          Container(width: 50, height: 50,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tile),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                                boxShadow: [BoxShadow(color: tile.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: const Icon(Icons.folder_outlined, color: Colors.white, size: 22)),
                          const SizedBox(width: 14),
                          Expanded(child: Text(p, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF2B2520)))),
                          Container(width: 32, height: 32,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                color: isDark ? Colors.white10 : Colors.white.withOpacity(0.7),
                                border: Border.all(color: isDark ? Colors.white24 : Colors.white)),
                            child: Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.white54 : const Color(0xFF6B4F10))),
                        ]),
                      ),
                    );
                  }).toList(),
                )
              : Stack(children: [
                  WebViewWidget(controller: _driveController),
                  if (_driveLoading) const Center(child: CircularProgressIndicator(color: _bronze)),
                  if (_driveError != null)
                    Container(
                      color: bg,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline, size: 44, color: Colors.red[300]),
                          const SizedBox(height: 12),
                          Text(_driveError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400], fontSize: 13)),
                          const SizedBox(height: 12),
                          TextButton(onPressed: () => _loadDriveFolder(widget.selectedProject), child: const Text('Retry')),
                        ]),
                      ),
                    ),
                ]),
        ),
      ]),
      ]),
    );
  }

  Widget _champagneOrb(Color color, double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(opacity), color.withOpacity(0)])),
    );
  }

  Widget _projectDropdown(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.5), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.selectedProject,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF3A2509),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          selectedItemBuilder: (context) => _projectOptions.map((p) => Row(children: [
                const Icon(Icons.apartment_rounded, size: 16, color: _gold),
                const SizedBox(width: 8),
                Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ])).toList(),
          items: _projectOptions.map((p) => DropdownMenuItem(value: p, child: Row(children: [
                const Icon(Icons.apartment_outlined, size: 16, color: _gold),
                const SizedBox(width: 8),
                Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ]))).toList(),
          onChanged: (value) {
            if (value != null) widget.onProjectChanged?.call(value);
          },
        ),
      ),
    );
  }

}

// ── PROFILE ────────────────────────────────────────────────────
class EmployeeProfileScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final String employeeName;
  final String? employeeId;
  final String? designation;
  final ValueChanged<int>? onNavigate;
  const EmployeeProfileScreen({super.key, this.onOpenDrawer, required this.employeeName, this.employeeId, this.designation, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        if (!isDark) ...[
          Positioned(left: -90, top: 180, child: _champagneOrb(const Color(0xFFD4AF37), 320, 0.5)),
          Positioned(right: -120, top: 420, child: _champagneOrb(const Color(0xFFE8A77A), 340, 0.4)),
        ],
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: onOpenDrawer,
                  child: Container(width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.white.withOpacity(0.85)),
                        boxShadow: isDark ? null : [BoxShadow(color: const Color(0xFF6B5948).withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 8))]),
                    child: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF2B2520), size: 22)),
                ),
                const SizedBox(width: 14),
                Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2B2520))),
              ]),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFFB0862A), Color(0xFF6B5948)]),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.45)),
                  boxShadow: [BoxShadow(color: const Color(0xFF6B5948).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
                ),
                child: Column(children: [
                  Container(width: 84, height: 84,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFFF5D97A), Color(0xFFD4AF37), Color(0xFF8A6516)]),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14)]),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle,
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [Color(0xFF8A6516), Color(0xFF5C4C3E)])),
                      child: const Icon(Icons.badge_outlined, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(employeeName, textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  if (designation != null && designation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(designation!, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
                  ],
                  if (employeeId != null && employeeId!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.35))),
                        child: Text(employeeId!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFFF5D97A)))),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              Expanded(child: ListView(children: [
                _row(context, Icons.person_outline, 'Personal Details', isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeePersonalDetailsScreen()))),
                _row(context, Icons.description_outlined, 'My Documents', isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeDocumentsScreen()))),
                _row(context, Icons.account_balance_outlined, 'Bank Details', isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeBankDetailsScreen()))),
                _row(context, Icons.play_circle_outline, 'Training Videos', isDark,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeTrainingVideosScreen()))),
                const SizedBox(height: 8),
                _row(context, Icons.logout, 'Sign Out', isDark, color: Colors.red, onTap: () async {
                  Provider.of<EmployeeAttendanceProvider>(context, listen: false).reset();
                  await OtpEmailService.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                }),
              ])),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _champagneOrb(Color color, double size, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(opacity), color.withOpacity(0)])),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, bool isDark, {Color? color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coming soon.'), backgroundColor: _bronze)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isDark ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.72), Colors.white.withOpacity(0.32)]),
          color: isDark ? const Color(0xFF1E1E1E) : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? _gold.withOpacity(0.15) : Colors.white.withOpacity(0.85)),
          boxShadow: isDark ? null : [BoxShadow(color: const Color(0xFF6B5948).withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color ?? _bronze),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? (isDark ? Colors.white : const Color(0xFF1A0A00)))),
          const Spacer(),
          Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey[400]),
        ]),
      ),
    );
  }
}
