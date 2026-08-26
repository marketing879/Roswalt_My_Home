import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

/// Band replacement is a placeholder flow — no real payment gateway is
/// wired up yet. "Pay & Replace" simulates a successful payment locally.
class EmployeeLostBandScreen extends StatefulWidget {
  const EmployeeLostBandScreen({super.key});
  @override
  State<EmployeeLostBandScreen> createState() => _EmployeeLostBandScreenState();
}

class _EmployeeLostBandScreenState extends State<EmployeeLostBandScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Lost or Damaged Band', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(width: 130, height: 130,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.08),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 2)),
            child: const Icon(Icons.watch_off_outlined, color: Colors.red, size: 56)),
          const SizedBox(height: 24),
          Text('Lost or Damaged Band?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          const SizedBox(height: 8),
          Text('Get a replacement band by paying a refundable amount.', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey[600])),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.15))),
            child: Column(children: [
              Text('Replacement Charges', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
              const SizedBox(height: 6),
              const Text('₹150', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _bronze)),
              const SizedBox(height: 12),
              _bullet(isDark, 'Get a new band'),
              _bullet(isDark, 'Same features. Same access.'),
            ]),
          ),
          const Spacer(),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: attendance.bandReplacementInProgress ? null : () async {
                await Provider.of<EmployeeAttendanceProvider>(context, listen: false).payAndReplaceBand();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Replacement band on the way!'), backgroundColor: _bronze));
              },
              child: attendance.bandReplacementInProgress
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Pay ₹150 & Replace', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _bullet(bool isDark, String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      const Icon(Icons.check_circle, color: Colors.green, size: 14),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700])),
    ]),
  );
}
