import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

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
  Future<ScanResult> scanTicket(String ticketCode, String token) async {
    final url = Uri.parse('${ApiConfig.gateBaseUrl}/api/v1/gate/scan');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ticket_code': ticketCode}),
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
}
