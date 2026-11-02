import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

/// For a Sourcing Manager: every CP walk-in tagged to them
/// (cpWalkIns.smEmployeeId == their own employeeId), via the
/// listMyTaggedWalkIns callable. Mirrors "My Team" for Field Duty.
class EmployeeTaggedLeadsScreen extends StatefulWidget {
  const EmployeeTaggedLeadsScreen({super.key});
  @override
  State<EmployeeTaggedLeadsScreen> createState() => _EmployeeTaggedLeadsScreenState();
}

class _EmployeeTaggedLeadsScreenState extends State<EmployeeTaggedLeadsScreen> {
  List<Map<String, dynamic>> _walkIns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('listMyTaggedWalkIns').call();
      final list = (result.data['walkIns'] as List).cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      if (!mounted) return;
      setState(() { _walkIns = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Hot': return Colors.red;
      case 'Warm': return Colors.orange;
      case 'Cold': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Tagged Leads', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _bronze))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, size: 44, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400], fontSize: 12))),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _walkIns.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.local_offer_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No leads tagged to you yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _walkIns.length,
                        itemBuilder: (_, i) {
                          final w = _walkIns[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _gold.withOpacity(0.15))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(w['clientName'] as String? ?? 'Unknown client',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1A0A00)))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: _statusColor(w['status'] as String?).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(w['status'] as String? ?? '', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                                        color: _statusColor(w['status'] as String?)))),
                              ]),
                              const SizedBox(height: 6),
                              Text('${w['project'] ?? ''} · ${w['configuration'] ?? ''}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
                              if ((w['clientPhone'] as String?)?.isNotEmpty ?? false)
                                Text(w['clientPhone'] as String, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white38 : Colors.grey[500])),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.business_outlined, size: 13, color: isDark ? Colors.white38 : Colors.grey[500]),
                                const SizedBox(width: 5),
                                Expanded(child: Text('${w['cpName'] ?? ''} · ${w['cpFirm'] ?? ''}',
                                    style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white38 : Colors.grey[500]))),
                              ]),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}
