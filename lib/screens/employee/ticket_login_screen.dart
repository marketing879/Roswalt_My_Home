import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/otp_email_service.dart';
import '../../services/ticket_api_service.dart';
import '../../widgets/synergy_logo.dart';

const _navy = Color(0xFF0B1E3D);
const _gold = Color(0xFFD4AF37);

/// One-time bridge login into the separate Sales-App backend that also
/// backs My Team's org-chart lookup. The employee's @roswalt.com email is
/// already known from the My Home session (OtpEmailService), so this only
/// ever asks for the OTP digits — never re-collects the email.
class TicketLoginScreen extends StatefulWidget {
  /// Kept for call-site compatibility; login always just pops back to the
  /// caller on success now that the Tickets flow has been removed.
  final bool popOnSuccess;
  const TicketLoginScreen({super.key, this.popOnSuccess = false});
  @override
  State<TicketLoginScreen> createState() => _TicketLoginScreenState();
}

class _TicketLoginScreenState extends State<TicketLoginScreen> {
  final _otpController = TextEditingController();
  String? _email;
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = OtpEmailService.instance.verifiedEmail;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email == null || _email!.isEmpty) {
      setState(() => _error = 'Could not detect your employee email. Please log out and sign back in.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<TicketProvider>().requestOtp(_email!);
      if (mounted) setState(() => _codeSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().length < 4) {
      setState(() => _error = 'Enter the code sent to your email.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await context.read<TicketProvider>().verifyOtp(_otpController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on TicketApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_navy, Color(0xFF14315C)])),
        ),
        SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: _gold.withOpacity(0.25), blurRadius: 28, spreadRadius: 2)],
                ),
                child: const SynergyLogo(width: 150),
              ),
              const SizedBox(height: 16),
              Text('Sales App Login', style: GoogleFonts.playfairDisplay(color: _gold, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Verify your email to view your org chart',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.mail_outline, color: _gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_email ?? 'unknown', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                  ]),
                  const SizedBox(height: 18),
                  if (_sending)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _gold)),
                        SizedBox(width: 10),
                        Text('Sending verification code…', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                    )
                  else if (_codeSent) ...[
                    Text('Enter the 6-digit code sent to your email', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        hintText: '••••••',
                        hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold, foregroundColor: _navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _verifying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _navy))
                            : const Text('Verify & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _sending ? null : _sendCode,
                      child: const Text('Resend code', style: TextStyle(color: _gold, fontSize: 12.5)),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: Colors.red[300], fontSize: 12.5)),
                  ],
                ]),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
        ),
      ]),
    );
  }
}
