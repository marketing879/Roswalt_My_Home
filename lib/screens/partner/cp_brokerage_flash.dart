import 'package:flutter/material.dart';
import '../../services/ticket_api_service.dart';
import 'cp_payouts_screen.dart' show CPSubmitInvoiceScreen;

const _gold = Color(0xFFD4AF37);

/// Shows the brokerage-confirmation flash (per "Brokerage Confirmation Flash"
/// spec) for every pending (needsAck) claim in [claims], one after another.
/// Call this whenever the CP opens the dashboard or Payouts, or pulls to
/// refresh Payouts. Each flash can't be dismissed by tapping outside -
/// "Later" just closes it until the next time this is called.
Future<void> showPendingBrokerageFlashes(
  BuildContext context,
  List<Map<String, dynamic>> claims, {
  required String mahaRera,
  VoidCallback? onChanged,
}) async {
  final pending = claims.where((c) => c['needsAck'] == true).toList();
  for (final claim in pending) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CpBrokerageFlash(claim: claim, mahaRera: mahaRera, onChanged: onChanged),
    );
  }
}

/// The flash itself: "Brokerage confirmed" (pending) -> "Acknowledged" (after
/// the CP taps acknowledge), matching the two states in the spec's mockups.
class CpBrokerageFlash extends StatefulWidget {
  final Map<String, dynamic> claim;
  final String mahaRera;
  final VoidCallback? onChanged;
  const CpBrokerageFlash({super.key, required this.claim, required this.mahaRera, this.onChanged});

  @override
  State<CpBrokerageFlash> createState() => _CpBrokerageFlashState();
}

class _CpBrokerageFlashState extends State<CpBrokerageFlash> {
  bool _acknowledging = false;
  bool _acknowledged = false;
  String? _error;

  String get _amount => (widget.claim['amount'] ?? widget.claim['approvedAmount'] ?? '--').toString();
  String get _bookingId => (widget.claim['bookingId'] ?? '--').toString();
  String get _unitNo => (widget.claim['unitNo'] ?? '--').toString();
  String get _clientName => (widget.claim['clientName'] ?? widget.claim['name'] ?? '--').toString();
  String get _project => (widget.claim['project'] ?? '--').toString();
  String get _confirmedByName => (widget.claim['confirmedByName'] ?? '--').toString();
  num? get _brokeragePct => widget.claim['brokeragePct'] is num ? widget.claim['brokeragePct'] as num : null;

  String _fmtDate(dynamic iso) {
    if (iso == null) return '--';
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso.toString();
    }
  }

  Future<void> _acknowledge() async {
    setState(() { _acknowledging = true; _error = null; });
    try {
      await TicketApiService.instance.acknowledgeChannelPartnerInvoice(
        claimId: (widget.claim['id'] ?? '').toString(),
        mahaRera: widget.mahaRera,
      );
      if (!mounted) return;
      setState(() { _acknowledging = false; _acknowledged = true; });
      widget.onChanged?.call();
    } on TicketApiException catch (e) {
      if (!mounted) return;
      setState(() { _acknowledging = false; _error = e.message; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _acknowledging = false; _error = 'Could not acknowledge: $e'; });
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // The CP can't dismiss this by the back button either - only
      // "I acknowledge this amount" or "Later" closes it, per spec section 3.
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF3A2509), Color(0xFF1A0A00)]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _gold.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_acknowledged ? Colors.green : _gold).withOpacity(0.15),
                  border: Border.all(color: (_acknowledged ? Colors.greenAccent : _gold).withOpacity(0.5), width: 2),
                ),
                child: Icon(Icons.check, color: _acknowledged ? Colors.greenAccent : _gold, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                _acknowledged ? 'Acknowledged' : 'Brokerage confirmed',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _acknowledged ? 'You can now raise your invoice.' : 'Please review and acknowledge',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 18),
              Text('AMOUNT CONFIRMED',
                  style: TextStyle(color: _gold.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text('₹$_amount', style: const TextStyle(color: _gold, fontSize: 30, fontWeight: FontWeight.bold)),
              if (_brokeragePct != null) ...[
                const SizedBox(height: 2),
                Text('$_brokeragePct% brokerage', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  _detailRow('Booking', _bookingId),
                  _detailRow('Unit', _unitNo),
                  _detailRow('Client', _clientName),
                  if (!_acknowledged) _detailRow('Project', _project),
                ]),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirmed by $_confirmedByName (PACO) on ${_fmtDate(widget.claim['confirmedAt'])}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 18),
              if (!_acknowledged) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _acknowledging ? null : _acknowledge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xFF1A0A00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _acknowledging
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A0A00)))
                        : const Text('I acknowledge this amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Later', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CPSubmitInvoiceScreen(
                        claimId: (widget.claim['id'] ?? '').toString(),
                        prefillMahaRera: widget.mahaRera,
                        prefillBookingId: _bookingId,
                        prefillClientName: _clientName,
                        prefillAmount: _amount,
                      )));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: const Color(0xFF1A0A00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Raise invoice now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
