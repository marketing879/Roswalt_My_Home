import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ConstructionScreen extends StatefulWidget {
  const ConstructionScreen({super.key});

  @override
  State<ConstructionScreen> createState() => _ConstructionScreenState();
}

class _ConstructionScreenState extends State<ConstructionScreen> {
  int _selectedPhase = 0;

  final List<Map<String, dynamic>> _phases = [
    {
      'name': 'Foundation',
      'progress': 100,
      'status': 'completed',
      'date': 'Jan 2024',
      'updates': [
        {
          'title': 'Foundation Work Completed',
          'desc': 'All foundation work has been completed successfully.',
          'date': '15 Jan 2024',
          'image': 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400',
        },
        {
          'title': 'Soil Testing Done',
          'desc': 'Soil testing and quality checks completed.',
          'date': '05 Jan 2024',
          'image': 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w=400',
        },
      ],
    },
    {
      'name': 'Plinth',
      'progress': 100,
      'status': 'completed',
      'date': 'Mar 2024',
      'updates': [
        {
          'title': 'Plinth Level Completed',
          'desc': 'Plinth beam and slab work completed.',
          'date': '20 Mar 2024',
          'image': 'https://images.unsplash.com/photo-1590650046871-92c887180603?w=400',
        },
      ],
    },
    {
      'name': '1st Floor',
      'progress': 60,
      'status': 'in_progress',
      'date': 'Jun 2024',
      'updates': [
        {
          'title': '1st Floor Slab In Progress',
          'desc': 'Column work completed. Slab casting underway.',
          'date': '04 Jun 2024',
          'image': 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=400',
        },
        {
          'title': 'Column Work Done',
          'desc': 'All columns for 1st floor have been cast.',
          'date': '01 Jun 2024',
          'image': 'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=400',
        },
      ],
    },
    {
      'name': 'Brick Work',
      'progress': 0,
      'status': 'upcoming',
      'date': 'Sep 2024',
      'updates': [],
    },
    {
      'name': 'Finishing',
      'progress': 0,
      'status': 'upcoming',
      'date': 'Dec 2024',
      'updates': [],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase = _phases[_selectedPhase];

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFF8F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryMaroon,
            title: const Text(
              'Construction Updates',
              style: TextStyle(
                  color: const Color(0xFFF0F0F0), fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: const Color(0xFFF0F0F0)),
                onPressed: () {},
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // Overall progress banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF543813), Color(0xFF543813)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Roswalt At Neo City',
                    style: TextStyle(
                        color: const Color(0xFFF0F0F0),
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overall Progress: 60%',
                    style: TextStyle(
                        color: const Color(0xFFF0F0F0).withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.60,
                      backgroundColor: const Color(0xFFF0F0F0).withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFB8860B)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Phase selector
            Container(
              height: 80,
              color: isDark ? AppTheme.darkSurface : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                itemCount: _phases.length,
                itemBuilder: (context, index) {
                  final p = _phases[index];
                  final isSelected = _selectedPhase == index;
                  Color statusColor;
                  switch (p['status']) {
                    case 'completed':
                      statusColor = Colors.green;
                      break;
                    case 'in_progress':
                      statusColor = Colors.orange;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPhase = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryMaroon
                            : isDark
                                ? AppTheme.darkCardBg
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryMaroon
                              : statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.goldAccent
                                  : statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Phase details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phase progress card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                phase['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                              _statusBadge(phase['status']),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${phase['progress']}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: phase['progress'] / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                phase['status'] == 'completed'
                                    ? Colors.green
                                    : phase['status'] == 'in_progress'
                                        ? Colors.orange
                                        : Colors.grey,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expected: ${phase['date']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if ((phase['updates'] as List).isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.construction,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'No updates yet',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[400],
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        'Recent Updates',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(phase['updates'] as List)
                          .map((update) =>
                              _buildUpdateCard(update, isDark))
                          .toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'In Progress';
        break;
      default:
        color = Colors.grey;
        label = 'Upcoming';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildUpdateCard(Map update, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              update['image'],
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 160,
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                child: const Icon(Icons.construction,
                    size: 48, color: AppTheme.primaryMaroon),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  update['desc'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  update['date'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}