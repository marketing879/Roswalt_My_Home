
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantAssistanceScreen extends StatefulWidget {
  const TenantAssistanceScreen({super.key});
  @override
  State<TenantAssistanceScreen> createState() => _TenantAssistanceScreenState();
}

class _TenantAssistanceScreenState extends State<TenantAssistanceScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);
  int _tab = 0;
  final tabs = ['Assistance', 'Raise Request', 'My Requests'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : _cream,
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Assistance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {})],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _tab == 0 ? _assistanceTab(isDark)
            : _tab == 1 ? _raiseRequestTab(isDark)
            : _myRequestsTab(isDark),
      ),
    );
  }

  Widget _assistanceTab(bool isDark) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ASSIGNED CRM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: isDark ? Colors.white54 : _bronze)),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _bronze.withOpacity(0.1), border: Border.all(color: _gold.withOpacity(0.3), width: 2)),
              child: const Icon(Icons.person, color: _bronze, size: 32)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Aziz Shaikh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              Text('Tenant Relationship Manager', style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey[500])),
            ]),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _crmBtn(Icons.phone, 'Call', Colors.green, () => launchUrl(Uri.parse('tel:+918879778560'))),
            _crmBtn(Icons.chat, 'WhatsApp', const Color(0xFF25D366), () => launchUrl(Uri.parse('https://wa.me/918879778560'))),
            _crmBtn(Icons.email_outlined, 'Email', Colors.blue, () => launchUrl(Uri.parse('mailto:aziz@roswalt.com'))),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('QUICK ASSISTANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: isDark ? Colors.white54 : _bronze)),
          const SizedBox(height: 16),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
            children: [
              _aItem(Icons.account_balance_wallet_outlined, 'Rental Compensation', isDark),
              _aItem(Icons.home_outlined, 'Transit Accommodation', isDark),
              _aItem(Icons.feedback_outlined, 'Complaints Feedback', isDark),
            ]),
        ]),
      ),
    ]);
  }

  Widget _crmBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 80, height: 80,
        decoration: BoxDecoration(color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
    );
  }

  Widget _aItem(IconData icon, String label, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withOpacity(0.2))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _bronze, size: 24),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : _bronze,
                fontWeight: FontWeight.w500, height: 1.3)),
      ]),
    );
  }

  Widget _raiseRequestTab(bool isDark) {
    final categories = ['Rental Compensation', 'Transit Accommodation',
        'Construction Update', 'Complaints', 'Other'];
    String? selected;
    return StatefulBuilder(
      builder: (ctx, set) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RAISE A REQUEST', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : _bronze)),
          const SizedBox(height: 20),
          _label('Category', isDark),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selected, hint: const Text('Select Category'),
            decoration: InputDecoration(filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => set(() => selected = v)),
          const SizedBox(height: 16),
          _label('Subject', isDark),
          const SizedBox(height: 6),
          TextField(decoration: InputDecoration(hintText: 'Enter Subject', filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          _label('Description', isDark),
          const SizedBox(height: 6),
          TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Enter detailed description', filled: true,
            fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF543813), Color(0xFF3A2509)]),
              borderRadius: BorderRadius.circular(16)),
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request submitted!'), backgroundColor: Color(0xFF543813))),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Submit Request', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 15))),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : Colors.black54));
  }

  Widget _myRequestsTab(bool isDark) {
    final requests = [
      {'title': 'Rental not received for May 2026', 'id': 'REQ-2505-0012',
       'date': '05 Jun 2026', 'status': 'In Progress', 'color': Colors.orange},
      {'title': 'Request for corpus receipt', 'id': 'REQ-2505-0021',
       'date': '28 May 2026', 'status': 'Under Review', 'color': Colors.blue},
      {'title': 'Transit accommodation AC issue', 'id': 'REQ-2505-0015',
       'date': '16 May 2026', 'status': 'Resolved', 'color': Colors.green},
      {'title': 'Update mobile number in records', 'id': 'REQ-2505-0008',
       'date': '10 May 2026', 'status': 'Closed', 'color': Colors.grey},
    ];
    return Column(children: [
      ...requests.map((req) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withOpacity(0.15))),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: (req['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.receipt_long_outlined, color: req['color'] as Color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(req['title'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            Text('${req["id"]} - ${req["date"]}', style: TextStyle(fontSize: 10,
                color: isDark ? Colors.white38 : Colors.grey[500])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: (req['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (req['color'] as Color).withOpacity(0.3))),
            child: Text(req['status'] as String, style: TextStyle(
                color: req['color'] as Color, fontSize: 10, fontWeight: FontWeight.w600))),
        ]),
      )).toList(),
    ]);
  }
}
