import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/employee_attendance_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

class EmployeeDocumentsScreen extends StatefulWidget {
  const EmployeeDocumentsScreen({super.key});
  @override
  State<EmployeeDocumentsScreen> createState() => _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState extends State<EmployeeDocumentsScreen> {
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Provider.of<EmployeeAttendanceProvider>(context, listen: false).loadDocuments();
    });
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final name = result.files.single.name;
    if (result.files.single.size > 15 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 15 MB).'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _uploading = true);
    try {
      await Provider.of<EmployeeAttendanceProvider>(context, listen: false).uploadDocument(file, name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _confirmDelete(String path, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('This will permanently remove "$name".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Provider.of<EmployeeAttendanceProvider>(context, listen: false).deleteDocument(path);
    }
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_outlined;
    return Icons.description_outlined;
  }

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
        title: const Text('My Documents', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.upload_file, color: Colors.white, size: 18),
              label: Text(_uploading ? 'Uploading...' : 'Upload Document', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        Expanded(
          child: attendance.documentsLoading && attendance.documents.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _bronze))
              : attendance.documents.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.folder_open_outlined, size: 56, color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No documents uploaded yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: attendance.documents.length,
                      itemBuilder: (_, i) {
                        final d = attendance.documents[i];
                        final name = d['name'] as String;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _gold.withOpacity(0.15))),
                          child: Row(children: [
                            Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(_iconFor(name), color: _bronze, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                              Text(_fmtSize(d['sizeBytes'] as int), style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 18, color: _bronze),
                              onPressed: () => launchUrl(Uri.parse(d['url'] as String), mode: LaunchMode.externalApplication),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => _confirmDelete(d['path'] as String, name),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
