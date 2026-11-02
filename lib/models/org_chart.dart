/// Flat person directory entry (GET /api/v1/org-chart). Only `id`/`name` are
/// reliable for cross-referencing — project/subDept/tlId/hodId here are a
/// legacy single-placement mirror and must NOT be used to answer "who does
/// this person report to" (use OrgProjectStructure for that).
class OrgPerson {
  final String id;
  final String name;
  final String department;
  final String designation;
  final String tier; // hod | tl | doer

  OrgPerson({
    required this.id,
    required this.name,
    required this.department,
    required this.designation,
    required this.tier,
  });

  factory OrgPerson.fromJson(Map<String, dynamic> j) => OrgPerson(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
        designation: j['designation']?.toString() ?? '',
        tier: j['tier']?.toString() ?? 'doer',
      );
}

class OrgMember {
  final String id;
  final String personId;
  final String? tlId;
  OrgMember({required this.id, required this.personId, this.tlId});

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        id: j['id']?.toString() ?? '',
        personId: j['personId']?.toString() ?? '',
        tlId: j['tlId']?.toString(),
      );
}

class OrgSubDepartment {
  final String id;
  final String name;
  final String? hodId;
  final List<String> tlIds;
  final List<OrgMember> members;

  OrgSubDepartment({
    required this.id,
    required this.name,
    this.hodId,
    required this.tlIds,
    required this.members,
  });

  factory OrgSubDepartment.fromJson(Map<String, dynamic> j) => OrgSubDepartment(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        hodId: j['hodId']?.toString(),
        tlIds: (j['tlIds'] as List? ?? []).map((e) => e.toString()).toList(),
        members: (j['members'] as List? ?? [])
            .map((e) => OrgMember.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  /// Section 3.2: resolve who a TL in this sub-department reports to (another
  /// TL, if any), guarding against cyclic/corrupt data per the spec.
  String? managerOfTl(String tlPersonId) {
    for (final m in members) {
      if (m.personId == tlPersonId && m.tlId != null && m.tlId != tlPersonId && tlIds.contains(m.tlId)) {
        return m.tlId;
      }
    }
    return null;
  }

  bool _hasCycle(String startTlId) {
    final seen = <String>{startTlId};
    String? cur = managerOfTl(startTlId);
    while (cur != null) {
      if (seen.contains(cur)) return true;
      seen.add(cur);
      cur = managerOfTl(cur);
    }
    return false;
  }

  /// Safe version of managerOfTl that falls back to null (reports to HOD)
  /// if following the chain would cycle — corrupt data, not a real loop.
  String? safeManagerOfTl(String tlPersonId) => _hasCycle(tlPersonId) ? null : managerOfTl(tlPersonId);
}

class OrgDepartment {
  final String id;
  final String name;
  final List<OrgSubDepartment> subDepartments;
  OrgDepartment({required this.id, required this.name, required this.subDepartments});

  factory OrgDepartment.fromJson(Map<String, dynamic> j) => OrgDepartment(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        subDepartments: (j['subDepartments'] as List? ?? [])
            .map((e) => OrgSubDepartment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class OrgProjectStructure {
  final String project;
  final List<OrgDepartment> departments;
  OrgProjectStructure({required this.project, required this.departments});

  factory OrgProjectStructure.fromJson(Map<String, dynamic> j) => OrgProjectStructure(
        project: j['project']?.toString() ?? '',
        departments: (j['departments'] as List? ?? [])
            .map((e) => OrgDepartment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// One resolved link in a reporting chain or team list — just enough to
/// display a name + role without re-walking the hierarchy.
class OrgChainLink {
  final String personId;
  final String name;
  final String role; // 'HOD' | 'TL' | 'Doer'
  OrgChainLink({required this.personId, required this.name, required this.role});
}

/// One node in the full nested reporting tree below a TL/HOD — children are
/// their direct reports, recursively, down to leaf Doers.
class OrgTreeNode {
  final String personId;
  final String name;
  final String role; // 'TL' | 'Doer'
  final List<OrgTreeNode> children;
  OrgTreeNode({required this.personId, required this.name, required this.role, required this.children});
}

/// One placement this person holds (section 3.1) — a person can hold more
/// than one at once (different sub-departments, or the same sub-department
/// under different projects).
class OrgPlacement {
  final String project;
  final String department;
  final String subDepartment;
  final String role; // 'HOD' | 'TL' | 'Doer'
  final List<OrgChainLink> reportsTo; // nearest manager first, HOD last
  final List<OrgChainLink> teamMembers; // direct reports (or TL-mates for a doer)
  final int? indirectReportCount; // set only for an HOD placement (whole sub-dept minus direct)
  final List<OrgTreeNode> teamTree; // full nested hierarchy below this placement (HOD/TL only)

  OrgPlacement({
    required this.project,
    required this.department,
    required this.subDepartment,
    required this.role,
    required this.reportsTo,
    required this.teamMembers,
    this.indirectReportCount,
    this.teamTree = const [],
  });
}
