import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entra_app/models/gate_stats.dart';
import 'package:entra_app/services/auth_service.dart';
import 'package:entra_app/services/gate_service.dart';

void main() {
  group('GateService Unit Tests', () {
    late GateService gateService;

    setUp(() {
      gateService = GateService();
    });

    test('scanTicket normalizes QR code payload and handles 200 success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/gate/scan'));
        expect(request.headers['Authorization'], equals('Bearer valid_token'));
        final body = jsonDecode(request.body);
        expect(body['ticket_code'], equals('TCK-VIP-001'));
        expect(body['event_id'], equals('eve-101'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Check-in sukses! Selamat datang.',
            'data': {
              'user_name': 'Ahmad Fauzi',
              'ticket_type_name': 'VIP Pass',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        // Raw URL QR code gets normalized to TCK-VIP-001
        final result = await gateService.scanTicket(
          'https://entra.id/checkin?code=TCK-VIP-001',
          'valid_token',
          eventId: 'eve-101',
        );

        expect(result.status, equals(ScanStatus.success));
        expect(result.message, equals('Check-in sukses! Selamat datang.'));
        expect(result.ticketCode, equals('TCK-VIP-001'));
        expect(result.attendeeName, equals('Ahmad Fauzi'));
        expect(result.ticketTypeName, equals('VIP Pass'));
      }, () => mockClient);
    });

    test('scanTicket handles 409 already used response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Tiket sudah pernah digunakan pada 10:30 WIB',
            'data': {
              'attendee_name': 'Dewi Sartika',
              'tier_name': 'Festival General',
            }
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await gateService.scanTicket(
          '{"ticket_code": "TCK-USED-002"}',
          'token_123',
        );

        expect(result.status, equals(ScanStatus.alreadyUsed));
        expect(result.message, contains('Tiket sudah pernah digunakan'));
        expect(result.ticketCode, equals('TCK-USED-002'));
        expect(result.attendeeName, equals('Dewi Sartika'));
        expect(result.ticketTypeName, equals('Festival General'));
      }, () => mockClient);
    });

    test('scanTicket handles 404 invalid/not found response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Tiket tidak ditemukan di database.',
          }),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final result = await gateService.scanTicket(
          'TCK-INVALID-003',
          'token_123',
        );

        expect(result.status, equals(ScanStatus.invalid));
        expect(result.message, contains('Tiket tidak ditemukan'));
        expect(result.ticketCode, equals('TCK-INVALID-003'));
      }, () => mockClient);
    });

    test('scanTicket broadcasts session expired on 401', () async {
      var broadcastFired = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        broadcastFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        final result = await gateService.scanTicket('TCK-001', 'expired_token');
        expect(result.status, equals(ScanStatus.invalid));
        await Future.delayed(const Duration(milliseconds: 10));
        expect(broadcastFired, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('scanTicket handles network error and returns serverError status', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection dropped');
      });

      await http.runWithClient(() async {
        final result = await gateService.scanTicket('TCK-ERR-001', 'token_abc');
        expect(result.status, equals(ScanStatus.serverError));
        expect(result.message, contains('Gagal terhubung ke server gate check-in.'));
        expect(result.ticketCode, equals('TCK-ERR-001'));
      }, () => mockClient);
    });

    test('getGateStats returns GateStats on 200 response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/gate/stats/ev-99'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'event_id': 'ev-99',
              'total_tickets': 1000,
              'checked_in': 750,
              'remaining': 250,
              'checkin_rate': 75.0,
              'status': 'ACTIVE',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final stats = await gateService.getGateStats('ev-99');
        expect(stats, isNotNull);
        expect(stats!.eventId, equals('ev-99'));
        expect(stats.totalTickets, equals(1000));
        expect(stats.checkedIn, equals(750));
        expect(stats.remaining, equals(250));
        expect(stats.checkinRate, equals(75.0));
      }, () => mockClient);
    });

    test('getGateStats returns null on non-200 or network error', () async {
      final mockClient404 = MockClient((request) async => http.Response('Not Found', 404));
      await http.runWithClient(() async {
        final stats = await gateService.getGateStats('non-existent');
        expect(stats, isNull);
      }, () => mockClient404);

      final mockClientErr = MockClient((request) async => throw Exception('Timeout'));
      await http.runWithClient(() async {
        final stats = await gateService.getGateStats('error-ev');
        expect(stats, isNull);
      }, () => mockClientErr);
    });
  });
}
