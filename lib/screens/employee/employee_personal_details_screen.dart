import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

class EmployeePersonalDetailsScreen extends StatefulWidget {
  const EmployeePersonalDetailsScreen({super.key});
  @override
  State<EmployeePersonalDetailsScreen> createState() => _EmployeePersonalDetailsScreenState();
}

class _EmployeePersonalDetailsScreenState extends State<EmployeePersonalDetailsScreen> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;
  String? _bloodGroup;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final attendance = Provider.of<EmployeeAttendanceProvider>(context, listen: false);
    _phoneCtrl = TextEditingController(text: attendance.personalPhone);
    _emailCtrl = TextEditingController(text: attendance.personalEmail);
    _dobCtrl = TextEditingController(text: attendance.dateOfBirth);
    _addressCtrl = TextEditingController(text: attendance.address);
    _emergencyNameCtrl = TextEditingController(text: attendance.emergencyContactName);
    _emergencyPhoneCtrl = TextEditingController(text: attendance.emergencyContactPhone);
    _bloodGroup = attendance.bloodGroup.isNotEmpty ? attendance.bloodGroup : null;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: now,
    );
    if (picked != null) {
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      setState(() => _dobCtrl.text = '${picked.day} ${months[picked.month - 1]} ${picked.year}');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Provider.of<EmployeeAttendanceProvider>(context, listen: false).savePersonalDetails(
      phone: _phoneCtrl.text.trim(),
      personalEmail: _emailCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      bloodGroup: _bloodGroup ?? '',
      address: _addressCtrl.text.trim(),
      emergencyContactName: _emergencyNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal details saved.'), backgroundColor: _bronze));
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
        title: const Text('Personal Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _field(isDark, cardBg, 'Phone Number', _phoneCtrl, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
          const SizedBox(height: 16),
          _field(isDark, cardBg, 'Personal Email', _emailCtrl, icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label(isDark, 'Date of Birth'),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.cake_outlined, size: 18, color: _bronze),
                const SizedBox(width: 10),
                Expanded(child: Text(_dobCtrl.text.isEmpty ? 'Select date of birth' : _dobCtrl.text,
                    style: TextStyle(fontSize: 13, color: _dobCtrl.text.isEmpty ? Colors.grey[400] : (isDark ? Colors.white : const Color(0xFF1A0A00))))),
                const Icon(Icons.calendar_today_outlined, size: 16, color: _bronze),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _label(isDark, 'Blood Group'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.2))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _bloodGroup,
                isExpanded: true,
                hint: Text('Select blood group', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _bronze),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A0A00)),
                dropdownColor: cardBg,
                items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _bloodGroup = v),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label(isDark, 'Address'),
          TextField(
            controller: _addressCtrl,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A0A00), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Current residential address',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true, fillColor: cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 24),
          Text('Emergency Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A0A00))),
          const SizedBox(height: 12),
          _field(isDark, cardBg, 'Contact Name', _emergencyNameCtrl, icon: Icons.person_outline),
          const SizedBox(height: 16),
          _field(isDark, cardBg, 'Contact Phone', _emergencyPhoneCtrl, icon: Icons.phone_outlined, keyboard: TextInputType.phone),
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
