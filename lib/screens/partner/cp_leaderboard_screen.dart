import 'package:flutter/material.dart';

class CPLeaderboardScreen extends StatefulWidget {
  const CPLeaderboardScreen({super.key});
  @override
  State<CPLeaderboardScreen> createState() => _CPLeaderboardScreenState();
}

class _CPLeaderboardScreenState extends State<CPLeaderboardScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  int _period = 0; // 0 = Weekly, 1 = Monthly, 2 = Yearly

  // No leaderboard API exists yet - stays empty until wired to real data.
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Leaderboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Leaderboard data not available yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) => const SizedBox(), // TODO: render real entries once API is available
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
