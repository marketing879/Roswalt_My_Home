import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

AppBar _flowAppBar(String title) => AppBar(
      backgroundColor: _bronze,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );

const _leaveIcons = {
  'Casual Leave': Icons.wb_sunny_outlined,
  'Sick Leave': Icons.local_hospital_outlined,
  'Earned Leave': Icons.savings_outlined,
  'Comp Off': Icons.swap_horiz,
  'Maternity Leave': Icons.family_restroom_outlined,
};

// ── LEAVE MANAGEMENT ───────────────────────────────────────────
class EmployeeLeaveManagementScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const EmployeeLeaveManagementScreen({super.key, this.onOpenDrawer});

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
        title: const Text('Leave Management', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeLeaveHistoryScreen()))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            _stat(isDark, cardBg, 'Total Leaves', '${attendance.totalLeaves}'),
            const SizedBox(width: 10),
            _stat(isDark, cardBg, 'Used Leaves', '${attendance.usedLeaves}'),
            const SizedBox(width: 10),
            _stat(isDark, cardBg, 'Available', '${attendance.availableLeaves}'),
          ]),
          const SizedBox(height: 20),
          Align(alignment: Alignment.centerLeft,
            child: Text('Leave Types', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
          const SizedBox(height: 10),
          Expanded(child: ListView(children: [
            ...attendance.leaveBalances.entries.map((e) {
              final available = e.key == 'Maternity Leave' ? null : e.value[0] - e.value[1];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeLeaveBalanceScreen())),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _gold.withOpacity(0.15))),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_leaveIcons[e.key] ?? Icons.event_note_outlined, color: _bronze, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.key, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                    Text(available != null ? '$available Available' : 'As per Policy',
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.grey[600])),
                  ]),
                ),
              );
            }),
          ])),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeApplyLeaveScreen())),
              child: const Text('Apply Leave', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stat(bool isDark, Color cardBg, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.15))),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.grey[500])),
        ]),
      ),
    );
  }
}

// ── APPLY LEAVE ────────────────────────────────────────────────
class EmployeeApplyLeaveScreen extends StatefulWidget {
  const EmployeeApplyLeaveScreen({super.key});
  @override
  State<EmployeeApplyLeaveScreen> createState() => _EmployeeApplyLeaveScreenState();
}

class _EmployeeApplyLeaveScreenState extends State<EmployeeApplyLeaveScreen> {
  String _type = 'Casual Leave';
  DateTime? _from;
  DateTime? _to;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_to != null && _to!.isBefore(picked)) _to = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final totalDays = (_from != null && _to != null) ? _to!.difference(_from!).inDays + 1 : null;

    return Scaffold(
      backgroundColor: bg,
      appBar: _flowAppBar('Apply Leave'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(isDark, 'Leave Type'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.2))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _bronze),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A0A00)),
                dropdownColor: cardBg,
                items: _leaveIcons.keys.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label(isDark, 'From Date'),
              _dateField(isDark, cardBg, _fmt(_from), () => _pickDate(isFrom: true)),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label(isDark, 'To Date'),
              _dateField(isDark, cardBg, _fmt(_to), () => _pickDate(isFrom: false)),
            ])),
          ]),
          const SizedBox(height: 16),
          _label(isDark, 'Total Days'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.2))),
            child: Text(totalDays != null ? '$totalDays Day${totalDays > 1 ? 's' : ''}' : '--',
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          ),
          const SizedBox(height: 16),
          _label(isDark, 'Reason'),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A0A00), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Personal work',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true, fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          _label(isDark, 'Upload Document (Optional)'),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document upload coming soon.'), backgroundColor: _bronze)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.attach_file, size: 18, color: _bronze),
                const SizedBox(width: 8),
                Text('Add File', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
              ]),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
              ])),
          ],
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _submitting ? null : () async {
                if (_from == null || _to == null) {
                  setState(() => _error = 'Please select from and to dates.');
                  return;
                }
                if (_reasonCtrl.text.trim().isEmpty) {
                  setState(() => _error = 'Please enter a reason.');
                  return;
                }
                setState(() { _submitting = true; _error = null; });
                await Provider.of<EmployeeAttendanceProvider>(context, listen: false).applyLeave(
                  type: _type, from: _from!, to: _to!, reason: _reasonCtrl.text.trim(),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leave request submitted.'), backgroundColor: _bronze));
              },
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Submit Request', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(bool isDark, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])));

  Widget _dateField(bool isDark, Color cardBg, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _gold.withOpacity(0.2))),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: _bronze),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
        ]),
      ),
    );
  }
}

// ── LEAVE BALANCE ──────────────────────────────────────────────
class EmployeeLeaveBalanceScreen extends StatelessWidget {
  const EmployeeLeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: _flowAppBar('Leave Balance'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: attendance.leaveBalances.entries.map((e) {
          final total = e.value[0];
          final used = e.value[1];
          final available = total - used;
          final progress = total == 0 ? 0.0 : used / total;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold.withOpacity(0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_leaveIcons[e.key] ?? Icons.event_note_outlined, color: _bronze, size: 18),
                const SizedBox(width: 10),
                Text(e.key, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A0A00))),
              ]),
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 6,
                    backgroundColor: _gold.withOpacity(0.12), color: _bronze)),
              const SizedBox(height: 8),
              Text('$available / $total Days Available',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ── LEAVE HISTORY ──────────────────────────────────────────────
class EmployeeLeaveHistoryScreen extends StatefulWidget {
  const EmployeeLeaveHistoryScreen({super.key});
  @override
  State<EmployeeLeaveHistoryScreen> createState() => _EmployeeLeaveHistoryScreenState();
}

class _EmployeeLeaveHistoryScreenState extends State<EmployeeLeaveHistoryScreen> {
  String _filter = 'All';

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved': return Colors.green;
      case 'Rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final items = _filter == 'All'
        ? attendance.leaveHistory
        : attendance.leaveHistory.where((h) => h['status'] == _filter).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: _flowAppBar('Leave History'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: ['All', 'Approved', 'Pending', 'Rejected'].map((f) {
            final active = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: active ? _bronze : cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _bronze : _gold.withOpacity(0.2))),
                  child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]))),
                ),
              ),
            );
          }).toList()),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text('No leave requests found.', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final h = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _gold.withOpacity(0.15))),
                      child: Row(children: [
                        Container(width: 36, height: 36,
                          decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_leaveIcons[h['type']] ?? Icons.event_note_outlined, color: _bronze, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(h['type'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                          Text('${h['dateLabel']}  •  ${h['days']} Day${(h['days'] as int) > 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
                        ])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _statusColor(h['status'] as String).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(h['status'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                              color: _statusColor(h['status'] as String)))),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
