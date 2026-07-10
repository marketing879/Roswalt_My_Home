
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../client/client_shell.dart';
import '../tenant/tenant_shell.dart';
import 'login_screen.dart';
import '../splash/splash_screen.dart';

class SessionWrapper extends StatefulWidget {
  const SessionWrapper({super.key});
  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  bool _checking = true;

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
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SplashScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
  }
}
