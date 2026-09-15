import 'dart:convert';
import '../config/api_config.dart';
import '../models/event.dart';
import '../models/ticket_tier.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _apiClient;

  EventService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  Future<List<EventModel>> getOrganizerEvents(String token) async {
    final url = Uri.parse('${ApiConfig.eventBaseUrl}/api/v1/organizer/events');
    final response = await _apiClient.get(url, token: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? data ?? [];
      return list.map((item) => EventModel.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sesi login telah berakhir. Silakan keluar dan login kembali.');
    } else {
      throw Exception('Gagal memuat daftar event');
    }
  }

  Future<EventModel?> getEventDetail(String id, String token) async {
    final url = Uri.parse('${ApiConfig.eventBaseUrl}/api/v1/events/$id');
    final response = await _apiClient.get(url, token: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null) {
        return EventModel.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<List<TicketTier>> getEventTicketTiers(String eventId, String token) async {
    final url = Uri.parse('${ApiConfig.eventBaseUrl}/api/v1/events/$eventId/tickets');
    final response = await _apiClient.get(url, token: token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] is List ? data['data'] : (data is List ? data : []);
      return list.map((item) => TicketTier.fromJson(item as Map<String, dynamic>)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sesi login telah berakhir. Silakan keluar dan login kembali.');
    } else {
      throw Exception('Gagal memuat kategori tiket (HTTP ${response.statusCode})');
    }
  }
}


