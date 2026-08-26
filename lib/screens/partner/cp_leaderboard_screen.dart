import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';

class CPTier {
  final String name;
  final Color color;
  final int threshold;
  const CPTier(this.name, this.color, this.threshold);
}

// Walk-in tier thresholds ("PB Planned") as defined by the business:
// Platinum >=20, Gold >=10, Silver >=5, Bronze >=0. Sorted descending so the
// first threshold a partner's walk-in count clears is their tier.
const List<CPTier> kCPTiers = [
  CPTier('PLATINUM', Color(0xFFB9C4D4), 20),
  CPTier('GOLD', Color(0xFFD4AF37), 10),
  CPTier('SILVER', Color(0xFFAEB0B4), 5),
  CPTier('BRONZE', Color(0xFFB08D57), 0),
];

CPTier tierForWalkIns(int walkIns) {
  for (final t in kCPTiers) {
    if (walkIns >= t.threshold) return t;
  }
  return kCPTiers.last;
}

CPTier? nextTier(CPTier current) {
  final i = kCPTiers.indexOf(current);
  return i > 0 ? kCPTiers[i - 1] : null;
}

class CPLeaderboardScreen extends StatefulWidget {
  const CPLeaderboardScreen({super.key});
  @override
  State<CPLeaderboardScreen> createState() => _CPLeaderboardScreenState();
}

class _CPLeaderboardScreenState extends State<CPLeaderboardScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  int _period = 0; // 0 = Weekly, 1 = Monthly, 2 = Yearly

  // No cross-partner ranking API exists yet (confirmed: the only endpoint
  // that responds is scoped to the logged-in CP's own data) - stays empty
  // until a real leaderboard endpoint exists.
  final List<Map<String, dynamic>> _entries = [];

  Widget _periodTab(int index, String label) {
    final isActive = _period == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _bronze : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? _bronze : _gold.withOpacity(0.3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : _bronze,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _yourCategoryCard(bool isDark, int walkIns) {
    final tier = tierForWalkIns(walkIns);
    final next = nextTier(tier);
    final toNext = next == null ? 0 : (next.threshold - walkIns).clamp(0, next.threshold);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [tier.color.withOpacity(0.25), tier.color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tier.color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tier.color.withOpacity(0.25),
                border: Border.all(color: tier.color, width: 2)),
            child: Icon(Icons.workspace_premium, color: tier.color, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: isDark ? Colors.white54 : Colors.grey[600])),
            const SizedBox(height: 2),
            Text(tier.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _bronze, borderRadius: BorderRadius.circular(20)),
            child: Text('$walkIns walk-ins', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        if (next != null) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: next.threshold == 0 ? 1 : (walkIns / next.threshold).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(next.color),
            ),
          ),
          const SizedBox(height: 8),
          Text('$toNext more walk-in${toNext == 1 ? '' : 's'} to reach ${next.name}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
        ] else ...[
          const SizedBox(height: 10),
          Text('You\'ve reached the top category!',
              style: TextStyle(fontSize: 12, color: tier.color, fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }

  Widget _tierTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withOpacity(0.2)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(flex: 2, child: Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1, color: isDark ? Colors.white38 : Colors.grey[500]))),
            Expanded(child: Text('WALK-INS', textAlign: TextAlign.end, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1, color: isDark ? Colors.white38 : Colors.grey[500]))),
          ]),
        ),
        const Divider(height: 1),
        ...kCPTiers.map((t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: t.color)),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: Text(t.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                Expanded(child: Text('${t.threshold}+', textAlign: TextAlign.end, style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey[700]))),
              ]),
            )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cpData = Provider.of<BookingProvider>(context).cpDashboardData;
    final walkIns = (cpData?['totalWalkIns'] as num?)?.toInt() ?? 0;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _yourCategoryCard(isDark, walkIns),
            const SizedBox(height: 16),
            Text('Category Thresholds', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            const SizedBox(height: 8),
            _tierTable(isDark),
            const SizedBox(height: 24),
            Text('Top 10 Channel Partners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            Text('By Walk-ins', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
            const SizedBox(height: 16),
            Row(
              children: [
                _periodTab(0, 'Weekly'),
                _periodTab(1, 'Monthly'),
                _periodTab(2, 'Yearly'),
              ],
            ),
            const SizedBox(height: 20),
            _entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Leaderboard data not available yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) => const SizedBox(), // TODO: render real entries once a cross-CP ranking API is available
                  ),
          ],
        ),
      ),
    );
  }
}
