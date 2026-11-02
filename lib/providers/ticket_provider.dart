import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/ticket_api_service.dart';

enum TicketAuthStatus { unknown, loggedOut, awaitingOtp, loggedIn }

class TicketProvider extends ChangeNotifier {
  final _api = TicketApiService.instance;

  TicketAuthStatus authStatus = TicketAuthStatus.unknown;
  TicketAppUser? user;
  String? pendingEmail;

  List<Ticket> tickets = [];
  bool loadingTickets = false;
  String? error;

  /// Restore a previously-verified session (app relaunch). Mirrors spec 2.2:
  /// a missing/invalid token just means "not logged in", never a hard error.
  Future<void> restoreSession() async {
    if (!await _api.hasToken) {
      authStatus = TicketAuthStatus.loggedOut;
      notifyListeners();
      return;
    }
    try {
      user = await _api.me();
      authStatus = TicketAuthStatus.loggedIn;
    } catch (_) {
      authStatus = TicketAuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<void> requestOtp(String email) async {
    error = null;
    await _api.requestOtp(email);
    pendingEmail = email;
    authStatus = TicketAuthStatus.awaitingOtp;
    notifyListeners();
  }

  Future<void> verifyOtp(String otp) async {
    if (pendingEmail == null) throw TicketApiException('Request a code first.');
    error = null;
    user = await _api.verifyOtp(pendingEmail!, otp);
    authStatus = TicketAuthStatus.loggedIn;
    notifyListeners();
    await refreshTickets();
  }

  Future<void> refreshMe() async {
    user = await _api.me();
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    user = null;
    tickets = [];
    pendingEmail = null;
    authStatus = TicketAuthStatus.loggedOut;
    notifyListeners();
  }

  Future<void> refreshTickets() async {
    loadingTickets = true;
    error = null;
    notifyListeners();
    try {
      tickets = await _api.listTickets();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingTickets = false;
      notifyListeners();
    }
  }

  void _replaceTicket(Ticket t) {
    final idx = tickets.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      tickets[idx] = t;
    } else {
      tickets.insert(0, t);
    }
    notifyListeners();
  }

  Future<Ticket> createTicket({
    required String category,
    String? customCategory,
    required String subject,
    required String description,
    required String project,
    required bool requiresDataAccess,
  }) async {
    final t = await _api.createTicket(
      category: category,
      customCategory: customCategory,
      subject: subject,
      description: description,
      project: project,
      requiresDataAccess: requiresDataAccess,
    );
    tickets.insert(0, t);
    notifyListeners();
    return t;
  }

  Future<Ticket> hodDecision(String id, String decision) async {
    final t = await _api.hodDecision(id, decision);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> guardianDecision(String id, String decision, {DateTime? accessExpiresAt}) async {
    final t = await _api.guardianDecision(id, decision, accessExpiresAt: accessExpiresAt);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> setTimeline(String id, {required DateTime dueDate, required String doerName}) async {
    final t = await _api.setTimeline(id, dueDate: dueDate, doerName: doerName);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> markComplete(String id, {required String doerName}) async {
    final t = await _api.markComplete(id, doerName: doerName);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> confirm(String id, {required bool confirmed}) async {
    final t = await _api.confirm(id, confirmed: confirmed);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> primeAdminReject(String id, {required String reason}) async {
    final t = await _api.primeAdminReject(id, reason: reason);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> forwardToGuardian(String id) async {
    final t = await _api.forwardToGuardian(id);
    _replaceTicket(t);
    return t;
  }

  Future<void> deleteTicket(String id) async {
    await _api.deleteTicket(id);
    tickets.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  Future<Ticket> addAttachmentFile(String id, File file) async {
    final t = await _api.addAttachmentFile(id, file);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> addAttachmentLink(String id, {required String url, String? label}) async {
    final t = await _api.addAttachmentLink(id, url: url, label: label);
    _replaceTicket(t);
    return t;
  }

  Future<Ticket> addComment(String id, String message) async {
    final t = await _api.addComment(id, message);
    _replaceTicket(t);
    return t;
  }

  String attachmentDownloadUrl(String url) => _api.attachmentDownloadUrl(url);
}
