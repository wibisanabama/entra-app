import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entra_app/models/attendee.dart';
import 'package:entra_app/services/auth_service.dart';
import 'package:entra_app/services/ticket_service.dart';

void main() {
  group('TicketService Unit Tests', () {
    late TicketService ticketService;

    setUp(() {
      ticketService = TicketService();
    });

    test('getOrganizerStats returns stats map on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/tickets/organizer/stats'));
        expect(request.headers['Authorization'], equals('Bearer valid_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'total_orders': 150,
              'total_revenue': 45000000,
              'tickets_sold': 300,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final stats = await ticketService.getOrganizerStats('valid_token');
        expect(stats['total_orders'], equals(150));
        expect(stats['total_revenue'], equals(45000000));
        expect(stats['tickets_sold'], equals(300));
      }, () => mockClient);
    });

    test('getOrganizerStats broadcasts session expired on 401 and returns fallback map', () async {
      var expiredBroadcast = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        expiredBroadcast = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        final stats = await ticketService.getOrganizerStats('expired_token');
        expect(stats['total_orders'], equals(0));
        expect(stats['total_revenue'], equals(0));
        expect(stats['tickets_sold'], equals(0));
        await Future.delayed(const Duration(milliseconds: 10));
        expect(expiredBroadcast, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('getOrganizerStats returns default zeroed map on network error', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network disconnected');
      });

      await http.runWithClient(() async {
        final stats = await ticketService.getOrganizerStats('token_123');
        expect(stats['total_orders'], equals(0));
        expect(stats['total_revenue'], equals(0));
        expect(stats['tickets_sold'], equals(0));
      }, () => mockClient);
    });

    test('getEventAttendees returns parsed list of Attendees on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/tickets/organizer/events/eve-1/attendees'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'att-1',
                'order_id': 'ord-1',
                'user_id': 'usr-1',
                'event_id': 'eve-1',
                'ticket_type_id': 'tt-1',
                'ticket_code': 'TCK-001',
                'status': 'USED',
                'created_at': '2026-08-20T00:00:00Z',
                'user': {'name': 'Budi', 'email': 'budi@entra.id'},
              },
              {
                'id': 'att-2',
                'order_id': 'ord-2',
                'user_id': 'usr-2',
                'event_id': 'eve-1',
                'ticket_type_id': 'tt-1',
                'ticket_code': 'TCK-002',
                'status': 'ACTIVE',
                'created_at': '2026-08-21T00:00:00Z',
                'user': {'name': 'Siti', 'email': 'siti@entra.id'},
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final attendees = await ticketService.getEventAttendees('eve-1', 'token_ok');
        expect(attendees.length, equals(2));
        expect(attendees[0].userName, equals('Budi'));
        expect(attendees[0].isCheckedIn, isTrue);
        expect(attendees[1].userName, equals('Siti'));
        expect(attendees[1].isCheckedIn, isFalse);
      }, () => mockClient);
    });

    test('getEventAttendees throws and broadcasts on 401', () async {
      var expiredBroadcast = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        expiredBroadcast = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        expect(
          () => ticketService.getEventAttendees('eve-1', 'expired_token'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Sesi login telah berakhir'))),
        );
        await Future.delayed(const Duration(milliseconds: 10));
        expect(expiredBroadcast, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('getEventAttendees throws descriptive exception on 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Internal Server Error"}', 500, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        expect(
          () => ticketService.getEventAttendees('eve-1', 'token'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Gagal memuat daftar peserta'))),
        );
      }, () => mockClient);
    });
  });
}
