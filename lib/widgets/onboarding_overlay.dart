
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingOverlay extends StatefulWidget {
  final Widget child;
  const OnboardingOverlay({super.key, required this.child});
  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  bool _showOverlay = false;
  int _currentStep = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final steps = [
    {
      'title': 'Welcome to Roswalt My Home!',
      'desc': 'Your personal property dashboard. Let us show you around.',
      'icon': Icons.home_work_outlined,
      'position': 'center',
      'highlight': null,
    },
    {
      'title': 'Your Property',
      'desc': 'View your booking details, unit info and project status right here.',
      'icon': Icons.apartment_outlined,
      'position': 'top',
      'highlight': 'property',
    },
    {
      'title': 'Quick Actions',
      'desc': 'Access Construction Updates, Documents and more with one tap.',
      'icon': Icons.grid_view_outlined,
      'position': 'middle',
      'highlight': 'actions',
    },
    {
      'title': 'Bottom Navigation',
      'desc': 'Switch between Home, Documents, Payments and Assistance tabs.',
      'icon': Icons.navigation_outlined,
      'position': 'bottom',
      'highlight': 'nav',
    },
    {
      'title': 'Drawer Menu',
      'desc': 'Tap the hamburger menu ☰ to access My Property, Settings and more.',
      'icon': Icons.menu_outlined,
      'position': 'top',
      'highlight': 'drawer',
    },
    {
      'title': 'Payment Reminder',
      'desc': 'Stay on top of your payment milestones with instant alerts.',
      'icon': Icons.notifications_active_outlined,
      'position': 'middle',
      'highlight': 'alerts',
    },
    {
      'title': "You're all set!",
      'desc': 'Explore your property dashboard. Tap anywhere to get started.',
      'icon': Icons.check_circle_outline,
      'position': 'center',
      'highlight': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_done') ?? false;
    if (!seen && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _showOverlay = true);
      _animController.forward();
    }
  }

  Future<void> _next() async {
    if (_currentStep < steps.length - 1) {
      await _animController.reverse();
      setState(() => _currentStep++);
      _animController.forward();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await _animController.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _showOverlay = false);
  }

  void _skip() => _finish();

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOverlay) return widget.child;

    final step = steps[_currentStep];
    final isCenter = step['position'] == 'center';
    final isBottom = step['position'] == 'bottom';
    final isTop = step['position'] == 'top';
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        widget.child,
        // Dark overlay
        FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _next,
            child: Container(
              color: Colors.black.withOpacity(0.75),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        // Step card
        FadeTransition(
          opacity: _fadeAnim,
          child: Positioned(
            top: isTop ? 100 : isBottom ? null : size.height * 0.3,
            bottom: isBottom ? 100 : null,
            left: 24, right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(steps.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentStep ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentStep ? _gold : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4)),
                  )),
                ),
                const SizedBox(height: 20),
                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)]),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 30, spreadRadius: 2),
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20),
                    ]),
                  child: Column(children: [
                    // Icon with glow
                    Stack(alignment: Alignment.center, children: [
                      Container(width: 90, height: 90,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _gold.withOpacity(0.3), Colors.transparent]))),
                      Container(width: 72, height: 72,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: _gold.withOpacity(0.15),
                          border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                          boxShadow: [BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 16)]),
                        child: Icon(step['icon'] as IconData, color: _gold, size: 34)),
                    ]),
                    const SizedBox(height: 16),
                    Text(step['title'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white, fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(step['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7),
                            fontSize: 14, height: 1.5)),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(children: [
                      if (_currentStep < steps.length - 1) ...[
                        Expanded(child: TextButton(
                          onPressed: _skip,
                          child: Text('Skip Tour',
                              style: TextStyle(color: Colors.white.withOpacity(0.4),
                                  fontSize: 13)))),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_gold, Color(0xFF8B6914)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: _gold.withOpacity(0.4),
                                blurRadius: 12, offset: const Offset(0, 4))]),
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: Text(
                              _currentStep == steps.length - 1 ? "Let's Go! 🚀" : "Next →",
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text('${_currentStep + 1} of ${steps.length}',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
