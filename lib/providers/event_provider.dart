import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/ticket_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();

  List<EventModel> _events = [];
  Map<String, dynamic> _stats = {
    'total_orders': 0,
    'total_revenue': 0,
    'tickets_sold': 0,
  };
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _eventService.getOrganizerEvents(token),
        _ticketService.getOrganizerStats(token),
      ]);

      _events = results[0] as List<EventModel>;
      _stats = results[1] as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  EventModel? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
