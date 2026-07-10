
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/booking_provider.dart';
import '../auth/booking_lookup_screen.dart';

class TenantHomeScreen extends StatelessWidget {
  const TenantHomeScreen({super.key});
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);
  static const _dark = Color(0xFF1A0A00);

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context).selectedBooking;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : _cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: _bronze,
            leading: const SizedBox(),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)]),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ROSWALT REALTY',
                            style: TextStyle(color: Colors.white60,
                                fontSize: 9, letterSpacing: 2)),
                        Text('MY HOME',
                            style: GoogleFonts.playfairDisplay(
                                color: _gold, fontSize: 16,
                                fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const BookingLookupScreen()),
                        (r) => false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Row(children: [
                          Icon(Icons.logout, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text('Logout', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _welcomeCard(booking, isDark),
                  const SizedBox(height: 16),
                  _homeUpgradeCard(isDark),
                  const SizedBox(height: 16),
                  _flatEntitlementCard(isDark),
                  const SizedBox(height: 16),
                  _constructionCard(isDark),
                  const SizedBox(height: 16),
                  _quickActionsSection(context, isDark),
                  const SizedBox(height: 16),
                  _announcementsSection(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeCard(booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _bronze.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome Back', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
                Text(booking?.clientName ?? 'Tenant',
                    style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : _dark)),
                Text(booking?.projectName ?? 'Roswalt Zaiden',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[500])),
                const SizedBox(height: 12),
                Row(children: [
                  _chip('Tenant ID', 'TN-50234', isDark),
                  const SizedBox(width: 8),
                  _chip('CRM', 'Aziz Shaikh', isDark),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3))),
                    child: const Row(children: [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 4),
                      Text('Active Tenant', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  _chip('Possession', booking?.possessionDate ?? 'Dec 2026', isDark),
                ]),
              ],
            ),
          ),
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1), shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.3))),
            child: const Icon(Icons.person, color: _gold, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bronze.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _bronze.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey[500])),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white : _bronze)),
      ]),
    );
  }

  Widget _homeUpgradeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF543813), Color(0xFF3A2509)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _bronze.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.upgrade_rounded, color: _gold, size: 18),
          SizedBox(width: 8),
          Text('YOUR HOME UPGRADE', style: TextStyle(color: _gold, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('EXISTING HOME', style: TextStyle(color: Colors.white60, fontSize: 9, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('1 BHK', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('380 SQ FT', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          )),
          Container(width: 36, height: 36, margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: _gold.withOpacity(0.2), shape: BoxShape.circle,
                border: Border.all(color: _gold.withOpacity(0.5))),
            child: const Icon(Icons.arrow_forward, color: _gold, size: 18)),
          Expanded(child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NEW ROSWALT HOME', style: TextStyle(color: _gold.withOpacity(0.8), fontSize: 9, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('2 BHK', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('500 SQ FT', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ]),
          )),
        ]),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: _gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withOpacity(0.3))),
          child: const Center(child: Text('+120 SQ FT BENEFIT',
              style: TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _feat(Icons.local_parking_outlined, 'Parking Included'),

          _feat(Icons.layers_outlined, 'Higher Floor'),

          _feat(Icons.crop_free_outlined, 'Premium Layout'),

        ]),
      ]),
    );
  }

  Widget _feat(IconData icon, String label) {
    return Column(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white70, size: 18)),
      const SizedBox(height: 4),
      Text(label, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 9, height: 1.3)),
    ]);
  }

  Widget _flatEntitlementCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FLAT ENTITLEMENT SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : _bronze, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Existing Flat', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
            const SizedBox(height: 4),
            Text('Wing A - 12', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : _dark)),
          ])),
          const Icon(Icons.arrow_forward, color: _gold, size: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('New Flat', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
            const SizedBox(height: 4),
            Text('Wing B - 502', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : _dark)),
          ])),
        ]),
      ]),
    );
  }

  Widget _constructionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONSTRUCTION PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : _bronze, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Text('68%', style: GoogleFonts.playfairDisplay(fontSize: 36,
              fontWeight: FontWeight.bold, color: Colors.green[600])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Current Stage', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
            Text('Residential Slab 14', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _dark)),
            Text('Last Update: 15 Jun 2026', style: TextStyle(fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey[500])),
          ])),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: 0.68, minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!)),
        ),
      ]),
    );
  }

  Widget _quickActionsSection(BuildContext context, bool isDark) {
    final actions = [
      {'icon': Icons.construction_outlined, 'label': 'Construction Updates'},

      {'icon': Icons.description_outlined, 'label': 'Documents'},
      {'icon': Icons.announcement_outlined, 'label': 'Society Notices'},

      {'icon': Icons.campaign_outlined, 'label': 'Announcements'},
      {'icon': Icons.support_agent_outlined, 'label': 'CRM'},
      {'icon': Icons.people_outlined, 'label': 'Refer Friend'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('QUICK ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : _bronze, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1),
        itemCount: actions.length,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _gold.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: _bronze.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(actions[i]['icon'] as IconData, color: _bronze, size: 20)),
            const SizedBox(height: 6),
            Text(actions[i]['label'] as String, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : _dark, height: 1.3)),
          ]),
        ),
      ),
    ]);
  }

  Widget _announcementsSection(bool isDark) {
    final items = [
      {'icon': Icons.construction, 'color': Colors.orange,
       'title': 'Construction Update', 'desc': 'Residential slab 14 completed.', 'time': '15 Jun 2026'},
      {'icon': Icons.announcement, 'color': Colors.blue,
       'title': 'Society Notice', 'desc': 'AGM scheduled on 20 June 2026.', 'time': '14 Jun 2026'},
      {'icon': Icons.key, 'color': Colors.green,
       'title': 'Possession Update', 'desc': 'Target possession: Dec 2026.', 'time': '10 Jun 2026'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LATEST ANNOUNCEMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : _bronze, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ...items.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: (a['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _dark)),
            Text(a['desc'] as String, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
          ])),
          Text(a['time'] as String, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey[400])),
        ]),
      )).toList(),
    ]);
  }
}
