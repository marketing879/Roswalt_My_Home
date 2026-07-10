import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credhomes_screen.dart';
import '../../widgets/complaint_numbers_sheet.dart';
class AssistanceScreen extends StatefulWidget {
  const AssistanceScreen({super.key});
  @override
  State<AssistanceScreen> createState() =>
      _AssistanceScreenState();
}

class _AssistanceScreenState
    extends State<AssistanceScreen> {
  final List<Map<String, dynamic>> _myRequests = [];

  void _showRaiseRequestSheet() {
    String? selectedType;
    final descController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Raise a Request',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                  "We'll get back to you within 24 hours",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500])),
              const SizedBox(height: 24),
              const Text('REQUEST TYPE',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Payment',
                  'Document',
                  'Service',
                  'Construction',
                  'Other'
                ]
                    .map((type) => GestureDetector(
                          onTap: () => setModalState(
                              () => selectedType = type),
                          child: Container(
                            padding: const EdgeInsets
                                .symmetric(
                                horizontal: 14,
                                vertical: 8),
                            decoration: BoxDecoration(
                              color: selectedType == type
                                  ? AppTheme.primaryMaroon
                                  : Colors.grey[100],
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: selectedType == type
                                    ? AppTheme.primaryMaroon
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(type,
                                style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        selectedType == type
                                            ? Colors.white
                                            : Colors
                                                .grey[700],
                                    fontWeight:
                                        FontWeight.w500)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('DESCRIPTION',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: descController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText:
                        'Describe your request in detail...',
                    hintStyle: TextStyle(
                        color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryMaroon,
                          width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(
                      content: const Text(
                          'Request submitted successfully!'),
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
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Request',
                      style: TextStyle(
                          color: const Color(0xFFF0F0F0),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? const Color(0xFF121212) : AppTheme.creamBg;
    final cardBg =
        isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final canPop = Navigator.canPop(context);

    final actions = [
      {
        'icon': Icons.phone_outlined,
        'label': 'Contact CRM',
        'sub': 'Call / Chat',
        'color1': const Color(0xFF2196F3),
        'color2': const Color(0xFF1565C0),
        'iconBg': const Color(0xFFE3F2FD),
        'onTap': () => _showCRMNumbers(context, isDark),
      },
        {
        'icon': Icons.home_work_outlined,
        'label': 'CredHomes',
        'sub': 'Home Loan',
        'color1': const Color(0xFF4CAF50),
        'color2': const Color(0xFF2E7D32),
        'iconBg': const Color(0xFFE8F5E9),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CredHomesScreen())),
      },
      {

        'icon': Icons.people_outline,
        'label': 'Referral',
        'sub': 'Refer & Earn',
        'color1': const Color(0xFFFF9800),
        'color2': const Color(0xFFE65100),
        'iconBg': const Color(0xFFFFF3E0),
        'onTap': () => _showReferralForm(context, isDark),
      },
    ];
    // ── BACK BUTTON APPBAR (only when pushed) ──
    return Scaffold(
      backgroundColor: bg,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg,
                  ),
                  child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: isDark
                          ? Colors.white
                          : AppTheme.primaryMaroon),
                ),
              ),
              title: Text('Assistance',
                  style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppTheme.primaryMaroon,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── HEADER (only when no appbar) ──
              if (!canPop) ...[
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('Assistance',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme
                                        .primaryMaroon)),
                        Text(
                            'How can we help you today?',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[500])),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius:
                            BorderRadius.circular(14),
                        boxShadow: AppTheme.clayCardShadow(
                            isDark: isDark),
                      ),
                      child: Icon(
                          Icons.notifications_outlined,
                          size: 22,
                          color: isDark
                              ? Colors.white
                              : AppTheme.primaryMaroon),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ── SUPPORT BANNER ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF543813),
                      Color(0xFF543813),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF543813)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent
                            .withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.support_agent,
                          color: AppTheme.goldAccent,
                          size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text("We're here to help you",
                              style: TextStyle(
                                  color: const Color(0xFFF0F0F0),
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                              'Mon-Sat 9AM-7PM | Wed 11AM-7PM',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── QUICK ACTIONS ──
              Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white
                          : AppTheme.primaryMaroon)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.7,
                children: actions.map((a) {
                  final color1 = a['color1'] as Color;
                  final color2 = a['color2'] as Color;
                  final iconBg = a['iconBg'] as Color;
                  final onTap =
                      a['onTap'] as VoidCallback;
                  return GestureDetector(
                    onTap: onTap,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius:
                            BorderRadius.circular(24),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset:
                                      const Offset(5, 8),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: color1
                                      .withOpacity(0.25),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                  offset:
                                      const Offset(6, 8),
                                ),
                                BoxShadow(
                                  color: color2
                                      .withOpacity(0.1),
                                  blurRadius: 10,
                                  offset:
                                      const Offset(3, 4),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFF0F0F0)
                                      .withOpacity(0.95),
                                  blurRadius: 6,
                                  spreadRadius: -2,
                                  offset: const Offset(
                                      -4, -4),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? color1
                                        .withOpacity(0.15)
                                    : iconBg,
                                borderRadius:
                                    BorderRadius.circular(
                                        12),
                                boxShadow: [
                                  BoxShadow(
                                    color: color1
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset:
                                        const Offset(2, 3),
                                ),
                              ],
                            ),
                              child: Icon(
                                  a['icon'] as IconData,
                                  color: color1,
                                  size: 18),
                            ),
                            const SizedBox(height: 6),
                            Text(a['label'] as String,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(
                                            0xFF3A2509))),
                            const SizedBox(height: 2),
                            Text(a['sub'] as String,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors
                                            .grey[500])),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── COMPLAINTS & REDRESSAL ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF543813),
                      Color(0xFF543813),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF543813)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showComplaintNumbersSheet(context),
                    borderRadius:
                        BorderRadius.circular(20),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0)
                                  .withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.phone,
                                color: const Color(0xFFF0F0F0),
                                size: 24),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Complaints & Redressal',
                                  style: TextStyle(
                                      color: const Color(0xFFF0F0F0),
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold)),
                              Text(
                                  'Tap to raise a complaint',
                                  style: TextStyle(
                                      color: const Color(0xFFF0F0F0)
                                          .withOpacity(0.7),
                                      fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding:
                                const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0)
                                  .withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(
                                Icons.arrow_forward_ios,
                                color: const Color(0xFFF0F0F0),
                                size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── MY REQUESTS ──
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Requests',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppTheme.primaryMaroon)),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.goldAccent
                                .withOpacity(0.3)),
                      ),
                      child: const Text('View All',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  AppTheme.goldAccent)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._myRequests
                  .map((req) => _requestCard(
                      req, isDark, cardBg))
                  .toList(),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> req,
      bool isDark, Color cardBg) {
    final isResolved = req['status'] == 'resolved';
    final statusColor = isResolved
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF9800);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border(
            left:
                BorderSide(color: statusColor, width: 4)),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(4, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: statusColor.withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(5, 7),
                ),
                BoxShadow(
                  color: const Color(0xFFF0F0F0).withOpacity(0.9),
                  blurRadius: 6,
                  spreadRadius: -2,
                  offset: const Offset(-3, -3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isResolved
                  ? Icons.check_circle_outline
                  : Icons.access_time,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(req['title'],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF3A2509))),
                const SizedBox(height: 2),
                Text('Request ${req['id']}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1),
                ),
                child: Text(
                  isResolved
                      ? 'Resolved'
                      : 'In Progress',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(req['time'],
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? Colors.white38
                          : Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  void _showCRMNumbers(BuildContext context, bool isDark) {
    final numbers = [
      {'name': 'CRM Manager', 'number': '+917977496818', 'role': 'Roswalt Zyon'},
      {'name': 'CRM Manager', 'number': '+919142114400', 'role': 'Roswalt Zeya'},
      {'name': 'CRM Manager', 'number': '+918108536493', 'role': 'Roswalt Zaiden'},
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2C1A0E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
          Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3))),
              child: const Icon(Icons.support_agent_rounded, color: Color(0xFFD4AF37), size: 26)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Contact CRM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF5F5F5))),
              Text("Tap to call directly", style: TextStyle(fontSize: 12, color: const Color(0xFFF5F5F5).withOpacity(0.45))),
            ]),
          ]),
          const SizedBox(height: 20),
          ...numbers.map((n) => GestureDetector(
            onTap: () { Navigator.pop(ctx); launchUrl(Uri.parse('tel:' + (n['number'] as String))); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: const Color(0xFF543813), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.phone_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n['name']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3A2509))),
                  Text(n['role']!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 2),
                  Text(n['number']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF543813))),
                ])),
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF543813).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.call_rounded, color: Color(0xFF543813), size: 20)),
              ]),
            ),
          )).toList(),
        ]),
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
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
                  final booking = Provider.of<BookingProvider>(context, listen: false).selectedBooking;
                  try {
                    final res = await http.post(Uri.parse('https://api.roswaltsmartcue.com/api/referrals'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'project': selectedProject ?? '',
                        'config': selectedConfig ?? '',
                        'referredBy': booking?.clientName ?? '',
                        'bookingId': booking?.bookingId ?? '',
                        'submittedAt': DateTime.now().toIso8601String(),
                      }));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Referral submitted!'), backgroundColor: AppTheme.primaryMaroon, behavior: SnackBarBehavior.floating));
                  } catch (e) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral submitted!'), backgroundColor: AppTheme.primaryMaroon, behavior: SnackBarBehavior.floating));
                  }
                }, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('SUBMIT REFERRAL', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w600)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
