import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _complaints = [
    {
      'id': '#CMP001',
      'title': 'Water leakage in bathroom',
      'category': 'Maintenance',
      'status': 'in_progress',
      'date': '01 Jun 2026',
      'priority': 'high',
    },
    {
      'id': '#CMP002',
      'title': 'Lift not working on 3rd floor',
      'category': 'Facility',
      'status': 'resolved',
      'date': '28 May 2026',
      'priority': 'medium',
    },
    {
      'id': '#CMP003',
      'title': 'Parking space occupied by others',
      'category': 'Security',
      'status': 'resolved',
      'date': '20 May 2026',
      'priority': 'low',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showRaiseComplaintSheet() {
    String? selectedCategory;
    String? selectedPriority;
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Raise a Complaint',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('We take all complaints seriously',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 24),

                // Title
                const Text('COMPLAINT TITLE',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Brief title of your complaint',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryMaroon, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category
                const Text('CATEGORY',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Maintenance',
                    'Facility',
                    'Security',
                    'Construction',
                    'Staff',
                    'Other'
                  ]
                      .map((cat) => GestureDetector(
                            onTap: () => setModalState(
                                () => selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedCategory == cat
                                    ? AppTheme.primaryMaroon
                                    : Colors.grey[100],
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: selectedCategory == cat
                                      ? AppTheme.primaryMaroon
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedCategory == cat
                                        ? Colors.white
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Priority
                const Text('PRIORITY',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _priorityChip('Low', Colors.green,
                        selectedPriority, setModalState,
                        (v) => selectedPriority = v),
                    const SizedBox(width: 8),
                    _priorityChip('Medium', Colors.orange,
                        selectedPriority, setModalState,
                        (v) => selectedPriority = v),
                    const SizedBox(width: 8),
                    _priorityChip('High', Colors.red,
                        selectedPriority, setModalState,
                        (v) => selectedPriority = v),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                const Text('DESCRIPTION',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.black45,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Describe your complaint in detail...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryMaroon, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Complaint submitted successfully!'),
                          backgroundColor: AppTheme.primaryMaroon,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Complaint',
                        style: TextStyle(
                            color: const Color(0xFFF0F0F0),
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(
      String label,
      Color color,
      String? selected,
      StateSetter setModalState,
      Function(String) onSelect) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => setModalState(() => onSelect(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? color : Colors.grey[700],
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryMaroon,
            title: const Text('Complaints & Redressal',
                style: TextStyle(
                    color: const Color(0xFFF0F0F0),
                    fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: const Color(0xFFF0F0F0)),
                onPressed: _showRaiseComplaintSheet,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.goldAccent,
              indicatorWeight: 3,
              labelColor: AppTheme.goldAccent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'My Complaints'),
                Tab(text: 'Track Status'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildComplaintsList(isDark),
            _buildTrackStatus(isDark),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRaiseComplaintSheet,
        backgroundColor: AppTheme.primaryMaroon,
        icon: const Icon(Icons.add, color: const Color(0xFFF0F0F0)),
        label: const Text('New Complaint',
            style: TextStyle(color: const Color(0xFFF0F0F0))),
      ),
    );
  }

  Widget _buildComplaintsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final c = _complaints[index];
        final isResolved = c['status'] == 'resolved';
        Color priorityColor;
        switch (c['priority']) {
          case 'high':
            priorityColor = Colors.red;
            break;
          case 'medium':
            priorityColor = Colors.orange;
            break;
          default:
            priorityColor = Colors.green;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8)
                  ],
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c['id'],
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[400])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isResolved ? 'Resolved' : 'In Progress',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isResolved
                                    ? Colors.green
                                    : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(c['title'],
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMaroon
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c['category'],
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryMaroon,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text(c['date'],
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[400])),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackStatus(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _complaints.map((c) {
          final isResolved = c['status'] == 'resolved';
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8)
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['title'],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1A1A))),
                const SizedBox(height: 12),
                _statusStep('Submitted', true, isDark),
                _statusStep('Under Review', true, isDark),
                _statusStep('In Progress', isResolved, isDark),
                _statusStep('Resolved', isResolved, isDark),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusStep(String label, bool done, bool isDark) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? Colors.green
                    : isDark
                        ? Colors.white24
                        : Colors.grey[300],
              ),
              child: done
                  ? const Icon(Icons.check,
                      size: 12, color: const Color(0xFFF0F0F0))
                  : null,
            ),
            Container(
                width: 2, height: 28, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    done ? FontWeight.w600 : FontWeight.normal,
                color: done
                    ? (isDark
                        ? Colors.white
                        : const Color(0xFF1A1A1A))
                    : Colors.grey)),
      ],
    );
  }
}