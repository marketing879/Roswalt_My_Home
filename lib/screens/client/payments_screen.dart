import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'document_viewer_screen.dart';
import 'demand_webview_screen.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── BANK DETAILS ──
  final Map<String, String> _bankDetails = {
    'Bank Name': '-',
    'Account No': '-',
    'IFSC Code': '-',
    'Branch': '-',
    'Account Type': '-',
  };


  final List<Map<String, dynamic>> _ledger = [
    {
      'date': '10 Jan 2024',
      'description': 'Booking Amount',
      'amount': '₹5,00,000',
      'type': 'debit',
    },
    {
      'date': '15 Feb 2024',
      'description': 'Agreement Payment',
      'amount': '₹6,00,000',
      'type': 'debit',
    },
    {
      'date': '20 Mar 2024',
      'description': 'Plinth Level Payment',
      'amount': '₹6,00,000',
      'type': 'debit',
    },
    {
      'date': '01 Apr 2024',
      'description': 'TDS Refund',
      'amount': '₹25,000',
      'type': 'credit',
    },
  ];

  bool _loadingDemands = false;

  Future<void> _fetchDemands() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final booking = provider.selectedBooking;
    if (booking == null) return;
    setState(() => _loadingDemands = true);
    await provider.fetchDemands(booking.bookingId);
    setState(() => _loadingDemands = false);
    await provider.fetchReceipts(booking.bookingId);
    if (mounted) setState(() {});
  }
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDemands());
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryMaroon,
            title: const Text('Payments',
                style: TextStyle(
                    color: const Color(0xFFF0F0F0), fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.goldAccent,
              indicatorWeight: 3,
              labelColor: AppTheme.goldAccent,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Demands'),
                Tab(text: 'Ledger'),
                Tab(text: 'Receipts'),
                Tab(text: 'TDS'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverview(isDark),
              _buildDemands(isDark),
            _buildLedger(isDark),
            _buildReceipts(isDark),
            _buildTDS(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryCard('Total Demand Raised', _getTotalPaid(context), Icons.account_balance_wallet_outlined, AppTheme.primaryMaroon, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard('Last Demand Raised', _getLastPaymentWithDate(context), Icons.payment_outlined, Colors.green, isDark),
              ),



            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final provider = Provider.of<BookingProvider>(context, listen: false);
                final booking = provider.selectedBooking;
                if (booking != null && provider.receipts.isEmpty) {
                  await provider.fetchReceipts(booking.bookingId);
                }
                _showCumulativeReceipt(context, isDark);
              },
              icon: const Icon(Icons.description_outlined, size: 16, color: AppTheme.primaryMaroon),
              label: const Text('Cumulative Payment Receipt', style: TextStyle(color: AppTheme.primaryMaroon, fontSize: 13)),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.account_balance_outlined, color: AppTheme.primaryMaroon, size: 18),
                  const SizedBox(width: 8),
                  Text('Payment Bank Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                ]),
                const SizedBox(height: 12),
                ..._bankDetails.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[500])),
                      Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
          Text('Milestone Overview',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          ...List.generate(Provider.of<BookingProvider>(context, listen: false).demands.length,
              (i) => _buildMilestone(Provider.of<BookingProvider>(context, listen: false).demands[i], i, isDark)),
        ],
      ),
    );
  }

  String _getTotalPaid(BuildContext context) {
    final demands = Provider.of<BookingProvider>(context, listen: false).demands;
    final paid = demands.where((d) => d['status'] == 'paid');
    final total = paid.fold<double>(0.0, (sum, d) => sum + (double.tryParse(d['amount'].toString()) ?? 0.0));
    return '₹${_formatAmount(total)}';
  }

  String _getLastPaymentWithDate(BuildContext context) {
    final demands = Provider.of<BookingProvider>(context, listen: false).demands;
    if (demands.isEmpty) return '₹0';
    final last = demands.last;
    final date = _formatDate(last['date']);
    final amt = '₹' + _formatAmount(double.tryParse(last['amount'].toString()) ?? 0);
    return date.isNotEmpty ? (amt + ' ' + date) : amt;
  }
  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(2)} L';
    return amount.toStringAsFixed(0);
  }
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == '--') return '--';
    try {
      final d = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day.toString().padLeft(2,'0')}-${months[d.month-1]}-${d.year}';
    } catch(_) { return raw; }
  }

  Widget _summaryCard(String title, String amount, IconData icon,
      Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white60
                            : Colors.grey[600])),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(amount.contains(' ') ? amount.split(' ')[0] : amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          Text(amount.contains(' ') ? amount.split(' ').sublist(1).join(' ') : '', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ],
      ),
    );
  }









  Widget _buildDemands(bool isDark) {
    final demands = List<Map<String, dynamic>>.from(Provider.of<BookingProvider>(context, listen: false).demands);
    demands.sort((a, b) {
      final da = DateTime.tryParse((a["date"] ?? "").toString()) ?? DateTime(2100);
      final db = DateTime.tryParse((b["date"] ?? "").toString()) ?? DateTime(2100);
      return da.compareTo(db);
    });
    if (demands.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text("No demands available", style: TextStyle(color: Colors.grey[500])),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: demands.length,
      itemBuilder: (context, index) {
        final d = demands[index];
        return GestureDetector(
          onTap: () => _openDemandLink(context, d),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryMaroon.withOpacity(0.1)),
                child: Icon(Icons.attach_file, size: 18, color: AppTheme.primaryMaroon),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((d["demandNo"] ?? "Demand").toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text("Due: " + _formatDate(d["date"]), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[500])),
              ])),
              Icon(Icons.open_in_new, size: 16, color: AppTheme.primaryMaroon),
            ]),
          ),
        );
      },
    );
  }
  Widget _buildMilestone(Map<String, dynamic> milestone, int index, bool isDark) {
    final demands = Provider.of<BookingProvider>(context, listen: false).demands;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 28, height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.4), width: 2)),
          child: Icon(Icons.receipt_outlined, size: 14, color: AppTheme.primaryMaroon)),
        if (index < demands.length - 1)
          Container(width: 2, height: 60, color: Colors.grey.withOpacity(0.15)),
      ]),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: null, // moved to Demands tab
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(milestone["name"] ?? "--", maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text("Due: " + _formatDate(milestone["date"]), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[500])),
            ]),
            const SizedBox(height: 2),
            Text("Milestone: ${milestone["milestone"] ?? "--"}", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("₹ ${milestone["netAmount"]}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            const SizedBox(height: 4),
            Text("+ Tax: ₹${milestone["tax"] ?? "0"}", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ]),
      ),
      )),
    ]);
  }


  Future<void> _openDemandLink(BuildContext context, Map<String, dynamic> milestone) async {
    final link = (milestone["demandLink"] ?? "").toString().trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Demand document not available for this milestone yet."),
        backgroundColor: Colors.grey,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DemandWebViewScreen(
          url: link,
          title: (milestone["demandNo"] ?? "Demand").toString(),
        ),
      ),
    );
  }
  Widget _buildLedger(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF543813).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF543813), size: 32),
          ),
          const SizedBox(height: 16),
          Text('Payment Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Download your complete payment ledger including all demands and receipts across all bookings.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.grey[500])),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateLedgerPdf(context),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Ledger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF543813),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }


  Widget _buildReceipts(bool isDark) {
    final receipts = Provider.of<BookingProvider>(context, listen: false).receipts;
    if (receipts.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text("No receipts found", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final r = receipts[index];
        final _rAmt = double.tryParse(r["totalAmount"]?.toString() ?? "0") ?? 0;
        final _rTax = (double.tryParse(r["cgst"]?.toString() ?? "0") ?? 0) + (double.tryParse(r["sgst"]?.toString() ?? "0") ?? 0);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.receipt_long, color: Colors.red.shade400, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r["milestoneName"] ?? r["receiptNumber"] ?? "Receipt", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
              const SizedBox(height: 3),
              Text((r["receiptNumber"] ?? "--").toString() + " • " + _formatDate(r["receiptDate"]), style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[500])),
              const SizedBox(height: 3),
              Text("₹ " + _rAmt.toStringAsFixed(0) + " + Tax: ₹" + _rTax.toStringAsFixed(0), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon)),
            ])),
            GestureDetector(
              onTap: () => _downloadSingleReceipt(context, r),
              child: Icon(Icons.download_outlined, color: AppTheme.primaryMaroon, size: 20),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildTDS(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: 48, color: AppTheme.primaryMaroon),
            const SizedBox(height: 12),
            Text('TDS Certificate FY 23-24',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text('Your TDS certificate is ready for download',
                style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark ? Colors.white60 : Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: const Color(0xFFF0F0F0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCumulativeReceipt(BuildContext context, bool isDark) {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final booking = provider.selectedBooking;
    final receipts = provider.receipts;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF543813),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Cumulative Payment Receipt', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text((booking?.clientName ?? '') + ' • ' + (booking?.bookingId ?? ''), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 4),
                Builder(builder: (bctx) { final total = receipts.fold<double>(0, (s, r) { try { return s + double.parse(r['totalAmount'].toString()); } catch(_) { return s; } }); return Text('Total Paid: Rs. ' + total.toStringAsFixed(0), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)); }),
              ])),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          Expanded(child: receipts.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No receipts available', style: TextStyle(color: Colors.grey[400])),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: receipts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final r = receipts[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8E0D8)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F4EF),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.receipt_rounded, color: Color(0xFF543813), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r['receiptNumber'] ?? '--', overflow: TextOverflow.ellipsis, maxLines: 2, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF543813)))),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(r['paymentStatus'] ?? '--', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(children: [
                          _receiptRow('Receipt Number', r['receiptNumber'] ?? '--'),
                          _receiptRow('Total Amount', '₹${r['totalAmount'] ?? '0'}'),
                          _receiptRow('Project Name', r['projectName'] ?? '--'),
                          _receiptRow('CGST', '₹${r['cgst'] ?? '0'}'),
                          _receiptRow('SGST', '₹${r['sgst'] ?? '0'}'),
                          _receiptRow('Receipt Status', r['receiptStatus'] ?? '--'),
                          _receiptRow('Receipt Source', r['receiptSource'] ?? '--'),
                          _receiptRow('Receipt Type', r['receiptType'] ?? '--'),
                          _receiptRow('Transaction ID', r['transactionId'] ?? '--'),
                          _receiptRow('Payment Status', r['paymentStatus'] ?? '--'),
                          _receiptRow('Receipt Date', _formatDate(r['receiptDate'])),
                          _receiptRow('Payment Method', r['paymentMethod'] ?? '--'),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
          ),
        ]),
      ),
    );
  }

    String _getProjectLogoAsset(String? projectName) {
    if (projectName == null) return 'logos/ryla.png';
    final p = projectName.toLowerCase();
    if (p.contains('zaiden')) return 'logos/zaiden.png';
    if (p.contains('raya')) return 'logos/raya.png';
    if (p.contains('zeya')) return 'logos/zeya.png';
    if (p.contains('ryla')) return 'logos/ryla.png';
    return 'logos/ryla.png';
  }
Future<void> _downloadSingleReceipt(BuildContext context, Map<String, dynamic> r) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final booking = provider.selectedBooking;
    final logoBytes1 = await rootBundle.load(_getProjectLogoAsset(booking?.projectName));
    final logoImage = pw.MemoryImage(logoBytes1.buffer.asUint8List());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Generating receipt..."),
      backgroundColor: Color(0xFF543813),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
    try {
      final brown = PdfColor.fromHex("#543813");
      final darkBrown = PdfColor.fromHex("#3B1F08");
      final gold = PdfColor.fromHex("#D4AF37");
      final borderColor = PdfColor.fromHex("#E0D4C4");

      final amt = double.tryParse(r["totalAmount"]?.toString() ?? "0") ?? 0;
      final tax = (double.tryParse(r["cgst"]?.toString() ?? "0") ?? 0) + (double.tryParse(r["sgst"]?.toString() ?? "0") ?? 0);

      pw.Widget row(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
      }

      final pdfDoc = pw.Document();
      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Image(logoImage, width: 70, height: 70),
                  pw.SizedBox(height: 6),
                  pw.Text("A.S HIGHTECH LLP", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brown)),
              pw.SizedBox(height: 2),
              pw.Text("Roswalt Zaiden, Andheri West, Mumbai - 400053", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ]),
              pw.SizedBox(height: 12),
              pw.Divider(color: brown, thickness: 1.2),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(color: darkBrown, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Payment Receipt", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text((r["receiptNumber"] ?? "--").toString(), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: gold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text((booking?.clientName ?? "").toString(), style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.7), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Column(
                  children: [
                    row("Receipt Number", (r["receiptNumber"] ?? "--").toString()),
                    row("Total Amount", "Rs. " + amt.toStringAsFixed(0)),
                    row("Project Name", (r["projectName"] ?? "--").toString()),
                    row("CGST", "Rs. " + (double.tryParse(r["cgst"]?.toString() ?? "0") ?? 0).toStringAsFixed(0)),
                    row("SGST", "Rs. " + (double.tryParse(r["sgst"]?.toString() ?? "0") ?? 0).toStringAsFixed(0)),
                    row("Receipt Status", (r["receiptStatus"] ?? "--").toString()),
                    row("Receipt Source", (r["receiptSource"] ?? "--").toString()),
                    row("Receipt Type", (r["receiptType"] ?? "--").toString()),
                    row("Transaction ID", (r["transactionId"] ?? "--").toString()),
                    row("Payment Status", (r["paymentStatus"] ?? "--").toString()),
                    row("Receipt Date", _formatDate(r["receiptDate"])),
                    row("Payment Method", (r["paymentMethod"] ?? "--").toString()),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColor.fromHex("#F8F4EF"), borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Paid (incl. tax)", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.Text("Rs. " + (amt + tax).toStringAsFixed(0), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brown)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text("System-generated document. No signature required. Support: 8879778560 . customercare@roswaltrealty.com",
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            ],
          ),
        ),
      );

      final bytes = await pdfDoc.save();
      final safeReceiptNo = (r["receiptNumber"] ?? "receipt").toString().replaceAll("/", "-").replaceAll("\\", "-").replaceAll(" ", "_");
      final fileName = "receipt_" + safeReceiptNo + ".pdf";
      if (!context.mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error generating receipt: " + e.toString()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
        Expanded(flex: 3, child: Text(value, overflow: TextOverflow.ellipsis, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3A2509)), textAlign: TextAlign.right)),
      ]),
    );
  }

  Future<void> _generateLedgerPdf(BuildContext context) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final allBookings = provider.allBookings;
    final booking = provider.selectedBooking;
    if (booking == null) return;
    final logoBytes2 = await rootBundle.load(_getProjectLogoAsset(booking.projectName));
    final logoImage = pw.MemoryImage(logoBytes2.buffer.asUint8List());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Generating ledger PDF...'),
      backgroundColor: Color(0xFF543813),
      behavior: SnackBarBehavior.floating,
    ));
    try {
      final allData = await provider.fetchAllBookingsData();
      final allDemands = allData.values.expand((v) => v['demands'] ?? []).toList();
      final allReceipts = allData.values.expand((v) => v['receipts'] ?? []).toList();
      final totalPaid = allReceipts.fold<double>(0, (s, r) { try { return s + double.parse(r['totalAmount'].toString()); } catch(_) { return s; } });
      final totalDemanded = allDemands.fold<double>(0, (s, d) { try { return s + double.parse(d['amount'].toString()); } catch(_) { return s; } });
      final balance = (totalDemanded - totalPaid).abs();
      final now = DateTime.now();
      final genDate = _formatDate(now.toIso8601String().substring(0, 10));

      final sortedReceipts = List<Map<String, dynamic>>.from(allReceipts)
        ..sort((a, b) => (b['receiptDate'] ?? '').toString().compareTo((a['receiptDate'] ?? '').toString()));
      final lastReceipt = sortedReceipts.isNotEmpty ? sortedReceipts.first : null;
      final lastPaymentAmt = lastReceipt != null ? double.tryParse(lastReceipt['totalAmount']?.toString() ?? '0') ?? 0 : 0.0;
      final lastPaymentDate = lastReceipt != null ? _formatDate(lastReceipt['receiptDate']) : '--';

      String _inr(double v) {
        final s = v.toStringAsFixed(0);
        final parts = s.split('');
        if (parts.length <= 3) return 'Rs. ' + s;
        String result = parts.sublist(parts.length - 3).join();
        int rem = parts.length - 3;
        while (rem > 0) { result = parts.sublist(rem > 2 ? rem - 2 : 0, rem).join() + ',' + result; rem -= 2; }
        return 'Rs. ' + result;
      }

      final brown = PdfColor.fromHex('#543813');
      final darkBrown = PdfColor.fromHex('#3B1F08');
      final gold = PdfColor.fromHex('#D4AF37');
      final lightBg = PdfColor.fromHex('#F8F4EF');
      final borderColor = PdfColor.fromHex('#E0D4C4');
      final greenTxt = PdfColor.fromHex('#2E7D32');
      final orangeTxt = PdfColor.fromHex('#E65100');
      final greenBg = PdfColor.fromHex('#E8F5E9');
      final orangeBg = PdfColor.fromHex('#FFF3E0');
      final demandRowBg = PdfColor.fromHex('#FFFAF5');
      final receiptRowBg = PdfColor.fromHex('#F5FFF8');
      final greyLabel = PdfColor.fromHex('#999999');
      final greySub = PdfColor.fromHex('#AAAAAA');

      pw.Widget badge(String text, bool paid) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(color: paid ? greenBg : orangeBg, borderRadius: pw.BorderRadius.circular(3)),
          child: pw.Text(text, maxLines: 1, softWrap: false, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: paid ? greenTxt : orangeTxt)),
        );
      }

      pw.Widget cellText(String t, {bool alignRight = false, PdfColor? color, bool bold = false}) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 8, color: color ?? PdfColors.grey800, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left),
        );
      }

      pw.TableRow headerRow(List<String> headers) {
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: brown),
          children: headers.asMap().entries.map((e) {
            final i = e.key;
            final h = e.value;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: i == headers.length - 1 ? pw.TextAlign.right : pw.TextAlign.left),
            );
          }).toList(),
        );
      }

      pw.Widget sectionLabel(String t) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.only(bottom: 3),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.5))),
          child: pw.Text(t, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brown, letterSpacing: 0.5)),
        );
      }

      pw.Widget udCell(String label, String val, {PdfColor? color}) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 8, color: greyLabel)),
              pw.SizedBox(height: 2),
              pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.grey900)),
            ],
          ),
        );
      }

      pw.Widget unitCard(dynamic b) {
        final bReceipts = List<Map<String, dynamic>>.from(allData[b.bookingId]?['receipts'] ?? []);
        final bDemands = List<Map<String, dynamic>>.from(allData[b.bookingId]?['demands'] ?? []);
        final bPaid = bReceipts.fold<double>(0, (s, r) { try { return s + double.parse(r['totalAmount'].toString()); } catch(_) { return s; } });
        final bDemanded = bDemands.fold<double>(0, (s, d) { try { return s + double.parse(d['amount'].toString()); } catch(_) { return s; } });
        final bBalance = (bDemanded - bPaid).abs();
        String agreementVal = 'Rs. 0';
        try {
          final cleaned = b.bookingAmount.toString().replaceAll(',', '').replaceAll('Rs.', '').trim();
          agreementVal = _inr(double.tryParse(cleaned) ?? 0);
        } catch (_) {}
        return pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 0.5), borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(color: darkBrown, borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6))),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Booking ' + b.bookingId + '  .  Unit ' + b.unitNumber, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    pw.Text('Paid: ' + _inr(bPaid), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: gold)),
                  ],
                ),
              ),
              pw.Table(
                border: pw.TableBorder(horizontalInside: pw.BorderSide(color: const PdfColor.fromInt(0xFFE8E0D0), width: 0.5), verticalInside: pw.BorderSide(color: const PdfColor.fromInt(0xFFE8E0D0), width: 0.5)),
                columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
                children: [
                  pw.TableRow(children: [udCell('Tower / Floor', b.towerName + ' . Floor ' + b.floor), udCell('Flat type', b.flatType)]),
                  pw.TableRow(children: [udCell('Carpet area', b.carpetArea), udCell('Car parking', b.carParking)]),
                  pw.TableRow(children: [udCell('Agreement value', agreementVal), udCell('Booking stage', b.bookingStage)]),
                  pw.TableRow(children: [udCell('Booking date', _formatDate(b.bookingDate)), udCell('Balance due', _inr(bBalance), color: orangeTxt)]),
                ],
              ),
            ],
          ),
        );
      }

      pw.Widget subtotalBarDemand(String amountText) {
        return pw.Container(
          color: lightBg,
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 56, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text('Total demanded', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brown)))),
              pw.Expanded(flex: 14, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text(amountText, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brown)))),
              pw.Expanded(flex: 14, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text('--', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brown)))),
              pw.Expanded(flex: 16, child: pw.SizedBox()),
            ],
          ),
        );
      }

      pw.Widget subtotalBarReceipt(String label, String amountText) {
        return pw.Container(
          color: lightBg,
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 84, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brown)))),
              pw.Expanded(flex: 8, child: pw.SizedBox()),
              pw.Expanded(flex: 8, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text(amountText, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: brown)))),
            ],
          ),
        );
      }

      pw.Widget gsCell(String label, String val, String sub, {PdfColor? valColor, bool isLast = false}) {
        return pw.Expanded(
          child: pw.Container(
            decoration: isLast ? null : pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(color: borderColor, width: 0.5))),
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label, style: pw.TextStyle(fontSize: 8, color: greyLabel)),
                pw.SizedBox(height: 2),
                pw.Text(val, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: valColor ?? brown)),
                pw.SizedBox(height: 1),
                pw.Text(sub, style: pw.TextStyle(fontSize: 8, color: greySub)),
              ],
            ),
          ),
        );
      }

      final unitCards = <pw.Widget>[];
      for (int i = 0; i < allBookings.length; i += 2) {
        final rowItems = <pw.Widget>[pw.Expanded(child: unitCard(allBookings[i]))];
        if (i + 1 < allBookings.length) {
          rowItems.add(pw.SizedBox(width: 10));
          rowItems.add(pw.Expanded(child: unitCard(allBookings[i + 1])));
        } else {
          rowItems.add(pw.SizedBox(width: 10));
          rowItems.add(pw.Expanded(child: pw.SizedBox()));
        }
        unitCards.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: rowItems));
        unitCards.add(pw.SizedBox(height: 10));
      }

      final pdfDoc = pw.Document();

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          footer: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: const PdfColor.fromInt(0xFFDDDDDD), width: 1))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('System-generated document. No signature required. Support: 8879778560 . customercare@roswaltrealty.com', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                pw.Text('A.S HIGHTECH LLP MY HOME', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: gold)),
              ],
            ),
          ),
          build: (ctx) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Image(logoImage, width: 60, height: 60),
                    pw.SizedBox(height: 6),
                    pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('A.S HIGHTECH LLP', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.SizedBox(height: 2),
                    pw.Text('Roswalt Zaiden, Andheri West, Mumbai - 400053', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('CIN: U45200MH2010PTC208765  .  RERA: P51700049358', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
                  ]),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Cumulative Payment Ledger', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: brown)),
                    pw.SizedBox(height: 2),
                    pw.Text('Generated: ' + genDate, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    pw.Text('All bookings consolidated statement', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: brown, thickness: 1.4),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: lightBg, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(booking.clientName, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('Mobile: ' + booking.phone + '  .  Project: ' + booking.projectName, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(allBookings.length.toString() + ' active booking(s)', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: pw.BoxDecoration(color: brown, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Combined total paid', style: pw.TextStyle(fontSize: 8, color: PdfColors.white)),
                        pw.SizedBox(height: 2),
                        pw.Text(_inr(totalPaid), style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: gold)),
                        pw.SizedBox(height: 2),
                        pw.Text(allReceipts.length.toString() + ' receipts  .  ' + allBookings.length.toString() + ' units', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey300)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            ...unitCards,
            ...allBookings.expand<pw.Widget>((b) {
              final bR = List<Map<String, dynamic>>.from(allData[b.bookingId]?['receipts'] ?? []);
              final bD = List<Map<String, dynamic>>.from(allData[b.bookingId]?['demands'] ?? []);
              final bPaid = bR.fold<double>(0, (s, r) { try { return s + double.parse(r['totalAmount'].toString()); } catch(_) { return s; } });
              final bDemanded = bD.fold<double>(0, (s, d) { try { return s + double.parse(d['amount'].toString()); } catch(_) { return s; } });
              final bBalance = (bDemanded - bPaid).abs();

              return <pw.Widget>[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(color: darkBrown),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(b.bookingId + '  .  Demand schedule', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.Text('Unit ' + b.unitNumber + '  .  ' + b.towerName + '  .  Floor ' + b.floor, style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    decoration: pw.BoxDecoration(color: lightBg, border: pw.Border.all(color: borderColor, width: 0.6)),
                    child: pw.Row(
                      children: [
                        pw.Expanded(child: pw.Column(children: [pw.Text('Total demanded', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)), pw.SizedBox(height: 2), pw.Text(_inr(bDemanded), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brown))])),
                        pw.Expanded(child: pw.Column(children: [pw.Text('Total paid', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)), pw.SizedBox(height: 2), pw.Text(_inr(bPaid), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brown))])),
                        pw.Expanded(child: pw.Column(children: [pw.Text('Balance', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)), pw.SizedBox(height: 2), pw.Text(_inr(bBalance), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: orangeTxt))])),
                        pw.Expanded(child: pw.Column(children: [pw.Text('Milestones', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)), pw.SizedBox(height: 2), pw.Text(bD.length.toString(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brown))])),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  sectionLabel('DEMAND SCHEDULE'),
                  pw.Table(
                    columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1.2), 2: pw.FlexColumnWidth(1.2), 3: pw.FlexColumnWidth(1.0), 4: pw.FlexColumnWidth(1.4), 5: pw.FlexColumnWidth(1.4), 6: pw.FlexColumnWidth(1.6)},
                    children: [
                      headerRow(['Milestone name', 'Invoice date', 'Due date', 'Milestone no.', 'Amount', 'Tax', 'Status']),
                      ...bD.map((d) {
                        final isPaid = (d['status'] ?? '').toString().toLowerCase().contains('paid');
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: demandRowBg),
                          children: [
                            cellText((d['name'] ?? '--').toString()),
                            cellText(_formatDate(d['invoiceDate'])),
                            cellText(_formatDate(d['date'])),
                            cellText((d['demandNo'] ?? '--').toString()),
                            cellText(_inr(double.tryParse((d['netAmount'] ?? d['amount'] ?? '0').toString()) ?? 0), alignRight: true),
                            cellText(_inr(double.tryParse((d['tax'] ?? '0').toString()) ?? 0), alignRight: true),
                            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: badge((d['status'] ?? 'Due').toString(), isPaid))),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  subtotalBarDemand(_inr(bDemanded)),
                  pw.SizedBox(height: 10),
                  sectionLabel('RECEIPT REGISTER'),
                  pw.Table(
                    columnWidths: const {0: pw.FlexColumnWidth(1.0), 1: pw.FlexColumnWidth(1.1), 2: pw.FlexColumnWidth(1.1), 3: pw.FlexColumnWidth(1.6), 4: pw.FlexColumnWidth(1.0), 5: pw.FlexColumnWidth(2.0), 6: pw.FlexColumnWidth(1.4), 7: pw.FlexColumnWidth(0.8)},
                    children: [
                      headerRow(['Receipt no.', 'Receipt date', 'Payment date', 'Type', 'Method', 'Transaction ID', 'Status', 'Amount']),
                      ...bR.map((r) {
                        final amt = double.tryParse(r['totalAmount']?.toString() ?? '0') ?? 0;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: receiptRowBg),
                          children: [
                            cellText((r['milestoneName'] ?? r['receiptNumber'] ?? '--').toString(), color: greenTxt, bold: true),
                            cellText(_formatDate(r['receiptDate'])),
                            cellText(_formatDate(r['receiptDate'])),
                            cellText((r['receiptType'] ?? '--').toString()),
                            cellText((r['paymentMethod'] ?? '--').toString()),
                            cellText((r['transactionId'] ?? '--').toString()),
                            pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: badge((r['paymentStatus'] ?? 'Paid').toString(), true))),
                            cellText(_inr(amt), alignRight: true, bold: true),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  subtotalBarReceipt('Subtotal ' + b.bookingId, _inr(bPaid)),
                  pw.SizedBox(height: 16),
              ];
            }),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: brown, width: 1.2), borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: pw.BoxDecoration(color: brown, borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6))),
                    child: pw.Text('Grand total - all bookings', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                  pw.Row(
                    children: [
                      gsCell('Total demanded', _inr(totalDemanded), allBookings.length.toString() + ' units'),
                      gsCell('Total paid', _inr(totalPaid), allReceipts.length.toString() + ' receipts', valColor: greenTxt),
                      gsCell('Balance due', _inr(balance), 'outstanding', valColor: orangeTxt),
                      gsCell('Last payment', _inr(lastPaymentAmt), lastPaymentDate, isLast: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final bytes = await pdfDoc.save();
      await Printing.sharePdf(bytes: bytes, filename: 'roswalt_ledger_' + booking.bookingId + '.pdf');
    } catch (e, st) {
      debugPrint('Ledger PDF error: ' + e.toString());
      debugPrint(st.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ' + e.toString()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}



