import 'package:flutter/material.dart';
import '../models/attendee.dart';
import '../services/ticket_service.dart';

class AttendeeProvider extends ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<Attendee> _attendees = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Attendee> get attendees {
    if (_searchQuery.isEmpty) return _attendees;
    return _attendees.where((a) {
      final name = a.userName.toLowerCase();
      final email = a.userEmail.toLowerCase();
      final code = a.ticketCode.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query) || code.contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  int get totalCount => _attendees.length;
  int get checkedInCount => _attendees.where((a) => a.isCheckedIn).length;

  Future<void> fetchAttendees(String eventId, String token) async {
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
