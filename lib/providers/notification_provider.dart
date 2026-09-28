import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.data = const {},
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'data': data,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        receivedAt: DateTime.tryParse(j['receivedAt'] ?? '') ?? DateTime.now(),
        data: Map<String, dynamic>.from(j['data'] ?? {}),
        read: j['read'] ?? false,
      );
}

class NotificationProvider extends ChangeNotifier {
  static const _storageKey = 'app_notifications_history';
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _notifications = list.map((e) => AppNotification.fromJson(e)).toList();
        _notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('NotificationProvider load error: ' + e.toString());
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('NotificationProvider persist error: ' + e.toString());
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final n = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      data: data,
    );
    _notifications.insert(0, n);
    if (_notifications.length > 200) {
      _notifications = _notifications.sublist(0, 200);
    }
    notifyListeners();
    await _persist();
  }

  /// Pulls the durable server-side history from
  /// `employees/{uid}/notifications` (written by Cloud Functions, e.g. leave
  /// / regularisation decisions) and merges it into the local list, so the
  /// panel always reflects these events even if the push itself was missed
  /// (device offline, notification dismissed without tapping, app killed).
  Future<void> syncFromFirestore(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('employees').doc(uid).collection('notifications')
          .orderBy('createdAt', descending: true).limit(50).get();

      final existingIds = _notifications.map((n) => n.id).toSet();
      var changed = false;
      for (final d in snap.docs) {
        if (existingIds.contains(d.id)) continue;
        final data = d.data();
        _notifications.add(AppNotification(
          id: d.id,
          title: (data['title'] as String?) ?? 'Notification',
          body: (data['body'] as String?) ?? '',
          receivedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          data: Map<String, dynamic>.from(data['data'] ?? {}),
          read: (data['read'] as bool?) ?? false,
        ));
        changed = true;
      }
      if (changed) {
        _notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        notifyListeners();
        await _persist();
      }
    } catch (e) {
      debugPrint('NotificationProvider syncFromFirestore error: ' + e.toString());
    }
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _notifications = [];
    notifyListeners();
    await _persist();
  }
}
