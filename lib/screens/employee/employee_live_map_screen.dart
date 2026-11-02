import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_attendance_provider.dart';

const _bronze = Color(0xFF543813);
const _gold = Color(0xFFD4AF37);

/// Embeddable card showing today's check-in-to-now movement trail on a live
/// map, Zomato/Swiggy style — a polyline through every recorded GPS ping
/// (employees/{uid}/attendance/{dateKey}/locationTrail) plus a marker for
/// the current live position. Only meaningful while checked in (tracking
/// is foreground-only — see EmployeeAttendanceProvider._startLiveTracking).
/// Embedded directly above the Attendance Calendar, not behind a link.
class EmployeeMovementMapCard extends StatefulWidget {
  final double height;
  const EmployeeMovementMapCard({super.key, this.height = 220});
  @override
  State<EmployeeMovementMapCard> createState() => _EmployeeMovementMapCardState();
}

class _EmployeeMovementMapCardState extends State<EmployeeMovementMapCard> {
  GoogleMapController? _mapController;
  List<LatLng> _trail = [];
  StreamSubscription? _trailSub;

  String get _dateKey {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _trailSub = FirebaseFirestore.instance
          .collection('employees').doc(uid)
          .collection('attendance').doc(_dateKey)
          .collection('locationTrail')
          .orderBy('recordedAt')
          .snapshots()
          .listen((snap) {
        final points = snap.docs
            .map((d) => LatLng((d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()))
            .toList();
        if (!mounted) return;
        setState(() => _trail = points);
        if (points.isNotEmpty) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(points.last));
        }
      });
    }
  }

  @override
  void dispose() {
    _trailSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final current = (attendance.todayLatitude != null && attendance.todayLongitude != null)
        ? LatLng(attendance.todayLatitude!, attendance.todayLongitude!)
        : (_trail.isNotEmpty ? _trail.last : null);

    return Container(
      height: widget.height,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withOpacity(0.15))),
      child: current == null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_off_outlined, size: 36, color: isDark ? Colors.white24 : Colors.grey[400]),
              const SizedBox(height: 8),
              Text(attendance.isCheckedInToday
                      ? 'Waiting for the first location fix...'
                      : "Check in to start tracking today's movement.",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500])),
            ]))
          : Stack(children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: current, zoom: 16),
                onMapCreated: (c) => _mapController = c,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                markers: {
                  if (_trail.isNotEmpty)
                    Marker(markerId: const MarkerId('start'), position: _trail.first,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Check-in location')),
                  Marker(markerId: const MarkerId('current'), position: current,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(title: 'Current position')),
                },
                polylines: {
                  if (_trail.length > 1)
                    Polyline(polylineId: const PolylineId('trail'), points: _trail,
                        color: _bronze, width: 4),
                },
              ),
              if (attendance.isLiveTrackingActive)
                Positioned(top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)]),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                      const SizedBox(width: 5),
                      const Text('Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ]),
                  ),
                ),
            ]),
    );
  }
}

/// Zomato-style compact live-tracking card for the employee's OWN Field
/// Duty session — shown right on the Dashboard while active, not tucked
/// behind a link, so the "end doer" out on visits sees their own route too
/// (not just their TL, who watches the same thing via My Team).
class EmployeeFieldDutyMapCard extends StatefulWidget {
  const EmployeeFieldDutyMapCard({super.key});
  @override
  State<EmployeeFieldDutyMapCard> createState() => _EmployeeFieldDutyMapCardState();
}

class _EmployeeFieldDutyMapCardState extends State<EmployeeFieldDutyMapCard> {
  GoogleMapController? _mapController;
  List<LatLng> _trail = [];
  StreamSubscription? _trailSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _trailSub = FirebaseFirestore.instance
          .collection('employees').doc(uid)
          .collection('fieldDuty').doc('status')
          .collection('trail')
          .orderBy('recordedAt')
          .snapshots()
          .listen((snap) {
        final points = snap.docs
            .map((d) => LatLng((d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()))
            .toList();
        if (!mounted) return;
        setState(() => _trail = points);
        if (points.isNotEmpty) _mapController?.animateCamera(CameraUpdate.newLatLng(points.last));
      });
    }
  }

  @override
  void dispose() {
    _trailSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String _elapsed(DateTime? since) {
    if (since == null) return '';
    final d = DateTime.now().difference(since);
    if (d.inMinutes < 1) return 'Just started';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final current = (attendance.fieldDutyCurrentLat != null && attendance.fieldDutyCurrentLng != null)
        ? LatLng(attendance.fieldDutyCurrentLat!, attendance.fieldDutyCurrentLng!)
        : (_trail.isNotEmpty ? _trail.last : null);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeOwnFieldDutyMapScreen())),
      child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
              const SizedBox(width: 6),
              const Text('Field Duty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
            ]),
            const SizedBox(height: 4),
            Text(_elapsed(attendance.fieldDutyStartedAt), style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Your TL can see this route', style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.grey[500])),
          ]),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 120, height: 90,
            child: current == null
                ? Container(color: _bronze.withOpacity(0.08),
                    child: const Center(child: Icon(Icons.location_searching, color: _bronze, size: 20)))
                : IgnorePointer(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: current, zoom: 15),
                      onMapCreated: (c) => _mapController = c,
                      zoomControlsEnabled: false, myLocationButtonEnabled: false,
                      scrollGesturesEnabled: false, zoomGesturesEnabled: false, rotateGesturesEnabled: false, tiltGesturesEnabled: false,
                      markers: {
                        Marker(markerId: const MarkerId('current'), position: current,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
                      },
                      polylines: {
                        if (_trail.length > 1)
                          Polyline(polylineId: const PolylineId('trail'), points: _trail, color: _bronze, width: 3),
                      },
                    ),
                  ),
          ),
        ),
      ]),
      ),
    );
  }
}

/// Full-screen version of the employee's own Field Duty route — opened by
/// tapping the compact Dashboard card. Same live Firestore listener, just a
/// bigger, interactive map instead of a small static-looking preview.
class EmployeeOwnFieldDutyMapScreen extends StatefulWidget {
  const EmployeeOwnFieldDutyMapScreen({super.key});
  @override
  State<EmployeeOwnFieldDutyMapScreen> createState() => _EmployeeOwnFieldDutyMapScreenState();
}

class _EmployeeOwnFieldDutyMapScreenState extends State<EmployeeOwnFieldDutyMapScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _trail = [];
  StreamSubscription? _trailSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _trailSub = FirebaseFirestore.instance
          .collection('employees').doc(uid)
          .collection('fieldDuty').doc('status')
          .collection('trail')
          .orderBy('recordedAt')
          .snapshots()
          .listen((snap) {
        final points = snap.docs
            .map((d) => LatLng((d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()))
            .toList();
        if (!mounted) return;
        setState(() => _trail = points);
        if (points.isNotEmpty) _mapController?.animateCamera(CameraUpdate.newLatLng(points.last));
      });
    }
  }

  @override
  void dispose() {
    _trailSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendance = Provider.of<EmployeeAttendanceProvider>(context);
    final current = (attendance.fieldDutyCurrentLat != null && attendance.fieldDutyCurrentLng != null)
        ? LatLng(attendance.fieldDutyCurrentLat!, attendance.fieldDutyCurrentLng!)
        : (_trail.isNotEmpty ? _trail.last : null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bronze,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Field Duty Route', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: current == null
          ? const Center(child: CircularProgressIndicator(color: _bronze))
          : Stack(children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: current, zoom: 16),
                onMapCreated: (c) => _mapController = c,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                markers: {
                  if (_trail.isNotEmpty)
                    Marker(markerId: const MarkerId('start'), position: _trail.first,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        infoWindow: const InfoWindow(title: 'Field Duty started')),
                  Marker(markerId: const MarkerId('current'), position: current,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      infoWindow: const InfoWindow(title: 'Current position')),
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
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                    const SizedBox(width: 6),
                    const Text('Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  ]),
                ),
              ),
            ]),
    );
  }
}
