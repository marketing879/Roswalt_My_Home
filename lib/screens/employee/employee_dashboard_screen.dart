import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';
import 'employee_lms_screen.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

class EmployeeDashboardScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final String employeeName;
  final ValueChanged<int>? onNavigate;
  const EmployeeDashboardScreen({super.key, this.onOpenDrawer, required this.employeeName, this.onNavigate});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label coming soon.'), backgroundColor: _bronze));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final firstName = employeeName.split(' ').first;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GestureDetector(
                onTap: onOpenDrawer,
                child: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withOpacity(0.25))),
                  child: Icon(Icons.menu_rounded, color: isDark ? Colors.white : _bronze, size: 20)),
              ),
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _gold.withOpacity(0.25))),
                child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white : _bronze, size: 20)),
            ]),
            const SizedBox(height: 18),
            Text('Hello, $firstName 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            Text('Welcome back!', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[600])),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Today's Overview", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_todayLabel(), style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                const SizedBox(height: 16),
                Row(children: [
                  _overviewStat('Check In', attendance.todayCheckIn != null ? _fmtTime(attendance.todayCheckIn!) : '--:--'),
                  _overviewStat('Check Out', attendance.todayCheckOut != null ? _fmtTime(attendance.todayCheckOut!) : '--:--'),
                  _overviewStat('Total Hours', attendance.totalHoursToday),
                ]),
                if (attendance.isCheckedInToday) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent)),
                    const SizedBox(width: 6),
                    Text(attendance.isCheckedOutToday ? 'Day completed' : 'On Time', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 24),
            Text('Quick Access', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 12, childAspectRatio: 0.8,
              children: [
                _quickAccess(context, isDark, cardBg, Icons.event_available_outlined, 'Attendance',
                    () => onNavigate?.call(2)),
                _quickAccess(context, isDark, cardBg, Icons.beach_access_outlined, 'Leave',
                    () => onNavigate?.call(3)),
                _quickAccess(context, isDark, cardBg, Icons.watch_outlined, 'My Band',
                    () => onNavigate?.call(2)),
                _quickAccess(context, isDark, cardBg, Icons.school_outlined, 'Training',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeLmsScreen()))),
                _quickAccess(context, isDark, cardBg, Icons.receipt_long_outlined, 'Payslip',
                    () => _comingSoon(context, 'Payslip')),
                _quickAccess(context, isDark, cardBg, Icons.support_agent_outlined, 'Help Desk',
                    () => _comingSoon(context, 'Help Desk')),
                _quickAccess(context, isDark, cardBg, Icons.campaign_outlined, 'Announcements',
                    () => _comingSoon(context, 'Announcements')),
                _quickAccess(context, isDark, cardBg, Icons.description_outlined, 'Documents',
                    () => _comingSoon(context, 'Documents')),
                _quickAccess(context, isDark, cardBg, Icons.more_horiz, 'More',
                    () => _comingSoon(context, 'More')),
              ],
            ),
            const SizedBox(height: 24),
            Text('This Month Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            const SizedBox(height: 12),
            Row(children: [
              _summaryStat(isDark, cardBg, 'Present Days', '${attendance.presentDaysThisMonth}'),
              const SizedBox(width: 10),
              _summaryStat(isDark, cardBg, 'Leaves', '${attendance.leavesThisMonth}'),
              const SizedBox(width: 10),
              _summaryStat(isDark, cardBg, 'Total Hours', attendance.totalHoursThisMonth),
            ]),
          ]),
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${now.day} ${months[now.month - 1]} ${now.year}, ${weekdays[now.weekday - 1]}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Widget _overviewStat(String label, String value) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _quickAccess(BuildContext context, bool isDark, Color cardBg, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
          child: Icon(icon, color: _bronze, size: 22)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700])),
      ]),
    );
  }

  Widget _summaryStat(bool isDark, Color cardBg, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.15))),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5,
              color: isDark ? Colors.white38 : Colors.grey[500])),
        ]),
      ),
    );
  }
}
