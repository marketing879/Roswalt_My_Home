import 'package:flutter/material.dart';
import 'dart:ui';

class HorseProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  const HorseProgressBar({super.key, required this.progress, this.height = 60});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _HorseOverlay extends StatelessWidget {
  const _HorseOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withOpacity(0.45),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.50,
            child: Image.asset(
              'assets/images/horse_loader.webp',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

OverlayEntry? _activeHorseOverlay;

void showHorseLoader(BuildContext context) {
  if (_activeHorseOverlay != null) return;
  _activeHorseOverlay = OverlayEntry(
    builder: (_) => const Positioned.fill(child: _HorseOverlay()),
  );
  Overlay.of(context).insert(_activeHorseOverlay!);
}

void hideHorseLoader() {
  _activeHorseOverlay?.remove();
  _activeHorseOverlay = null;
}
