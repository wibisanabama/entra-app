import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/gate_stats.dart';

enum ScanStatus { success, alreadyUsed, invalid, serverError }

class ScanResult {
  final ScanStatus status;
  final String message;
  final String ticketCode;

  ScanResult({
    required this.status,
    required this.message,
    required this.ticketCode,
  });
}

class GateService {
  Future<ScanResult> scanTicket(String ticketCode, String token, {String? eventId}) async {
    final url = Uri.parse('${ApiConfig.gateBaseUrl}/api/v1/gate/scan');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ticket_code': ticketCode,
          if (eventId != null && eventId.isNotEmpty) 'event_id': eventId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ScanResult(
          status: ScanStatus.success,
          message: data['message'] ?? 'Tiket valid! Check-in berhasil.',
          ticketCode: ticketCode,
        );
      } else if (response.statusCode == 409) {
        return ScanResult(
          status: ScanStatus.alreadyUsed,
          message: data['message'] ?? 'Tiket sudah pernah digunakan atau tidak valid.',
          ticketCode: ticketCode,
        );
      } else {
        return ScanResult(
          status: ScanStatus.invalid,
          message: data['message'] ?? 'Tiket tidak valid atau tidak ditemukan.',
          ticketCode: ticketCode,
        );
      }
    } catch (e) {
      return ScanResult(
        status: ScanStatus.serverError,
        message: 'Gagal terhubung ke server gate check-in.',
        ticketCode: ticketCode,
      );
    }
  }

  Future<GateStats?> getGateStats(String eventId) async {
    final url = Uri.parse('${ApiConfig.gateBaseUrl}/api/v1/gate/stats/$eventId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statsData = data['data'] ?? data;
        return GateStats.fromJson(statsData as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
