import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CredHomesScreen extends StatelessWidget {
  const CredHomesScreen({super.key});

  void _call(BuildContext context, String number) {
    launchUrl(Uri.parse('tel:$number'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0D3B5E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset('assets/images/credhomes_logo.png', height: 26, fit: BoxFit.contain),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The right loan.\nThe right partner.',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                      color: Color(0xFF0D3B5E), height: 1.3)),
              const SizedBox(height: 16),
              const Text(
                'Getting the right loan is not just about approval. It is about choosing the right financial partner who can guide you properly, reduce your stress, and help you move faster.\n\nThat is where CredHomes comes in.',
                style: TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 32),
              const Text('What we offer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF0D3B5E), letterSpacing: 1.2)),
              const SizedBox(height: 16),
              ...['Home Loan', 'Commercial Loan', 'Balance Transfer',
                  'Loan Against Property', 'Loan Top-Up'].map((s) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF0D3B5E), size: 18),
                    const SizedBox(width: 12),
                    Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A))),
                  ]),
                )
              ).toList(),
              const SizedBox(height: 8),
              const Text('*T&C Apply',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA), fontStyle: FontStyle.italic)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showNumbers(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D3B5E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Apply Now',
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showNumbers(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D3B5E)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Call Us',
                      style: TextStyle(color: Color(0xFF0D3B5E), fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNumbers(BuildContext context) {
    final numbers = [
      {'name': 'CRM Manager', 'number': '+918169740804', 'role': 'Sr. Support'},
      {'name': 'CRM Manager', 'number': '+919137192439', 'role': 'Sr. Support'},
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D3B5E))),
            const SizedBox(height: 4),
            Text('Tap to call directly', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),
            ...numbers.map((n) => GestureDetector(
              onTap: () { Navigator.pop(ctx); launchUrl(Uri.parse('tel:${n['number']}')); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0D3B5E).withOpacity(0.15)),
                ),
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: const Color(0xFF0D3B5E), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.phone, color: Colors.white, size: 20)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D3B5E))),
                    Text(n['number']!, style: const TextStyle(fontSize: 13, color: Color(0xFF0D3B5E), fontWeight: FontWeight.w500)),
                  ])),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFF0D3B5E), size: 14),
                ]),
              ),
            )).toList(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}