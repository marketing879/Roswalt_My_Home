import 'dart:convert';
import 'dart:io';
import 'privacy_policy_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/booking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_tour.dart';
import '../../widgets/onboarding_overlay.dart';
import 'home_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/complaint_numbers_sheet.dart';
import 'documents_screen.dart';
import 'payments_screen.dart';
import 'assistance_screen.dart';
import 'construction_screen.dart';
import 'notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credhomes_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;
  String? _profilePhotoPath;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePhotoPath = prefs.getString('profile_photo_path');
    });
  }

  Future<void> _changeProfilePhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Change Profile Photo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryMaroon
                                .withOpacity(0.3)),
                      ),
                      child: const Column(children: [
                        Icon(Icons.camera_alt_outlined,
                            color: AppTheme.primaryMaroon, size: 32),
                        SizedBox(height: 8),
                        Text('Camera',
                            style: TextStyle(
                                color: AppTheme.primaryMaroon,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryMaroon
                                .withOpacity(0.3)),
                      ),
                      child: const Column(children: [
                        Icon(Icons.photo_library_outlined,
                            color: AppTheme.primaryMaroon, size: 32),
                        SizedBox(height: 8),
                        Text('Gallery',
                            style: TextStyle(
                                color: AppTheme.primaryMaroon,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            if (_profilePhotoPath != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _removeProfilePhoto();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline,
                          color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text('Remove Photo',
                          style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_photo_path', image.path);
        setState(() => _profilePhotoPath = image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Profile photo updated!'),
            backgroundColor: AppTheme.primaryMaroon,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _removeProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_photo_path');
    setState(() => _profilePhotoPath = null);
  }

  Widget _buildProfileAvatar({double size = 56}) {
    if (_profilePhotoPath != null) {
      if (kIsWeb) {
        return ClipOval(
          child: Image.network(_profilePhotoPath!,
              width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => _defaultAvatar(size: size)),
        );
      } else {
        return ClipOval(
          child: Image.file(File(_profilePhotoPath!),
              width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => _defaultAvatar(size: size)),
        );
      }
    }
    return _defaultAvatar(size: size);
  }

  Widget _defaultAvatar({double size = 56}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: AppTheme.goldAccent.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person,
          color: AppTheme.goldAccent, size: size * 0.5),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon,
      String label, bool isDark) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryMaroon
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF6F1E9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryMaroon.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF0F0F0).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(-2, -2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : const Color(0xFFD4AF37).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF0F0F0).withOpacity(0.7),
                    blurRadius: 4,
                    offset: const Offset(-1, -1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => isActive
                  ? const LinearGradient(
                      colors: [Color(0xFFD4A017), Color(0xFFFFD700), Color(0xFFB8860B)],
                    ).createShader(bounds)
                  : const LinearGradient(
                      colors: [Color(0xFF888888), Color(0xFFAAAAAA), Color(0xFF666666)],
                    ).createShader(bounds),
              child: Icon(
                isActive ? activeIcon : icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => isActive
                  ? const LinearGradient(
                      colors: [Color(0xFFD4A017), Color(0xFFFFD700), Color(0xFFB8860B)],
                    ).createShader(bounds)
                  : const LinearGradient(
                      colors: [Color(0xFF888888), Color(0xFFAAAAAA), Color(0xFF666666)],
                    ).createShader(bounds),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    final screens = [
      HomeScreen(
          onOpenDrawer: () =>
              _scaffoldKey.currentState?.openDrawer()),
      const DocumentsScreen(),
      const PaymentsScreen(),
      const AssistanceScreen(),
    ];
    return Scaffold(


      key: _scaffoldKey,
      drawer: _buildDrawer(isDark, themeProvider),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, -6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined, Icons.home,
                'Home', isDark),
            _navItem(1, Icons.folder_outlined, Icons.folder,
                'Documents', isDark),
            _navItem(2, Icons.payment_outlined, Icons.payment,
                'Payments', isDark),
            _navItem(3, Icons.headset_mic_outlined,
                Icons.headset_mic, 'Assistance', isDark),
          ],
        ),
      ),
    );
  }

  // Returns the correct logo asset path based on project name
  String _getProjectLogoAsset(String? projectName) {
    if (projectName == null) return 'logos/ryla.png';
    final p = projectName.toLowerCase();
    if (p.contains('zaiden')) return 'logos/zaiden.png';
    if (p.contains('raya')) return 'logos/raya.png';
    if (p.contains('zeya')) return 'logos/zeya.png';
    if (p.contains('ryla')) return 'logos/ryla.png';
    return 'logos/ryla.png';
  }

  Widget _buildDrawer(bool isDark, ThemeProvider themeProvider) {
    final bg = isDark ? const Color(0xFF121212) : AppTheme.creamBg;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final booking =
        Provider.of<BookingProvider>(context).bookingData;
    final clientName = booking?.clientName ?? 'Client';
    final bookingId = booking?.bookingId ?? 'ROSWALT00123';
    final logoAsset = _getProjectLogoAsset(booking?.projectName);

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          children: [
            // ── PROJECT LOGO HEADER ──
            SizedBox(
              width: double.infinity,
              height: 165,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video background
                  ClipRect(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: _DrawerVideoBackground(),
                    ),
                  ),
                  // Dark overlay for contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                  // Content on top
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          logoAsset,
                          height: 55,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.home_work_rounded,
                            size: 56,
                            color: AppTheme.goldAccent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          booking?.projectName ?? 'Roswalt',
                          style: TextStyle(
                            color: const Color(0xFFF0F0F0).withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(clientName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF0F0F0), fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.goldAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            bookingId,
                            style: const TextStyle(
                              color: AppTheme.goldAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── MENU ITEMS ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),

                  _drawerSection('MY ACCOUNT', isDark),
                  _drawerItem(Icons.home_work_outlined,
                      'My Property', isDark, cardBg,
                      () => _showBookingSwitcher(context, isDark)),
                  _drawerItem(Icons.receipt_long_outlined,
                      'Payment History', isDark, cardBg,
                      () { Navigator.pop(context); setState(() => _currentIndex = 2); }),
                  _drawerItem(Icons.description_outlined,
                      'My Documents', isDark, cardBg,
                      () { Navigator.pop(context); setState(() => _currentIndex = 1); }),

                  const SizedBox(height: 16),
                  _drawerSection('SERVICES', isDark),
                  _drawerItem(
                      Icons.construction_outlined,
                      'Construction Updates',
                      isDark, cardBg, () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ConstructionScreen()));
                  }),
                  _drawerItem(
                      Icons.phone_outlined,
                      'Complaints & Redressal',
                      isDark, cardBg, () {
                    Navigator.pop(context);
                    showComplaintNumbersSheet(context);
                  }),
                  _drawerItem(Icons.people_outlined,
                      'Refer a Friend', isDark, cardBg,
                      () { Navigator.pop(context); _showReferralForm(context, isDark); }),
                  _drawerItem(
                      Icons.home_work_outlined,
                      'CredHomes', isDark, cardBg, () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CredHomesScreen()));
                  }),

                  const SizedBox(height: 16),
                  _drawerSection('SETTINGS', isDark),

                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow:
                          AppTheme.clayCardShadow(isDark: isDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Icon(
                              isDark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              color: AppTheme.goldAccent,
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Dark Mode',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF3A2509))),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (_) =>
                                themeProvider.toggleTheme(),
                            activeColor: const Color(0xFFF0F0F0),
                            activeTrackColor:
                                AppTheme.primaryMaroon,
                            inactiveThumbColor: Colors.grey[600],
                            inactiveTrackColor: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _drawerItem(Icons.notifications_outlined,
                      'Notifications', isDark, cardBg,
                      () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      }),
                  _drawerItem(Icons.privacy_tip_outlined,
                      'Privacy Policy', isDark, cardBg,
                      () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())); }),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Provider.of<BookingProvider>(context, listen: false).clearSession();
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: isDark ? const LinearGradient(colors: [Color(0xFF808080), Color(0xFFB0B0B0)]) : const LinearGradient(colors: [Color(0xFF0A0A2E), Color(0xFF1A1A5E)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: isDark ? Colors.grey.withOpacity(0.3) : const Color(0xFF0A0A2E).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: isDark ? Colors.white : const Color(0xFFD4AF37), size: 20),
                          const SizedBox(width: 8),
                          Text('Logout',
                              style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialIcon('assets/images/facebook.png', () => launchUrl(Uri.parse('https://www.facebook.com/p/Roswalt-Realty-61557042066769'), mode: LaunchMode.externalApplication)),
                      const SizedBox(width: 16),
                      _socialIcon('assets/images/instagram.png', () => launchUrl(Uri.parse('https://www.instagram.com/roswaltrealty_/'), mode: LaunchMode.externalApplication)),
                      const SizedBox(width: 16),
                      _socialIcon('assets/images/linkedin.png', () => launchUrl(Uri.parse('https://www.linkedin.com/company/28707255/'), mode: LaunchMode.externalApplication)),
                      const SizedBox(width: 16),
                      _socialIcon('assets/images/youtube.png', () => launchUrl(Uri.parse('https://www.youtube.com/channel/UCE5zUCQ5KCAf9LzLJYDWIeg'), mode: LaunchMode.externalApplication)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 24),
                  Text(
                    'Roswalt My Home v1.0.0\n© 2026 Roswalt Realty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF808080)
                            : Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: isDark
                  ? const Color(0xFF808080)
                  : const Color(0xFF808080))),
    );
  }

  void _showReferralForm(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedProject;
    String? selectedConfig;
    final projects = ['Roswalt Zaiden', 'Roswalt Ryla', 'Roswalt Raya', 'Roswalt Zeya', 'Roswalt Zyon'];
    final configs = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK+'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Refer a Friend',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryMaroon)),
                const SizedBox(height: 4),
                Text('Fill in your friend details to refer them',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 24),
                // Name
                Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter full name',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryMaroon),
                  ),
                ),
                const SizedBox(height: 16),
                // Phone
                Text('Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+91 98765 43210',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryMaroon),
                  ),
                ),
                const SizedBox(height: 16),
                // Project dropdown
                Text('Preferred Project', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedProject,
                  hint: const Text('Select a project'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.primaryMaroon),
                  ),
                  items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setModalState(() => selectedProject = v),
                ),
                const SizedBox(height: 16),
                // Config dropdown
                Text('Preferred Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedConfig,
                  hint: const Text('Select configuration'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.apartment_outlined, color: AppTheme.primaryMaroon),
                  ),
                  items: configs.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => selectedConfig = v),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = Provider.of<BookingProvider>(context, listen: false);
                      final booking = provider.selectedBooking;
                      try { await http.post(Uri.parse('https://api.roswaltsmartcue.com/api/referrals'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'project': selectedProject ?? '', 'config': selectedConfig ?? '', 'referredBy': booking?.clientName ?? '', 'bookingId': booking?.bookingId ?? '', 'submittedAt': DateTime.now().toIso8601String()})); } catch (_) {}
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Referral submitted!'), backgroundColor: AppTheme.primaryMaroon, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('SUBMIT REFERRAL', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingSwitcher(BuildContext context, bool isDark) {
    Navigator.pop(context);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final bookings = provider.allBookings;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Booking Switcher',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            child: Container(
              width: 280,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Bookings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryMaroon)),
                  const SizedBox(height: 8),
                  Text('${bookings.length} booking(s) found',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (_, i) {
                        final b = bookings[i];
                        final isSelected = provider.selectedBooking?.bookingId == b.bookingId;
                        final isApproved = b.status.toLowerCase() == 'approved';
                        return GestureDetector(
                          onTap: () { provider.selectBooking(b); Navigator.pop(ctx); },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryMaroon
                                : isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.goldAccent : Colors.transparent,
                                width: 1.5),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.home_work_outlined,
                                  color: isSelected ? AppTheme.goldAccent : Colors.grey[500],
                                  size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.bookingId,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87))),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: b.customerType == 'Buyer'
                                                ? const Color(0xFF8B0000).withOpacity(0.1)
                                                : const Color(0xFF543813).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(b.customerType,
                                              style: TextStyle(
                                                fontSize: 8, fontWeight: FontWeight.bold,
                                                color: b.customerType == 'Buyer'
                                                  ? const Color(0xFF8B0000)
                                                  : const Color(0xFF543813))),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(b.projectName,
                                        style: TextStyle(fontSize: 11,
                                          color: isSelected ? Colors.white70 : Colors.grey[500])),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isApproved ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6)),
                                        child: Text(b.status,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                                            color: isApproved ? Colors.green : Colors.orange)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _socialIcon(String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(6),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label,
      bool isDark, Color cardBg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.clayCardShadow(isDark: isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: AppTheme.goldAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF3A2509))),
            ),
            Icon(Icons.chevron_right,
                color: isDark
                    ? const Color(0xFF808080)
                    : Colors.grey[400],
                size: 18),
          ],
        ),
      ),
    );
  }
}
// ── Drawer video background widget ──────────────────────────────────────────
class _DrawerVideoBackground extends StatefulWidget {
  @override
  State<_DrawerVideoBackground> createState() =>
      _DrawerVideoBackgroundState();
}

class _DrawerVideoBackgroundState
    extends State<_DrawerVideoBackground> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
        'assets/videos/drawer_bg.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container(color: const Color(0xFF0A0A2E));
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
