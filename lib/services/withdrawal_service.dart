import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/balance.dart';
import '../models/withdrawal.dart';

class WithdrawalService {
  Future<OrganizerBalance> getOrganizerBalance(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/balance');
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
          return OrganizerBalance.fromJson(data['data']);
        }
        return OrganizerBalance.empty();
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login telah berakhir. Silakan keluar dan login kembali.');
      } else {
        throw Exception('Gagal memuat informasi saldo organizer.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<List<Withdrawal>> getOrganizerWithdrawals(String token, {int page = 1, int perPage = 20}) async {
    try {
      final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/withdrawals?page=$page&per_page=$perPage');
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
        return list.map((item) => Withdrawal.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login telah berakhir. Silakan keluar dan login kembali.');
      } else {
        throw Exception('Gagal memuat riwayat penarikan dana.');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<Withdrawal> requestWithdrawal({
    required String token,
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
    String? notes,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.ticketBaseUrl}/api/v1/tickets/organizer/withdrawals');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_name': accountName,
          'notes': notes ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Withdrawal.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login telah berakhir. Silakan keluar dan login kembali.');
      } else {
        final msg = data['message'] ?? 'Gagal mengajukan penarikan dana.';
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
  }
}
