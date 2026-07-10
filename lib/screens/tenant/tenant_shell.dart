
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'tenant_home_screen.dart';
import 'tenant_compensation_screen.dart';
import 'tenant_documents_screen.dart';
import 'tenant_assistance_screen.dart';

class TenantShell extends StatefulWidget {
  const TenantShell({super.key});
  @override
  State<TenantShell> createState() => _TenantShellState();
}

class _TenantShellState extends State<TenantShell> {
  int _currentIndex = 0;
  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TenantHomeScreen(),
      const TenantCompensationScreen(),
      const TenantDocumentsScreen(),
      const TenantAssistanceScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _bronze,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12, offset: const Offset(0, -3))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _navItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Compensation'),
            _navItem(2, Icons.folder_outlined, Icons.folder, 'Documents'),
            _navItem(3, Icons.headset_mic_outlined, Icons.headset_mic, 'Assistance'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _gold.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? _gold.withOpacity(0.5) : Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: isActive ? _gold : Colors.white60, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _gold : Colors.white60)),
          ],
        ),
      ),
    );
  }
}
