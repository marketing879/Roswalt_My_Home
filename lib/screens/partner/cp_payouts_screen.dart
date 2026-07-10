import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CPPayoutsScreen extends StatefulWidget {
  const CPPayoutsScreen({super.key});
  @override
  State<CPPayoutsScreen> createState() => _CPPayoutsScreenState();
}

class _CPPayoutsScreenState extends State<CPPayoutsScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  // No backend endpoint exists yet for payouts/invoices - this stays empty
  // until a real API is wired in. Submitted invoices are held only in-memory
  // for this session so the flow can be demonstrated end-to-end.
  final List<Map<String, dynamic>> _invoices = [];

  Color _statusColor(String status) {
    switch (status) {
      case 'SUBMITTED':
        return const Color(0xFF2E7D32);
      case 'UNDER VERIFICATION':
        return const Color(0xFFE65100);
      case 'APPROVED':
        return const Color(0xFF1565C0);
      case 'PAYMENT PROCESSED':
        return const Color(0xFF6A1B9A);
      case 'PAID':
        return const Color(0xFF2E7D32);
      case 'NOT APPROVED':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  void _showRejectionReason(BuildContext context, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Not Approved', style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
            GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFC62828).withOpacity(0.1)),
              child: const Icon(Icons.close, color: Color(0xFFC62828), size: 34),
            ),
            const SizedBox(height: 16),
            const Text('This invoice is not approved.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(reason, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC62828))),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, foregroundColor: Colors.white),
              child: const Text('Got It'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Payouts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _invoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No invoices submitted yet', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Tap + to submit your first invoice', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final inv = _invoices[index];
                final status = inv['status'] as String;
                final color = _statusColor(status);
                return GestureDetector(
                  onTap: status == 'NOT APPROVED'
                      ? () => _showRejectionReason(context, inv['reason'] ?? 'No reason provided.')
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: _bronze.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.description_outlined, color: _bronze, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv['invoiceNo'] ?? '--', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(inv['date'] ?? '--', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        if (status == 'NOT APPROVED') const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _bronze,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CPSubmitInvoiceScreen()),
          );
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              _invoices.insert(0, {
                'invoiceNo': result['invoiceNo'] ?? 'INV_' + DateTime.now().millisecondsSinceEpoch.toString().substring(7),
                'date': result['date'] ?? '--',
                'status': 'SUBMITTED',
              });
            });
          }
        },
      ),
    );
  }
}

class CPSubmitInvoiceScreen extends StatefulWidget {
  const CPSubmitInvoiceScreen({super.key});
  @override
  State<CPSubmitInvoiceScreen> createState() => _CPSubmitInvoiceScreenState();
}

class _CPSubmitInvoiceScreenState extends State<CPSubmitInvoiceScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _firmCtrl = TextEditingController();
  final _reraCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  final _bankNameCtrl = TextEditingController();
  final _acNameCtrl = TextEditingController();
  final _acNoCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  String _acType = 'Savings';

  PlatformFile? _pickedFile;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _mobileCtrl, _firmCtrl, _reraCtrl, _panCtrl, _gstCtrl, _bankNameCtrl, _acNameCtrl, _acNoCtrl, _branchCtrl, _ifscCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if ((file.size) > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('File too large. Maximum size is 10MB.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _pickedFile = file);
  }

  Future<void> _downloadProforma() async {
    try {
      final pdfDoc = pw.Document();
      final brown = PdfColor.fromHex('#543813');
      final borderColor = PdfColor.fromHex('#E0D4C4');

      pw.Widget field(String label) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Container(height: 1, color: borderColor),
            ],
          ),
        );
      }

      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ROSWALT REALTY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brown)),
              pw.SizedBox(height: 2),
              pw.Text('Channel Partner Invoice - Proforma Format', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text('Please fill this format completely and attach it along with your original invoice when submitting for payout.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              pw.SizedBox(height: 16),
              pw.Divider(color: brown, thickness: 1.2),
              pw.SizedBox(height: 12),
              pw.Text('PARTNER DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brown, letterSpacing: 0.5)),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Expanded(child: field('1. Name')),
                pw.SizedBox(width: 16),
                pw.Expanded(child: field('2. Mobile')),
              ]),
              pw.Row(children: [
                pw.Expanded(child: field('3. Firm Name')),
                pw.SizedBox(width: 16),
                pw.Expanded(child: field('4. MahaRERA No.')),
              ]),
              pw.Row(children: [
                pw.Expanded(child: field('5. PAN Card No.')),
                pw.SizedBox(width: 16),
                pw.Expanded(child: field('6. GST No.')),
              ]),
              field('7. Invoice Date'),
              pw.SizedBox(height: 12),
              pw.Text('BANK DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brown, letterSpacing: 0.5)),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Expanded(child: field('1. Bank Name')),
                pw.SizedBox(width: 16),
                pw.Expanded(child: field('2. Account Holder Name')),
              ]),
              pw.Row(children: [
                pw.Expanded(child: field('3. Account Number')),
                pw.SizedBox(width: 16),
                pw.Expanded(child: field('4. Account Type (Savings/Current)')),
              ]),
              pw.Row(children: [
                pw.Expanded(child: field('5. Branch')),
                pw.SizedBox(width: 16),
                pw.Expanded(child: field('6. IFSC Code')),
              ]),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8F4EF'), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text(
                  'Note: This is a proforma reference format only. Please attach your actual signed invoice as a separate PDF when submitting.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        ),
      );

      final bytes = await pdfDoc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'roswalt_cp_proforma_invoice.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error generating proforma: ' + e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return d.day.toString().padLeft(2, '0') + ' ' + months[d.month - 1] + ' ' + d.year.toString();
  }

  Widget _inputField(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A2509))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter ' + label.replaceAll(RegExp(r'^\d+\.\s*'), '').toLowerCase(),
              filled: true,
              fillColor: const Color(0xFFF8F4EF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _mobileCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill at least Name and Mobile number.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please attach your invoice PDF.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _submitting = true);

    // NOTE: No backend endpoint exists yet for invoice submission.
    // This currently just simulates a brief delay and returns the entered
    // details to the Payouts list locally. Replace this block with a real
    // API call (multipart upload of _pickedFile plus the form fields) once
    // the endpoint is available.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Invoice added locally. Backend submission is not yet connected.'),
      backgroundColor: Colors.orange,
    ));

    Navigator.pop(context, {
      'invoiceNo': 'INV_' + DateTime.now().millisecondsSinceEpoch.toString().substring(7),
      'date': _fmtDate(_date),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Submit Invoice', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _downloadProforma,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _bronze.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: _bronze, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.download_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Download Proforma Invoice Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Reference template to fill and attach', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Partner Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _inputField('1. Name', _nameCtrl),
            _inputField('2. Mobile', _mobileCtrl, keyboardType: TextInputType.phone),
            _inputField('3. Firm Name', _firmCtrl),
            _inputField('4. RERA No.', _reraCtrl),
            _inputField('5. Pan Card', _panCtrl),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('6. Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A2509))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFF8F4EF), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtDate(_date), style: const TextStyle(fontSize: 14)),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _inputField('7. GST No.', _gstCtrl),
            const SizedBox(height: 8),
            const Text('Bank Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _inputField('1. Bank Name', _bankNameCtrl),
            _inputField('2. A/C Name', _acNameCtrl),
            _inputField('3. A/C No.', _acNoCtrl, keyboardType: TextInputType.number),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('4. A/C Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A2509))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: const Color(0xFFF8F4EF), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _acType,
                        isExpanded: true,
                        items: ['Savings', 'Current'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _acType = v ?? 'Savings'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _inputField('5. Branch', _branchCtrl),
            _inputField('6. IFSC Code', _ifscCtrl),
            const SizedBox(height: 8),
            const Text('7. Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A2509))),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickPdf,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4EF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.4), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(_pickedFile != null ? Icons.picture_as_pdf : Icons.upload_file_outlined, color: _bronze, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _pickedFile != null ? _pickedFile!.name : 'Upload Invoice (PDF only)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _pickedFile != null
                          ? (_pickedFile!.size / 1024).toStringAsFixed(0) + ' KB'
                          : 'Max size 10MB',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bronze,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
