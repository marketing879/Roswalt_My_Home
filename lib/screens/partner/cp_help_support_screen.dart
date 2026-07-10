import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CPHelpSupportScreen extends StatelessWidget {
  const CPHelpSupportScreen({super.key});

  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _cream = Color(0xFFFFF8F1);

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : _cream,
      appBar: AppBar(
        backgroundColor: _bronze,
        title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ROSWALT SUPPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: isDark ? Colors.white54 : _bronze)),
                  const SizedBox(height: 4),
                  Text('We are here to help with your Channel Partner queries',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actionBtn(Icons.phone, 'Call', Colors.green, () => launchUrl(Uri.parse('tel:+918879778560'))),
                      _actionBtn(Icons.chat, 'WhatsApp', const Color(0xFF25D366), () => launchUrl(Uri.parse('https://wa.me/918879778560'))),
                      _actionBtn(Icons.email_outlined, 'Email', Colors.blue, () => launchUrl(Uri.parse('mailto:customercare@roswaltrealty.com'))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CONTACT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: isDark ? Colors.white54 : _bronze)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Icon(Icons.phone_outlined, size: 18, color: isDark ? Colors.white54 : Colors.grey[600]),
                    const SizedBox(width: 10),
                    Text('8879778560', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF1A0A00))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.email_outlined, size: 18, color: isDark ? Colors.white54 : Colors.grey[600]),
                    const SizedBox(width: 10),
                    Text('customercare@roswaltrealty.com', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF1A0A00))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
