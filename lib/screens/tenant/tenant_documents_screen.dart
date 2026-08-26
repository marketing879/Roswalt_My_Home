import '../client/notifications_screen.dart';

import 'package:flutter/material.dart';

class TenantDocumentsScreen extends StatefulWidget {
  const TenantDocumentsScreen({super.key});
  @override
  State<TenantDocumentsScreen> createState() => _TenantDocumentsScreenState();
}

class _TenantDocumentsScreenState extends State<TenantDocumentsScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);
  int _tab = 0;
  final tabs = ['Society', 'Project', 'Personal', 'Legal', 'Payments'];
  final docs = <String, List<Map<String,String>>>{
    'Society': [
      {'name': 'Meeting Notices', 'count': '12 Documents'},
      {'name': 'Minutes of Meetings', 'count': '18 Documents'},
      {'name': 'Resolutions', 'count': '09 Documents'},
      {'name': 'Circulars', 'count': '25 Documents'},
      {'name': 'By-Laws', 'count': '04 Documents'},
      {'name': 'Annual Reports', 'count': '03 Documents'},
      {'name': 'Society Registrations', 'count': '06 Documents'},
      {'name': 'Other Documents', 'count': '08 Documents'},
    ],
    'Project': [
      {'name': 'Approved Plans', 'count': '04 Documents'},
      {'name': 'NOC Certificates', 'count': '07 Documents'},
      {'name': 'Completion Certificates', 'count': '02 Documents'},
    ],
    'Personal': [
      {'name': 'Agreement Copy', 'count': '01 Document'},
      {'name': 'ID Proof', 'count': '02 Documents'},
    ],
    'Legal': [
      {'name': 'Sale Deed', 'count': '01 Document'},
      {'name': 'Title Documents', 'count': '03 Documents'},
    ],
    'Payments': [
      {'name': 'Payment Receipts', 'count': '24 Documents'},
      {'name': 'Ledger Statements', 'count': '06 Documents'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDocs = docs[tabs[_tab]] ?? [];
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : _cream,
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Documents', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())))],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(children: List.generate(tabs.length, (i) {
              final isActive = _tab == i;
              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? _gold : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(tabs[i], style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            })),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: currentDocs.length,
        itemBuilder: (_, i) {
          final doc = currentDocs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: _bronze.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.folder_outlined, color: _bronze, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc['name']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                Text(doc['count']!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
              ])),
              Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey[400]),
            ]),
          );
        },
      ),
    );
  }
}
