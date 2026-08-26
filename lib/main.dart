import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/app_theme.dart';
import 'providers/booking_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/employee_attendance_provider.dart';
import 'providers/employee_lms_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/session_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final notificationProvider = NotificationProvider();
  await notificationProvider.load();
  await NotificationService.instance.initialize(notificationProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeLmsProvider()),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const RoswaltApp(),
    ),
  );
}

class RoswaltApp extends StatelessWidget {
  const RoswaltApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Roswalt My Home',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const SessionWrapper(),
    );
  }
}
