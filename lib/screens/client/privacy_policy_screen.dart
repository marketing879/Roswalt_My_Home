import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppTheme.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.clayCardShadow(isDark: isDark),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16,
                color: isDark ? Colors.white : AppTheme.primaryMaroon),
          ),
        ),
        title: Text('Privacy Policy',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.primaryMaroon,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF543813), Color(0xFF7A5230)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 32),
                  SizedBox(height: 12),
                  Text('Privacy Policy',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Roswalt Realty Pvt. Ltd.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _section(isDark, 'Overview',
                'This Privacy Policy describes the manner in which Roswalt Realty Pvt. Ltd. (A S HIGHTECH LLP) collects, holds, and uses personal information. If you wish to make any inquiries regarding this Privacy Policy, contact the Privacy Officer at: info@roswalt.com\n\nRoswalt Realty Pvt. Ltd. may, from time to time, review and update this Privacy Policy to take account of new laws and technology.'),
            _section(isDark, 'What is Personal Information?',
                'Personal Information is any information or opinion about a person, whether true or not, from which that person may be identified.'),
            _section(isDark, 'When do we collect Personal Information?',
                'Roswalt Realty Pvt. Ltd. collects Personal Information from its website and App users in a variety of ways — such as your name, email address, contact details, and country/state location when you visit or register with our website and Mobile App or contact us by telephone or email.'),
            _section(isDark, 'Information Collected via this Website',
                'Roswalt Realty Pvt. Ltd. will collect Personal Information about visitors when they knowingly provide it. The website host will collect Personal Information for statistical, marketing, reporting and maintenance purposes, including:\n\n• Number of users visiting and pages viewed\n• Date, time and duration of a visit\n• Your physical location\n• The path taken through this website\n\nCookies are small text files transferred to a user\'s computer for storing information about identity, browser type or visiting patterns. A cookie may be downloaded when you first log on and will be automatically deleted when you log out.'),
            _section(isDark, 'How We Use Your Personal Information',
                'Roswalt Realty Pvt. Ltd. uses the Personal Information it collects to:\n\n• Provide products or services you have requested\n• Personalise and customise your experiences\n• Research the needs of users and market products with better understanding\n• Communicate with you\n• Provide de-identified data to advertisers or merchants\n• Improve and promote its services'),
            _section(isDark, 'To Whom We Disclose Your Information',
                'Roswalt Realty Pvt. Ltd. discloses de-identified information to current and potential advertisers. It may also disclose your Personal Information to the website host in limited circumstances, for example when the website experiences a technical problem.\n\nIf you become a customer, information accessible to other users is limited to:\n• Your name\n• Property address\n• Property photos (if provided)\n• Email address\n• Telephone number (if provided)'),
            _section(isDark, 'Marketing',
                'Roswalt Realty Pvt. Ltd. may use your Personal Information to provide promotional material about its services. If you do not wish to receive promotional material, contact the Privacy Officer at: info@roswalt.com'),
            _section(isDark, 'Security of Personal Information',
                'Roswalt Realty Pvt. Ltd. aims to keep your Personal Information secure and up to date. Any Personal Information collected via this website is protected by safeguards including physical, technical and procedural methods.\n\nYou can update your contact and profile information at any time by contacting our Privacy Officer. If we have no further need for your Personal Information, we will remove it from our system and destroy all records of it.'),
            _section(isDark, 'Privacy Disclaimer',
                'This Privacy Policy is subject to the relevant legislation. To the extent that this Policy provides for greater privacy protection than required by law, Roswalt Realty Pvt. Ltd. will not be liable for any loss, liability, cost, expenses or damage arising as a result of failing to meet that increased standard of privacy protection.'),
            const SizedBox(height: 40),
            Center(
              child: Text('Last updated: June 2026',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _section(bool isDark, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF3A2509))),
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.grey[700])),
        ],
      ),
    );
  }
}