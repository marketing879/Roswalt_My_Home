import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

class EmployeeBankDetailsScreen extends StatefulWidget {
  const EmployeeBankDetailsScreen({super.key});
  @override
  State<EmployeeBankDetailsScreen> createState() => _EmployeeBankDetailsScreenState();
}

class _EmployeeBankDetailsScreenState extends State<EmployeeBankDetailsScreen> {
  late final TextEditingController _holderCtrl;
  late final TextEditingController _bankCtrl;
  late final TextEditingController _accountCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _branchCtrl;
  late final TextEditingController _upiCtrl;
  bool _saving = false;
  bool _revealAccount = false;

  @override
  void initState() {
    super.initState();
    final attendance = Provider.of<EmployeeAttendanceProvider>(context, listen: false);
    _holderCtrl = TextEditingController(text: attendance.accountHolderName);
    _bankCtrl = TextEditingController(text: attendance.bankName);
    _accountCtrl = TextEditingController(text: attendance.accountNumber);
    _ifscCtrl = TextEditingController(text: attendance.ifscCode);
    _branchCtrl = TextEditingController(text: attendance.branchName);
    _upiCtrl = TextEditingController(text: attendance.upiId);
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Provider.of<EmployeeAttendanceProvider>(context, listen: false).saveBankDetails(
      accountHolderName: _holderCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      accountNumber: _accountCtrl.text.trim(),
      ifscCode: _ifscCtrl.text.trim().toUpperCase(),
      branchName: _branchCtrl.text.trim(),
      upiId: _upiCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details saved.'), backgroundColor: _bronze));
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
        title: const Text('Bank Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: _gold.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.lock_outline, size: 16, color: _bronze),
              const SizedBox(width: 8),
              Expanded(child: Text('Only you can view your bank details — used for payroll processing.',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.grey[700]))),
            ]),
          ),
          _field(isDark, cardBg, 'Account Holder Name', _holderCtrl, icon: Icons.person_outline),
          const SizedBox(height: 16),
          _field(isDark, cardBg, 'Bank Name', _bankCtrl, icon: Icons.account_balance_outlined),
          const SizedBox(height: 16),
          _label(isDark, 'Account Number'),
          TextField(
            controller: _accountCtrl,
            obscureText: !_revealAccount,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A0A00), fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card_outlined, size: 18, color: _bronze),
              suffixIcon: IconButton(
                icon: Icon(_revealAccount ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _bronze),
                onPressed: () => setState(() => _revealAccount = !_revealAccount),
              ),
              filled: true, fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          _field(isDark, cardBg, 'IFSC Code', _ifscCtrl, icon: Icons.qr_code_outlined),
          const SizedBox(height: 16),
          _field(isDark, cardBg, 'Branch Name', _branchCtrl, icon: Icons.location_city_outlined),
          const SizedBox(height: 16),
          _field(isDark, cardBg, 'UPI ID (Optional)', _upiCtrl, icon: Icons.qr_code_2_outlined),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _bronze, padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Save Details', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(bool isDark, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[700])));

  Widget _field(bool isDark, Color cardBg, String label, TextEditingController controller,
      {required IconData icon, TextInputType? keyboard}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(isDark, label),
      TextField(
        controller: controller,
        keyboardType: keyboard,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A0A00), fontSize: 13),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: _bronze),
          filled: true, fillColor: cardBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    ]);
  }
}
