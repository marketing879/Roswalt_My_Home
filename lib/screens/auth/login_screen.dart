import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:local_auth/local_auth.dart';
import '../client/client_shell.dart';
import '../auth/booking_lookup_screen.dart';
import '../partner/partner_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  int _loginMode = 0;
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
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
    _emailController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _loginWithEmail() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => BookingLookupScreen(email: _emailController.text.trim())));
  }

  Future<void> _loginWithBiometric() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) {
        setState(() { _isLoading = false; _errorMessage = 'Biometric not available.'; });
        return;
      }
      final didAuth = await auth.authenticate(
        localizedReason: 'Authenticate to access Roswalt My Home',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (didAuth) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const BookingLookupScreen()));
      } else {
        setState(() => _errorMessage = 'Authentication failed.');
      }
    } catch (e) {
      if (e is PlatformException) {
        String friendly;
        bool fallbackToEmail = false;
        switch (e.code) {
          case 'NotAvailable':
          case 'NotEnrolled':
            friendly = 'Fingerprint is not set up on this device. Please use Email login instead.';
            fallbackToEmail = true;
            break;
          case 'PasscodeNotSet':
            friendly = 'Please set a screen lock (PIN/pattern) on your device to use biometric login, or use Email login instead.';
            fallbackToEmail = true;
            break;
          case 'LockedOut':
            friendly = 'Too many failed attempts. Please try again in a moment or use Email login.';
            break;
          case 'PermanentlyLockedOut':
            friendly = 'Biometric login is locked. Please unlock your device with your PIN/pattern first, or use Email login.';
            fallbackToEmail = true;
            break;
          default:
            friendly = 'Could not verify biometrics. Please use Email login instead.';
        }
        setState(() {
          _isLoading = false;
          _errorMessage = friendly;
          if (fallbackToEmail) _loginMode = 0;
        });
      } else {
        setState(() { _isLoading = false; _errorMessage = 'Something went wrong. Please use Email login instead.'; });
      }
    }
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
  Widget _modeTab(int index, IconData icon, String label) {
    final isActive = _loginMode == index;
    return GestureDetector(
      onTap: () => setState(() { _loginMode = index; _errorMessage = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _gold.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? _gold.withOpacity(0.6) : Colors.white.withOpacity(0.15))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: isActive ? _gold : Colors.white60),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: isActive ? _gold : Colors.white60)),
        ]),
      ),
    );
  }

  Widget _inputField({
    required String label, required String hint,
    required TextEditingController controller, required IconData icon,
    bool obscure = false, Widget? suffix,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25))),
        child: TextField(
          controller: controller, obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            prefixIcon: Icon(icon, color: _gold, size: 20),
            suffix: suffix, border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
      ),
    ]);
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
                Text('Sign in to access your property dashboard',
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
                        blurRadius: 24, offset: const Offset(0, 8))]),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        _modeTab(0, Icons.email_outlined, 'Email'),
                        _modeTab(1, Icons.fingerprint, 'Biometric'),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    if (_loginMode == 0) ...[
                      _inputField(label: 'Email Address', hint: 'Enter your email',
                        controller: _emailController, icon: Icons.email_outlined),
                    ],
                    if (_loginMode == 1) ...[
                      const SizedBox(height: 20),
                      Container(width: 100, height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: _gold.withOpacity(0.1),
                          border: Border.all(color: _gold.withOpacity(0.3), width: 2)),
                        child: Icon(Icons.fingerprint, color: _gold, size: 52)),
                      const SizedBox(height: 16),
                      Text('Touch the fingerprint sensor',
                          style: TextStyle(color: Colors.white60, fontSize: 14)),
                      const SizedBox(height: 20),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.4))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                        ])),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_gold, const Color(0xFF8B6914)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _gold.withOpacity(0.35),
                            blurRadius: 16, offset: const Offset(0, 6))]),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          if (_loginMode == 0) _loginWithEmail();
                          else _loginWithBiometric();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text(_loginMode == 0 ? 'SIGN IN' : 'AUTHENTICATE',
                                style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.5)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _showCPLoginDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF1A0800), Color(0xFF2D1200), Color(0xFF1A0800)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                      boxShadow: [BoxShadow(color: _gold.withOpacity(0.2),
                          blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.handshake_outlined, color: Color(0xFFE8E0D0), size: 18),
                      const SizedBox(width: 8),
                      const Text('LOGIN AS CHANNEL PARTNER',
                          style: TextStyle(color: Color(0xFFE8E0D0),
                              fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2)),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
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
