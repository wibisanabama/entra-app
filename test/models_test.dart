import 'package:flutter_test/flutter_test.dart';
import 'package:entra_app/models/ticket_tier.dart';
import 'package:entra_app/models/attendee.dart';
import 'package:entra_app/models/balance.dart';
import 'package:entra_app/models/gate_stats.dart';

void main() {
  group('TicketTier Model Tests', () {
    test('Calculates remaining, fillRate, and isSoldOut accurately', () {
      final tier = TicketTier(
        id: 'tier-1',
        eventId: 'event-1',
        name: 'VIP',
        price: 150000,
        capacity: 100,
        sold: 75,
        description: 'VIP Pass with front row access',
      );

      expect(tier.remaining, equals(25));
      expect(tier.fillRate, closeTo(0.75, 0.001));
      expect(tier.isSoldOut, isFalse);
    });

    test('Identifies sold out tier correctly', () {
      final soldOutTier = TicketTier(
        id: 'tier-2',
        eventId: 'event-1',
        name: 'Early Bird',
        price: 75000,
        capacity: 50,
        sold: 50,
        description: 'Early bird pass',
      );

      expect(soldOutTier.remaining, equals(0));
      expect(soldOutTier.fillRate, equals(1.0));
      expect(soldOutTier.isSoldOut, isTrue);
    });

    test('Parses from JSON with string and num price variants', () {
      final json = {
        'id': 'tier-json',
        'event_id': 'event-json',
        'name': 'Presale 1',
        'price': '120000',
        'capacity': 200,
        'sold': 50,
        'description': 'Online presale',
      };

      final tier = TicketTier.fromJson(json);
      expect(tier.name, equals('Presale 1'));
      expect(tier.price, equals(120000));
      expect(tier.capacity, equals(200));
      expect(tier.sold, equals(50));
      expect(tier.remaining, equals(150));
    });
  });

  group('Attendee Model Tests', () {
    test('Correctly identifies check-in status from USED or CHECKED_IN', () {
      final attendee1 = Attendee(
        id: 'att-1',
        orderId: 'ord-1',
        userId: 'usr-1',
        eventId: 'eve-1',
        ticketTypeId: 'tt-1',
        ticketCode: 'TCK-001',
        status: 'USED',
        createdAt: '2026-08-20T00:00:00Z',
        userName: 'John Doe',
        userEmail: 'john@example.com',
      );

      final attendee2 = Attendee(
        id: 'att-2',
        orderId: 'ord-2',
        userId: 'usr-2',
        eventId: 'eve-1',
        ticketTypeId: 'tt-1',
        ticketCode: 'TCK-002',
        status: 'ACTIVE',
        createdAt: '2026-08-20T00:00:00Z',
        userName: 'Jane Doe',
        userEmail: 'jane@example.com',
      );

      expect(attendee1.isCheckedIn, isTrue);
      expect(attendee2.isCheckedIn, isFalse);
    });
  });

  group('OrganizerBalance Model Tests', () {
    test('Creates empty balance with zero defaults', () {
      final balance = OrganizerBalance.empty();
      expect(balance.totalRevenue, equals(0.0));
      expect(balance.availableBalance, equals(0.0));
      expect(balance.totalRequests, equals(0));
    });
  });

  group('GateStats Model Tests', () {
    test('Parses gate statistics correctly', () {
      final json = {
        'event_id': 'eve-123',
        'total_tickets': 500,
        'checked_in': 350,
        'remaining': 150,
        'checkin_rate': 70.0,
        'status': 'ACTIVE',
      };

      final stats = GateStats.fromJson(json);
      expect(stats.totalTickets, equals(500));
      expect(stats.checkedIn, equals(350));
      expect(stats.remaining, equals(150));
      expect(stats.checkinRate, equals(70.0));
    });
  });
}
