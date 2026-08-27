import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/ticket_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();
  bool _disposed = false;

  List<EventModel> _events = [];
  Map<String, dynamic> _stats = {
    'total_orders': 0,
    'total_revenue': 0,
    'tickets_sold': 0,
  };
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  List<EventModel> get events => _events;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool eventsFailed = false;
    bool statsFailed = false;
    String? eventsError;
    String? statsError;

    final eventsFuture = _eventService.getOrganizerEvents(token).then((data) {
      _events = data;
    }).catchError((e) {
      eventsFailed = true;
      eventsError = e.toString().replaceAll('Exception: ', '');
    });

    final statsFuture = _ticketService.getOrganizerStats(token).then((data) {
      _stats = data;
    }).catchError((e) {
      statsFailed = true;
      statsError = e.toString().replaceAll('Exception: ', '');
    });

    await Future.wait([eventsFuture, statsFuture]);

    if (eventsFailed && statsFailed) {
      _errorMessage = eventsError ?? statsError ?? 'Gagal memuat data dashboard.';
    } else {
      _errorMessage = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  EventModel? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearData() {
    _events = [];
    _stats = {
      'total_orders': 0,
      'total_revenue': 0,
      'tickets_sold': 0,
    };
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
