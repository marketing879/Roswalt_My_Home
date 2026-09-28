import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../config/secrets.dart' as secrets;

// ── SFDC CONFIG (loaded from gitignored lib/config/secrets.dart) ──
const String _sfdcBaseUrl = secrets.sfdcBaseUrl;
const String _clientId = secrets.sfdcClientId;
const String _clientSecret = secrets.sfdcClientSecret;
const String _demandsClientId = secrets.demandsClientId;
const String _demandsClientSecret = secrets.demandsClientSecret;
const String _demandsUsername = secrets.demandsUsername;
const String _demandsPassword = secrets.demandsPassword;
class BookingData {
  final String bookingId;       // B-0408 (bookingNumber)
  final String sfdcId;          // a0AC4000001ReC5MAK (internal)
  final String clientName;
  final String projectName;
  final String unitNumber;
  final String towerName;
  String get tower => towerName;
  final String status;
  final String phone;
  final String email;
  // Fields from future API calls (defaults for now)
  final String floor;
  final String bhkType;
  final String bookingDate;
  final String bookingAmount;
  final String possessionDate;
  final int constructionProgress;
  final List<Map<String, dynamic>> milestones;
  final List<Map<String, dynamic>> alerts;
  final String customerType;
  final String carpetArea;
  final String carParking;
  final String flatType;
  final String bookingStage;
  final String registrationStatus;
  final List<Map<String,dynamic>> files;
  final String registrationDate;

  BookingData({
    required this.bookingId,
    required this.sfdcId,
    required this.clientName,
    required this.projectName,
    required this.unitNumber,
    required this.towerName,
    required this.status,
    required this.phone,
    this.email = '',
    this.floor = '--',
    this.bhkType = '--',
    this.bookingDate = '--',
    this.bookingAmount = '--',
    this.possessionDate = '--',
    this.constructionProgress = 0,
    this.milestones = const [],
    this.alerts = const [],
    this.customerType = 'Buyer',
    this.carpetArea = '--',
    this.carParking = '--',
    this.flatType = '--',
    this.bookingStage = '--',
    this.registrationStatus = '--',
    this.files = const [],
    this.registrationDate = '--',
  });

  // ── Build from SFDC JSON ──
  static List<Map<String,dynamic>> _parseFiles(Map<String,dynamic> json) {
    debugPrint('SFDC ALL KEYS: ' + json.keys.toList().toString());
    for (final key in ['files','KYCFiles','documents','bookingFiles','attachments','Attachments','Documents','Files']) {
      final val = json[key];
      if (val is List && val.isNotEmpty) {
        debugPrint('Found files under key: ' + key);
        return val.map((f) => Map<String,dynamic>.from(f as Map)).toList();
      }
    }
    return [];
  }

  factory BookingData.fromSfdc(Map<String, dynamic> json, String phone) {
    // Format amount
    String formatAmount(dynamic val) {
      if (val == null) return '--';
      final num amount = val is num ? val : double.tryParse(val.toString()) ?? 0;
      if (amount == 0) return '--';
      final inLakhs = amount / 100000;
      if (inLakhs >= 100) {
        return '\u20b9' + (amount / 10000000).toStringAsFixed(2) + ' Cr';
      }
      return '\u20b9' + inLakhs.toStringAsFixed(2) + ' L';
    }

    return BookingData(
      bookingId: json['bookingNumber'] ?? '--',
      sfdcId: json['bookingId'] ?? '',
      clientName: json['applicantName'] ?? 'Customer',
      projectName: json['projectName'] ?? '--',
      unitNumber: json['unitName'] ?? '--',
      towerName: json['towerName'] ?? '--',
      status: json['ApprovalStatus'] ?? json['status'] ?? '--',
      phone: phone,
      email: json['Email'] ?? '',
      floor: json['Floor'] != null ? json['Floor'].toString() : '--',
      bhkType: json['FlatType'] ?? '--',
      carpetArea: json['CarpetArea'] != null ? json['CarpetArea'].toString() + ' sqft' : '--',
      carParking: json['CarPark'] ?? '--',
      flatType: json['InventoryType'] ?? json['FlatType'] ?? '--',
      bookingStage: json['BookingStage'] ?? '--',
      registrationStatus: json['RegistrationStatus'] ?? '--',
      files: _parseFiles(json),
      registrationDate: json['RgistrationNumber'] ?? '--',
      bookingDate: json['BookingDate'] ?? '--',
      bookingAmount: formatAmount(json['AgreeementAmount']),
      possessionDate: json['PossessionDate'] ?? '--',
      customerType: (json['bookingNumber'] != null && 
          (json['bookingNumber'] as String).isNotEmpty && 
          (json['bookingNumber'] as String).startsWith('B-')) 
          ? 'Buyer' : 'Tenant',
      alerts: [
        {
          'title': 'Booking Status',
          'desc': 'Your booking ${json['bookingNumber']} status: ${json['ApprovalStatus'] ?? json['status'] ?? '--'}',
          'time': 'Now',
        },
      ],
    );
  }
  BookingData copyWith({List<Map<String,dynamic>>? files}) {
    return BookingData(
      bookingId: bookingId,
      sfdcId: sfdcId,
      clientName: clientName,
      projectName: projectName,
      unitNumber: unitNumber,
      towerName: towerName,
      status: status,
      phone: phone,
      email: email,
      floor: floor,
      bhkType: bhkType,
      bookingDate: bookingDate,
      bookingAmount: bookingAmount,
      possessionDate: possessionDate,
      constructionProgress: constructionProgress,
      milestones: milestones,
      alerts: alerts,
      customerType: customerType,
      carpetArea: carpetArea,
      carParking: carParking,
      flatType: flatType,
      bookingStage: bookingStage,
      registrationStatus: registrationStatus,
      registrationDate: registrationDate,
      files: files ?? this.files,
    );
  }
}
class BookingProvider extends ChangeNotifier {
  BookingData? _selectedBooking;
  List<BookingData> _allBookings = [];
  bool _isLoading = false;
  String? _error;
  String? _accessToken;

  BookingData? get selectedBooking => _selectedBooking;
  List<BookingData> get allBookings => _allBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _selectedBooking != null;

  // ── STEP 1: Get SFDC Access Token ──
  Future<String?> _getSfdcToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://login.salesforce.com/services/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'password',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'username': _demandsUsername,
          'password': _demandsPassword,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('SFDC FULL RESPONSE: ' + response.body.substring(0, response.body.length > 500 ? 500 : response.body.length));
        return data['access_token'] as String?;
      } else {
        debugPrint('SFDC Auth Error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('SFDC Auth Exception: $e');
      return null;
    }
  }

  // ── STEP 2: Fetch Bookings by Phone ──
  Future<List<String>> fetchPhonesByEmail(String email) async {
    try {
      final token = await _getSfdcToken();
      if (token == null) return [];
      final phones = <String>{};
      final queries = [
        "SELECT Mobile_Number__c FROM Applicant__c WHERE Email__c = '' LIMIT 10",
        "SELECT Mobile_Number__c FROM Applicant__c WHERE Email = '' LIMIT 10",
      ];
      for (final soql in queries) {
        try {
          final res = await http.get(
            Uri.parse("$_sfdcBaseUrl/services/data/v59.0/query?q=${Uri.encodeComponent(soql)}"),
            headers: {"Authorization": "Bearer $token"},
          );
          debugPrint("Email lookup: ${res.statusCode} ${res.body.length > 200 ? res.body.substring(0,200) : res.body}");
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final records = data["records"] as List? ?? [];
            for (final r in records) {
              for (final v in (r as Map).values) {
                if (v != null && v is String && v.length >= 10) phones.add(v);
              }
            }
          }
        } catch (_) {}
      }
      debugPrint("Phones found: $phones");
      return phones.toList();
    } catch (e) { debugPrint("Email lookup error: $e"); }
    return [];
  }
  Future<bool> fetchBookingsByPhone(String phone) async {
    _isLoading = true;
    _error = null;
    _allBookings = [];
    _selectedBooking = null;
    notifyListeners();

    try {
      // Get token
      final token = await _getSfdcToken();
      if (token == null) {
        _error = 'Unable to connect to Salesforce.\nPlease try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _accessToken = token;

      // Fetch bookings
      final cleanPhone = phone.trim().replaceAll(' ', '');
      final response = await http.get(
        Uri.parse(
            '$_sfdcBaseUrl/services/apexrest/mobile/bookings?mobileNumber=$cleanPhone'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final bookings =
              data['bookings'] as List<dynamic>? ?? [];
          if (bookings.isEmpty) {
            _error =
                'No bookings found for this mobile number.\nPlease check and try again.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
          _allBookings = bookings
              .map((b) => BookingData.fromSfdc(
                  b as Map<String, dynamic>, cleanPhone))
              .toList();


          // If only 1 booking, auto-select it
          if (_allBookings.length == 1) {
            _selectedBooking = _allBookings.first;
          }

          _isLoading = false;
          notifyListeners();
          // Fetch documents for all bookings
          for (final b in _allBookings) {
            _fetchDocumentsForBooking(b.sfdcId, token);
          }
          return true;
        } else {
          _error = data['message'] ??
              'No bookings found. Please check your number.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _error =
            'Server error (${response.statusCode}). Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Booking fetch error: $e');
      _error =
          'Network error. Please check your internet connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Fetch documents from SFDC directly ──
  Future<void> _fetchDocumentsForBooking(String sfdcId, String token) async {
    try {
      final linkRes = await http.get(
        Uri.parse('$_sfdcBaseUrl/services/data/v59.0/query?q=SELECT+Id,+ContentDocumentId+FROM+ContentDocumentLink+WHERE+LinkedEntityId=\'' + sfdcId + '\''),
        headers: {'Authorization': 'Bearer ' + token},
      );
      if (linkRes.statusCode != 200) return;
      final linkData = jsonDecode(linkRes.body);
      final links = linkData['records'] as List<dynamic>? ?? [];
      if (links.isEmpty) return;
      final ids = links.map((l) => "'" + (l['ContentDocumentId'] as String) + "'").join(',');
      final docRes = await http.get(
        Uri.parse('$_sfdcBaseUrl/services/data/v59.0/query?q=SELECT+Id,+Title,+FileExtension+FROM+ContentDocument+WHERE+Id+IN+(' + ids + ')'),
        headers: {'Authorization': 'Bearer ' + token},
      );
      if (docRes.statusCode != 200) return;
      final docData = jsonDecode(docRes.body);
      final docs = docData['records'] as List<dynamic>? ?? [];
      final files = docs.map((d) => <String,dynamic>{
        'fileName': d['Title'] as String? ?? 'Unknown',
        'fileType': d['FileExtension'] as String? ?? '',
        'downloadUrl': '$_sfdcBaseUrl/services/data/v59.0/sobjects/ContentDocument/' + (d['Id'] as String) + '/LatestPublishedVersion/VersionData?access_token=' + token,
      }).toList();
      if (_selectedBooking != null && _selectedBooking!.sfdcId == sfdcId) {
        _selectedBooking = _selectedBooking!.copyWith(files: files);
      }
      _allBookings = _allBookings.map((b) => b.sfdcId == sfdcId ? b.copyWith(files: files) : b).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchDocuments error: ' + e.toString());
    }
  }

  // ── Select a specific booking ──
  void selectBooking(BookingData booking) {
    _selectedBooking = booking;
    notifyListeners();
  }


  void clearBooking() {
    _selectedBooking = null;
    _allBookings = [];
    _error = null;
    _accessToken = null;
    notifyListeners();
  }

  // Keep backward compat
  List<Map<String, dynamic>> _demands = [];
  List<Map<String, dynamic>> get demands => _demands;

  Future<void> fetchDemands(String bookingName) async {
    try {
      final tokenRes = await http.post(
        Uri.parse('https://login.salesforce.com/services/oauth2/token'),
        body: {
          'grant_type': 'password',
          'client_id': _demandsClientId,
          'client_secret': _demandsClientSecret,
          'username': _demandsUsername,
          'password': _demandsPassword,
        },
      );
      if (tokenRes.statusCode != 200) {
        debugPrint('Demands token failed: ${tokenRes.statusCode}');
        return;
      }
      final token = jsonDecode(tokenRes.body)['access_token'] as String;
      final res = await http.post(
        Uri.parse('$_sfdcBaseUrl/services/apexrest/bookingDemands/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'BookingName': bookingName}),
      );
      debugPrint('Demands response: ${res.statusCode} ${res.body.substring(0, res.body.length > 400 ? 400 : res.body.length)}');
      if (res.statusCode == 200) {
          final raw = jsonDecode(res.body);
          final data = raw is String ? jsonDecode(raw) : raw;
        List<dynamic> rawList = [];
        if (data is List) { rawList = data; }
        else if (data is Map) { rawList = data['Demands'] ?? data['demands'] ?? data['records'] ?? []; }
        _demands = rawList.map((d) {
          final m = Map<String, dynamic>.from(d);
          final amt = (m['TotalAmountDemanded'] ?? 0).toDouble();
          final tax = (m['TotalTaxDemanded'] ?? 0).toDouble();
          return {
            'name': m['MilestoneName'] ?? m['name'] ?? '--',
            'date': m['Due_Date__c'] ?? m['date'] ?? '--',
            'amount': (amt + tax).toStringAsFixed(0),
            'netAmount': amt.toStringAsFixed(0),
            'tax': tax.toStringAsFixed(0),
            'status': _deriveStatus(m['Due_Date__c']),
            'demandNo': m['Name'] ?? '',
            'invoiceDate': m['InvoiceDate'] ?? '',
            'demandLink': m['DemandLink'] ?? '',
            'id': m['Id'] ?? '',
          };
        }).toList();
      }
    } catch (e) { debugPrint('Demands error: $e'); }
  }
  List<Map<String, dynamic>> _receipts = [];
  List<Map<String, dynamic>> get receipts => _receipts;

  Future<void> fetchReceipts(String bookingName) async {
    _receipts = [];
    try {
      final tokenRes = await http.post(
        Uri.parse('https://login.salesforce.com/services/oauth2/token'),
        body: {'grant_type': 'password', 'client_id': _demandsClientId, 'client_secret': _demandsClientSecret, 'username': _demandsUsername, 'password': _demandsPassword},
      );
      if (tokenRes.statusCode != 200) return;
      final token = jsonDecode(tokenRes.body)['access_token'];
      final res = await http.post(
        Uri.parse('$_sfdcBaseUrl/services/apexrest/bookingReceipts/'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'BookingName': bookingName}),
      );
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);
        final data = raw is String ? jsonDecode(raw) : raw;
        final List rawList = data is List ? data : (data['Receipts'] ?? data['receipts'] ?? []);
        _receipts = rawList.map<Map<String, dynamic>>((r) => <String, dynamic>{
          'receiptNumber': r['ReceiptNumber'] ?? r['Name'] ?? '--',
          'totalAmount': r['TotalAmount']?.toString() ?? '0',
          'projectName': r['ProjectName'] ?? '--',
          'cgst': (r['CGST__c'] ?? r['CGST'] ?? 0).toString(),
          'sgst': (r['SGST__c'] ?? r['SGST'] ?? 0).toString(),
          'receiptStatus': r['PaymentStatus'] ?? '--',
          'receiptSource': r['ReceiptSource'] ?? '--',
          'receiptType': r['ReceiptType'] ?? '--',
          'transactionId': r['TransactionID']?.toString() ?? '--',
          'paymentStatus': r['PaymentStatus'] ?? '--',
          'receiptDate': r['ReceiptDate'] ?? '--',
          'paymentMethod': r['PaymentMethod'] ?? '--',
          'milestoneName': r['Name'] ?? '--',
        }).toList();
        _receipts.sort((a, b) => (b['receiptDate'] ?? '').compareTo(a['receiptDate'] ?? '')); for(final r in _receipts) { debugPrint('Receipt: ' + (r['milestoneName'] ?? '') + ' | ' + (r['totalAmount'] ?? '').toString() + ' | ' + (r['receiptDate'] ?? '')); } debugPrint('Total receipts: ' + _receipts.length.toString() + ' Total: ' + _receipts.fold<double>(0, (s, r) { try { return s + double.parse(r['totalAmount'].toString()); } catch(_) { return s; } }).toString());
      }
    } catch (e) { debugPrint('Receipts error: $e'); }
  }

  // Fetch demands+receipts for ALL bookings for ledger PDF
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> fetchAllBookingsData() async {
    final result = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final b in _allBookings) {
      await fetchDemands(b.bookingId);
      final d = List<Map<String, dynamic>>.from(_demands);
      await fetchReceipts(b.bookingId);
      final r = List<Map<String, dynamic>>.from(_receipts);
      result[b.bookingId] = {'demands': d, 'receipts': r};
    }
    // Restore selected booking data
    if (_selectedBooking != null) {
      await fetchDemands(_selectedBooking!.bookingId);
      await fetchReceipts(_selectedBooking!.bookingId);
    }
    return result;
  }

String _deriveStatus(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) return 'upcoming';
    try {
      final due = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final diff = due.difference(now).inDays;
      if (diff < 0) return 'paid';
      if (diff <= 30) return 'due';
      return 'upcoming';
    } catch (_) { return 'upcoming'; }
  }
  BookingData? get bookingData => _selectedBooking;
  Future<void> persistSession() async {
    if (_selectedBooking == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_phone', _selectedBooking!.phone);
    await prefs.setString('saved_booking_id', _selectedBooking!.bookingId);
    if (_accessToken != null) await prefs.setString('saved_token', _accessToken!);
  }
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('saved_phone');
    if (phone == null || phone.isEmpty) return false;
    final success = await fetchBookingsByPhone(phone);
    return success;
  }
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_phone');
    await prefs.remove('saved_token');
    clearBooking();
  }
  String? get accessToken => _accessToken;
  // ── CP Dashboard (MahaRERA-based) ──
  Map<String, dynamic>? _cpDashboardData;
  Map<String, dynamic>? get cpDashboardData => _cpDashboardData;
  String? _mahaRERA;
  String? get mahaRERA => _mahaRERA;
  String? _cpLoginError;
  String? get cpLoginError => _cpLoginError;
  bool _cpLoading = false;
  bool get cpLoading => _cpLoading;

  Future<bool> loginCPWithMahaRERA(String mahaRera) async {
    _cpLoading = true;
    _cpLoginError = null;
    notifyListeners();
    try {
      final token = await _getSfdcToken();
      if (token == null) {
        _cpLoginError = 'Could not connect. Please try again.';
        _cpLoading = false;
        notifyListeners();
        return false;
      }
      final cleanRera = mahaRera.trim();
      final response = await http.get(
        Uri.parse('$_sfdcBaseUrl/services/apexrest/mobile/cpDashboard?MahaRERA=$cleanRera'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _cpDashboardData = data['data'] as Map<String, dynamic>?;
          _mahaRERA = cleanRera;
          _cpLoading = false;
          notifyListeners();
          return true;
        } else {
          _cpLoginError = data['message'] ?? 'MahaRERA number not found. Please check and try again.';
          _cpLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _cpLoginError = 'Server error (${response.statusCode}). Please try again.';
        _cpLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('CP Dashboard error: $e');
      _cpLoginError = 'Something went wrong. Please try again.';
      _cpLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshCPDashboard() async {
    if (_mahaRERA == null) return;
    await loginCPWithMahaRERA(_mahaRERA!);
  }

  // ── Employee Lookup ──
  // NOTE: 'services/apexrest/mobile/employeeLookup' does not exist on the
  // SFDC org yet — this is the agreed contract for the backend team to
  // build. Expected response: {"success": true, "data": {"name": "...",
  // "employeeId": "...", "email": "..."}} or {"success": false, "message":
  // "..."}. The app-side call is fully wired and will work as soon as that
  // endpoint exists.
  Future<Map<String, dynamic>?> lookupEmployeeByPhone(String phone) async {
    _error = null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    // Org-wide staff directory (Firestore, looked up server-side via this
    // callable so the directory itself is never exposed to unauthenticated
    // clients) — populated with name/designation for everyone, phone/email
    // filled in as they're provided. Once a record has a matching phone and
    // loginEnabled=true, this lets that person log in without waiting on
    // the real SFDC employeeLookup endpoint to exist.
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('lookupStaffByPhone').call({'phone': digits});
      final data = result.data;
      if (data is Map && data['found'] == true) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
    } catch (e) {
      debugPrint('staffDirectory lookup error: $e');
    }

    try {
      final token = await _getSfdcToken();
      if (token == null) {
        _error = 'Unable to connect. Please try again.';
        return null;
      }
      final res = await http.get(
        Uri.parse('$_sfdcBaseUrl/services/apexrest/mobile/employeeLookup?mobileNumber=$phone'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return data['data'] as Map<String, dynamic>?;
        _error = data['message'] ?? 'No employee record found for this number.';
        return null;
      }
      _error = 'Server error (${res.statusCode}). Please try again.';
      return null;
    } catch (e) {
      debugPrint('lookupEmployeeByPhone error: $e');
      _error = 'Network error. Please check your connection.';
      return null;
    }
  }

  // ── CP Walk-In Submission ──
  // NOTE: 'services/apexrest/mobile/cpWalkin' does not exist on the SFDC org
  // yet (confirmed 404 with a valid token) — this is the agreed contract for
  // the backend team to build. The app-side call is fully wired and will
  // work as soon as that endpoint exists.
  String? _cpWalkInError;
  String? get cpWalkInError => _cpWalkInError;

  Future<bool> submitCPWalkIn({
    required String project,
    required String clientName,
    required String clientPhone,
    String? configuration,
    String? budget,
    String? cpFirm,
    String? cpName,
    String? sourcingManager,
    String? status,
  }) async {
    _cpWalkInError = null;
    try {
      final token = await _getSfdcToken();
      if (token == null) {
        _cpWalkInError = 'Unable to connect. Please try again.';
        return false;
      }
      final res = await http.post(
        Uri.parse('$_sfdcBaseUrl/services/apexrest/mobile/cpWalkin'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'mahaRERA': _mahaRERA ?? '',
          'project': project,
          'clientName': clientName,
          'clientPhone': clientPhone,
          'configuration': configuration ?? '',
          'budget': budget ?? '',
          'cpFirm': cpFirm ?? '',
          'cpName': cpName ?? '',
          'sourcingManager': sourcingManager ?? '',
          'status': status ?? 'Hot',
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) return true;
        _cpWalkInError = data['message'] ?? 'Could not save this walk-in. Please try again.';
        return false;
      }
      _cpWalkInError = 'Server error (${res.statusCode}). Please try again.';
      return false;
    } catch (e) {
      debugPrint('submitCPWalkIn error: $e');
      _cpWalkInError = 'Network error. Please check your connection.';
      return false;
    }
  }

}
