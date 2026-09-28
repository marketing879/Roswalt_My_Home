import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/employee_attendance_provider.dart';
import 'employee_lost_band_screen.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

AppBar _flowAppBar(String title) => AppBar(
      backgroundColor: _bronze,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );

// ── MY SMART BAND ──────────────────────────────────────────────
class EmployeeSmartBandScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const EmployeeSmartBandScreen({super.key, this.onOpenDrawer});

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
        leading: onOpenDrawer != null
            ? IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: onOpenDrawer)
            : null,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Smart Band', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.15))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Band ID', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
                const SizedBox(height: 4),
                Text(attendance.bandId, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              ])),
              Row(children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle,
                    color: attendance.bandConnected ? Colors.green : Colors.red)),
                const SizedBox(width: 5),
                Text(attendance.bandConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: attendance.bandConnected ? Colors.green : Colors.red)),
                const SizedBox(width: 10),
                Icon(Icons.battery_full, size: 14, color: isDark ? Colors.white54 : Colors.grey[600]),
                Text(' ${attendance.bandBatteryPercent}%', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
              ]),
            ]),
          ),
          const SizedBox(height: 28),
          Stack(alignment: Alignment.center, children: [
            Container(width: 140, height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _bronze.withOpacity(0.08),
                  border: Border.all(color: _gold.withOpacity(0.3), width: 2)),
              child: const Icon(Icons.watch, color: _bronze, size: 64)),
            if (attendance.bandConnected)
              Positioned(bottom: 6, right: 6,
                child: Container(width: 30, height: 30,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                  child: const Icon(Icons.check, color: Colors.white, size: 18))),
          ]),
          const SizedBox(height: 20),
          Text(attendance.bandConnected ? 'Your band is connected' : 'Your band is not connected',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          const SizedBox(height: 6),
          Text('You can now mark your attendance using your band.', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
          const SizedBox(height: 28),
          _row(context, isDark, cardBg, Icons.sync, 'Sync Band', subtitle: 'Last synced: Today, 09:15 AM',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Band synced.'), backgroundColor: _bronze))),
          _row(context, isDark, cardBg, Icons.settings_outlined, 'Band Settings',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Band settings coming soon.'), backgroundColor: _bronze))),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeLostBandScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Lost or Damaged Band?', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Replace your band for ₹150', style: TextStyle(color: Colors.red.withOpacity(0.8), fontSize: 11)),
                ])),
                const Icon(Icons.chevron_right, color: Colors.red, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  !attendance.isCheckedInToday ? const EmployeeCheckInScreen()
                      : !attendance.isCheckedOutToday ? const EmployeeCheckOutScreen()
                          : const EmployeeAttendanceCalendarScreen())),
              child: Text(
                  !attendance.isCheckedInToday ? 'Check In'
                      : !attendance.isCheckedOutToday ? 'Check Out'
                          : 'View Attendance',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, bool isDark, Color cardBg, IconData icon, String label, {String? subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.15))),
        child: Row(children: [
          Icon(icon, size: 20, color: _bronze),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey[500])),
          ])),
          Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey[400]),
        ]),
      ),
    );
  }
}

// ── CHECK IN ───────────────────────────────────────────────────
class EmployeeCheckInScreen extends StatelessWidget {
  const EmployeeCheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final done = attendance.isCheckedInToday;

    return Scaffold(
      backgroundColor: bg,
      appBar: _flowAppBar('Check In'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: done ? null : () => Provider.of<EmployeeAttendanceProvider>(context, listen: false).checkIn(),
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: done ? Colors.green.withOpacity(0.1) : _gold.withOpacity(0.12),
                  border: Border.all(color: done ? Colors.green : _gold, width: 2)),
              child: Icon(done ? Icons.check_circle : Icons.touch_app_outlined,
                  color: done ? Colors.green : _bronze, size: 56)),
          ),
          const SizedBox(height: 24),
          Text(done ? 'Check-In Successful' : 'Tap to Check In',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: done ? Colors.green : (isDark ? Colors.white : const Color(0xFF1A0A00)))),
          const SizedBox(height: 8),
          Text(_todayLabel(), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
          if (done) ...[
            const SizedBox(height: 20),
            Text(_fmtTime(attendance.todayCheckIn!), style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            const SizedBox(height: 24),
            Text('Location', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
            Text(attendance.officeLocation, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            if (attendance.todayLatitude != null && attendance.todayLongitude != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${attendance.todayLatitude},${attendance.todayLongitude}')),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, size: 13, color: _bronze),
                  const SizedBox(width: 4),
                  Text('View GPS location on map', style: TextStyle(fontSize: 11.5, color: _bronze, decoration: TextDecoration.underline)),
                ]),
              ),
            ] else if (attendance.locationError != null) ...[
              const SizedBox(height: 4),
              Text(attendance.locationError!, style: TextStyle(fontSize: 11, color: Colors.orange[800])),
            ],
            const SizedBox(height: 8),
            Text(attendance.isLateCheckInToday
                    ? 'Checked in after 9:45 AM — marked late for today.'
                    : 'You are marked present for today.',
                style: TextStyle(fontSize: 12,
                    color: attendance.isLateCheckInToday ? Colors.amber[800] : (isDark ? Colors.white54 : Colors.grey[600]))),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeAttendanceCalendarScreen())),
                child: const Text('View Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]),
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
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ── CHECK OUT ──────────────────────────────────────────────────
class EmployeeCheckOutScreen extends StatelessWidget {
  const EmployeeCheckOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final canCheckOut = attendance.isCheckedInToday;
    final done = attendance.isCheckedOutToday;

    return Scaffold(
      backgroundColor: bg,
      appBar: _flowAppBar('Check Out'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!canCheckOut)
            Text('Please check in first.', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.grey[600]))
          else ...[
            GestureDetector(
              onTap: done ? null : () => Provider.of<EmployeeAttendanceProvider>(context, listen: false).checkOut(),
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: done ? Colors.green.withOpacity(0.1) : _gold.withOpacity(0.12),
                    border: Border.all(color: done ? Colors.green : _gold, width: 2)),
                child: Icon(done ? Icons.check_circle : Icons.touch_app_outlined,
                    color: done ? Colors.green : _bronze, size: 56)),
            ),
            const SizedBox(height: 24),
            Text(done ? 'Check-Out Successful' : 'Tap to Check Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: done ? Colors.green : (isDark ? Colors.white : const Color(0xFF1A0A00)))),
            const SizedBox(height: 8),
            Text(_todayLabel(), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
            if (done) ...[
              const SizedBox(height: 20),
              Text(_fmtTime(attendance.todayCheckOut!), style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              const SizedBox(height: 24),
              Text('Total Working Hours', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
              Text(attendance.totalHoursToday, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              const SizedBox(height: 8),
              Text('Thank you for your hard work!', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
              const SizedBox(height: 28),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeAttendanceCalendarScreen())),
                  child: const Text('View Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ]),
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
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ── ATTENDANCE CALENDAR ────────────────────────────────────────
class EmployeeAttendanceCalendarScreen extends StatefulWidget {
  const EmployeeAttendanceCalendarScreen({super.key});
  @override
  State<EmployeeAttendanceCalendarScreen> createState() => _EmployeeAttendanceCalendarScreenState();
}

class _EmployeeAttendanceCalendarScreenState extends State<EmployeeAttendanceCalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<EmployeeAttendanceProvider>(context, listen: false).loadMonthAttendance(_month);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'late': return Colors.amber;
      case 'halfDay': return Colors.orange;
      case 'absent': return Colors.red;
      case 'weeklyOff': return Colors.grey;
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = (firstDay.weekday - DateTime.monday) % 7;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Attendance Calendar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeAttendanceDetailsScreen()))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.15))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(icon: const Icon(Icons.chevron_left, color: _bronze),
                    onPressed: () {
                      setState(() => _month = DateTime(_month.year, _month.month - 1));
                      attendance.loadMonthAttendance(_month);
                    }),
                Text('${months[_month.month - 1]} ${_month.year}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                IconButton(icon: const Icon(Icons.chevron_right, color: _bronze),
                    onPressed: () {
                      setState(() => _month = DateTime(_month.year, _month.month + 1));
                      attendance.loadMonthAttendance(_month);
                    }),
              ]),
              GridView.count(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) => Center(
                    child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white38 : Colors.grey[500])))).toList(),
              ),
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (_, i) {
                  if (i < leadingBlanks) return const SizedBox();
                  final day = i - leadingBlanks + 1;
                  final date = DateTime(_month.year, _month.month, day);
                  final isToday = date == today;
                  final isSelected = date == _selected;
                  final status = attendance.statusFor(date);
                  return GestureDetector(
                    onTap: () => setState(() => _selected = date),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: isSelected ? _gold.withOpacity(0.25) : Colors.transparent,
                          border: isToday ? Border.all(color: _gold, width: 1.5) : null),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$day', style: TextStyle(fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                        if (status.isNotEmpty)
                          Container(margin: const EdgeInsets.only(top: 2), width: 5, height: 5,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(status))),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 4, alignment: WrapAlignment.center, children: [
                _legend('Present', Colors.green, isDark),
                _legend('Late', Colors.amber, isDark),
                _legend('Half Day', Colors.orange, isDark),
                _legend('Absent', Colors.red, isDark),
                _legend('Weekly Off', Colors.grey, isDark),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_fmtSelectedDate(_selected), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              const SizedBox(height: 10),
              if (_selected == today && attendance.isCheckedInToday) ...[
                _detailRow('Check In', _fmtTime(attendance.todayCheckIn!), isDark),
                if (attendance.isCheckedOutToday) _detailRow('Check Out', _fmtTime(attendance.todayCheckOut!), isDark),
                _detailRow('Total Hours', attendance.totalHoursToday, isDark),
              ] else
                Text(_statusLabel(attendance.statusFor(_selected)), style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600])),
              if (attendance.regularisationFor(_selected) != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: _gold.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.published_with_changes, size: 14, color: _bronze),
                    const SizedBox(width: 6),
                    Text(attendance.regularisationStepLabel(attendance.regularisationFor(_selected)!),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _bronze)),
                  ]),
                ),
              ] else if (attendance.needsRegularisation(_selected)) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: _bronze, side: const BorderSide(color: _bronze),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _showRegularisationSheet(context, _selected),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                    label: const Text('Apply for Regularisation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _showRegularisationSheet(BuildContext context, DateTime date) async {
    final reasonCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Apply for Regularisation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              const SizedBox(height: 4),
              Text(_fmtSelectedDate(date), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A0A00), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Reason (e.g. missed punch, remote work, band not synced)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12.5),
                  filled: true, fillColor: isDark ? const Color(0xFF121212) : _cream,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
              const SizedBox(height: 18),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (reasonCtrl.text.trim().isEmpty) {
                      setSheetState(() => error = 'Please enter a reason.');
                      return;
                    }
                    await Provider.of<EmployeeAttendanceProvider>(sheetContext, listen: false).applyRegularisation(
                      date: date, reason: reasonCtrl.text.trim(),
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present': return 'Present';
      case 'late': return 'Late';
      case 'halfDay': return 'Half Day';
      case 'absent': return 'Absent';
      case 'weeklyOff': return 'Weekly Off';
      default: return 'No record';
    }
  }

  String _fmtSelectedDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${weekdays[d.weekday - 1]}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A0A00))),
      ]),
    );
  }

  Widget _legend(String label, Color color, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.grey[500])),
    ]);
  }
}

// ── ATTENDANCE DETAILS ─────────────────────────────────────────
class EmployeeAttendanceDetailsScreen extends StatefulWidget {
  const EmployeeAttendanceDetailsScreen({super.key});
  @override
  State<EmployeeAttendanceDetailsScreen> createState() => _EmployeeAttendanceDetailsScreenState();
}

class _EmployeeAttendanceDetailsScreenState extends State<EmployeeAttendanceDetailsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: _flowAppBar('Attendance Details'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.15))),
            child: Row(children: ['Day', 'Week', 'Month'].asMap().entries.map((e) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: _tab == e.key ? _bronze : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                    child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _tab == e.key ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600]))),
                  ),
                ))).toList()),
          ),
          const SizedBox(height: 16),
          if (_tab != 0)
            Expanded(child: Center(child: Text(
                _tab == 1 ? 'Weekly summary coming soon.' : 'Monthly summary coming soon.',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500]))))
          else
            Expanded(child: ListView(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold.withOpacity(0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_todayLabel(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                  const SizedBox(height: 14),
                  _entry(isDark, Icons.login, 'Check In',
                      attendance.todayCheckIn != null ? _fmtTime(attendance.todayCheckIn!) : '--:--',
                      attendance.isCheckedInToday ? 'On Time' : null),
                  const SizedBox(height: 10),
                  _entry(isDark, Icons.logout, 'Check Out',
                      attendance.todayCheckOut != null ? _fmtTime(attendance.todayCheckOut!) : '--:--',
                      attendance.isCheckedOutToday ? 'On Time' : null),
                  const Divider(height: 28),
                  _statLine(isDark, 'Total Working Hours', attendance.totalHoursToday),
                  _statLine(isDark, 'Break Duration', '45m'),
                  _statLine(isDark, 'Overtime', '00h 20m'),
                ]),
              ),
            ])),
        ]),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${now.day} ${months[now.month - 1]} ${now.year}, ${weekdays[now.weekday - 1]}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _entry(bool isDark, IconData icon, String label, String time, String? badge) {
    return Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: _bronze, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700]))),
      Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1A0A00))),
      if (badge != null) ...[
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(badge, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600))),
      ],
    ]);
  }

  Widget _statLine(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A0A00))),
      ]),
    );
  }
}
