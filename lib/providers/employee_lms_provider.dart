import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LmsCourse {
  final String id;
  final String title;
  final IconData icon;
  final List<String> lessons;
  const LmsCourse({required this.id, required this.title, required this.icon, required this.lessons});
}

// Placeholder course catalog — no real LMS/course-content backend exists
// yet. Completion progress itself is real, persisted per employee in
// Firestore (employees/{uid}/lmsCourses/{courseId}).
const List<LmsCourse> lmsCatalog = [
  LmsCourse(id: 'sales-onboarding', title: 'Sales Onboarding', icon: Icons.handshake_outlined, lessons: [
    'Introduction to Roswalt Realty',
    'Understanding Our Projects',
    'Sales Process Overview',
    'Objection Handling',
    'Closing Techniques',
  ]),
  LmsCourse(id: 'product-knowledge', title: 'Product Knowledge', icon: Icons.apartment_outlined, lessons: [
    'Roswalt Zaiden Overview',
    'Roswalt Ryla Overview',
    'Roswalt Raya Overview',
    'Roswalt Zyon Overview',
  ]),
  LmsCourse(id: 'compliance-rera', title: 'Compliance & RERA Basics', icon: Icons.gavel_outlined, lessons: [
    'What is RERA',
    'Documentation Requirements',
    'Customer Data Privacy',
    'Code of Conduct',
  ]),
  LmsCourse(id: 'customer-service', title: 'Customer Service Excellence', icon: Icons.support_agent_outlined, lessons: [
    'Communication Skills',
    'Handling Complaints',
    'Building Trust',
    'Follow-up Best Practices',
  ]),
];

class EmployeeLmsProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  DocumentReference<Map<String, dynamic>>? get _employeeDoc =>
      _uid == null ? null : _db.collection('employees').doc(_uid);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  final Map<String, Set<String>> _completedLessons = {};

  Future<void> load() async {
    final doc = _employeeDoc;
    if (doc == null) return;
    final snap = await doc.collection('lmsCourses').get();
    _completedLessons.clear();
    for (final d in snap.docs) {
      final completed = (d.data()['completedLessons'] as List?)?.cast<String>() ?? const [];
      _completedLessons[d.id] = completed.toSet();
    }
    _loaded = true;
    notifyListeners();
  }

  Set<String> completedFor(String courseId) => _completedLessons[courseId] ?? const {};

  double progressFor(LmsCourse course) {
    final done = completedFor(course.id).length;
    if (course.lessons.isEmpty) return 0;
    return done / course.lessons.length;
  }

  String statusFor(LmsCourse course) {
    final progress = progressFor(course);
    if (progress <= 0) return 'Not Started';
    if (progress >= 1) return 'Completed';
    return 'In Progress';
  }

  Future<void> toggleLesson(String courseId, String lesson) async {
    final doc = _employeeDoc;
    if (doc == null) return;
    final current = Set<String>.from(_completedLessons[courseId] ?? const {});
    final adding = !current.contains(lesson);
    if (adding) {
      current.add(lesson);
    } else {
      current.remove(lesson);
    }
    _completedLessons[courseId] = current;
    notifyListeners();

    await doc.collection('lmsCourses').doc(courseId).set({
      'completedLessons': adding ? FieldValue.arrayUnion([lesson]) : FieldValue.arrayRemove([lesson]),
    }, SetOptions(merge: true));
  }

  void reset() {
    _loaded = false;
    _completedLessons.clear();
  }
}
