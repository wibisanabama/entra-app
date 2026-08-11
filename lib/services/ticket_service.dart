import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/attendee.dart';

class TicketService {
  Future<Map<String, dynamic>> getOrganizerStats(String token) async {
    final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/stats');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? {
        'total_orders': 0,
        'total_revenue': 0,
        'tickets_sold': 0,
      };
    }
    return {
      'total_orders': 0,
      'total_revenue': 0,
      'tickets_sold': 0,
    };
  }

  Future<List<Attendee>> getEventAttendees(String eventId, String token) async {
    final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/events/$eventId/attendees');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((item) => Attendee.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat daftar peserta');
    }
  }
}
