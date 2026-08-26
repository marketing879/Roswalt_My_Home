import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/booking_provider.dart';
import '../client/client_shell.dart';
import '../auth/login_screen.dart';
import '../tenant/tenant_shell.dart';

class BookingSelectionScreen extends StatelessWidget {
  const BookingSelectionScreen({super.key});

  static const _bronze = Color(0xFF543813);
  static const _gold = Color(0xFFD4AF37);
  static const _maroon = Color(0xFF8B0000);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final bookings = provider.allBookings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasBuyer = bookings.any((b) => b.customerType == 'Buyer');
    final hasTenant = bookings.any((b) => b.customerType == 'Tenant');
    final isMixed = hasBuyer && hasTenant;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B4A1E), Color(0xFF543813), Color(0xFF3A2509)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Property',
                              style: GoogleFonts.playfairDisplay(
                                  color: Colors.white, fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('${bookings.length} propert${bookings.length == 1 ? 'y' : 'ies'} found',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Mixed role banner
              if (isMixed) ...[
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _gold, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You have both Buyer and Tenant properties. Select one to continue.',
                          style: TextStyle(color: Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Booking list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: bookings.length,
                  itemBuilder: (ctx, i) {
                    final b = bookings[i];
                    final isBuyer = b.customerType == 'Buyer';
                    final isApproved = b.status.toLowerCase() == 'approved';

                    return GestureDetector(
                      onTap: () {
                        provider.selectBooking(b);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isBuyer
                                ? const ClientShell()
                                : const TenantShell()),
                          (route) => false,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(
                              color: _gold.withOpacity(0.15),
                              blurRadius: 20, spreadRadius: 2,
                              offset: const Offset(0, 6))],
                          border: Border.all(
                              color: isBuyer
                                  ? _maroon.withOpacity(0.2)
                                  : _bronze.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Role header bar
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isBuyer
                                      ? [_maroon, const Color(0xFF5C0000)]
                                      : [_bronze, const Color(0xFF3A2509)],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isBuyer
                                            ? Icons.home_work_outlined
                                            : Icons.apartment_outlined,
                                        color: _gold, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        isBuyer ? 'BUYER' : 'TENANT',
                                        style: const TextStyle(
                                            color: _gold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isApproved
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: isApproved
                                              ? Colors.green.withOpacity(0.4)
                                              : Colors.orange.withOpacity(0.4)),
                                    ),
                                    child: Text(b.status,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isApproved
                                                ? Colors.green
                                                : Colors.orange)),
                                  ),
                                ],
                              ),
                            ),

                            // Booking details
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isBuyer
                                            ? [_maroon, const Color(0xFF5C0000)]
                                            : [_bronze, const Color(0xFF3A2509)],
                                      ),
                                      borderRadius: BorderRadius.circular(16)),
                                    child: Icon(
                                      isBuyer
                                          ? Icons.apartment
                                          : Icons.person_pin_outlined,
                                      color: Colors.white, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(b.projectName,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1A0000))),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${b.towerName} • Unit ${b.unitNumber}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isBuyer
                                                    ? _maroon.withOpacity(0.08)
                                                    : _bronze.withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isBuyer
                                                    ? 'Booking: ${b.bookingId}'
                                                    : 'Unit: ${b.unitNumber}',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: isBuyer
                                                        ? _maroon
                                                        : _bronze,
                                                    fontWeight: FontWeight.w600)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isBuyer
                                          ? _maroon.withOpacity(0.08)
                                          : _bronze.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.arrow_forward_ios,
                                        color: isBuyer ? _maroon : _bronze,
                                        size: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}