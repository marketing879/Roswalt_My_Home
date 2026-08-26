import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Employee Attendance/Leave/Smart-Band state, backed by Firestore
/// (`employees/{uid}/...`) so check-ins, leave requests and band status are
/// real server data, not local-only placeholders. `{uid}` is the Firebase
/// custom-token uid minted during email OTP verification. A scheduled Cloud
/// Function finalizes each day's attendance doc shortly after midnight IST.
class EmployeeAttendanceProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  DocumentReference<Map<String, dynamic>>? get _employeeDoc =>
      _uid == null ? null : _db.collection('employees').doc(_uid);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // ── Smart Band ──
  String bandId = '';
  bool bandConnected = false;
  int bandBatteryPercent = 0;
  bool bandReplacementInProgress = false;

  // ── Today's Attendance ──
  DateTime? todayCheckIn;
  DateTime? todayCheckOut;
  String officeLocation = 'Head Office, Mumbai';

  bool get isCheckedInToday => todayCheckIn != null;
  bool get isCheckedOutToday => todayCheckOut != null;

  String get totalHoursToday {
    if (todayCheckIn == null) return '--';
    final end = todayCheckOut ?? DateTime.now();
    final diff = end.difference(todayCheckIn!);
    if (diff.isNegative) return '--';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Call once (e.g. when EmployeeShell mounts) to load this employee's real
  /// data from Firestore, seeding sensible defaults on first-ever login.
  Future<void> load({required String employeeName, String? employeeId}) async {
    final doc = _employeeDoc;
    if (doc == null) return;

    await doc.set({
      'name': employeeName,
      'employeeId': employeeId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final bandSnap = await doc.collection('meta').doc('band').get();
    if (bandSnap.exists) {
      final b = bandSnap.data()!;
      bandId = (b['bandId'] as String?) ?? 'RW-EMP-${employeeId ?? '0000'}';
      bandConnected = (b['connected'] as bool?) ?? true;
      bandBatteryPercent = (b['batteryPercent'] as num?)?.toInt() ?? 100;
    } else {
      bandId = 'RW-EMP-${employeeId ?? '0000'}';
      bandConnected = true;
      bandBatteryPercent = 100;
      await doc.collection('meta').doc('band').set({
        'bandId': bandId, 'connected': true, 'batteryPercent': 100,
      });
    }

    final leaveSnap = await doc.collection('meta').doc('leaveBalances').get();
    if (leaveSnap.exists) {
      final l = leaveSnap.data()!;
      leaveBalances.forEach((type, _) {
        final entry = l[type] as Map<String, dynamic>?;
        if (entry != null) {
          leaveBalances[type] = [(entry['total'] as num).toInt(), (entry['used'] as num).toInt()];
        }
      });
    } else {
      await doc.collection('meta').doc('leaveBalances').set(
          leaveBalances.map((type, v) => MapEntry(type, {'total': v[0], 'used': v[1]})));
    }

    final today = DateTime.now();
    final todaySnap = await doc.collection('attendance').doc(_dateKey(today)).get();
    if (todaySnap.exists) {
      final a = todaySnap.data()!;
      todayCheckIn = (a['checkIn'] as Timestamp?)?.toDate();
      todayCheckOut = (a['checkOut'] as Timestamp?)?.toDate();
      officeLocation = (a['location'] as String?) ?? officeLocation;
    }

    final historySnap = await doc.collection('leaveRequests').orderBy('requestedAt', descending: true).limit(50).get();
    leaveHistory
      ..clear()
      ..addAll(historySnap.docs.map((d) => {
            'id': d.id,
            'type': d['type'],
            'dateLabel': d['dateLabel'],
            'days': d['days'],
            'status': d['status'],
          }));

    await _loadMonthAttendanceStats(today);
    _loaded = true;
    notifyListeners();
  }

  Future<void> payAndReplaceBand() async {
    final doc = _employeeDoc;
    if (doc == null) return;
    bandReplacementInProgress = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    bandConnected = true;
    bandBatteryPercent = 100;
    await doc.collection('meta').doc('band').set({
      'bandId': bandId, 'connected': true, 'batteryPercent': 100,
      'lastReplacedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    bandReplacementInProgress = false;
    notifyListeners();
  }

  Future<void> checkIn() async {
    final doc = _employeeDoc;
    if (doc == null) return;
    final now = DateTime.now();
    todayCheckIn = now;
    await doc.collection('attendance').doc(_dateKey(now)).set({
      'date': _dateKey(now),
      'checkIn': Timestamp.fromDate(now),
      'status': 'present',
      'location': officeLocation,
      'finalized': false,
    }, SetOptions(merge: true));
    _attendanceStatus[_dateKey(now)] = 'present';
    notifyListeners();
  }

  Future<void> checkOut() async {
    final doc = _employeeDoc;
    if (doc == null || todayCheckIn == null) return;
    final now = DateTime.now();
    todayCheckOut = now;
    final minutes = now.difference(todayCheckIn!).inMinutes;
    await doc.collection('attendance').doc(_dateKey(now)).set({
      'checkOut': Timestamp.fromDate(now),
      'totalMinutes': minutes,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  // ── Attendance Calendar ──
  final Map<String, String> _attendanceStatus = {};
  DateTime? _statsMonth;

  Future<void> _loadMonthAttendanceStats(DateTime month) async {
    final doc = _employeeDoc;
    if (doc == null) return;
    final start = _dateKey(DateTime(month.year, month.month, 1));
    final end = _dateKey(DateTime(month.year, month.month + 1, 0));
    final snap = await doc
        .collection('attendance')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: start)
        .where(FieldPath.documentId, isLessThanOrEqualTo: end)
        .get();
    for (final d in snap.docs) {
      _attendanceStatus[d.id] = (d.data()['status'] as String?) ?? 'present';
    }
    _statsMonth = DateTime(month.year, month.month);
    presentDaysThisMonth = snap.docs.where((d) => d.data()['status'] == 'present').length;
    totalMinutesThisMonth = snap.docs.fold<int>(0, (sum, d) => sum + ((d.data()['totalMinutes'] as num?)?.toInt() ?? 0));
    notifyListeners();
  }

  /// Called by the Attendance Calendar screen when the visible month changes.
  Future<void> loadMonthAttendance(DateTime month) async {
    if (_statsMonth != null && _statsMonth!.year == month.year && _statsMonth!.month == month.month) return;
    await _loadMonthAttendanceStats(month);
  }

  String statusFor(DateTime d) {
    final key = _dateKey(d);
    if (_attendanceStatus.containsKey(key)) return _attendanceStatus[key]!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date.isAfter(today)) return '';
    if (d.weekday == DateTime.sunday) return 'weeklyOff';
    return '';
  }

  // ── This Month Summary ──
  int presentDaysThisMonth = 0;
  int totalMinutesThisMonth = 0;
  String get totalHoursThisMonth => '${totalMinutesThisMonth ~/ 60}h ${totalMinutesThisMonth % 60}m';
  int get leavesThisMonth {
    final now = DateTime.now();
    return leaveHistory.where((h) {
      if (h['status'] == 'Rejected') return false;
      final label = (h['dateLabel'] as String).split(' – ').first;
      try {
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        final parts = label.split(' ');
        final month = months.indexOf(parts[1]) + 1;
        final year = int.parse(parts[2]);
        return month == now.month && year == now.year;
      } catch (_) {
        return false;
      }
    }).fold<int>(0, (sum, h) => sum + (h['days'] as int));
  }

  // ── Leave Balances (total, used) ──
  final Map<String, List<int>> leaveBalances = {
    'Casual Leave': [12, 0],
    'Sick Leave': [6, 0],
    'Earned Leave': [15, 5],
    'Comp Off': [6, 2],
    'Maternity Leave': [60, 0],
  };

  int get totalLeaves => leaveBalances.values.fold(0, (s, v) => s + v[0]);
  int get usedLeaves => leaveBalances.values.fold(0, (s, v) => s + v[1]);
  int get availableLeaves => totalLeaves - usedLeaves;

  // ── Leave History ──
  final List<Map<String, dynamic>> leaveHistory = [];

  Future<void> applyLeave({
    required String type,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    final doc = _employeeDoc;
    if (doc == null) return;
    final days = to.difference(from).inDays + 1;
    final dateLabel = (from.year == to.year && from.month == to.month && from.day == to.day)
        ? _fmtDate(from)
        : '${_fmtDate(from)} – ${_fmtDate(to)}';

    final ref = await doc.collection('leaveRequests').add({
      'type': type, 'fromDate': Timestamp.fromDate(from), 'toDate': Timestamp.fromDate(to),
      'days': days, 'reason': reason, 'status': 'Pending', 'dateLabel': dateLabel,
      'requestedAt': FieldValue.serverTimestamp(),
    });

    leaveHistory.insert(0, {'id': ref.id, 'type': type, 'dateLabel': dateLabel, 'days': days, 'status': 'Pending'});
    if (leaveBalances.containsKey(type)) {
      leaveBalances[type]![1] += days;
      await doc.collection('meta').doc('leaveBalances').set(
          {type: {'total': leaveBalances[type]![0], 'used': leaveBalances[type]![1]}}, SetOptions(merge: true));
    }
    notifyListeners();
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Clears in-memory state on sign-out; Firestore data itself is untouched.
  void reset() {
    _loaded = false;
    todayCheckIn = null;
    todayCheckOut = null;
    _attendanceStatus.clear();
    _statsMonth = null;
    presentDaysThisMonth = 0;
    totalMinutesThisMonth = 0;
    leaveHistory.clear();
  }
}
