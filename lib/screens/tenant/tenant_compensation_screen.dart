
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TenantCompensationScreen extends StatefulWidget {
  const TenantCompensationScreen({super.key});
  @override
  State<TenantCompensationScreen> createState() => _TenantCompensationScreenState();
}

class _TenantCompensationScreenState extends State<TenantCompensationScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);
  int _tab = 0;
  final tabs = ['Rental', 'Transit', 'Corpus Fund'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : _cream,
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Compensation Overview',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        child: _tab == 0 ? _rentalTab(isDark) : _tab == 1 ? _transitTab(isDark) : _corpusTab(isDark),
      ),
    );
  }

  Widget _rentalTab(bool isDark) {
    final months = ['Jun 2026','May 2026','Apr 2026','Mar 2026','Feb 2026',
                    'Jan 2026','Dec 2025','Nov 2025','Oct 2025','Sep 2025'];
    return Column(children: [
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF543813), Color(0xFF3A2509)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _bronze.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(children: [
          const Icon(Icons.account_balance_wallet_outlined, color: _gold, size: 36),
          const SizedBox(height: 8),
          const Text('RENTAL COMPENSATION', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.5)),
          const Text('Monthly Rent', style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Rs.25,000', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _rentCol('Last Paid', '01 Jun 2026', Colors.green),
            Container(width: 1, height: 40, color: Colors.white24),
            _rentCol('Next Payment', '01 Jul 2026', Colors.orange),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _badge('PAID', Colors.green),
            _badge('DUE IN 15 DAYS', Colors.orange),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      ...months.map((m) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withOpacity(0.15))),
        child: Row(children: [
          Expanded(child: Text(m, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
          Text('Rs.25,000', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('Paid', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Icon(Icons.download_outlined, color: _gold, size: 18),
        ]),
      )).toList(),
    ]);
  }

  Widget _rentCol(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)));
  }

  Widget _transitTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.home_outlined, color: _gold, size: 24),
          const SizedBox(width: 10),
          Text('TRANSIT ACCOMMODATION', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.bold, color: isDark ? Colors.white : _bronze)),
        ]),
        const SizedBox(height: 16),
        _row('Address', 'Jogeshwari West, Mumbai', isDark),
        _row('Unit Number', 'T-12', isDark),
        _row('Move-in Date', '15 Mar 2024', isDark),
        _row('Agreement Period', '15 Mar 2024 - 14 Mar 2026', isDark),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF543813), Color(0xFF3A2509)]),
            borderRadius: BorderRadius.circular(14)),
          child: TextButton(onPressed: () {},
            child: const Text('View Transit Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ]),
    );
  }

  Widget _corpusTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.savings_outlined, color: _gold, size: 24),
          const SizedBox(width: 10),
          Text('CORPUS FUND', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.bold, color: isDark ? Colors.white : _bronze)),
        ]),
        const SizedBox(height: 16),
        _row('Corpus Amount', 'Rs.2,50,000', isDark),
        _row('Status', 'PAID', isDark),
        _row('Paid On', '10 Apr 2024', isDark),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFF8B6914)]),
            borderRadius: BorderRadius.circular(14)),
          child: TextButton(onPressed: () {},
            child: const Text('View Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
      ]),
    );
  }

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[500])),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A0A00))),
      ]),
    );
  }
}
