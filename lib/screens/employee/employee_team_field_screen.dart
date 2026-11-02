import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/org_chart.dart';
import '../../providers/ticket_provider.dart';
import '../../services/org_resolution_service.dart';
import '../../services/ticket_api_service.dart';
import 'ticket_login_screen.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);
const _cream = Color(0xFFFFF8F1);

/// For a TL: everyone who reports to them (reportingMap.tlId), with a live
/// dot for anyone currently on Field Duty. Tap an active one to watch their
/// route. Poll-based (via listMyFieldDutyTeam / getFieldDutyTrail) rather
/// than a live Firestore listener, since this crosses between two different
/// employees' data and is enforced server-side (see functions/index.js).
class EmployeeTeamFieldScreen extends StatefulWidget {
  const EmployeeTeamFieldScreen({super.key});
  @override
  State<EmployeeTeamFieldScreen> createState() => _EmployeeTeamFieldScreenState();
}

class _EmployeeTeamFieldScreenState extends State<EmployeeTeamFieldScreen> {
  List<Map<String, dynamic>> _team = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  Timer? _orgPollTimer;

  // Org chart ("who do I report to") — independent of the Field Duty
  // tracking above, sourced from the Sales App's org-structure (see
  // Roswalt_OrgChart_Integration_Spec.pdf). Uses the same Sales API bearer
  // session as the Tickets feature.
  bool _orgLoading = false;
  String? _orgError;
  List<OrgPerson> _orgCandidates = [];
  OrgPerson? _orgSelectedPerson;
  List<OrgPlacement> _orgPlacements = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadOrgChart();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
    _orgPollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadOrgChart(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _orgPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('listMyFieldDutyTeam').call();
      final team = (result.data['team'] as List).cast<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      team.sort((a, b) => (b['active'] == true ? 1 : 0) - (a['active'] == true ? 1 : 0));
      if (!mounted) return;
      setState(() { _team = team; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadOrgChart({bool silent = false}) async {
    final tp = context.read<TicketProvider>();
    if (tp.authStatus != TicketAuthStatus.loggedIn || tp.user == null) return;
    if (!silent) setState(() { _orgLoading = true; _orgError = null; });
    try {
      final api = TicketApiService.instance;
      final roster = await api.fetchOrgChart();
      final structure = await api.fetchOrgStructure();
      final candidates = OrgResolutionService.findCandidates(tp.user!.name, roster);
      if (!mounted) return;
      setState(() {
        _orgCandidates = candidates;
        _orgLoading = false;
        if (candidates.length == 1) {
          _orgSelectedPerson = candidates.first;
          _orgPlacements = OrgResolutionService.resolvePlacements(
              personId: candidates.first.id, structure: structure, roster: roster);
        }
      });
      // Keep a copy for when the user disambiguates below.
      _orgRoster = roster;
      _orgStructure = structure;
    } catch (e) {
      if (!mounted) return;
      setState(() { _orgLoading = false; _orgError = e.toString(); });
    }
  }

  List<OrgPerson> _orgRoster = [];
  List<OrgProjectStructure> _orgStructure = [];

  void _selectOrgCandidate(OrgPerson person) {
    setState(() {
      _orgSelectedPerson = person;
      _orgPlacements = OrgResolutionService.resolvePlacements(
          personId: person.id, structure: _orgStructure, roster: _orgRoster);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : _cream;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Team', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { _load(); _loadOrgChart(); })],
      ),
      body: Column(children: [
        _buildOrgChartSection(context, isDark, cardBg),
        Divider(height: 1, color: isDark ? Colors.white12 : _bronze.withOpacity(0.12)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(children: [
            Icon(Icons.my_location, size: 14, color: isDark ? Colors.white54 : Colors.grey[600]),
            const SizedBox(width: 6),
            Text('Live Field Duty', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white54 : Colors.grey[600])),
          ]),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _bronze))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, size: 44, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[400], fontSize: 12))),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => _load(), child: const Text('Retry')),
                ]))
              : _team.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.groups_outlined, size: 48, color: isDark ? Colors.white24 : Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No one reports to you yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500])),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _team.length,
                      itemBuilder: (_, i) {
                        final m = _team[i];
                        final active = m['active'] == true;
                        return GestureDetector(
                          onTap: active
                              ? () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => EmployeeFieldDutyTrailScreen(uid: m['uid'] as String, name: m['name'] as String)))
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: active ? Colors.green.withOpacity(0.4) : _gold.withOpacity(0.15))),
                            child: Row(children: [
                              Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: _bronze.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.person_outline, color: _bronze, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1A0A00))),
                                Text(m['employeeId'] as String, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500])),
                              ])),
                              if (active)
                                Row(children: [
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                                  const SizedBox(width: 6),
                                  const Text('On Field Duty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right, size: 18, color: Colors.green),
                                ])
                              else
                                Text('Not active', style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.grey[400])),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Widget _buildOrgChartSection(BuildContext context, bool isDark, Color cardBg) {
    final tp = context.watch<TicketProvider>();

    if (tp.authStatus != TicketAuthStatus.loggedIn) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.2))),
          child: Row(children: [
            Icon(Icons.account_tree_outlined, color: _bronze, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text('Log in once to see who you report to and your org-chart team.',
                style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.grey[700]))),
            TextButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketLoginScreen(popOnSuccess: true)));
                if (mounted) _loadOrgChart();
              },
              child: const Text('Log in'),
            ),
          ]),
        ),
      );
    }

    if (_orgLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: _bronze)),
      );
    }

    if (_orgError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.25))),
          child: Row(children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(_orgError!, style: TextStyle(fontSize: 12, color: Colors.red[400]))),
            TextButton(onPressed: _loadOrgChart, child: const Text('Retry')),
          ]),
        ),
      );
    }

    if (_orgCandidates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.15))),
          child: Text("You're not in the org chart yet — check back once HR places you.",
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey[600])),
        ),
      );
    }

    if (_orgCandidates.length > 1 && _orgSelectedPerson == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('A few people share your name on the org chart — which one is you?',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1A0A00))),
            const SizedBox(height: 10),
            ..._orgCandidates.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton(
                    onPressed: () => _selectOrgCandidate(p),
                    child: Text('${p.name} — ${p.designation.isNotEmpty ? p.designation : p.department}'),
                  ),
                )),
          ]),
        ),
      );
    }

    if (_orgPlacements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.15))),
          child: Text("You're on the org chart but not placed under any project yet.",
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.grey[600])),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(children: _orgPlacements.map((p) => _orgPlacementCard(p, isDark, cardBg)).toList()),
    );
  }

  Widget _orgPlacementCard(OrgPlacement p, bool isDark, Color cardBg) {
    final textColor = isDark ? Colors.white : const Color(0xFF1A0A00);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: _gold.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(p.role, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _bronze))),
          const SizedBox(width: 8),
          Expanded(child: Text('${p.project} · ${p.subDepartment}',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor), overflow: TextOverflow.ellipsis)),
        ]),
        if (p.reportsTo.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Reports to', style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey[500])),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: p.reportsTo.map((l) => Chip(
              label: Text('${l.name} (${l.role})', style: const TextStyle(fontSize: 11)),
              backgroundColor: _bronze.withOpacity(0.08),
              side: BorderSide(color: _bronze.withOpacity(0.15)),
              visualDensity: VisualDensity.compact)).toList()),
        ],
        if (p.teamTree.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Full hierarchy', style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey[500])),
          const SizedBox(height: 4),
          ...p.teamTree.map((n) => _orgTreeNode(n, 0, isDark, textColor)),
        ] else if (p.teamMembers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Team members', style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey[500])),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: p.teamMembers.map((l) => Chip(
              label: Text(l.name, style: const TextStyle(fontSize: 11)),
              backgroundColor: _gold.withOpacity(0.1),
              side: BorderSide(color: _gold.withOpacity(0.25)),
              visualDensity: VisualDensity.compact)).toList()),
        ],
      ]),
    );
  }

  Widget _orgTreeNode(OrgTreeNode node, int depth, bool isDark, Color textColor) {
    final isLeaf = node.children.isEmpty;
    final rowChild = Padding(
      padding: EdgeInsets.only(left: depth * 18.0, top: 4, bottom: 4),
      child: Row(children: [
        Icon(node.role == 'TL' ? Icons.account_tree_outlined : Icons.person_outline,
            size: 15, color: node.role == 'TL' ? _bronze : (isDark ? Colors.white38 : Colors.grey[500])),
        const SizedBox(width: 6),
        Expanded(child: Text(node.name,
            style: TextStyle(fontSize: 12, fontWeight: node.role == 'TL' ? FontWeight.w600 : FontWeight.w400, color: textColor),
            overflow: TextOverflow.ellipsis)),
        if (node.role == 'TL')
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: _gold.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: const Text('TL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _bronze))),
      ]),
    );
    if (isLeaf) return rowChild;
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: depth == 0,
        title: rowChild,
        children: node.children.map((c) => _orgTreeNode(c, depth + 1, isDark, textColor)).toList(),
      ),
    );
  }
}

class EmployeeFieldDutyTrailScreen extends StatefulWidget {
  final String uid;
  final String name;
  const EmployeeFieldDutyTrailScreen({super.key, required this.uid, required this.name});
  @override
  State<EmployeeFieldDutyTrailScreen> createState() => _EmployeeFieldDutyTrailScreenState();
}

class _EmployeeFieldDutyTrailScreenState extends State<EmployeeFieldDutyTrailScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _trail = [];
  LatLng? _current;
  bool _active = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('getFieldDutyTrail').call({'uid': widget.uid});
      final data = result.data;
      final trailRaw = (data['trail'] as List).cast<Map>();
      final trail = trailRaw.map((p) => LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble())).toList();
      final current = (data['currentLat'] != null && data['currentLng'] != null)
          ? LatLng((data['currentLat'] as num).toDouble(), (data['currentLng'] as num).toDouble())
          : (trail.isNotEmpty ? trail.last : null);
      if (!mounted) return;
      setState(() { _trail = trail; _current = current; _active = data['active'] == true; });
      if (current != null) _mapController?.animateCamera(CameraUpdate.newLatLng(current));
    } catch (e) {
      debugPrint('getFieldDutyTrail error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("${widget.name}'s Route", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: _current == null
          ? const Center(child: CircularProgressIndicator(color: _bronze))
          : Stack(children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _current!, zoom: 15),
                onMapCreated: (c) => _mapController = c,
                zoomControlsEnabled: false,
                markers: {
                  if (_trail.isNotEmpty)
                    Marker(markerId: const MarkerId('start'), position: _trail.first,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Field Duty started')),
                  Marker(markerId: const MarkerId('current'), position: _current!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: InfoWindow(title: '${widget.name} — current position')),
                },
                polylines: {
                  if (_trail.length > 1)
                    Polyline(polylineId: const PolylineId('trail'), points: _trail, color: _bronze, width: 4),
                },
              ),
              Positioned(top: 16, left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _active ? Colors.green : Colors.grey)),
                    const SizedBox(width: 6),
                    Text(_active ? 'Live' : 'Ended', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: _active ? Colors.green : Colors.grey)),
                  ]),
                ),
              ),
            ]),
    );
  }
}
