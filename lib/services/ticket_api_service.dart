import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/ticket.dart';
import '../models/org_chart.dart';

class TicketApiException implements Exception {
  final String message;
  TicketApiException(this.message);
  @override
  String toString() => message;
}

/// Thin REST client for the Roswalt Sales App ticketing backend. This is a
/// SEPARATE system from Firebase/My Home — its own email-OTP session, its
/// own bearer token, its own host. Everything here mirrors
/// Roswalt_Ticketing_Integration_Spec.pdf sections 2-4 exactly.
class TicketApiService {
  TicketApiService._();
  static final TicketApiService instance = TicketApiService._();

  static const _base = 'https://sales-api.roswaltsmartcue.com';
  static const _tokenKey = 'ticket_api_token';
  final _storage = const FlutterSecureStorage();
  String? _token;

  // API key for the Channel Partner invoice endpoint, injected at build time
  // via --dart-define=SALES_API_KEY=... (never hardcode it here). CP invoice
  // submission authenticates with this static key rather than the per-user
  // bearer token above, since a Channel Partner never goes through the
  // ticketing module's email-OTP login.
  static const _cpInvoiceApiKey = String.fromEnvironment('SALES_API_KEY');

  Future<void> _loadToken() async {
    _token ??= await _storage.read(key: _tokenKey);
  }

  Future<bool> get hasToken async {
    await _loadToken();
    return _token != null && _token!.isNotEmpty;
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  dynamic _decode(http.Response res) {
    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) body = Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (_) {}
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw TicketApiException(body['error']?.toString() ?? 'Something went wrong (${res.statusCode}).');
  }

  // ---------------- Auth ----------------

  Future<void> requestOtp(String email) async {
    final res = await http
        .post(Uri.parse('$_base/api/v1/auth/request-otp'), headers: _authHeaders, body: jsonEncode({'email': email}))
        .timeout(const Duration(seconds: 20));
    _decode(res);
  }

  /// Returns the logged-in user profile on success; stores the bearer token.
  Future<TicketAppUser> verifyOtp(String email, String otp) async {
    final res = await http
        .post(Uri.parse('$_base/api/v1/auth/verify-otp'), headers: _authHeaders, body: jsonEncode({'email': email, 'otp': otp}))
        .timeout(const Duration(seconds: 20));
    final data = _decode(res) as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) throw TicketApiException('Verification failed. Please try again.');
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
    return TicketAppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<TicketAppUser> me() async {
    await _loadToken();
    final res = await http.get(Uri.parse('$_base/api/v1/auth/me'), headers: _authHeaders).timeout(const Duration(seconds: 20));
    final data = _decode(res) as Map<String, dynamic>;
    return TicketAppUser.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$_base/api/v1/auth/logout'), headers: _authHeaders).timeout(const Duration(seconds: 10));
    } catch (_) {
      // best-effort; clear local state regardless
    }
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  // ---------------- Tickets: list / create ----------------

  Future<List<Ticket>> listTickets() async {
    final res = await http.get(Uri.parse('$_base/api/v1/tickets'), headers: _authHeaders).timeout(const Duration(seconds: 25));
    Map<String, dynamic> body = {};
    List list = [];
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map) {
        body = Map<String, dynamic>.from(decoded);
        list = (body['tickets'] ?? body['data'] ?? []) as List;
      }
    } catch (_) {}
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TicketApiException(body['error']?.toString() ?? 'Could not load tickets (${res.statusCode}).');
    }
    return list.map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Ticket> createTicket({
    required String category,
    String? customCategory,
    required String subject,
    required String description,
    required String project,
    required bool requiresDataAccess,
  }) async {
    final res = await http
        .post(Uri.parse('$_base/api/v1/tickets'),
            headers: _authHeaders,
            body: jsonEncode({
              'category': category,
              if (customCategory != null && customCategory.isNotEmpty) 'customCategory': customCategory,
              'subject': subject,
              'description': description,
              'project': project,
              'requiresDataAccess': requiresDataAccess,
            }))
        .timeout(const Duration(seconds: 25));
    return Ticket.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // ---------------- Stage transitions ----------------

  Future<Ticket> _patch(String path, Map<String, dynamic> body) async {
    final res = await http
        .patch(Uri.parse('$_base/api/v1/tickets/$path'), headers: _authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));
    return Ticket.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<Ticket> hodDecision(String id, String decision) => _patch('$id/hod-decision', {'decision': decision});

  Future<Ticket> guardianDecision(String id, String decision, {DateTime? accessExpiresAt}) => _patch(
      '$id/guardian-decision',
      {'decision': decision, if (accessExpiresAt != null) 'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String()});

  Future<Ticket> setTimeline(String id, {required DateTime dueDate, required String doerName}) =>
      _patch('$id/timeline', {'dueDate': dueDate.toUtc().toIso8601String(), 'doerName': doerName});

  Future<Ticket> markComplete(String id, {required String doerName}) => _patch('$id/complete', {'doerName': doerName});

  Future<Ticket> confirm(String id, {required bool confirmed}) => _patch('$id/confirm', {'confirmed': confirmed});

  Future<Ticket> primeAdminReject(String id, {required String reason}) =>
      _patch('$id/prime-admin-reject', {'reason': reason});

  Future<Ticket> forwardToGuardian(String id) => _patch('$id/forward-guardian', {});

  Future<void> deleteTicket(String id) async {
    final res = await http.delete(Uri.parse('$_base/api/v1/tickets/$id'), headers: _authHeaders).timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Map<String, dynamic> body = {};
      try {
        body = Map<String, dynamic>.from(jsonDecode(res.body));
      } catch (_) {}
      throw TicketApiException(body['error']?.toString() ?? 'Could not delete ticket (${res.statusCode}).');
    }
  }

  // ---------------- Attachments & comments ----------------

  Future<Ticket> addAttachmentFile(String id, File file) async {
    final uri = Uri.parse('$_base/api/v1/tickets/$id/attachments/file');
    final req = http.MultipartRequest('POST', uri);
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    return Ticket.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<Ticket> addAttachmentLink(String id, {required String url, String? label}) async {
    final res = await http
        .post(Uri.parse('$_base/api/v1/tickets/$id/attachments/link'),
            headers: _authHeaders, body: jsonEncode({'url': url, if (label != null) 'label': label}))
        .timeout(const Duration(seconds: 20));
    return Ticket.fromJson(_decode(res) as Map<String, dynamic>);
  }

  Future<Ticket> addComment(String id, String message) async {
    final res = await http
        .post(Uri.parse('$_base/api/v1/tickets/$id/comments'), headers: _authHeaders, body: jsonEncode({'message': message}))
        .timeout(const Duration(seconds: 20));
    return Ticket.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // ---------------- Org chart (read-only, same session) ----------------

  Future<List<dynamic>> _getList(String path) async {
    final res = await http.get(Uri.parse('$_base$path'), headers: _authHeaders).timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Map<String, dynamic> body = {};
      try {
        body = Map<String, dynamic>.from(jsonDecode(res.body));
      } catch (_) {}
      throw TicketApiException(body['error']?.toString() ?? 'Could not load org chart (${res.statusCode}).');
    }
    final decoded = jsonDecode(res.body);
    return decoded is List ? decoded : <dynamic>[];
  }

  /// GET /api/v1/org-chart — flat person directory (names only). Use only to
  /// turn a personId into a display name / resolve the logged-in user's own
  /// personId by name — never for reporting relationships (see OrgPerson doc).
  Future<List<OrgPerson>> fetchOrgChart() async {
    final list = await _getList('/api/v1/org-chart');
    return list.map((e) => OrgPerson.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// GET /api/v1/org-structure — the authoritative Project > Department >
  /// Sub-Department > People hierarchy. The only correct source for "who
  /// reports to whom".
  Future<List<OrgProjectStructure>> fetchOrgStructure() async {
    final list = await _getList('/api/v1/org-structure');
    return list.map((e) => OrgProjectStructure.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  String attachmentDownloadUrl(String relativeOrAbsoluteUrl) {
    if (relativeOrAbsoluteUrl.startsWith('http')) return relativeOrAbsoluteUrl;
    return '$_base$relativeOrAbsoluteUrl';
  }

  // ---------------- Channel Partner invoice submission ----------------

  // Confirmed live against the real Sales API on 2026-10-19 (curl probing,
  // bypassing the app entirely): base path is '/api/v1/cp-invoices', not
  // '/api/v1/channel-partner/invoices' as originally guessed. GET with a
  // 'mahaRera' query param looks up a CP's invoices; POST (multipart) with
  // the same field name plus 'name'/'mobile' required and the file under
  // the field name 'file' (not 'invoice') submits one. Auth is the static
  // API key (X-API-Key), not the bearer token used elsewhere in this file,
  // since Channel Partners authenticate via MahaRERA number rather than the
  // ticketing module's email-OTP login.
  // In-memory store for mockInvoiceSubmission mode, so the Payouts list
  // reflects invoices "submitted" via the mock path above instead of hitting
  // the real (and, for an unregistered test MahaRERA, empty) lookup.
  static final List<Map<String, dynamic>> _mockInvoices = [];

  // Mock-mode tracking for the brokerage-confirmation-flash feature: which
  // PACO-confirmed claims the CP has already acknowledged, so a demo claim
  // can be re-queried across polls/refreshes without re-prompting forever.
  static final Set<String> _mockAcknowledgedClaimIds = {};
  static const _mockDemoClaimId = 'mock-claim-zaiden-2878';

  Future<List<Map<String, dynamic>>> lookupChannelPartnerInvoices(String mahaRera) async {
    if (mockInvoiceSubmission) {
      await Future.delayed(const Duration(milliseconds: 300));
      final acknowledged = _mockAcknowledgedClaimIds.contains(_mockDemoClaimId);
      // Demo PACO-confirmed brokerage claim (per Brokerage Confirmation Flash
      // spec) so the flash/acknowledge/raise-invoice flow can be exercised
      // end-to-end without a real PACO confirmation existing server-side.
      final demoClaim = {
        'id': _mockDemoClaimId,
        'bookingId': 'B-2878',
        'unitNo': 'ZAIDEN-2502',
        'clientName': 'Demo Client',
        'project': 'ROSWALT ZAIDEN',
        'mahaRera': mahaRera,
        'amount': '125000',
        'brokeragePct': null,
        'status': 'AWAITING INVOICE',
        'confirmedByName': 'Rashmi Arde',
        'confirmedAt': DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String(),
        'needsAck': !acknowledged,
        'acknowledgedAt': acknowledged ? DateTime.now().toUtc().toIso8601String() : '',
        'canUpload': acknowledged,
      };
      return [demoClaim, ..._mockInvoices.where((inv) => inv['mahaRera'] == mahaRera)];
    }
    if (_cpInvoiceApiKey.isEmpty) {
      throw TicketApiException('Invoice lookup is not configured on this build. Missing SALES_API_KEY.');
    }
    final uri = Uri.parse('$_base/api/v1/cp-invoices?mahaRera=${Uri.encodeQueryComponent(mahaRera)}');
    final res = await http.get(uri, headers: {'X-API-Key': _cpInvoiceApiKey}).timeout(const Duration(seconds: 25));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      Map<String, dynamic> body = {};
      try {
        body = Map<String, dynamic>.from(jsonDecode(res.body));
      } catch (_) {}
      throw TicketApiException(body['error']?.toString() ?? 'Could not load invoices (${res.statusCode}).');
    }
    final list = jsonDecode(res.body);
    return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Acknowledges a PACO-confirmed brokerage amount (Brokerage Confirmation
  // Flash spec, section 6). Required before the matching invoice can be
  // raised - the real server returns 404 if claimId/mahaRera don't match a
  // confirmed brokerage, and 409 if there's nothing left to acknowledge.
  // Acknowledging twice is harmless server-side.
  Future<Map<String, dynamic>> acknowledgeChannelPartnerInvoice({
    required String claimId,
    required String mahaRera,
  }) async {
    if (mockInvoiceSubmission) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mockAcknowledgedClaimIds.add(claimId);
      return {
        'id': claimId,
        'needsAck': false,
        'canUpload': true,
        'acknowledgedAt': DateTime.now().toUtc().toIso8601String(),
      };
    }
    if (_cpInvoiceApiKey.isEmpty) {
      throw TicketApiException('Acknowledgement is not configured on this build. Missing SALES_API_KEY.');
    }
    final uri = Uri.parse('$_base/api/v1/cp-invoices/acknowledge');
    final res = await http
        .post(uri,
            headers: {'X-API-Key': _cpInvoiceApiKey, 'Content-Type': 'application/json'},
            body: jsonEncode({'claimId': claimId, 'mahaRera': mahaRera}))
        .timeout(const Duration(seconds: 25));
    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) body = Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (_) {}
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TicketApiException(body['error']?.toString() ?? 'Could not acknowledge (${res.statusCode}).');
    }
    return body;
  }

  // TEMP DEMO BYPASS - set to true to skip the real network call and return
  // a synthetic success response instead (useful if the server rejects
  // submissions whose mahaRera doesn't match a registered brokerage, e.g.
  // "This brokerage was not found for your MahaRERA no."). Currently false:
  // submissions and lookups go to the real Sales API, so they actually land
  // on the Sales App / PACO's view.
  static const bool mockInvoiceSubmission = false;

  Future<Map<String, dynamic>> submitChannelPartnerInvoice({
    required String name,
    required String mobile,
    required String mahaRera,
    required String firmName,
    String? pan,
    String? gst,
    required DateTime invoiceDate,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String accountType,
    required String branch,
    required String ifsc,
    required File invoiceFile,
    // Set when this submission is raised straight from an acknowledged
    // brokerage claim (Brokerage Confirmation Flash's "Raise invoice now"),
    // so the server can link the invoice back to that claim and carry the
    // already-confirmed amount instead of trusting whatever the CP typed.
    String? claimId,
    String? confirmedAmount,
  }) async {
    if (mockInvoiceSubmission) {
      await Future.delayed(const Duration(milliseconds: 600));
      final now = DateTime.now();
      final mock = {
        'id': 'mock-${now.millisecondsSinceEpoch}',
        'invoiceNo': 'MOCK-${now.millisecondsSinceEpoch.toString().substring(7)}',
        'mahaRera': mahaRera,
        'name': name,
        'mobile': mobile,
        'firmName': firmName,
        'invoiceDate':
            '${invoiceDate.year.toString().padLeft(4, '0')}-${invoiceDate.month.toString().padLeft(2, '0')}-${invoiceDate.day.toString().padLeft(2, '0')}',
        'fileName': invoiceFile.path.split(Platform.pathSeparator).last,
        'status': 'SUBMITTED',
        'approvedAmount': confirmedAmount ?? '',
        'pacoRemark': '',
        'reason': '',
        if (claimId != null) 'claimId': claimId,
        'submittedAt': now.toUtc().toIso8601String(),
      };
      _mockInvoices.insert(0, mock);
      return mock;
    }

    if (_cpInvoiceApiKey.isEmpty) {
      throw TicketApiException(
          'Invoice submission is not configured on this build. Missing SALES_API_KEY.');
    }

    final uri = Uri.parse('$_base/api/v1/cp-invoices');
    final req = http.MultipartRequest('POST', uri)
      ..headers['X-API-Key'] = _cpInvoiceApiKey
      ..fields.addAll({
        'mahaRera': mahaRera,
        'name': name,
        'mobile': mobile,
        'firmName': firmName,
        if (pan != null && pan.isNotEmpty) 'pan': pan,
        if (gst != null && gst.isNotEmpty) 'gst': gst,
        'invoiceDate':
            '${invoiceDate.year.toString().padLeft(4, '0')}-${invoiceDate.month.toString().padLeft(2, '0')}-${invoiceDate.day.toString().padLeft(2, '0')}',
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'accountType': accountType,
        'branch': branch,
        'ifsc': ifsc,
        if (claimId != null && claimId.isNotEmpty) 'claimId': claimId,
        if (confirmedAmount != null && confirmedAmount.isNotEmpty) 'confirmedAmount': confirmedAmount,
      })
      ..files.add(await http.MultipartFile.fromPath('file', invoiceFile.path));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);

    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) body = Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (_) {}
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TicketApiException(body['error']?.toString() ?? 'Invoice submission failed (${res.statusCode}).');
    }
    return body;
  }
}
