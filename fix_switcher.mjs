const fs = require('fs');
const path = 'lib/screens/client/client_shell.dart';
let content = fs.readFileSync(path, 'utf8');

const newFunc = `  void _showBookingSwitcher(BuildContext context, bool isDark) {
    Navigator.pop(context);
    final provider = Provider.of<BookingProvider>(context, listen: false);
    final bookings = provider.allBookings;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Booking Switcher',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        );
      },
      pageBuilder: (ctx, _, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            child: Container(
              width: 280,
              height: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Bookings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryMaroon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('\${bookings.length} booking(s) found',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (_, i) {
                        final b = bookings[i];
                        final isSelected = provider.selectedBooking?.bookingId == b.bookingId;
                        final isApproved = b.status.toLowerCase() == 'approved';
                        return GestureDetector(
                          onTap: () {
                            provider.selectBooking(b);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                ? AppTheme.primaryMaroon
                                : isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppTheme.goldAccent : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.home_work_outlined,
                                  color: isSelected ? AppTheme.goldAccent : Colors.grey[500],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(b.bookingId,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(b.projectName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? Colors.white70 : Colors.grey[500],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isApproved
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.orange.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(b.status,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isApproved ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 18),
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
      },
    );
  }`;

// Find and replace the old function
const startMarker = '  void _showBookingSwitcher(BuildContext context, bool isDark) {';
const startIdx = content.indexOf(startMarker);

// Find the end of the function by counting braces
let braceCount = 0;
let endIdx = startIdx;
let started = false;
for (let i = startIdx; i < content.length; i++) {
  if (content[i] === '{') { braceCount++; started = true; }
  if (content[i] === '}') { braceCount--; }
  if (started && braceCount === 0) { endIdx = i + 1; break; }
}

content = content.substring(0, startIdx) + newFunc + content.substring(endIdx);
fs.writeFileSync(path, content, 'utf8');
console.log('Done! Function replaced successfully.');
