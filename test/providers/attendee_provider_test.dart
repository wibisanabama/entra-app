import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entra_app/models/attendee.dart';
import 'package:entra_app/providers/attendee_provider.dart';
import 'package:entra_app/services/gate_service.dart';

void main() {
  group('AttendeeProvider Unit & State Tests', () {
    late AttendeeProvider provider;

    setUp(() {
      provider = AttendeeProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial state is empty and clean', () {
      expect(provider.attendees, isEmpty);
      expect(provider.totalCount, equals(0));
      expect(provider.checkedInCount, equals(0));
      expect(provider.uncheckedCount, equals(0));
      expect(provider.isLoading, isFalse);
      expect(provider.isProcessingAction, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.searchQuery, equals(''));
      expect(provider.statusFilter, equals(AttendeeStatusFilter.all));
    });

    test('fetchAttendees populates attendee list and updates counts', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/tickets/organizer/events/eve-1/attendees'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'att-1',
                'order_id': 'ord-1',
                'user_id': 'u1',
                'event_id': 'eve-1',
                'ticket_type_id': 'tt-1',
                'ticket_code': 'TCK-VIP-001',
                'status': 'USED',
                'created_at': '2026-08-20',
                'user': {'name': 'Budi Santoso', 'email': 'budi@entra.id'},
              },
              {
                'id': 'att-2',
                'order_id': 'ord-2',
                'user_id': 'u2',
                'event_id': 'eve-1',
                'ticket_type_id': 'tt-1',
                'ticket_code': 'TCK-VIP-002',
                'status': 'ACTIVE',
                'created_at': '2026-08-20',
                'user': {'name': 'Siti Rahma', 'email': 'siti@entra.id'},
              },
              {
                'id': 'att-3',
                'order_id': 'ord-3',
                'user_id': 'u3',
                'event_id': 'eve-1',
                'ticket_type_id': 'tt-2',
                'ticket_code': 'TCK-REG-003',
                'status': 'ACTIVE',
                'created_at': '2026-08-20',
                'user': {'name': 'Dewi Lestari', 'email': 'dewi@entra.id'},
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        await provider.fetchAttendees('eve-1', 'tok_valid');
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);
        expect(provider.totalCount, equals(3));
        expect(provider.checkedInCount, equals(1));
        expect(provider.uncheckedCount, equals(2));
        expect(provider.attendees.length, equals(3));
      }, () => mockClient);
    });

    test('fetchAttendees sets errorMessage on network failure', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Server unreachable');
      });

      await http.runWithClient(() async {
        await provider.fetchAttendees('eve-1', 'tok_valid');
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNotNull);
        expect(provider.errorMessage, contains('Server unreachable'));
        expect(provider.totalCount, equals(0));
      }, () => mockClient);
    });

    test('Filter by status (checkedIn and unchecked)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'att-1',
                'order_id': 'o1',
                'user_id': 'u1',
                'event_id': 'e1',
                'ticket_type_id': 't1',
                'ticket_code': 'T1',
                'status': 'USED',
                'user': {'name': 'Budi'},
              },
              {
                'id': 'att-2',
                'order_id': 'o2',
                'user_id': 'u2',
                'event_id': 'e1',
                'ticket_type_id': 't1',
                'ticket_code': 'T2',
                'status': 'ACTIVE',
                'user': {'name': 'Siti'},
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        await provider.fetchAttendees('e1', 'tok');
        expect(provider.attendees.length, equals(2));

        // Filter: checkedIn only
        provider.setStatusFilter(AttendeeStatusFilter.checkedIn);
        expect(provider.statusFilter, equals(AttendeeStatusFilter.checkedIn));
        expect(provider.attendees.length, equals(1));
        expect(provider.attendees.first.userName, equals('Budi'));

        // Filter: unchecked only
        provider.setStatusFilter(AttendeeStatusFilter.unchecked);
        expect(provider.statusFilter, equals(AttendeeStatusFilter.unchecked));
        expect(provider.attendees.length, equals(1));
        expect(provider.attendees.first.userName, equals('Siti'));

        // Filter: all
        provider.setStatusFilter(AttendeeStatusFilter.all);
        expect(provider.attendees.length, equals(2));
      }, () => mockClient);
    });

    test('Search filter matches name, email, and ticket code', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'att-1',
                'order_id': 'o1',
                'user_id': 'u1',
                'event_id': 'e1',
                'ticket_type_id': 't1',
                'ticket_code': 'TCK-ALPHA-01',
                'status': 'ACTIVE',
                'user': {'name': 'Andi Pratama', 'email': 'andi@mail.com'},
              },
              {
                'id': 'att-2',
                'order_id': 'o2',
                'user_id': 'u2',
                'event_id': 'e1',
                'ticket_type_id': 't1',
                'ticket_code': 'TCK-BETA-02',
                'status': 'ACTIVE',
                'user': {'name': 'Citra Kirana', 'email': 'citra@gmail.com'},
              },
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        await provider.fetchAttendees('e1', 'tok');

        // Search by name
        provider.setSearchQuery('Andi');
        expect(provider.searchQuery, equals('Andi'));
        expect(provider.attendees.length, equals(1));
        expect(provider.attendees.first.userName, equals('Andi Pratama'));

        // Search by email domain
        provider.setSearchQuery('gmail');
        expect(provider.attendees.length, equals(1));
        expect(provider.attendees.first.userName, equals('Citra Kirana'));

        // Search by ticket code substring
        provider.setSearchQuery('ALPHA');
        expect(provider.attendees.length, equals(1));
        expect(provider.attendees.first.ticketCode, equals('TCK-ALPHA-01'));

        // Non-matching query
        provider.setSearchQuery('xyz999');
        expect(provider.attendees, isEmpty);

        // Reset query
        provider.setSearchQuery('');
        expect(provider.attendees.length, equals(2));
      }, () => mockClient);
    });

    test('manualCheckIn updates attendee status locally on success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/v1/tickets/organizer/events/e1/attendees')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'att-10',
                  'order_id': 'o10',
                  'user_id': 'u10',
                  'event_id': 'e1',
                  'ticket_type_id': 't10',
                  'ticket_code': 'TCK-MANUAL-10',
                  'status': 'ACTIVE',
                  'user': {'name': 'Doni', 'email': 'doni@entra.id'},
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.endsWith('/api/v1/gate/scan')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Check-in manual berhasil',
              'data': {'user_name': 'Doni'}
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        await provider.fetchAttendees('e1', 'tok');
        expect(provider.uncheckedCount, equals(1));
        expect(provider.checkedInCount, equals(0));

        final target = provider.attendees.first;
        final scanResult = await provider.manualCheckIn(target, 'tok');

        expect(scanResult.status, equals(ScanStatus.success));
        expect(provider.isProcessingAction, isFalse);
        expect(provider.checkedInCount, equals(1));
        expect(provider.uncheckedCount, equals(0));
        expect(provider.attendees.first.isCheckedIn, isTrue);
      }, () => mockClient);
    });

    test('clearData resets all provider states', () async {
      provider.setSearchQuery('test');
      provider.setStatusFilter(AttendeeStatusFilter.checkedIn);
      provider.clearData();

      expect(provider.attendees, isEmpty);
      expect(provider.searchQuery, equals(''));
      expect(provider.statusFilter, equals(AttendeeStatusFilter.all));
      expect(provider.isLoading, isFalse);
      expect(provider.isProcessingAction, isFalse);
      expect(provider.errorMessage, isNull);
    });
  });
}
