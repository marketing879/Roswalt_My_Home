import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A user-facing OTP failure. Unlike StateError/Exception, toString() is
/// just the message with no "Bad state: " / "Exception: " prefix to strip.
class OtpException implements Exception {
  final String message;
  OtpException(this.message);
  @override
  String toString() => message;
}

/// Custom email OTP verification: a 6-digit code is generated, emailed, and
/// verified entirely by our own Cloud Functions (sendEmailOtp/verifyEmailOtp)
/// + Firestore, since Firebase Auth has no built-in "typed code via email"
/// provider. On success the function mints a Firebase custom token, which we
/// sign in with so the rest of the app can keep using
/// FirebaseAuth.instance.currentUser as the "verified" signal.
class OtpEmailService {
  OtpEmailService._();
  static final OtpEmailService instance = OtpEmailService._();

  static const _prefsEmailKey = 'verified_email';
  static const _prefsEmployeeNameKey = 'verified_employee_name';
  static const _prefsEmployeeIdKey = 'verified_employee_id';
  static const _prefsEmployeeDesignationKey = 'verified_employee_designation';
  final _functions = FirebaseFunctions.instance;
  String? _verifiedEmail;
  String? _employeeName;
  String? _employeeId;
  String? _employeeDesignation;

  // Only these codes come from our own HttpsError(...) calls in the Cloud
  // Function with a genuinely useful message. Anything else (e.g.
  // 'internal', thrown when the function hits an unhandled error such as
  // Nodemailer failing) gets Firebase's generic "INTERNAL" placeholder
  // message, which isn't fit to show a user.
  static const _friendlyCodes = {
    'invalid-argument', 'resource-exhausted', 'deadline-exceeded', 'permission-denied', 'not-found',
  };

  String _friendlyMessage(FirebaseFunctionsException e, String fallback) {
    if (_friendlyCodes.contains(e.code) && (e.message?.isNotEmpty ?? false)) {
      return e.message!;
    }
    return fallback;
  }

  Future<void> sendCode(String email) async {
    try {
      final callable = _functions.httpsCallable('sendEmailOtp');
      await callable.call({'email': email});
    } on FirebaseFunctionsException catch (e) {
      throw OtpException(_friendlyMessage(e, 'Could not send verification code. Please try again.'));
    }
  }

  Future<void> verifyCode(String email, String code) async {
    try {
      final callable = _functions.httpsCallable('verifyEmailOtp');
      final result = await callable.call({'email': email, 'code': code});
      final token = result.data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw OtpException('Verification failed. Please try again.');
      }
      await FirebaseAuth.instance.signInWithCustomToken(token);
      _verifiedEmail = email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsEmailKey, email);
    } on FirebaseFunctionsException catch (e) {
      throw OtpException(_friendlyMessage(e, 'Invalid code. Please try again.'));
    }
  }

  /// Call once at startup (before reading [isVerified]/[verifiedEmail]) to
  /// restore the email associated with a persisted Firebase session, since
  /// a custom-token user has no built-in `.email` property to read back.
  Future<void> restoreCachedEmail() async {
    if (_verifiedEmail != null) return;
    final prefs = await SharedPreferences.getInstance();
    _verifiedEmail = prefs.getString(_prefsEmailKey);
    _employeeName = prefs.getString(_prefsEmployeeNameKey);
    _employeeId = prefs.getString(_prefsEmployeeIdKey);
    _employeeDesignation = prefs.getString(_prefsEmployeeDesignationKey);
  }

  /// Caches the employee's name/ID/designation alongside the verified email
  /// so a relaunched app can restore straight into EmployeeShell without a
  /// fresh SFDC lookup (custom-token users carry no profile fields).
  Future<void> cacheEmployeeProfile(String name, String? employeeId, [String? designation]) async {
    _employeeName = name;
    _employeeId = employeeId;
    _employeeDesignation = designation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsEmployeeNameKey, name);
    if (employeeId != null) await prefs.setString(_prefsEmployeeIdKey, employeeId);
    if (designation != null) await prefs.setString(_prefsEmployeeDesignationKey, designation);
  }

  bool get isVerified => FirebaseAuth.instance.currentUser != null;
  String? get verifiedEmail => _verifiedEmail;
  String? get cachedEmployeeName => _employeeName;
  String? get cachedEmployeeId => _employeeId;
  String? get cachedEmployeeDesignation => _employeeDesignation;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _verifiedEmail = null;
    _employeeName = null;
    _employeeId = null;
    _employeeDesignation = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsEmailKey);
    await prefs.remove(_prefsEmployeeNameKey);
    await prefs.remove(_prefsEmployeeIdKey);
    await prefs.remove(_prefsEmployeeDesignationKey);
  }
}
