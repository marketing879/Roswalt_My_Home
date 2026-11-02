const List<String> kTicketCategories = [
  'MIS',
  'SFDC',
  'SmartCue',
  'Application',
  'Web Applications',
  'Data',
  'User ID Creation',
  'SFDC ID Creation/Deletion',
  'User-wise Temporary Access',
  'Others',
];

const Set<String> kForcedGuardianCategories = {
  'Data',
  'User ID Creation',
  'SFDC ID Creation/Deletion',
  'User-wise Temporary Access',
};

const List<String> kTicketProjects = [
  'ROSWALT ZAIDEN',
  'ROSWALT ZYON',
  'ROSWALT ZEYA',
  'ROSWALT RAYA',
  'ROSWALT RYLA',
  'SUJATA NIVAS',
];

const List<String> kTicketStages = [
  'pending_hod',
  'pending_guardian',
  'approved',
  'in_progress',
  'completed',
  'closed',
];

const Map<String, String> kTicketStageLabels = {
  'pending_hod': 'Pending HOD',
  'pending_guardian': 'Pending Guardian',
  'approved': 'Approved — awaiting timeline',
  'in_progress': 'In Progress',
  'completed': 'Completed — awaiting confirmation',
  'closed': 'Closed',
};

class TicketAttachment {
  final String id;
  final String kind; // file | link
  final String label;
  final String url;
  final String addedBy;
  final DateTime? addedAt;

  TicketAttachment({
    required this.id,
    required this.kind,
    required this.label,
    required this.url,
    required this.addedBy,
    this.addedAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> j) => TicketAttachment(
        id: j['id']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'link',
        label: j['label']?.toString() ?? '',
        url: j['url']?.toString() ?? '',
        addedBy: j['addedBy']?.toString() ?? '',
        addedAt: j['addedAt'] != null ? DateTime.tryParse(j['addedAt'].toString()) : null,
      );
}

class TicketComment {
  final String id;
  final String authorName;
  final String authorEmail;
  final String message;
  final DateTime? createdAt;

  TicketComment({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.message,
    this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> j) => TicketComment(
        id: j['id']?.toString() ?? '',
        authorName: j['authorName']?.toString() ?? '',
        authorEmail: j['authorEmail']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
      );
}

class Ticket {
  final String id;
  final String category;
  final String? customCategory;
  final String subject;
  final String description;
  final String project;
  final String raisedBy;
  final String raisedByEmail;
  final String hodName;
  final String hodEmail;
  final bool requiresDataAccess;
  final String stage;
  final String? hodDecisionBy;
  final DateTime? hodDecisionAt;
  final String? guardianDecisionBy;
  final DateTime? guardianDecisionAt;
  final DateTime? accessExpiresAt;
  final DateTime? allottedDueDate;
  final String? doerName;
  final DateTime? completedAt;
  final DateTime? closedAt;
  final int reopenCount;
  final List<TicketAttachment> attachments;
  final List<TicketComment> comments;
  final String? rejectedBy;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ticket({
    required this.id,
    required this.category,
    this.customCategory,
    required this.subject,
    required this.description,
    required this.project,
    required this.raisedBy,
    required this.raisedByEmail,
    required this.hodName,
    required this.hodEmail,
    required this.requiresDataAccess,
    required this.stage,
    this.hodDecisionBy,
    this.hodDecisionAt,
    this.guardianDecisionBy,
    this.guardianDecisionAt,
    this.accessExpiresAt,
    this.allottedDueDate,
    this.doerName,
    this.completedAt,
    this.closedAt,
    this.reopenCount = 0,
    this.attachments = const [],
    this.comments = const [],
    this.rejectedBy,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
  });

  /// Display label: shows customCategory instead of the literal "Others".
  String get displayCategory {
    if (category == 'Others' && (customCategory ?? '').isNotEmpty) return customCategory!;
    return category;
  }

  String get stageLabel => kTicketStageLabels[stage] ?? stage;

  static DateTime? _d(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
        id: j['id']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        customCategory: j['customCategory']?.toString(),
        subject: j['subject']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        project: j['project']?.toString() ?? '',
        raisedBy: j['raisedBy']?.toString() ?? '',
        raisedByEmail: j['raisedByEmail']?.toString() ?? '',
        hodName: j['hodName']?.toString() ?? '',
        hodEmail: j['hodEmail']?.toString() ?? '',
        requiresDataAccess: j['requiresDataAccess'] == true,
        stage: j['stage']?.toString() ?? 'pending_hod',
        hodDecisionBy: j['hodDecisionBy']?.toString(),
        hodDecisionAt: _d(j['hodDecisionAt']),
        guardianDecisionBy: j['guardianDecisionBy']?.toString(),
        guardianDecisionAt: _d(j['guardianDecisionAt']),
        accessExpiresAt: _d(j['accessExpiresAt']),
        allottedDueDate: _d(j['allottedDueDate']),
        doerName: j['doerName']?.toString(),
        completedAt: _d(j['completedAt']),
        closedAt: _d(j['closedAt']),
        reopenCount: (j['reopenCount'] is int) ? j['reopenCount'] as int : int.tryParse('${j['reopenCount'] ?? 0}') ?? 0,
        attachments: (j['attachments'] as List? ?? [])
            .map((e) => TicketAttachment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        comments: (j['comments'] as List? ?? [])
            .map((e) => TicketComment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        rejectedBy: j['rejectedBy']?.toString(),
        rejectionReason: j['rejectionReason']?.toString(),
        createdAt: _d(j['createdAt']),
        updatedAt: _d(j['updatedAt']),
      );
}

class TicketAppUser {
  final String email;
  final String name;
  final String role; // employee | hod | guardian | prime_admin
  final bool ticketAccess;
  final List<String> departmentAccess;
  final String? photoUrl;
  final String? phone;

  TicketAppUser({
    required this.email,
    required this.name,
    required this.role,
    required this.ticketAccess,
    this.departmentAccess = const [],
    this.photoUrl,
    this.phone,
  });

  factory TicketAppUser.fromJson(Map<String, dynamic> j) => TicketAppUser(
        email: j['email']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        role: j['role']?.toString() ?? 'employee',
        ticketAccess: j['ticketAccess'] != false,
        departmentAccess: (j['departmentAccess'] as List? ?? []).map((e) => e.toString()).toList(),
        photoUrl: j['photoUrl']?.toString(),
        phone: j['phone']?.toString(),
      );
}
