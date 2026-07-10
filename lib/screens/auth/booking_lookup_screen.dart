import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../providers/booking_provider.dart';
import '../client/client_shell.dart';
import '../tenant/tenant_shell.dart';
import 'booking_selection_screen.dart';
import 'login_screen.dart';

class BookingLookupScreen extends StatefulWidget {
  final String? email;
  final String? unitNo;
  const BookingLookupScreen({super.key, this.email, this.unitNo});
  @override
  State<BookingLookupScreen> createState() => _BookingLookupScreenState();
}

class _BookingLookupScreenState extends State<BookingLookupScreen> {
  static const _gold = Color(0xFFD4AF37);
  bool _isLoading = false;
  String? _errorMessage;
  final _phoneController = TextEditingController();
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initVideo();
    if (widget.unitNo != null && widget.unitNo!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _phoneController.text = widget.unitNo!;
        _fetchBookings();
      });
    } else if (widget.email != null && widget.email!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() => _isLoading = true);
        final provider = Provider.of<BookingProvider>(context, listen: false);
        final phones = await provider.fetchPhonesByEmail(widget.email!);
        setState(() => _isLoading = false);
        if (phones.isNotEmpty) {
          _phoneController.text = phones.first;
          _fetchBookings();
        } else {
          setState(() => _errorMessage = 'No account found for this email. Please enter your mobile number.');
        }
      });
    }
  }
  @override
  void dispose() {
    _videoController?.dispose();
    _phoneController.dispose();
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
    } catch (e) { debugPrint('Video error: ' + e.toString()); }
  }

  Widget _testChip(String number) {
    return GestureDetector(
      onTap: () { _phoneController.text = number; _fetchBookings(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2))),
        child: Text(number, style: const TextStyle(color: Colors.white70, fontSize: 11))));
  }

  Future<void> _fetchBookings() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Please enter your mobile number');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    final provider = Provider.of<BookingProvider>(context, listen: false);

    // Defensive handling: some records have multiple numbers entered together
    // (e.g. "9876543210/9123456789"). Split on common delimiters, clean each
    // candidate to digits only, and try each one until a match is found.
    final candidates = raw
        .split(RegExp(r'[\/,;|]'))
        .map((s) => s.replaceAll(RegExp(r'[^0-9]'), ''))
        .where((s) => s.length >= 10)
        .map((s) => s.length > 10 ? s.substring(s.length - 10) : s)
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
    if (success) {
      await provider.persistSession();
      if (provider.allBookings.length == 1) {
        final booking = provider.allBookings.first;
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) =>
                booking.customerType == 'Tenant'
                    ? const TenantShell()
                    : const ClientShell()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const BookingSelectionScreen()));
      }
    } else {
      setState(() => _errorMessage = provider.error ?? 'Something went wrong');
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
                    Text('Find Your Booking',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Enter your registered mobile number',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.15))),
                      child: Column(children: [
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
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.4))),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                            ])),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_gold, Color(0xFF8B6914)]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: _gold.withOpacity(0.35),
                                blurRadius: 16, offset: const Offset(0, 6))]),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _fetchBookings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('FIND MY BOOKING',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.5)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Text('← Back to Login',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))),
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
