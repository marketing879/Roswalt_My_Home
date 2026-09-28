
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/otp_email_service.dart';
import '../client/client_shell.dart';
import '../tenant/tenant_shell.dart';
import '../employee/employee_shell.dart';
import '../splash/splash_screen.dart';

class SessionWrapper extends StatefulWidget {
  const SessionWrapper({super.key});
  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final restored = await provider.restoreSession();
    if (!mounted) return;
    if (restored && provider.selectedBooking != null) {
      final booking = provider.selectedBooking!;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) =>
              booking.customerType == 'Tenant'
                  ? const TenantShell()
                  : const ClientShell()));
      return;
    }

    await OtpEmailService.instance.restoreCachedEmail();
    if (!mounted) return;
    final employeeName = OtpEmailService.instance.cachedEmployeeName;
    if (OtpEmailService.instance.isVerified && employeeName != null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => EmployeeShell(
              employeeName: employeeName,
              employeeId: OtpEmailService.instance.cachedEmployeeId,
              designation: OtpEmailService.instance.cachedEmployeeDesignation)));
      return;
    }

    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const SplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
  }
}
