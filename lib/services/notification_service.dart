import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../providers/notification_provider.dart';

// Top-level function required by firebase_messaging for background messages.
// Must be annotated with @pragma('vm:entry-point') and be a top-level or static function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: this runs in a separate isolate with no access to the app's
  // Provider tree, so we can't write to NotificationProvider directly here.
  // Android/iOS will show the system tray notification automatically for
  // background/terminated state as long as the FCM payload includes a
  // "notification" block (not just "data"). This handler is a hook for
  // any additional background-only work (e.g. logging) if needed later.
  debugPrint('Background FCM message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  NotificationProvider? _provider;
  bool _initialized = false;

  Future<void> initialize(NotificationProvider provider) async {
    if (_initialized) return;
    _initialized = true;
    _provider = provider;

    final messaging = FirebaseMessaging.instance;

    // Request permission (required explicitly on Android 13+ and iOS).
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // Subscribe to topics so future sends can target groups without needing
    // individual device tokens.
    try {
      await messaging.subscribeToTopic('construction_updates');
      await messaging.subscribeToTopic('announcements');
      debugPrint('Subscribed to topics: construction_updates, announcements');
    } catch (e) {
      debugPrint('Topic subscription error: ' + e.toString());
    }

    // Foreground messages: FCM does NOT auto-show a system tray notification
    // while the app is open, so we record it into our in-app history here.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message: ${message.messageId}');
      final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      _provider?.addNotification(title: title, body: body, data: message.data);
    });

    // When the user taps a notification and it opens/resumes the app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.messageId}');
      final title = message.notification?.title ?? message.data['title'] ?? 'Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      _provider?.addNotification(title: title, body: body, data: message.data);
    });

    // If the app was launched (from terminated state) by tapping a notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state via notification: ${initialMessage.messageId}');
      final title = initialMessage.notification?.title ?? initialMessage.data['title'] ?? 'Notification';
      final body = initialMessage.notification?.body ?? initialMessage.data['body'] ?? '';
      _provider?.addNotification(title: title, body: body, data: initialMessage.data);
    }

    // Save this device's FCM token against the signed-in employee so Cloud
    // Functions can push targeted alerts (e.g. leave/regularisation
    // decisions) instead of only broadcast topics. Runs on every sign-in
    // (login, or session restore on relaunch) and on token rotation.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) await _saveTokenForUser(currentUser.uid);
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _saveTokenForUser(user.uid);
    });
    messaging.onTokenRefresh.listen((newToken) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _saveToken(uid, newToken);
    });
  }

  Future<void> _saveTokenForUser(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(uid, token);
    } catch (e) {
      debugPrint('Error fetching FCM token: ' + e.toString());
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('employees').doc(uid).collection('meta').doc('fcm')
          .set({'token': token, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: ' + e.toString());
    }
  }
}

