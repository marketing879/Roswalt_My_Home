import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'phone_verification_screen.dart';
import '../partner/partner_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _gold = Color(0xFFD4AF37);

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/login_bg.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);
      _videoController!.play();
      if (mounted) setState(() {});
    } catch (e) { debugPrint('Video error: $e'); }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showCPLoginDialog() {
    final mahaReraCtrl = TextEditingController();
    String? error;
    bool loading = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A0A00), Color(0xFF2D1200), Color(0xFF1A0A00)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3))),
                  child: const Icon(Icons.handshake_outlined, color: Color(0xFFD4AF37), size: 22)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Channel Partner Login',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Access your CP dashboard',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.15))),
                child: TextField(
                  controller: mahaReraCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'MahaRERA Registration No.',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFD4AF37), size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                  ])),
              ],
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFF8B6914)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4))]),
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (mahaReraCtrl.text.trim().isEmpty) {
                      setModal(() => error = 'Please enter your MahaRERA number');
                      return;
                    }
                    setModal(() { loading = true; error = null; });
                    final provider = Provider.of<BookingProvider>(context, listen: false);
                    final ok = await provider.loginCPWithMahaRERA(mahaReraCtrl.text.trim());
                    if (!ok) {
                      setModal(() {
                        loading = false;
                        error = provider.cpLoginError ?? 'MahaRERA number not found. Please check and try again.';
                      });
                      return;
                    }
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const PartnerShell()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('LOGIN AS CHANNEL PARTNER',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
                              fontSize: 14, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _accountTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withOpacity(0.35))),
            child: Icon(icon, color: _gold, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.4), size: 14),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(fit: StackFit.expand,
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
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)])))),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.5))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Image.asset('assets/images/roswalt_logo.png',
                  width: 130, height: 130, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.home_work_outlined, color: _gold, size: 60)),
                const SizedBox(height: 8),
                Text('MY HOME', style: GoogleFonts.playfairDisplay(
                    fontSize: 18, color: _gold, letterSpacing: 6, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Text(_greeting, style: GoogleFonts.playfairDisplay(
                    fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Select your account type to continue',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 28),
                _accountTypeCard(
                  icon: Icons.badge_outlined,
                  title: 'Employee',
                  subtitle: 'Roswalt Realty staff login',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const PhoneVerificationScreen(accountType: AccountType.employee))),
                ),
                _accountTypeCard(
                  icon: Icons.home_work_outlined,
                  title: 'Client',
                  subtitle: 'Access your property & booking',
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const PhoneVerificationScreen(accountType: AccountType.client))),
                ),
                _accountTypeCard(
                  icon: Icons.handshake_outlined,
                  title: 'Channel Partner',
                  subtitle: 'Access your CP dashboard',
                  onTap: _showCPLoginDialog,
                ),
                const SizedBox(height: 20),
                Text('© 2026 Roswalt Realty',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
