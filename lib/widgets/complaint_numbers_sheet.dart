import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showComplaintNumbersSheet(BuildContext context) {
  final numbers = [
    {'name': 'Redressal Executive', 'number': '+919619394997', 'role': 'Help & Support'},
    {'name': 'Redressal Executive', 'number': '+917507345345', 'role': 'Help & Support'},
  ];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2C1A0E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.5), borderRadius: BorderRadius.circular(2))),
        Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3))),
            child: const Icon(Icons.support_agent_rounded, color: Color(0xFFD4AF37), size: 26)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Complaints & Redressal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF5F5F5))),
            Text("Tap to call directly", style: TextStyle(fontSize: 12, color: const Color(0xFFF5F5F5).withOpacity(0.45))),
          ]),
        ]),
        const SizedBox(height: 20),
        ...numbers.map((n) => GestureDetector(
          onTap: () { Navigator.pop(ctx); launchUrl(Uri.parse('tel:' + (n['number'] as String))); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4EF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(color: const Color(0xFF543813), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3A2509))),
                Text(n['role']!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                Text(n['number']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF543813))),
              ])),
              const Icon(Icons.chevron_right, color: Color(0xFF543813), size: 20),
            ]),
          ),
        )).toList(),
      ]),
    ),
  );
}
