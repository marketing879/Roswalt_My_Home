import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;

  const DocumentViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  int _totalPages = 0;
  int _currentPage = 0;

  bool get _isPdf => widget.fileType.toLowerCase() == 'pdf';
  bool get _isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(widget.fileType.toLowerCase());

  Future<void> _share() async {
    await Share.shareXFiles([XFile(widget.filePath)], text: widget.fileName);
  }

  Future<void> _download() async {
    await OpenFile.open(widget.filePath);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: _bronze,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.fileName,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_isPdf && _totalPages > 0)
              Text('Page ${_currentPage + 1} of $_totalPages',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _share,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _download,
            tooltip: 'Open with',
          ),
        ],
      ),
      body: _buildViewer(),
    );
  }

  Widget _buildViewer() {
    if (_isPdf) {
      return PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        fitPolicy: FitPolicy.BOTH,
        onRender: (pages) => setState(() => _totalPages = pages ?? 0),
        onPageChanged: (page, total) => setState(() => _currentPage = page ?? 0),
        onError: (error) => _errorWidget(error.toString()),
      );
    } else if (_isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(File(widget.filePath), fit: BoxFit.contain),
        ),
      );
    } else {
      return _unsupportedWidget();
    }
  }

  Widget _errorWidget(String msg) {
    return Center(child: Text('Error: $msg', style: const TextStyle(color: Colors.red)));
  }

  Widget _unsupportedWidget() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.insert_drive_file_outlined, size: 80, color: Color(0xFFD4AF37)),
        const SizedBox(height: 16),
        Text(widget.fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Preview not available for this file type', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _bronze),
          icon: const Icon(Icons.open_in_new, color: Colors.white),
          label: const Text('Open with App', style: TextStyle(color: Colors.white)),
          onPressed: _download,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _gold),
          icon: const Icon(Icons.share, color: Colors.white),
          label: const Text('Share', style: TextStyle(color: Colors.white)),
          onPressed: _share,
        ),
      ]),
    );
  }
}
