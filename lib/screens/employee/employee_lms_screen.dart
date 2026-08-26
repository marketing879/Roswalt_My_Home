import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_lms_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

class EmployeeLmsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const EmployeeLmsScreen({super.key, this.onOpenDrawer});
  @override
  State<EmployeeLmsScreen> createState() => _EmployeeLmsScreenState();
}

class _EmployeeLmsScreenState extends State<EmployeeLmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<EmployeeLmsProvider>(context, listen: false).load();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'In Progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final lms = Provider.of<EmployeeLmsProvider>(context);

    final completedCourses = lmsCatalog.where((c) => lms.statusFor(c) == 'Completed').length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        leading: IconButton(icon: const Icon(Icons.menu_rounded, color: Colors.white), onPressed: () => widget.onOpenDrawer?.call()),
        title: const Text('Training (LMS)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4A1E), _bronze, Color(0xFF3A2509)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.school_outlined, color: _gold, size: 28),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$completedCourses of ${lmsCatalog.length} courses completed',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('Keep learning to grow your skills.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          ...lmsCatalog.map((course) {
            final progress = lms.progressFor(course);
            final status = lms.statusFor(course);
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeLmsCourseDetailScreen(course: course))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold.withOpacity(0.15))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(course.icon, color: _bronze, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(course.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status)))),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: progress, minHeight: 6,
                        backgroundColor: _gold.withOpacity(0.12), color: _bronze)),
                  const SizedBox(height: 6),
                  Text('${(progress * 100).round()}% • ${lms.completedFor(course.id).length}/${course.lessons.length} lessons',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class EmployeeLmsCourseDetailScreen extends StatelessWidget {
  final LmsCourse course;
  const EmployeeLmsCourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final lms = Provider.of<EmployeeLmsProvider>(context);
    final completed = lms.completedFor(course.id);
    final progress = lms.progressFor(course);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(course.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ClipRRect(borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 8,
                  backgroundColor: _gold.withOpacity(0.15), color: _bronze)),
            const SizedBox(height: 8),
            Text('${(progress * 100).round()}% complete', style: TextStyle(fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[600])),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: course.lessons.length,
            itemBuilder: (_, i) {
              final lesson = course.lessons[i];
              final done = completed.contains(lesson);
              return GestureDetector(
                onTap: () => Provider.of<EmployeeLmsProvider>(context, listen: false).toggleLesson(course.id, lesson),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: done ? Colors.green.withOpacity(0.4) : _gold.withOpacity(0.15))),
                  child: Row(children: [
                    Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: done ? Colors.green : (isDark ? Colors.white38 : Colors.grey[400]), size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Text(lesson, style: TextStyle(fontSize: 13.5,
                        fontWeight: done ? FontWeight.w600 : FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
