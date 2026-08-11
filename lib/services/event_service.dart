import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/event.dart';

class EventService {
  Future<List<EventModel>> getOrganizerEvents(String token) async {
    final url = Uri.parse('${ApiConfig.eventBaseUrl}/api/v1/organizer/events');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? data ?? [];
      return list.map((item) => EventModel.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat daftar event');
    }
  }

  Future<EventModel?> getEventDetail(String id, String token) async {
    final url = Uri.parse('${ApiConfig.eventBaseUrl}/api/v1/events/$id');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null) {
        return EventModel.fromJson(data['data']);
      }
    }
    return null;
  }
}
