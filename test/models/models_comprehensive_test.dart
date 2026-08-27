import 'package:flutter_test/flutter_test.dart';
import 'package:entra_app/models/attendee.dart';
import 'package:entra_app/models/balance.dart';
import 'package:entra_app/models/event.dart';
import 'package:entra_app/models/gate_stats.dart';
import 'package:entra_app/models/ticket_tier.dart';
import 'package:entra_app/models/user.dart';
import 'package:entra_app/models/withdrawal.dart';

void main() {
  group('Attendee Model Comprehensive Tests', () {
    test('fromJson parses full nested user payload', () {
      final json = {
        'id': 'att-101',
        'order_id': 'ord-202',
        'user_id': 'usr-303',
        'event_id': 'eve-404',
        'ticket_type_id': 'tt-505',
        'ticket_code': 'TCK-VIP-999',
        'status': 'USED',
        'created_at': '2026-08-27T08:00:00Z',
        'user': {
          'name': 'Budi Santoso',
          'email': 'budi@entra.id',
        },
      };

      final attendee = Attendee.fromJson(json);
      expect(attendee.id, equals('att-101'));
      expect(attendee.orderId, equals('ord-202'));
      expect(attendee.userId, equals('usr-303'));
      expect(attendee.eventId, equals('eve-404'));
      expect(attendee.ticketTypeId, equals('tt-505'));
      expect(attendee.ticketCode, equals('TCK-VIP-999'));
      expect(attendee.status, equals('USED'));
      expect(attendee.createdAt, equals('2026-08-27T08:00:00Z'));
      expect(attendee.userName, equals('Budi Santoso'));
      expect(attendee.userEmail, equals('budi@entra.id'));
      expect(attendee.isCheckedIn, isTrue);
    });

    test('fromJson handles flat user_name/user_email and missing defaults', () {
      final json = {
        'id': 'att-102',
        'user_name': 'Siti Rahma',
        'user_email': 'siti@entra.id',
      };

      final attendee = Attendee.fromJson(json);
      expect(attendee.id, equals('att-102'));
      expect(attendee.orderId, equals(''));
      expect(attendee.status, equals('ACTIVE'));
      expect(attendee.userName, equals('Siti Rahma'));
      expect(attendee.userEmail, equals('siti@entra.id'));
      expect(attendee.isCheckedIn, isFalse);
    });

    test('fromJson handles completely empty map with fallback defaults', () {
      final attendee = Attendee.fromJson({});
      expect(attendee.id, equals(''));
      expect(attendee.status, equals('ACTIVE'));
      expect(attendee.userName, equals('Pengunjung'));
      expect(attendee.userEmail, equals(''));
      expect(attendee.isCheckedIn, isFalse);
    });

    test('isCheckedIn supports USED and CHECKED_IN (case-insensitive)', () {
      expect(Attendee.fromJson({'status': 'USED'}).isCheckedIn, isTrue);
      expect(Attendee.fromJson({'status': 'used'}).isCheckedIn, isTrue);
      expect(Attendee.fromJson({'status': 'CHECKED_IN'}).isCheckedIn, isTrue);
      expect(Attendee.fromJson({'status': 'checked_in'}).isCheckedIn, isTrue);
      expect(Attendee.fromJson({'status': 'ACTIVE'}).isCheckedIn, isFalse);
      expect(Attendee.fromJson({'status': 'CANCELLED'}).isCheckedIn, isFalse);
    });

    test('copyWith clones and selectively updates fields', () {
      final original = Attendee(
        id: 'orig-id',
        orderId: 'orig-order',
        userId: 'orig-user',
        eventId: 'orig-event',
        ticketTypeId: 'orig-tier',
        ticketCode: 'orig-code',
        status: 'ACTIVE',
        createdAt: '2026-01-01',
        userName: 'Original Name',
        userEmail: 'orig@entra.id',
      );

      final updated = original.copyWith(
        status: 'USED',
        userName: 'Updated Name',
      );

      expect(updated.id, equals('orig-id'));
      expect(updated.orderId, equals('orig-order'));
      expect(updated.status, equals('USED'));
      expect(updated.userName, equals('Updated Name'));
      expect(updated.userEmail, equals('orig@entra.id'));
      expect(updated.isCheckedIn, isTrue);
      expect(original.isCheckedIn, isFalse);
    });
  });

  group('OrganizerBalance Model Comprehensive Tests', () {
    test('fromJson parses numeric, string, and null fields', () {
      final json = {
        'total_revenue': '5000000.75',
        'total_withdrawn': 2000000,
        'available_balance': 3000000.75,
        'pending_amount': '0.00',
        'paid_amount': null,
        'total_requests': '12',
      };

      final balance = OrganizerBalance.fromJson(json);
      expect(balance.totalRevenue, equals(5000000.75));
      expect(balance.totalWithdrawn, equals(2000000.0));
      expect(balance.availableBalance, equals(3000000.75));
      expect(balance.pendingAmount, equals(0.0));
      expect(balance.paidAmount, equals(0.0));
      expect(balance.totalRequests, equals(12));
    });

    test('fromJson handles invalid strings and non-num values safely', () {
      final json = {
        'total_revenue': 'invalid_num',
        'total_withdrawn': true,
        'total_requests': 'not_int',
      };

      final balance = OrganizerBalance.fromJson(json);
      expect(balance.totalRevenue, equals(0.0));
      expect(balance.totalWithdrawn, equals(0.0));
      expect(balance.totalRequests, equals(0));
    });

    test('empty factory creates initial zero state', () {
      final empty = OrganizerBalance.empty();
      expect(empty.totalRevenue, equals(0.0));
      expect(empty.totalWithdrawn, equals(0.0));
      expect(empty.availableBalance, equals(0.0));
      expect(empty.pendingAmount, equals(0.0));
      expect(empty.paidAmount, equals(0.0));
      expect(empty.totalRequests, equals(0));
    });
  });

  group('EventModel Comprehensive Tests', () {
    test('fromJson and toJson round-trip serialization', () {
      final json = {
        'id': 'ev-100',
        'title': 'Java Jazz Festival 2026',
        'description': 'Annual international jazz event',
        'category_id': 'cat-music',
        'venue_id': 'ven-jiexpo',
        'organizer_id': 'org-77',
        'start_date': '2026-09-01T10:00:00Z',
        'end_date': '2026-09-03T23:00:00Z',
        'banner_url': 'https://entra.id/banners/jazz.png',
        'status': 'PUBLISHED',
      };

      final event = EventModel.fromJson(json);
      expect(event.id, equals('ev-100'));
      expect(event.title, equals('Java Jazz Festival 2026'));
      expect(event.description, equals('Annual international jazz event'));
      expect(event.categoryId, equals('cat-music'));
      expect(event.venueId, equals('ven-jiexpo'));
      expect(event.organizerId, equals('org-77'));
      expect(event.startDate, equals('2026-09-01T10:00:00Z'));
      expect(event.endDate, equals('2026-09-03T23:00:00Z'));
      expect(event.bannerUrl, equals('https://entra.id/banners/jazz.png'));
      expect(event.status, equals('PUBLISHED'));
      expect(event.isPublished, isTrue);

      final serialized = event.toJson();
      expect(serialized, equals(json));
    });

    test('fromJson defaults for missing fields', () {
      final event = EventModel.fromJson({});
      expect(event.id, equals(''));
      expect(event.title, equals(''));
      expect(event.status, equals('DRAFT'));
      expect(event.isPublished, isFalse);
    });
  });

  group('GateStats Model Comprehensive Tests', () {
    test('fromJson parses mixed num types and status', () {
      final json = {
        'event_id': 'ev-gate-1',
        'total_tickets': 1000.0, // double in json
        'checked_in': 650,
        'remaining': 350,
        'checkin_rate': 65, // int -> toDouble
        'status': 'IN_PROGRESS',
      };

      final stats = GateStats.fromJson(json);
      expect(stats.eventId, equals('ev-gate-1'));
      expect(stats.totalTickets, equals(1000));
      expect(stats.checkedIn, equals(650));
      expect(stats.remaining, equals(350));
      expect(stats.checkinRate, equals(65.0));
      expect(stats.status, equals('IN_PROGRESS'));
    });

    test('fromJson handles nulls with defaults', () {
      final stats = GateStats.fromJson({});
      expect(stats.eventId, equals(''));
      expect(stats.totalTickets, equals(0));
      expect(stats.checkedIn, equals(0));
      expect(stats.remaining, equals(0));
      expect(stats.checkinRate, equals(0.0));
      expect(stats.status, equals('NOT_STARTED'));
    });
  });

  group('TicketTier Model Comprehensive Tests', () {
    test('Parses price as string and capacity as quantity fallback', () {
      final json = {
        'id': 'tt-q',
        'event_id': 'ev-1',
        'name': 'Festival General',
        'price': '75000',
        'quantity': 500,
        'sold': 200,
        'description': 'Festival floor ticket',
      };

      final tier = TicketTier.fromJson(json);
      expect(tier.price, equals(75000));
      expect(tier.capacity, equals(500));
      expect(tier.sold, equals(200));
      expect(tier.remaining, equals(300));
      expect(tier.fillRate, closeTo(0.4, 0.001));
      expect(tier.isSoldOut, isFalse);
    });

    test('Handles oversold clamp and zero capacity edge cases', () {
      final zeroCapTier = TicketTier(
        id: 'tt-zero',
        eventId: 'ev-0',
        name: 'Free RSVP',
        price: 0,
        capacity: 0,
        sold: 0,
        description: '',
      );
      expect(zeroCapTier.remaining, equals(0));
      expect(zeroCapTier.fillRate, equals(0.0));
      expect(zeroCapTier.isSoldOut, isFalse);

      final oversoldTier = TicketTier(
        id: 'tt-over',
        eventId: 'ev-1',
        name: 'VIP Front',
        price: 500000,
        capacity: 50,
        sold: 55,
        description: '',
      );
      expect(oversoldTier.remaining, equals(0));
      expect(oversoldTier.fillRate, equals(1.0));
      expect(oversoldTier.isSoldOut, isTrue);
    });
  });

  group('User Model Comprehensive Tests', () {
    test('fromJson and toJson round-trip with full properties', () {
      final json = {
        'id': 'usr-999',
        'email': 'jane.organizer@entra.id',
        'full_name': 'Jane Organizer',
        'role': 'organizer',
        'phone': '081299998888',
        'avatar_url': 'https://entra.id/avatar.jpg',
        'is_verified': true,
      };

      final user = User.fromJson(json);
      expect(user.id, equals('usr-999'));
      expect(user.email, equals('jane.organizer@entra.id'));
      expect(user.name, equals('Jane Organizer'));
      expect(user.role, equals('organizer'));
      expect(user.phone, equals('081299998888'));
      expect(user.avatarUrl, equals('https://entra.id/avatar.jpg'));
      expect(user.isVerified, isTrue);
      expect(user.isOrganizer, isTrue);

      final serialized = user.toJson();
      expect(serialized['id'], equals('usr-999'));
      expect(serialized['email'], equals('jane.organizer@entra.id'));
      expect(serialized['name'], equals('Jane Organizer'));
      expect(serialized['role'], equals('organizer'));
      expect(serialized['phone'], equals('081299998888'));
      expect(serialized['avatar_url'], equals('https://entra.id/avatar.jpg'));
      expect(serialized['is_verified'], isTrue);
    });

    test('isOrganizer evaluates organizer and admin as true, customer as false', () {
      expect(User.fromJson({'role': 'organizer'}).isOrganizer, isTrue);
      expect(User.fromJson({'role': 'admin'}).isOrganizer, isTrue);
      expect(User.fromJson({'role': 'customer'}).isOrganizer, isFalse);
      expect(User.fromJson({'role': 'gate_staff'}).isOrganizer, isFalse);
      expect(User.fromJson({}).isOrganizer, isFalse);
    });

    test('copyWith updates properties correctly', () {
      final user = User(
        id: 'u1',
        email: 'u1@entra.id',
        name: 'User One',
        role: 'customer',
      );

      final promoted = user.copyWith(role: 'organizer', phone: '081111111');
      expect(promoted.id, equals('u1'));
      expect(promoted.name, equals('User One'));
      expect(promoted.role, equals('organizer'));
      expect(promoted.phone, equals('081111111'));
      expect(promoted.isOrganizer, isTrue);
    });
  });

  group('Withdrawal Model Comprehensive Tests', () {
    test('fromJson parses valid withdrawal object with nested pgText types', () {
      final json = {
        'id': 'wd-001',
        'organizer_id': 'org-123',
        'amount': '1500000.00',
        'bank_name': 'Bank Central Asia (BCA)',
        'account_number': '1234567890',
        'account_name': 'PT Entra Event',
        'status': 'PENDING',
        'rejection_reason': {
          'Valid': true,
          'String': 'Account name mismatch',
        },
        'notes': 'Pencairan tiket batch 1',
        'created_at': '2026-08-25T14:30:00Z',
        'updated_at': '2026-08-25T14:30:00Z',
      };

      final wd = Withdrawal.fromJson(json);
      expect(wd.id, equals('wd-001'));
      expect(wd.organizerId, equals('org-123'));
      expect(wd.amount, equals(1500000.0));
      expect(wd.bankName, equals('Bank Central Asia (BCA)'));
      expect(wd.accountNumber, equals('1234567890'));
      expect(wd.accountName, equals('PT Entra Event'));
      expect(wd.status, equals('PENDING'));
      expect(wd.rejectionReason, equals('Account name mismatch'));
      expect(wd.notes, equals('Pencairan tiket batch 1'));
      expect(wd.createdAt.year, equals(2026));
      expect(wd.updatedAt.year, equals(2026));
    });

    test('fromJson handles invalid pgText, null dates, and default status', () {
      final json = {
        'id': 'wd-002',
        'organizer_id': 'org-123',
        'amount': 250000,
        'bank_name': 'Mandiri',
        'account_number': '9876543210',
        'account_name': 'Budi',
        'rejection_reason': {'Valid': false, 'String': ''},
        'notes': null,
      };

      final wd = Withdrawal.fromJson(json);
      expect(wd.amount, equals(250000.0));
      expect(wd.status, equals('PENDING'));
      expect(wd.rejectionReason, isNull);
      expect(wd.notes, isNull);
      expect(wd.createdAt, isA<DateTime>());
      expect(wd.updatedAt, isA<DateTime>());
    });
  });
}
