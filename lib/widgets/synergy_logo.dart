import 'package:flutter/material.dart';

/// The real Synergy brand lockup (gradient ribbon "S" + wordmark), a single
/// flat PNG at assets/images/synergy_logo.png. [width] controls the
/// rendered size; height follows the image's own aspect ratio.
class SynergyLogo extends StatelessWidget {
  final double width;
  const SynergyLogo({super.key, this.width = 160});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/images/synergy_logo.png', width: width, fit: BoxFit.contain);
  }
}
