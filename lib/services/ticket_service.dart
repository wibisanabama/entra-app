import 'dart:convert';
import '../config/api_config.dart';
import '../models/attendee.dart';
import 'api_client.dart';

class TicketService {
  final ApiClient _apiClient;

  TicketService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  Future<Map<String, dynamic>> getOrganizerStats(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/stats');
      final response = await _apiClient.get(url, token: token);

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
    } catch (_) {
      return {
        'total_orders': 0,
        'total_revenue': 0,
        'tickets_sold': 0,
      };
    }
  }

  Future<List<Attendee>> getEventAttendees(String eventId, String token) async {
    try {
      final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/events/$eventId/attendees');
      final response = await _apiClient.get(url, token: token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        return list.map((item) => Attendee.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login telah berakhir. Silakan keluar dan login kembali.');
      } else {
        throw Exception('Gagal memuat daftar peserta');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }
}


