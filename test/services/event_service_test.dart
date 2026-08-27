import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entra_app/models/event.dart';
import 'package:entra_app/models/ticket_tier.dart';
import 'package:entra_app/services/auth_service.dart';
import 'package:entra_app/services/event_service.dart';

void main() {
  group('EventService Unit Tests', () {
    late EventService eventService;

    setUp(() {
      eventService = EventService();
    });

    test('getOrganizerEvents returns parsed EventModel list on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/organizer/events'));
        expect(request.headers['Authorization'], equals('Bearer tok_event'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'ev-1',
                'title': 'Tech Summit 2026',
                'description': 'Tech Conference',
                'category_id': 'cat-1',
                'venue_id': 'ven-1',
                'organizer_id': 'org-1',
                'start_date': '2026-10-01',
                'end_date': '2026-10-02',
                'banner_url': 'https://entra.id/banner1.png',
                'status': 'PUBLISHED',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final events = await eventService.getOrganizerEvents('tok_event');
        expect(events.length, equals(1));
        expect(events[0].id, equals('ev-1'));
        expect(events[0].title, equals('Tech Summit 2026'));
        expect(events[0].isPublished, isTrue);
      }, () => mockClient);
    });

    test('getOrganizerEvents throws and broadcasts on 401', () async {
      var expiredFired = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        expiredFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        expect(
          () => eventService.getOrganizerEvents('expired_tok'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Sesi login telah berakhir'))),
        );
        await Future.delayed(const Duration(milliseconds: 10));
        expect(expiredFired, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('getEventDetail returns EventModel on 200 and null on 404', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/v1/events/ev-found')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'ev-found',
                'title': 'Found Event',
                'description': 'Details',
                'category_id': 'cat-1',
                'venue_id': 'ven-1',
                'organizer_id': 'org-1',
                'start_date': '2026-10-10',
                'end_date': '2026-10-11',
                'banner_url': '',
                'status': 'DRAFT',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response('{"message": "Not Found"}', 404, headers: {'content-type': 'application/json'});
        }
      });

      await http.runWithClient(() async {
        final found = await eventService.getEventDetail('ev-found', 'tok');
        expect(found, isNotNull);
        expect(found!.title, equals('Found Event'));

        final missing = await eventService.getEventDetail('ev-missing', 'tok');
        expect(missing, isNull);
      }, () => mockClient);
    });

    test('getEventTicketTiers returns parsed TicketTier list on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/events/ev-1/tickets'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'tier-vip',
                'event_id': 'ev-1',
                'name': 'VIP Pass',
                'price': 250000,
                'capacity': 100,
                'sold': 60,
                'description': 'VIP',
              },
              {
                'id': 'tier-reg',
                'event_id': 'ev-1',
                'name': 'Regular',
                'price': 100000,
                'capacity': 500,
                'sold': 500,
                'description': 'Reg',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final tiers = await eventService.getEventTicketTiers('ev-1', 'tok');
        expect(tiers.length, equals(2));
        expect(tiers[0].name, equals('VIP Pass'));
        expect(tiers[0].remaining, equals(40));
        expect(tiers[1].isSoldOut, isTrue);
      }, () => mockClient);
    });

    test('getEventTicketTiers throws and broadcasts on 401', () async {
      var expiredFired = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        expiredFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        expect(
          () => eventService.getEventTicketTiers('ev-1', 'bad_tok'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Sesi login telah berakhir'))),
        );
        await Future.delayed(const Duration(milliseconds: 10));
        expect(expiredFired, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });
  });
}
