import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/guided_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/banner_service.dart';
import 'payments_screen.dart';
import 'assistance_screen.dart';
import 'construction_screen.dart';
import 'complaints_screen.dart';
import 'credhomes_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'documents_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const HomeScreen({super.key, this.onOpenDrawer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tour keys
  final _propertyKey = GlobalKey();
  final _quickActionsKey = GlobalKey();
  final _alertsKey = GlobalKey();
  bool _showTour = false;
  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  int _selectedMockBanner = 0;

  // ── ALL AVAILABLE QUICK ACTIONS ──
  final List<Map<String, dynamic>> _allActions = [
    {
      'id': 'payments',
      'icon': Icons.payments_outlined,
      'label': 'Payments',
      'sub': 'Track dues',
      'iconBg': Color(0xFFFFF3E0),
    },
    {
      'id': 'documents',
      'icon': Icons.description_outlined,
      'label': 'Documents',
      'sub': 'View files',
      'iconBg': Color(0xFFE3F2FD),
    },
    {
      'id': 'referrals',
      'icon': Icons.group_add_outlined,
      'label': 'Referrals',
      'sub': 'Invite friends',
      'iconBg': Color(0xFFFCE4EC),
    },
    {
      'id': 'construction',
      'icon': Icons.construction_outlined,
      'label': 'Construction',
      'sub': 'Track progress',
      'iconBg': Color(0xFFE8F5E9),
    },
    {
      'id': 'complaints',
      'icon': Icons.support_agent_outlined,
      'label': 'Complaints',
      'sub': 'Raise issue',
      'iconBg': Color(0xFFFFF3E0),
    },
    {
      'id': 'credhomes',
      'icon': Icons.home_work_outlined,
      'label': 'CredHomes',
      'sub': 'Home loan',
      'iconBg': Color(0xFFE8F5E9),
    },
    {
      'id': 'assistance',
      'icon': Icons.headset_mic_outlined,
      'label': 'Assistance',
      'sub': 'Get help',
      'iconBg': Color(0xFFE3F2FD),
    },
  ];


  List<String> _selectedActionIds = [
    'payments', 'documents', 'referrals'
  ];

  final List<Map<String, dynamic>> _mockBanners = [
    {
      'label': 'Neo City — Gold',
      'image': 'assets/images/banner_zaiden.jpg',
      'gradientColors': <Color>[Color(0xFFD4AF37), Color(0xFF8B6914)],
      'tag': 'GRAND LAUNCH',
      'title': 'Roswalt\nZaiden',
      'subtitle': 'Premium Living, Elevated.',
      'progress': 0.68,
      'progressLabel': '68',
      'accentColor': Color(0xFFFFFFFF),
    },
    {
      'label': 'Neo City — Night',
      'image': 'assets/images/banner_zeya.png',
      'gradientColors': <Color>[Color(0xFF1A1A2E), Color(0xFF16213E)],
      'tag': 'NIGHT LAUNCH',
      'title': 'Roswalt\nZyon',
      'subtitle': 'Luxury After Dark.',
      'progress': 0.68,
      'progressLabel': '68',
      'accentColor': Color(0xFFFFD700),
    },
    {
      'label': 'Sky Heights',
      'image': 'assets/images/banner_ryla.jpg',
      'gradientColors': <Color>[Color(0xFF543813), Color(0xFF3D0000)],
      'tag': 'NEW TOWERS',
      'title': 'Roswalt\nRaya',
      'subtitle': 'Timeless Elegance.',
      'progress': 0.45,
      'progressLabel': '45',
      'accentColor': Color(0xFFFFD700),
    },
    {
      'label': 'Special Offer',
      'image': 'assets/images/banner_construction.jpg',
      'gradientColors': <Color>[Color(0xFF1A3A5C), Color(0xFF0D1F33)],
      'tag': 'SPECIAL OFFER',
      'title': 'Construction\nUpdates',
      'subtitle': 'Progress On Track.',
      'progress': 0.82,
      'progressLabel': '82',
      'accentColor': Color(0xFFFFD700),
    },
  ];

  List<Map<String, dynamic>> _banners = [];

  @override
  void initState() {
    super.initState();
    // Onboarding disabled
    _banners = List.from(_mockBanners);
    _fetchRemoteBanners();
    // Auto-refresh banners every 60 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (mounted) _fetchRemoteBanners();
      return mounted;
    });
    _startAutoScroll();
    _loadSelectedActions();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final provider = Provider.of<BookingProvider>(context, listen: false);
      if (provider.demands.isEmpty && provider.selectedBooking != null) {
        await provider.fetchDemands(provider.selectedBooking!.bookingId);
      }
      if (mounted) _showPaymentReminder();
    });
  }

  Future<void> _loadSelectedActions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('quick_action_ids');
    if (saved != null && saved.length >= 1) {
      setState(() => _selectedActionIds = saved);
    }
  }

  Future<void> _fetchRemoteBanners() async {
    try {
      final booking = Provider.of<BookingProvider>(context, listen: false).selectedBooking;
      final remote = await BannerService.fetchBanners(project: booking?.projectName);
      if (remote.isNotEmpty && mounted) {
        setState(() => _banners = remote.map((b) => b.toSlideMap()).toList());
      }
    } catch (e) { debugPrint('Banner error'); }
  }

  Future<void> _saveSelectedActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'quick_action_ids', _selectedActionIds);
  }

  void _showCustomizeSheet(bool isDark, Color cardBg) {
    List<String> tempSelected = List.from(_selectedActionIds);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text('Customise Actions',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF3A2509))),
                      Text('Select up to 3 to show',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500])),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        '${tempSelected.length}/3 selected',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryMaroon)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: _allActions.map((a) {
                    final isSelected =
                        tempSelected.contains(a['id']);
                    return GestureDetector(
                      onTap: () {
                        setSheet(() {
                          if (isSelected) {
                            tempSelected.remove(a['id']);
                          } else if (tempSelected.length < 3) {
                            tempSelected.add(a['id'] as String);
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text(
                                  'Max 3 actions allowed'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryMaroon
                              : isDark
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF6F1E9),
                          borderRadius:
                              BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.goldLight
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryMaroon
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(
                                            0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(a['icon'] as IconData,
                                size: 24,
                                color: isSelected
                                    ? AppTheme.goldLight
                                    : isDark
                                        ? Colors.white54
                                        : AppTheme.primaryMaroon),
                            const SizedBox(height: 6),
                            Text(a['label'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : isDark
                                            ? Colors.white70
                                            : const Color(
                                                0xFF3A2509))),
                            if (isSelected)
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 3),
                                padding:
                                    const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.goldLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    size: 8,
                                    color: AppTheme.primaryMaroon),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: Colors.grey[500])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryMaroon,
                            Color(0xFF543813),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryMaroon
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: tempSelected.isEmpty
                            ? null
                            : () {
                                setState(() => _selectedActionIds =
                                    List.from(tempSelected));
                                _saveSelectedActions();
                                Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                        ),
                        child: const Text('Apply',
                            style: TextStyle(
                                color: const Color(0xFFF0F0F0),
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _bannerController.hasClients) {
        final next = (_currentBanner + 1) % _banners.length;
        _bannerController.animateToPage(next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut);
        _startAutoScroll();
      }
    });
  }



  void _showPropertyDetails(BuildContext context, bool isDark) {
    final booking = Provider.of<BookingProvider>(context, listen: false).selectedBooking;
    if (booking == null) return;

    final details = [
      {'label': 'Booking Number', 'value': booking.bookingId, 'icon': Icons.confirmation_number_outlined},
      {'label': 'Customer Name', 'value': booking.clientName, 'icon': Icons.person_outlined},
      {'label': 'Phone', 'value': booking.phone.isNotEmpty ? '+91 ' + booking.phone : '--', 'icon': Icons.phone_outlined},
      {'label': 'Project', 'value': booking.projectName, 'icon': Icons.location_city_outlined},
      {'label': 'Unit Number', 'value': booking.unitNumber, 'icon': Icons.apartment_outlined},
      {'label': 'Tower', 'value': booking.towerName, 'icon': Icons.business_outlined},
      {'label': 'Floor', 'value': booking.floor != '--' ? booking.floor + ' Floor' : '--', 'icon': Icons.layers_outlined},
      {'label': 'BHK Type', 'value': booking.bhkType, 'icon': Icons.villa_outlined},
      {'label': 'Carpet Area', 'value': booking.carpetArea, 'icon': Icons.square_foot_outlined},
      {'label': 'Car Parking', 'value': booking.carParking, 'icon': Icons.local_parking_outlined},
      {'label': 'Flat Type', 'value': booking.flatType, 'icon': Icons.home_outlined},
      {'label': 'Booking Stage', 'value': booking.bookingStage, 'icon': Icons.assignment_outlined},
      {'label': 'Registration Status', 'value': booking.registrationStatus, 'icon': Icons.verified_outlined},
      {'label': 'Registration Date', 'value': booking.registrationDate, 'icon': Icons.calendar_today_outlined},
      {'label': 'Booking Date', 'value': booking.bookingDate != '--' ? booking.bookingDate : '--', 'icon': Icons.event_outlined},
      {'label': 'Possession Date', 'value': booking.possessionDate != '--' ? booking.possessionDate : '--', 'icon': Icons.key_outlined},
      {'label': 'Total Amount', 'value': booking.bookingAmount != '--' ? booking.bookingAmount : '--', 'icon': Icons.currency_rupee_outlined},
      {'label': 'Status', 'value': booking.status, 'icon': Icons.info_outline},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.home_work_outlined,
                        color: AppTheme.primaryMaroon, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Property Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                        Text(booking.projectName,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: details.length,
                separatorBuilder: (_, __) => Divider(
                    color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
                itemBuilder: (_, i) {
                  final d = details[i];
                  final value = d['value'] as String;
                  final isEmpty = value == '--' || value.isEmpty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isEmpty
                                ? Colors.grey.withOpacity(0.1)
                                : AppTheme.primaryMaroon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                          child: Icon(d['icon'] as IconData,
                              color: isEmpty ? Colors.grey[400] : AppTheme.primaryMaroon,
                              size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d['label'] as String,
                                  style: TextStyle(fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 3),
                              Text(value,
                                  style: TextStyle(fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isEmpty
                                          ? Colors.grey[400]
                                          : (isDark ? Colors.white : const Color(0xFF1A1A1A)))),
                            ],
                          ),
                        ),
                        if (!isEmpty)
                          Icon(Icons.check_circle_outline,
                              color: Colors.green[400], size: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
                Text('Refer a Friend', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryMaroon)),
                const SizedBox(height: 4),
                Text('Fill in your friend details to refer them', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 24),
                Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: InputDecoration(hintText: 'Enter full name', filled: true, fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryMaroon))),
                const SizedBox(height: 16),
                Text('Mobile Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(hintText: '+91 98765 43210', filled: true, fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryMaroon))),
                const SizedBox(height: 16),
                Text('Preferred Project', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(value: selectedProject, hint: const Text('Select a project'), decoration: InputDecoration(filled: true, fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.primaryMaroon)), items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (v) => setModalState(() => selectedProject = v)),
                const SizedBox(height: 16),
                Text('Preferred Configuration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(value: selectedConfig, hint: const Text('Select configuration'), decoration: InputDecoration(filled: true, fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: Icon(Icons.apartment_outlined, color: AppTheme.primaryMaroon)), items: configs.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setModalState(() => selectedConfig = v)),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { final booking = Provider.of<BookingProvider>(context, listen: false).selectedBooking; try { await http.post(Uri.parse('https://api.roswaltsmartcue.com/api/referrals'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': nameController.text.trim(), 'phone': phoneController.text.trim(), 'project': selectedProject ?? '', 'config': selectedConfig ?? '', 'referredBy': booking?.clientName ?? '', 'bookingId': booking?.bookingId ?? '', 'submittedAt': DateTime.now().toIso8601String()})); } catch (_) {} Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Referral submitted!'), backgroundColor: AppTheme.primaryMaroon, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))); }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('SUBMIT REFERRAL', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateAction(String id) {
    switch (id) {
      case 'payments':
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const PaymentsScreen()));
        break;
      case 'documents':
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const DocumentsScreen()));
        break;
      case 'construction':
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const ConstructionScreen()));
        break;
      case 'complaints':
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const ComplaintsScreen()));
        break;
      case 'credhomes':
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const CredHomesScreen()));
        break;
      case 'assistance':
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const AssistanceScreen()));
        break;
        break;
      case 'referrals':
        _showReferralForm(context, Theme.of(context).brightness == Brightness.dark);
        break;
      default:
        break;
    }
  }
  void _showPaymentReminder() {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final booking = provider.selectedBooking;
    final demands = provider.demands;
    // Find next due or upcoming milestone
    final nextDue = demands.firstWhere(
      (d) => d['status'] == 'due' || d['status'] == 'upcoming',
      orElse: () => <String, dynamic>{},
    );
    final milestoneName = nextDue.isNotEmpty ? nextDue['name'] as String : '--';
    final milestoneDate = nextDue.isNotEmpty ? nextDue['date'] as String : '--';
    final milestoneAmt = nextDue.isNotEmpty ? nextDue['amount'] as String : '0';
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBF5), Color(0xFFFFF3DC), Color(0xFFFDE8B8)],
            ),
            boxShadow: [BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.35),
                blurRadius: 40, spreadRadius: 2, offset: const Offset(0, 10))],
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: -30, right: -20,
                child: Container(width: 140, height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFFD4AF37).withOpacity(0.2), Colors.transparent])))),
              Positioned(bottom: -20, left: -20,
                child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF543813).withOpacity(0.08), Colors.transparent])))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bell icon with glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 80, height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [
                              const Color(0xFFD4AF37).withOpacity(0.3),
                              Colors.transparent]))),
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFD4AF37), Color(0xFF8B6914)]),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.5),
                                blurRadius: 16, spreadRadius: 2)]),
                          child: const Icon(Icons.notifications_active_rounded,
                              color: Colors.white, size: 30),
                        ),
                        // Shine
                        Positioned(top: 10, left: 20,
                          child: Container(width: 20, height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(colors: [
                                Colors.white.withOpacity(0.6), Colors.transparent])))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF543813), Color(0xFF8B6914), Color(0xFF543813)],
                      ).createShader(bounds),
                      child: const Text('Payment Reminder',
                          style: TextStyle(color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFB8860B)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            blurRadius: 8, offset: const Offset(0, 2))]),
                      child: const Text('Milestone Payment Due',
                          style: TextStyle(color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1),
                              blurRadius: 12, offset: const Offset(0, 4)),
                          BoxShadow(color: Colors.white.withOpacity(0.8),
                              blurRadius: 4, offset: const Offset(-2, -2)),
                        ]),
                      child: Column(
                        children: [
                          _reminderRow2('🏗️  Milestone', milestoneName),
                          Divider(color: const Color(0xFFD4AF37).withOpacity(0.25), height: 18),
                          _reminderRow2('📅  Due Date', milestoneDate),
                          Divider(color: const Color(0xFFD4AF37).withOpacity(0.25), height: 18),
                          _reminderRow2('🏠  Unit No', booking?.unitNumber ?? '--'),
                          Divider(color: const Color(0xFFD4AF37).withOpacity(0.25), height: 18),
                          _reminderRow2('🔖  Booking ID', booking?.bookingId ?? '--'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6B4A1E), Color(0xFF3A2509)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFF543813).withOpacity(0.4),
                            blurRadius: 12, offset: const Offset(0, 4))]),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PaymentsScreen()));
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('View Payment Details',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Remind Me Later',
                          style: TextStyle(
                              color: const Color(0xFF543813).withOpacity(0.4),
                              fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final demands = Provider.of<BookingProvider>(context, listen: false).demands;
    final upcoming = demands.where((d) => d['status'] == 'upcoming' || d['status'] == 'due').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.notifications_active_rounded, color: AppTheme.primaryMaroon, size: 22),
                const SizedBox(width: 8),
                Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.primaryMaroon)),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('${upcoming.length} pending', style: TextStyle(fontSize: 11, color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold))),
              ]),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: upcoming.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No pending payments', style: TextStyle(color: Colors.grey[400])),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: upcoming.length,
                    itemBuilder: (ctx, i) {
                      final d = upcoming[i];
                      final isDue = d['status'] == 'due';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F4F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDue ? Colors.orange.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Container(width: 40, height: 40,
                            decoration: BoxDecoration(color: isDue ? Colors.orange.withOpacity(0.1) : AppTheme.primaryMaroon.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(isDue ? Icons.access_time : Icons.calendar_today_outlined, color: isDue ? Colors.orange : AppTheme.primaryMaroon, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d['name'] ?? '--', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF3A2509))),
                            const SizedBox(height: 3),
                            Text('Due: ${d['date']}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ])),
                          Text('₹${d['amount']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDue ? Colors.orange : AppTheme.primaryMaroon)),
                        ]),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderRow2(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6B4A1E), fontSize: 13)),
        Text(value, style: const TextStyle(
            color: Color(0xFF3A2509), fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }









  Widget _reminderRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: const Color(0xFFF0F0F0).withOpacity(0.6),
                fontSize: 12)),
        Text(value,
            style: TextStyle(color: const Color(0xFFF0F0F0),
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showBannerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Banner',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Choose a banner for your home screen',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: _mockBanners.length,
                  itemBuilder: (ctx, i) {
                    final mock = _mockBanners[i];
                    final isSelected = _selectedMockBanner == i;
                    final colors =
                        mock['gradientColors'] as List<Color>;
                    return GestureDetector(
                      onTap: () => setModalState(
                          () => _selectedMockBanner = i),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: colors,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.goldLight
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.goldLight
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                  )
                                ]
                              : null,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            if (isSelected)
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  padding:
                                      const EdgeInsets.all(4),
                                  decoration:
                                      const BoxDecoration(
                                    color: const Color(0xFFF0F0F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: AppTheme
                                          .primaryMaroon),
                                ),
                              )
                            else
                              const SizedBox(),
                            Text(mock['label'],
                                style: TextStyle(color: const Color(0xFFF0F0F0),
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: Colors.grey[500])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _banners[0] = Map.from(
                              _mockBanners[_selectedMockBanner]);
                          _currentBanner = 0;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content:
                              const Text('Banner updated!'),
                          backgroundColor:
                              AppTheme.primaryMaroon,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMaroon,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: const Text('Apply Banner',
                          style: TextStyle(
                              color: const Color(0xFFF0F0F0),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }


  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = true; // Tour disabled
    // _showTour = true; // disabled
  }



  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? const Color(0xFF121212) : AppTheme.creamBg;
    final cardBg =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // ── BOOKING PROVIDER DATA ──
    final booking =
        Provider.of<BookingProvider>(context).bookingData;
    final clientName = booking?.clientName ?? 'Welcome';
    final bookingId =
        booking?.bookingId ?? 'ROSWALT00123';
    final projectName =
        booking?.projectName ?? 'Roswalt At Neo City';
    final unitNumber = booking?.unitNumber ?? 'A-1203';
    final tower = booking?.tower ?? 'Tower A';
    final bhkType = booking?.bhkType ?? '2 BHK';
    final bookingDate =
        booking?.bookingDate ?? '10 Apr 2025';
    final bookingAmount =
        booking?.bookingAmount ?? '₹5,00,000';
    final possessionDate =
        booking?.possessionDate ?? 'Dec 2027';

    // Active actions based on selection
    final activeActions = _allActions
        .where((a) =>
            _selectedActionIds.contains(a['id']))
        .toList();

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── BANNER ──
          Container(
            height: 310,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB8860B)
                      .withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 310,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _bannerController,
                      onPageChanged: (i) => setState(
                          () => _currentBanner = i),
                      itemCount: _banners.length,
                      itemBuilder: (ctx, i) =>
                          _buildBannerSlide(_banners[i]),
                    ),
                  ),
                  // Header
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: widget.onOpenDrawer,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F0F0)
                                          .withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(
                                              12),
                                    ),
                                    child: const Icon(
                                        Icons.menu,
                                        color: const Color(0xFFF0F0F0),
                                        size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(width: 160, child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Welcome, $clientName',
                                        style: TextStyle(color: const Color(0xFFF0F0F0),
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 14)),
                                    Text(bookingId,
                                        style: TextStyle(
                                            color: const Color(0xFFF0F0F0)
                                                .withOpacity(0.7),
                                            fontSize: 10)),
                                  ],
                                )),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => _showNotifications(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.notifications_outlined, color: Color(0xFFF0F0F0), size: 20),
                              ),
                            ),


                          ],
                        ),
                      ),
                    ),
                  ),
                  // Change banner removed

                  // Dots
                  Positioned(
                    bottom: 14, left: 0, right: 90,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: List.generate(
                        _banners.length,
                        (di) => AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 300),
                          margin: const EdgeInsets.only(
                              right: 5),
                          width:
                              _currentBanner == di ? 18 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _currentBanner == di
                                ? Colors.white
                                : Colors.white38,
                            borderRadius:
                                BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── CONTENT ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Quick Actions Header
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quick Actions', key: _quickActionsKey,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.primaryMaroon)),
                      GestureDetector(
                        onTap: () => _showCustomizeSheet(
                            isDark, cardBg),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMaroon
                                .withOpacity(0.08),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryMaroon
                                    .withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune,
                                  size: 12,
                                  color: isDark
                                      ? AppTheme.goldLight
                                      : AppTheme.primaryMaroon),
                              const SizedBox(width: 4),
                              Text('Customise',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppTheme.goldLight
                                          : AppTheme
                                              .primaryMaroon)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Actions Row
                  Row(
                    children: activeActions.map((a) {
                      final isLast = activeActions.last == a;
                      final isReferral = a['id'] == 'referrals';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 10),
                          child: isReferral
                            ? _buildReferralCard(isDark, () => _navigateAction('referrals'))
                            : _buildActionCard(
                              a['icon'] as IconData,
                              a['label'] as String,
                              a['sub'] as String,
                              a['iconBg'] as Color,
                              isDark,
                              cardBg,
                              () => _navigateAction(a['id'] as String),
                            ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // My Property
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: AppTheme.goldLight
                              .withOpacity(0.3),
                          width: 1.5),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(4, 8),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFFB8860B)
                                    .withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 3,
                                offset: const Offset(6, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFFF0F0F0)
                                    .withOpacity(0.95),
                                blurRadius: 6,
                                spreadRadius: -2,
                                offset: const Offset(-4, -4),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('My Property',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme
                                            .primaryMaroon)),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text('Confirmed',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(18),
                           child: Stack(
                             children: [
                               Container(
                                 height: 140,
                                 width: double.infinity,
                                 decoration: const BoxDecoration(
                                   gradient: LinearGradient(
                                     begin: Alignment.topLeft,
                                     end: Alignment.bottomRight,
                                     colors: [Color(0xFF543813), Color(0xFF8B6914), Color(0xFF543813), Color(0xFF3A2509)],
                                     stops: [0.0, 0.35, 0.65, 1.0],
                                   ),
                                 ),
                               ),
                               Positioned.fill(
                                 child: Shimmer.fromColors(
                                   baseColor: Colors.transparent,
                                   highlightColor: const Color(0xFFF0F0F0).withOpacity(0.12),
                                   period: const Duration(seconds: 2),
                                   child: Container(color: const Color(0xFFF0F0F0).withOpacity(0.05)),
                                 ),
                               ),
                               Positioned(right: -15, top: -15, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.goldAccent.withOpacity(0.15)))),
                               Positioned(left: -20, bottom: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.goldAccent.withOpacity(0.08)))),
                               SizedBox(
                                 height: 140,
                                 child: Stack(
                                   children: [
                                     Positioned(
                                       top: 10, left: 10, right: 10,
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                             decoration: BoxDecoration(color: const Color(0xFFF0F0F0).withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                                             child: Text(projectName, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)),
                                           ),
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                             decoration: BoxDecoration(color: Colors.green.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                                             child: const Row(children: [Icon(Icons.check_circle, size: 9, color: const Color(0xFFF0F0F0)), SizedBox(width: 3), Text('Confirmed', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFF0F0F0)))]),
                                           ),
                                         ],
                                       ),
                                     ),
                                     Center(
                                       child: Column(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           Icon(Icons.apartment, color: const Color(0xFFF0F0F0).withOpacity(0.9), size: 36),
                                           const SizedBox(height: 4),
                                           Text("Unit $unitNumber", style: TextStyle(color: const Color(0xFFF0F0F0).withOpacity(0.95), fontSize: 15, fontWeight: FontWeight.bold)),
                                           Text("$tower • $bhkType", style: TextStyle(color: const Color(0xFFF0F0F0).withOpacity(0.6), fontSize: 10)),
                                         ],
                                       ),
                                     ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(height: 10),
                         Row(
                           children: [
                             Expanded(child: _insetDetail('BOOKING DATE', bookingDate, isDark)),
                             const SizedBox(width: 8),
                             Expanded(child: _insetDetail('AMOUNT', bookingAmount, isDark)),
                             const SizedBox(width: 8),
                             Expanded(child: _insetDetail('POSSESSION', possessionDate, isDark)),
                           ],
                         ),
                         const SizedBox(height: 12),
                         Container(
                           width: double.infinity,
                           decoration: BoxDecoration(
                             gradient: isDark
                                 ? const LinearGradient(colors: [Color(0xFFE8E8F0), Color(0xFFBDBDCC)])
                                 : const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)]),
                             borderRadius: BorderRadius.circular(14),
                           ),
                           child: ElevatedButton.icon(
                             onPressed: () => _showPropertyDetails(context, isDark),
                             icon: Icon(Icons.receipt_long_outlined, size: 16,
                                 color: isDark ? const Color(0xFF1A1A2E) : Colors.white),
                             label: Text('View Full Details',
                                 style: TextStyle(
                                     color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                                     fontWeight: FontWeight.bold,
                                     fontSize: 13)),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: Colors.transparent,
                               shadowColor: Colors.transparent,
                               padding: const EdgeInsets.symmetric(vertical: 13),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                             ),
                           ),
                         ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Updates & Alerts
                  Row(
                    children: [
                      Icon(Icons.bolt,
                          color: isDark
                              ? AppTheme.goldLight
                              : AppTheme.primaryMaroon,
                          size: 20),
                      const SizedBox(width: 4),
                      Text('Updates & Alerts', key: _alertsKey,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.primaryMaroon)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dynamic alerts from provider
                  ...((booking?.alerts ??
                          [
                            {
                              'title': 'Milestone Reached',
                              'desc':
                                  'Tower A slab casting complete.',
                              'time': '2h ago'
                            },
                            {
                              'title': 'Payment Reminder',
                              'desc':
                                  '\ due on \.',
                              'time': 'Yesterday'
                            },
                            {
                              'title': 'Tax Receipt Ready',
                              'desc':
                                  'Q1 maintenance tax receipt available.',
                              'time': 'May 12'
                            },
                          ])
                      .map((a) => _buildAlertTile(
                          a, isDark, cardBg))
                      .toList()),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBannerSlide(Map<String, dynamic> b) {
    final colors = b['gradientColors'] as List<Color>;
    final accent = b['accentColor'] as Color;
    final remoteImage = b['remoteImage'] as String?;
    final image = b['image'] as String?;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Remote image from API or local asset
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
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          if (remoteImage != null || image != null)
          if (image != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
            ),
          // Decorative circles
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0F0F0).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -40, bottom: -40,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(b['title'],
                              style: TextStyle(color: const Color(0xFFF0F0F0),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2)),
                          const SizedBox(height: 3),
                          Text(b['subtitle'],
                              style: TextStyle(
                                  color: const Color(0xFFF0F0F0)
                                      .withOpacity(0.7),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(b['progressLabel'],
                            style: TextStyle(
                                color: accent,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                height: 1.0)),
                        Text('%',
                            style: TextStyle(
                                color: accent.withOpacity(0.8),
                                fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 5),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: b['progress'] as double,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFEEEEEE)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF0F0F0).withOpacity(0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
    String subtitle,
    Color iconBg,
    bool isDark,
    Color cardBg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(4, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFFB8860B)
                        .withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(5, 7),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF0F0F0).withOpacity(0.95),
                    blurRadius: 5,
                    spreadRadius: -2,
                    offset: const Offset(-3, -3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: isDark
                      ? AppTheme.goldLight
                      : AppTheme.primaryMaroon,
                  size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF3A2509))),
            const SizedBox(height: 1),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 9,
                    color: isDark
                        ? Colors.white38
                        : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF543813), Color(0xFF8B6914), Color(0xFFD4AF37)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: const Color(0xFF543813).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            // Shimmer overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Shimmer.fromColors(
                  baseColor: Colors.transparent,
                  highlightColor: Colors.white.withOpacity(0.2),
                  period: const Duration(seconds: 2),
                  child: Container(color: Colors.white.withOpacity(0.05)),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group_add_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 8),
                const Text('Referrals',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                const Text('Invite & Earn',
                  style: TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _insetDetail(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF6F1E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[500],
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF3A2509))),
        ],
      ),
    );
  }

  Widget _buildAlertTile(
      Map<String, dynamic> alert, bool isDark, Color cardBg) {
    final isPayment = alert['title'] == 'Payment Reminder';
    final borderColor = isPayment
        ? const Color(0xFFD4AF37)
        : alert.containsKey('borderColor')
            ? alert['borderColor'] as Color
            : Colors.blueGrey;
    return GestureDetector(
      onTap: isPayment ? () => _showPaymentReminder() : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border(
              left: BorderSide(color: borderColor, width: 4)),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(3, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: borderColor.withOpacity(0.12),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(4, 5),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF0F0F0).withOpacity(0.9),
                    blurRadius: 5,
                    spreadRadius: -2,
                    offset: const Offset(-2, -2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPayment
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                size: 18,
                color: borderColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(alert['title'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF3A2509))),
                      ),
                      Row(
                        children: [
                          Text(alert['time'],
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[500])),
                          if (isPayment) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37)
                                    .withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(
                                            0xFFD4AF37)
                                        .withOpacity(0.4)),
                              ),
                              child: const Text('View',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight:
                                          FontWeight.bold,
                                      color:
                                          Color(0xFFB8860B))),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(alert['desc'],
                      style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





