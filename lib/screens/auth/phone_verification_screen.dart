import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../providers/booking_provider.dart';
import '../../services/otp_email_service.dart';
import '../client/client_shell.dart';
import '../tenant/tenant_shell.dart';
import '../employee/employee_shell.dart';
import 'booking_selection_screen.dart';

enum AccountType { employee, client }

enum _Step { phone, confirm, otp, success }

String maskId(String id) {
  final trimmed = id.trim();
  if (trimmed.length <= 4) return trimmed;
  return '${trimmed.substring(0, 2)}${'*' * (trimmed.length - 4)}${trimmed.substring(trimmed.length - 2)}';
}

String maskEmail(String email) {
  final i = email.indexOf('@');
  if (i <= 0) return email;
  final local = email.substring(0, i);
  final domain = email.substring(i);
  if (local.length <= 2) return '${local[0]}***$domain';
  return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}$domain';
}

class PhoneVerificationScreen extends StatefulWidget {
  final AccountType accountType;
  const PhoneVerificationScreen({super.key, required this.accountType});
  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  static const _gold = Color(0xFFD4AF37);

  _Step _step = _Step.phone;
  bool _isLoading = false;
  String? _errorMessage;
  VideoPlayerController? _videoController;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String _displayId = '';
  String _maskedId = '';
  String _realEmail = '';
  String _realName = '';
  String _designation = '';

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/booking_bg.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);
      _videoController!.play();
      if (mounted) setState(() {});
    } catch (e) { debugPrint('Video error: $e'); }
  }

  bool get _isEmployee => widget.accountType == AccountType.employee;

  Future<void> _lookupAccount() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile number');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    final provider = Provider.of<BookingProvider>(context, listen: false);

    if (_isEmployee) {
      final employee = await provider.lookupEmployeeByPhone(raw);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (employee == null) {
        setState(() => _errorMessage = provider.error ?? 'No employee record found for this number.');
        return;
      }
      final name = (employee['name'] as String?) ?? 'Employee';
      final email = (employee['email'] as String?) ?? '';
      final employeeId = (employee['employeeId'] as String?) ?? '';
      final designation = (employee['designation'] as String?) ?? '';
      if (email.isEmpty) {
        setState(() => _errorMessage = 'No email on file for this employee. Please contact support.');
        return;
      }
      setState(() {
        _realName = name;
        _realEmail = email;
        _displayId = employeeId;
        _maskedId = maskId(employeeId);
        _designation = designation;
        _step = _Step.confirm;
      });
      return;
    }

    // Client: same defensive multi-number handling the old lookup screen used
    // (some SFDC records store multiple numbers together, e.g. "98.../91...").
    final candidates = raw
        .split(RegExp(r'[\/,;|]'))
        .map((s) => s.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((s) => s.isNotEmpty)
        .map((s) => s.length > 25 ? s.substring(s.length - 25) : s)
        .toSet()
        .toList();
    final inputsToTry = candidates.isNotEmpty ? candidates : [raw];

    bool success = false;
    for (final candidate in inputsToTry) {
      success = await provider.fetchBookingsByPhone(candidate);
      if (success) break;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!success) {
      setState(() => _errorMessage = provider.error ?? 'No booking found for this number.');
      return;
    }
    final booking = provider.selectedBooking ?? provider.allBookings.first;
    if (booking.email.isEmpty) {
      setState(() => _errorMessage = 'No email on file for this booking. Please contact support.');
      return;
    }
    setState(() {
      _realName = booking.clientName;
      _realEmail = booking.email;
      _displayId = booking.bookingId;
      _maskedId = maskId(booking.bookingId);
      _step = _Step.confirm;
    });
  }

  void _confirmNo() {
    Provider.of<BookingProvider>(context, listen: false).clearBooking();
    setState(() {
      _step = _Step.phone;
      _phoneController.clear();
      _otpController.clear();
      _maskedId = '';
      _displayId = '';
      _realEmail = '';
      _realName = '';
      _errorMessage = null;
    });
  }

  Future<void> _sendOtp() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await OtpEmailService.instance.sendCode(_realEmail);
      if (!mounted) return;
      setState(() { _isLoading = false; _step = _Step.otp; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the code sent to your email');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await OtpEmailService.instance.verifyCode(_realEmail, code);
      if (!mounted) return;
      setState(() { _isLoading = false; _step = _Step.success; });
      _proceedAfterSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  Future<void> _proceedAfterSuccess() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (_isEmployee) {
      await OtpEmailService.instance.cacheEmployeeProfile(_realName, _displayId, _designation);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => EmployeeShell(employeeName: _realName, employeeId: _displayId, designation: _designation)));
      return;
    }
    final provider = Provider.of<BookingProvider>(context, listen: false);
    await provider.persistSession();
    if (!mounted) return;
    if (provider.allBookings.length == 1) {
      final booking = provider.allBookings.first;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) =>
              booking.customerType == 'Tenant' ? const TenantShell() : const ClientShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BookingSelectionScreen()));
    }
  }

  Widget _errorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.4))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 14),
          const SizedBox(width: 8),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_gold, const Color(0xFF8B6914)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _gold.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _cardContent(bool isDark) {
    switch (_step) {
      case _Step.phone:
        return Column(children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2))),
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: const Icon(Icons.phone_outlined, color: _gold, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
          _errorBanner(),
          const SizedBox(height: 20),
          _primaryButton('LOOK UP ACCOUNT', _lookupAccount),
        ]);

      case _Step.confirm:
        return Column(children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: _gold.withOpacity(0.12),
              border: Border.all(color: _gold.withOpacity(0.4), width: 2)),
            child: const Icon(Icons.person, color: _gold, size: 36)),
          const SizedBox(height: 16),
          Text(_realName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_isEmployee ? 'Employee ID: $_maskedId' : 'Booking ID: $_maskedId',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          const SizedBox(height: 16),
          const Text('Is this you?', style: TextStyle(color: Colors.white70, fontSize: 14)),
          _errorBanner(),
          const SizedBox(height: 20),
          _primaryButton('YES, THIS IS ME', _sendOtp),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading ? null : _confirmNo,
            child: Text('No, use a different number', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12))),
        ]);

      case _Step.otp:
        return Column(children: [
          Icon(Icons.mark_email_read_outlined, color: _gold, size: 44),
          const SizedBox(height: 12),
          Text('We sent a code to ${maskEmail(_realEmail)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2))),
            child: TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 6),
              decoration: const InputDecoration(
                hintText: '------',
                hintStyle: TextStyle(color: Colors.white30, letterSpacing: 6),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
          _errorBanner(),
          const SizedBox(height: 20),
          _primaryButton('VERIFY', _verifyOtp),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: Text('Resend code', style: TextStyle(color: _gold.withOpacity(0.8), fontSize: 12))),
        ]);

      case _Step.success:
        return Column(children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.15),
                border: Border.all(color: Colors.greenAccent, width: 2)),
            child: const Icon(Icons.check, color: Colors.greenAccent, size: 40)),
          const SizedBox(height: 16),
          const Text('Welcome to Roswalt Realty, My Home',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ]);
    }
  }

  String get _title {
    switch (_step) {
      case _Step.phone: return _isEmployee ? 'Employee Login' : 'Find Your Booking';
      case _Step.confirm: return 'Confirm Identity';
      case _Step.otp: return 'Enter Verification Code';
      case _Step.success: return 'Success';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _Step.phone: return 'Enter your registered mobile number';
      case _Step.confirm: return 'Please confirm your identity to continue';
      case _Step.otp: return '6-digit code';
      case _Step.success: return 'Login complete';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!))))
          else
            Positioned.fill(child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)])))),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.55))),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/roswalt_logo.png',
                      width: 100, height: 100, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.home_work_outlined, color: _gold, size: 50)),
                    const SizedBox(height: 8),
                    Text('MY HOME', style: GoogleFonts.playfairDisplay(
                        fontSize: 16, color: _gold, letterSpacing: 6, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    Text(_title,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(_subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.15))),
                      child: _cardContent(Theme.of(context).brightness == Brightness.dark),
                    ),
                    if (_step != _Step.success) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('← Back to Login',
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))),
                    ],
                    const SizedBox(height: 16),
                    Text('© 2026 Roswalt Realty',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
