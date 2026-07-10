import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AppTour extends StatefulWidget {
  final Widget child;
  const AppTour({super.key, required this.child});
  @override
  State<AppTour> createState() => _AppTourState();
}

class _TourStep {
  final String icon;
  final String title;
  final String desc;
  final String action;
  final GlobalKey? targetKey;
  final bool isFinal;
  const _TourStep({
    required this.icon, required this.title,
    required this.desc, required this.action,
    this.targetKey, this.isFinal = false,
  });
}

class _AppTourState extends State<AppTour> with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _bronze = Color(0xFF543813);

  bool _visible = false;
  int _step = 0;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  // GlobalKeys for each highlighted element
  static final drawerKey = GlobalKey();
  static final propertyKey = GlobalKey();
  static final quickActionsKey = GlobalKey();
  static final bottomNavKey = GlobalKey();

  late final List<_TourStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      const _TourStep(
        icon: '🏠',
        title: 'Welcome to Roswalt My Home!',
        desc: 'This guided tour walks you through every feature of your personal property dashboard. It takes about 60 seconds.',
        action: 'Tap Next to begin the tour',
      ),
      _TourStep(
        icon: '☰',
        title: 'Drawer Menu',
        desc: 'Tap the three-line icon (top-left) to open the drawer. From here you can switch between your bookings, toggle dark mode, access settings and log out.',
        action: 'Tap ☰ to open the drawer',
        targetKey: drawerKey,
      ),
      _TourStep(
        icon: '🏗',
        title: 'Your Property Card',
        desc: 'This card shows your live Salesforce data — project name, tower, unit number, floor, carpet area, parking slot and current approval status. Tap View Full Details to see everything.',
        action: 'Tap "View Full Details"',
        targetKey: propertyKey,
      ),
      _TourStep(
        icon: '⚡',
        title: 'Quick Actions',
        desc: 'Six shortcut tiles for Construction Updates, Documents, Announcements, CRM contact, Refer a Friend and CredHomes. Long-press any tile to customise which 6 appear.',
        action: 'Tap any tile to navigate',
        targetKey: quickActionsKey,
      ),
      _TourStep(
        icon: '🗂',
        title: 'Bottom Navigation',
        desc: 'Four permanent tabs — Home (this screen), Documents (all papers), Payments (milestones & receipts) and Assistance (raise a ticket or call your CRM). Tap each to explore.',
        action: 'Tap any tab to switch screens',
        targetKey: bottomNavKey,
      ),
      const _TourStep(
        icon: '🎉',
        title: "You're all set!",
        desc: 'You now know every section of your Roswalt My Home dashboard. Your data updates live from Salesforce — check back anytime for the latest on your property.',
        action: '',
        isFinal: true,
      ),
    ];
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _checkTour();
  }

  Future<void> _checkTour() async {
    final prefs = await SharedPreferences.getInstance();
    // For testing: always show. For release: use prefs.getBool('tour_done') ?? false
    final done = false; // Change to: prefs.getBool('tour_done') ?? false
    if (!done && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _visible = true);
        _ctrl.forward();
      }
    }
  }

  Future<void> _next() async {
    await _ctrl.reverse();
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _ctrl.forward();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_done', true);
    await _ctrl.reverse();
    if (mounted) setState(() { _visible = false; _step = 0; });
  }

  Future<void> _restart() async {
    await _ctrl.reverse();
    setState(() { _step = 0; });
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Rect? _getTargetRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(pos.dx - 8, pos.dy - 8, box.size.width + 16, box.size.height + 16);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Inject keys into child via InheritedWidget pattern
        _AppTourKeys(
          drawerKey: drawerKey,
          propertyKey: propertyKey,
          quickActionsKey: quickActionsKey,
          bottomNavKey: bottomNavKey,
          child: widget.child,
        ),
        if (_visible)
          FadeTransition(
            opacity: _fade,
            child: _TourOverlay(
              step: _steps[_step],
              stepIndex: _step,
              totalSteps: _steps.length,
              getTargetRect: _getTargetRect,
              onNext: _next,
              onSkip: _finish,
              onRestart: _restart,
            ),
          ),
      ],
    );
  }
}

// InheritedWidget to pass keys down
class _AppTourKeys extends InheritedWidget {
  final GlobalKey drawerKey;
  final GlobalKey propertyKey;
  final GlobalKey quickActionsKey;
  final GlobalKey bottomNavKey;

  const _AppTourKeys({
    required this.drawerKey, required this.propertyKey,
    required this.quickActionsKey, required this.bottomNavKey,
    required super.child,
  });

  static _AppTourKeys? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppTourKeys>();

  @override
  bool updateShouldNotify(_AppTourKeys old) => false;
}

class _TourOverlay extends StatelessWidget {
  final _TourStep step;
  final int stepIndex;
  final int totalSteps;
  final Rect? Function(GlobalKey) getTargetRect;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onRestart;

  static const _gold = Color(0xFFD4AF37);
  static const _bronze = Color(0xFF543813);

  const _TourOverlay({
    required this.step, required this.stepIndex, required this.totalSteps,
    required this.getTargetRect, required this.onNext,
    required this.onSkip, required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final targetRect = step.targetKey != null ? getTargetRect(step.targetKey!) : null;
    final hasTarget = targetRect != null;

    // Smart positioning: never cover the highlighted element
    const ttHeight = 260.0;
    const arrowHeight = 30.0;
    const gap = 8.0;
    const pad = 24.0;

    double tooltipTop;
    bool arrowPointsUp; // arrow points UP means tooltip is BELOW element

    if (hasTarget) {
      final spaceBelow = size.height - targetRect.bottom - arrowHeight - gap;
      final spaceAbove = targetRect.top - arrowHeight - gap;
      if (spaceBelow >= ttHeight) {
        // Place tooltip BELOW element
        tooltipTop = targetRect.bottom + arrowHeight + gap;
        arrowPointsUp = true;
      } else {
        // Place tooltip ABOVE element
        tooltipTop = targetRect.top - arrowHeight - ttHeight - gap;
        arrowPointsUp = false;
      }
      tooltipTop = tooltipTop.clamp(50.0, size.height - ttHeight - 20);
    } else {
      tooltipTop = size.height * 0.22;
      arrowPointsUp = false;
    }

    return GestureDetector(
      onTap: step.isFinal ? null : onNext,
      child: Stack(
        children: [
          // Dark overlay with cutout
          if (hasTarget)
            CustomPaint(
              size: size,
              painter: _GlassSpotlightPainter(rect: targetRect),
            )
          else
            Container(color: Colors.black.withOpacity(0.72)),

          // Glass ring around target
          if (hasTarget)
            Positioned(
              left: targetRect.left,
              top: targetRect.top,
              child: Container(
                width: targetRect.width,
                height: targetRect.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(color: _gold.withOpacity(0.8), width: 2),
                  boxShadow: [
                    BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                    BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 40, spreadRadius: 8),
                  ],
                ),
              ),
            ),

          // Arrow
          if (hasTarget)
            Positioned(
              left: targetRect.center.dx - 14,
              top: arrowPointsUp
                  ? targetRect.bottom + gap
                  : targetRect.top - arrowHeight - gap,
              child: _PulsingArrow(pointsUp: arrowPointsUp),
            ),

          // Tooltip card — NEVER overlaps highlighted element
          Positioned(
            left: pad,
            right: pad,
            top: tooltipTop,
            child: GestureDetector(
              onTap: () {}, // prevent tap-through
              child: _GlassTooltip(
                step: step,
                stepIndex: stepIndex,
                totalSteps: totalSteps,
                onNext: onNext,
                onSkip: onSkip,
                onRestart: onRestart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingArrow extends StatefulWidget {
  final bool pointsUp;
  const _PulsingArrow({required this.pointsUp});
  @override
  State<_PulsingArrow> createState() => _PulsingArrowState();
}

class _PulsingArrowState extends State<_PulsingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _a = Tween<double>(begin: 0, end: 6).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _c.repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, widget.pointsUp ? -_a.value : _a.value),
        child: Icon(
          widget.pointsUp ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: const Color(0xFFD4AF37), size: 30,
        ),
      ),
    );
  }
}

class _GlassTooltip extends StatelessWidget {
  final _TourStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onRestart;

  static const _gold = Color(0xFFD4AF37);

  const _GlassTooltip({
    required this.step, required this.stepIndex, required this.totalSteps,
    required this.onNext, required this.onSkip, required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
        color: Colors.white.withOpacity(0.06),
        boxShadow: [
          BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 24, spreadRadius: 2),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B4A1E).withOpacity(0.85),
                  const Color(0xFF3A2509).withOpacity(0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer top line
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.25),
                      Colors.transparent,
                    ]),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 12),
                // Icon + title row
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _gold.withOpacity(0.12),
                      border: Border.all(color: _gold.withOpacity(0.4)),
                      boxShadow: [BoxShadow(color: _gold.withOpacity(0.25), blurRadius: 10)],
                    ),
                    child: Center(child: Text(step.icon, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(step.title,
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 10),
                // Description
                Text(step.desc,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12, height: 1.5)),
                if (step.action.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _gold.withOpacity(0.35)),
                    ),
                    child: Text(step.action,
                        style: TextStyle(color: _gold.withOpacity(0.9),
                            fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
                const SizedBox(height: 14),
                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalSteps, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == stepIndex ? 18 : 6, height: 6,
                    decoration: BoxDecoration(
                      color: i == stepIndex ? _gold : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: i == stepIndex
                          ? [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 6)]
                          : null,
                    ),
                  )),
                ),
                const SizedBox(height: 14),
                // Buttons
                if (!step.isFinal)
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onSkip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Center(child: Text('Skip Tour',
                              style: TextStyle(color: Colors.white.withOpacity(0.4),
                                  fontSize: 12))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: onNext,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_gold, Color(0xFF8B6914)]),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: _gold.withOpacity(0.4),
                                  blurRadius: 12, offset: const Offset(0, 4)),
                              const BoxShadow(color: Colors.white10,
                                  blurRadius: 1, offset: Offset(0, -1)),
                            ],
                          ),
                          child: Center(child: Text(
                            stepIndex == totalSteps - 2 ? "Let's Go! 🚀" : "Next →",
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold, fontSize: 13),
                          )),
                        ),
                      ),
                    ),
                  ]),
                if (step.isFinal) ...[
                  GestureDetector(
                    onTap: onRestart,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold.withOpacity(0.45), width: 1.5),
                        boxShadow: [BoxShadow(color: _gold.withOpacity(0.15), blurRadius: 10)],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.replay_rounded, color: _gold, size: 18),
                        const SizedBox(width: 8),
                        Text('Restart the tour',
                            style: TextStyle(color: _gold, fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onSkip,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_gold, Color(0xFF8B6914)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: _gold.withOpacity(0.4),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Start Exploring! 🏠',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Center(child: Text('${stepIndex + 1} of $totalSteps',
                    style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 10))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSpotlightPainter extends CustomPainter {
  final Rect rect;
  const _GlassSpotlightPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.72);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlassSpotlightPainter old) => old.rect != rect;
}