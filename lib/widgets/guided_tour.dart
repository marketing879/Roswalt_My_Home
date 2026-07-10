
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class TourStep {
  final String title;
  final String desc;
  final IconData icon;
  final GlobalKey? targetKey;
  final VoidCallback? onShow;
  TourStep({required this.title, required this.desc, required this.icon,
    this.targetKey, this.onShow});
}

class GuidedTour extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onComplete;
  const GuidedTour({super.key, required this.steps, required this.onComplete});
  @override
  State<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<GuidedTour> with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _bronze = Color(0xFF543813);
  int _current = 0;
  Rect? _targetRect;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
    _anim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTarget());
  }

  void _updateTarget() {
    final step = widget.steps[_current];
    if (step.onShow != null) step.onShow!();
    Future.delayed(const Duration(milliseconds: 300), () => _findTarget(step.targetKey));
  }

  void _findTarget(GlobalKey? key) {
    if (key == null) { if (mounted) setState(() => _targetRect = null); return; }
    final ctx = key.currentContext;
    if (ctx == null) { if (mounted) setState(() => _targetRect = null); return; }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) { if (mounted) setState(() => _targetRect = null); return; }
    final pos = box.localToGlobal(Offset.zero);
    if (mounted) setState(() => _targetRect = Rect.fromLTWH(
      pos.dx - 8, pos.dy - 8, box.size.width + 16, box.size.height + 16));
  }

  void _next() async {
    await _anim.reverse();
    if (_current < widget.steps.length - 1) {
      setState(() { _current++; _targetRect = null; });
      _anim.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateTarget());
    } else {
      widget.onComplete();
    }
  }

  void _skip() => widget.onComplete();

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final step = widget.steps[_current];
    final hasTarget = _targetRect != null;
    final isBottomHalf = hasTarget && _targetRect!.center.dy > size.height * 0.55;

    return FadeTransition(
      opacity: _fade,
      child: Stack(children: [
        CustomPaint(size: size, painter: _SpotlightPainter(rect: _targetRect)),
        if (hasTarget)
          Positioned(
            left: _targetRect!.left, top: _targetRect!.top,
            child: Container(
              width: _targetRect!.width, height: _targetRect!.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold, width: 2.5)))),
        if (hasTarget)
          Positioned(
            left: _targetRect!.center.dx - 14,
            top: isBottomHalf ? _targetRect!.top - 36 : _targetRect!.bottom + 8,
            child: Icon(isBottomHalf ? Icons.arrow_upward : Icons.arrow_downward,
                color: _gold, size: 28)),
        Positioned(
          left: 20, right: 20,
          top: hasTarget && !isBottomHalf ? null : 80,
          bottom: hasTarget && !isBottomHalf ? 90 : null,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.steps.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _current ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                  color: i == _current ? _gold : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4))))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _gold.withOpacity(0.4), width: 1.5),
                boxShadow: [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 24)]),
              child: Column(children: [
                Container(width: 60, height: 60,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _gold.withOpacity(0.15),
                    border: Border.all(color: _gold.withOpacity(0.4)),
                    boxShadow: [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 12)]),
                  child: Icon(step.icon, color: _gold, size: 28)),
                const SizedBox(height: 12),
                Text(step.title, textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(step.desc, textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
                const SizedBox(height: 16),
                Row(children: [
                  if (_current < widget.steps.length - 1)
                    Expanded(child: TextButton(
                      onPressed: _skip,
                      child: Text('Skip', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)))),
                  if (_current < widget.steps.length - 1) const SizedBox(width: 8),
                  Expanded(flex: 2, child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_gold, Color(0xFF8B6914)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 10, offset: const Offset(0,3))]),
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(_current == widget.steps.length - 1 ? "Let's Go!" : "Next →",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  )),
                ]),
                const SizedBox(height: 2),
                Text('${_current + 1} of ${widget.steps.length}',
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? rect;
  _SpotlightPainter({this.rect});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.78);
    if (rect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect!, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_SpotlightPainter old) => old.rect != rect;
}
