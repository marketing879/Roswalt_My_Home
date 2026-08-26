import 'notifications_screen.dart';

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'document_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/horse_progress_bar.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Color _fileColor(String? t) {
    switch ((t ?? '').toUpperCase()) {
      case 'PDF': return Colors.red;
      case 'JPG': case 'JPEG': case 'PNG': return Colors.blue;
      case 'DOC': case 'DOCX': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  IconData _fileIconData(String? t) {
    switch ((t ?? '').toUpperCase()) {
      case 'PDF': return Icons.picture_as_pdf;
      case 'JPG': case 'JPEG': case 'PNG': return Icons.image_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _openFile(String url, String token, String fileName, String fileType) async {
    showHorseLoader(context);
    try {
      final finalUrl = url.contains('access_token') ? url : '=';
      final response = await http.get(Uri.parse(finalUrl), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final contentType = response.headers['content-type'] ?? '';
        String ext = '.bin';
        if (contentType.contains('pdf')) ext = '.pdf';
        else if (contentType.contains('jpeg') || contentType.contains('jpg')) ext = '.jpg';
        else if (contentType.contains('png')) ext = '.png';
        else if (contentType.contains('word') || contentType.contains('docx')) ext = '.docx';
        else if (contentType.contains('msword')) ext = '.doc';
        else if (contentType.contains('text/plain')) ext = '.txt';
        else if (contentType.contains('excel') || contentType.contains('spreadsheet')) ext = '.xlsx';
        else if (contentType.contains('powerpoint') || contentType.contains('presentation')) ext = '.pptx';
        final fileName = 'roswalt_doc_' + DateTime.now().millisecondsSinceEpoch.toString();
        final filePath = '${dir.path}/$fileName$ext';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        hideHorseLoader();
        if (mounted) Navigator.push(context, MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            filePath: filePath,
            fileName: fileName,
            fileType: fileType,
          ),
        ));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${response.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      hideHorseLoader();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final booking = provider.selectedBooking;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : AppTheme.creamBg;
    final allFiles = booking?.files ?? [];
    final filtered = _searchQuery.isEmpty ? allFiles
        : allFiles.where((f) => (f['fileName'] as String? ?? '')
            .toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        elevation: 0,
        title: _searchQuery.isEmpty
            ? const Text('My Documents', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
            : TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: 'Search...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), border: InputBorder.none),
                onChanged: (v) => setState(() => _searchQuery = v),
                autofocus: true),
        actions: [
          IconButton(
            icon: Icon(_searchQuery.isEmpty ? Icons.search : Icons.close, color: Colors.white),
            onPressed: () => setState(() { _searchQuery = ''; _searchController.clear(); })),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
        ],
      ),

      body: booking == null
          ? _empty(isDark, 'No booking selected')
          : allFiles.isEmpty
              ? _empty(isDark, 'No documents found')
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('${filtered.length} document${filtered.length == 1 ? "" : "s"}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500]))),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final file = filtered[i];
                        final name = file['fileName'] as String? ?? 'Unknown';
                        final type = file['fileType'] as String? ?? '';
                        final url = file['downloadUrl'] as String? ?? '';
                        final color = _fileColor(type);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _gold.withOpacity(0.15)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(_fileIconData(type), color: color, size: 26)),
                            title: Text(name,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1A0A00)),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text(type.toUpperCase(),
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
                            trailing: url.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => _openFile(url, provider.accessToken ?? '', name, type),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _gold.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _gold.withOpacity(0.3))),
                                      child: const Icon(Icons.download_outlined, color: _gold, size: 20)))
                                : null),
                        );
                      },
                    ),
                  ),
                ]),
    );
  }

  Widget _empty(bool isDark, String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text(msg, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 15)),
    ]));
  }
}
