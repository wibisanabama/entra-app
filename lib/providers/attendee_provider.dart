import 'package:flutter/material.dart';
import '../models/attendee.dart';
import '../services/gate_service.dart';
import '../services/ticket_service.dart';

enum AttendeeStatusFilter { all, checkedIn, unchecked }

class AttendeeProvider extends ChangeNotifier {
  final TicketService _ticketService = TicketService();
  final GateService _gateService = GateService();

  List<Attendee> _attendees = [];
  bool _isLoading = false;
  bool _isProcessingAction = false;
  String? _errorMessage;
  String _searchQuery = '';
  AttendeeStatusFilter _statusFilter = AttendeeStatusFilter.all;

  List<Attendee> get attendees {
    var list = _attendees;

    // Filter by status
    if (_statusFilter == AttendeeStatusFilter.checkedIn) {
      list = list.where((a) => a.isCheckedIn).toList();
    } else if (_statusFilter == AttendeeStatusFilter.unchecked) {
      list = list.where((a) => !a.isCheckedIn).toList();
    }

    // Filter by search query
    if (_searchQuery.isEmpty) return list;
    return list.where((a) {
      final name = a.userName.toLowerCase();
      final email = a.userEmail.toLowerCase();
      final code = a.ticketCode.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || code.contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get isProcessingAction => _isProcessingAction;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  AttendeeStatusFilter get statusFilter => _statusFilter;

  int get totalCount => _attendees.length;
  int get checkedInCount => _attendees.where((a) => a.isCheckedIn).length;
  int get uncheckedCount => _attendees.where((a) => !a.isCheckedIn).length;

  Future<void> fetchAttendees(String eventId, String token) async {
    _attendees = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendees = await _ticketService.getEventAttendees(eventId, token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ScanResult> manualCheckIn(Attendee attendee, String token, {String? eventId}) async {
    _isProcessingAction = true;
    notifyListeners();

    try {
      final result = await _gateService.scanTicket(
        attendee.ticketCode,
        token,
        eventId: eventId ?? attendee.eventId,
      );

      if (result.status == ScanStatus.success || result.status == ScanStatus.alreadyUsed) {
        // Mark attendee as checked in locally
        final index = _attendees.indexWhere((a) => a.ticketCode == attendee.ticketCode || a.id == attendee.id);
        if (index != -1) {
          _attendees[index] = _attendees[index].copyWith(status: 'USED');
        }
      }

      return result;
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  void setStatusFilter(AttendeeStatusFilter filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearData() {
    _attendees = [];
    _isLoading = false;
    _isProcessingAction = false;
    _errorMessage = null;
    _searchQuery = '';
    _statusFilter = AttendeeStatusFilter.all;
    notifyListeners();
  }
}
