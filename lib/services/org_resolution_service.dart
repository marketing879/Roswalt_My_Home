import '../models/org_chart.dart';


class OrgResolutionResult {
  final List<OrgPerson> matchedCandidates; // >1 means ambiguous (same name)
  final List<OrgPlacement> placements;
  OrgResolutionResult({required this.matchedCandidates, required this.placements});

  bool get notInOrgChart => matchedCandidates.isEmpty;
  bool get ambiguous => matchedCandidates.length > 1;
}

class OrgResolutionService {
  /// Section 2.3: exact, case-insensitive, trimmed name match.
  static List<OrgPerson> findCandidates(String loggedInName, List<OrgPerson> roster) {
    final target = loggedInName.trim().toLowerCase();
    if (target.isEmpty) return [];
    return roster.where((p) => p.name.trim().toLowerCase() == target).toList();
  }

  static OrgPerson? _personById(String? id, List<OrgPerson> roster) {
    if (id == null) return null;
    for (final p in roster) {
      if (p.id == id) return p;
    }
    return null;
  }

  static OrgChainLink _link(String? personId, List<OrgPerson> roster, String role) {
    final p = _personById(personId, roster);
    return OrgChainLink(personId: personId ?? '', name: p?.name ?? 'Unknown', role: role);
  }

  /// Full resolution for one chosen personId (after disambiguation, if any).
  static List<OrgPlacement> resolvePlacements({
    required String personId,
    required List<OrgProjectStructure> structure,
    required List<OrgPerson> roster,
  }) {
    final placements = <OrgPlacement>[];

    for (final project in structure) {
      for (final dept in project.departments) {
        for (final sub in dept.subDepartments) {
          if (sub.hodId == personId) {
            placements.add(_resolveHod(project.project, dept.name, sub, roster));
          } else if (sub.tlIds.contains(personId)) {
            placements.add(_resolveTl(project.project, dept.name, sub, personId, roster));
          } else if (sub.members.any((m) => m.personId == personId)) {
            final member = sub.members.firstWhere((m) => m.personId == personId);
            placements.add(_resolveDoer(project.project, dept.name, sub, member, roster));
          }
        }
      }
    }
    return placements;
  }

  static OrgPlacement _resolveHod(String project, String dept, OrgSubDepartment sub, List<OrgPerson> roster) {
    // 3.4: HOD's direct reports = top-level TLs (no manager above them) + doers with no tlId.
    final directTls = sub.tlIds.where((tl) => sub.safeManagerOfTl(tl) == null).toList();
    final directDoers = sub.members.where((m) => m.tlId == null || !sub.tlIds.contains(m.tlId)).toList();
    final team = [
      ...directTls.map((tl) => _link(tl, roster, 'TL')),
      ...directDoers.map((m) => _link(m.personId, roster, 'Doer')),
    ];
    final indirect = sub.members.length - directDoers.length;
    final tree = [
      ...directTls.map((tl) => _buildTreeNode(sub, tl, roster, {tl})),
      ...directDoers.map((m) => OrgTreeNode(personId: m.personId, name: _personById(m.personId, roster)?.name ?? 'Unknown', role: 'Doer', children: const [])),
    ];
    return OrgPlacement(
      project: project, department: dept, subDepartment: sub.name, role: 'HOD',
      reportsTo: const [], teamMembers: team, indirectReportCount: indirect > 0 ? indirect : null,
      teamTree: tree,
    );
  }

  /// Recursively builds the full nested subtree under one TL — their direct
  /// doers plus any nested TLs reporting to them (and so on), guarding against
  /// cyclic data via the `visited` path set.
  static OrgTreeNode _buildTreeNode(OrgSubDepartment sub, String tlId, List<OrgPerson> roster, Set<String> visited) {
    final doers = sub.members.where((m) => m.tlId == tlId);
    final nestedTls = sub.tlIds.where((tl) => tl != tlId && !visited.contains(tl) && sub.safeManagerOfTl(tl) == tlId);
    final children = <OrgTreeNode>[
      ...nestedTls.map((tl) => _buildTreeNode(sub, tl, roster, {...visited, tl})),
      ...doers.map((m) => OrgTreeNode(personId: m.personId, name: _personById(m.personId, roster)?.name ?? 'Unknown', role: 'Doer', children: const [])),
    ];
    return OrgTreeNode(personId: tlId, name: _personById(tlId, roster)?.name ?? 'Unknown', role: 'TL', children: children);
  }

  static OrgPlacement _resolveTl(
      String project, String dept, OrgSubDepartment sub, String myPersonId, List<OrgPerson> roster) {
    final chain = <OrgChainLink>[];
    String? manager = sub.safeManagerOfTl(myPersonId);
    final seen = <String>{myPersonId};
    while (manager != null && seen.add(manager)) {
      chain.add(_link(manager, roster, 'TL'));
      manager = sub.safeManagerOfTl(manager);
    }
    if (sub.hodId != null) chain.add(_link(sub.hodId, roster, 'HOD'));

    // Direct reports: members pointing straight at me, plus (if a nested TL
    // reports to me) that TL and their whole sub-tree.
    final team = <OrgChainLink>[];
    for (final m in sub.members) {
      if (m.tlId == myPersonId) team.add(_link(m.personId, roster, 'Doer'));
    }
    for (final tl in sub.tlIds) {
      if (tl != myPersonId && sub.safeManagerOfTl(tl) == myPersonId) {
        team.add(_link(tl, roster, 'TL'));
        for (final m in sub.members) {
          if (m.tlId == tl) team.add(_link(m.personId, roster, 'Doer'));
        }
      }
    }
    final node = _buildTreeNode(sub, myPersonId, roster, {myPersonId});
    return OrgPlacement(project: project, department: dept, subDepartment: sub.name, role: 'TL',
        reportsTo: chain, teamMembers: team, teamTree: node.children);
  }

  static OrgPlacement _resolveDoer(
      String project, String dept, OrgSubDepartment sub, OrgMember me, List<OrgPerson> roster) {
    final chain = <OrgChainLink>[];
    final hasValidTl = me.tlId != null && sub.tlIds.contains(me.tlId);
    if (hasValidTl) {
      chain.add(_link(me.tlId, roster, 'TL'));
      String? manager = sub.safeManagerOfTl(me.tlId!);
      final seen = <String>{me.tlId!};
      while (manager != null && seen.add(manager)) {
        chain.add(_link(manager, roster, 'TL'));
        manager = sub.safeManagerOfTl(manager);
      }
    }
    if (sub.hodId != null) chain.add(_link(sub.hodId, roster, 'HOD'));

    final team = hasValidTl
        ? sub.members.where((m) => m.personId != me.personId && m.tlId == me.tlId)
        : sub.members.where((m) => m.personId != me.personId && (m.tlId == null || !sub.tlIds.contains(m.tlId)));

    return OrgPlacement(
      project: project, department: dept, subDepartment: sub.name, role: 'Doer',
      reportsTo: chain, teamMembers: team.map((m) => _link(m.personId, roster, 'Doer')).toList(),
    );
  }
}
