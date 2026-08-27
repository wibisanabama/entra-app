import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:entra_app/models/balance.dart';
import 'package:entra_app/models/withdrawal.dart';
import 'package:entra_app/services/auth_service.dart';
import 'package:entra_app/services/withdrawal_service.dart';

void main() {
  group('WithdrawalService Unit Tests', () {
    late WithdrawalService withdrawalService;

    setUp(() {
      withdrawalService = WithdrawalService();
    });

    test('getOrganizerBalance returns OrganizerBalance on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/tickets/organizer/balance'));
        expect(request.headers['Authorization'], equals('Bearer tok_123'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'total_revenue': 10000000.0,
              'total_withdrawn': 3000000.0,
              'available_balance': 7000000.0,
              'pending_amount': 0.0,
              'paid_amount': 3000000.0,
              'total_requests': 2,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final balance = await withdrawalService.getOrganizerBalance('tok_123');
        expect(balance.totalRevenue, equals(10000000.0));
        expect(balance.availableBalance, equals(7000000.0));
        expect(balance.totalRequests, equals(2));
      }, () => mockClient);
    });

    test('getOrganizerBalance throws and broadcasts session expired on 401', () async {
      var broadcastFired = false;
      final sub = AuthService.onSessionExpired.listen((_) {
        broadcastFired = true;
      });

      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthorized"}', 401, headers: {'content-type': 'application/json'});
      });

      await http.runWithClient(() async {
        expect(
          () => withdrawalService.getOrganizerBalance('expired_tok'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Sesi login telah berakhir'))),
        );
        await Future.delayed(const Duration(milliseconds: 10));
        expect(broadcastFired, isTrue);
      }, () => mockClient);

      await sub.cancel();
    });

    test('getOrganizerWithdrawals returns parsed list of withdrawals with query params', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/tickets/organizer/withdrawals'));
        expect(request.url.queryParameters['page'], equals('2'));
        expect(request.url.queryParameters['per_page'], equals('10'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 'wd-1',
                'organizer_id': 'org-1',
                'amount': 2500000,
                'bank_name': 'Bank Mandiri',
                'account_number': '12345678',
                'account_name': 'Organizer Name',
                'status': 'PAID',
                'created_at': '2026-08-20T00:00:00Z',
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final list = await withdrawalService.getOrganizerWithdrawals('tok_123', page: 2, perPage: 10);
        expect(list.length, equals(1));
        expect(list[0].id, equals('wd-1'));
        expect(list[0].amount, equals(2500000.0));
        expect(list[0].status, equals('PAID'));
      }, () => mockClient);
    });

    test('requestWithdrawal creates withdrawal on 201 success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/api/v1/tickets/organizer/withdrawals'));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body);
        expect(body['amount'], equals(1500000.0));
        expect(body['bank_name'], equals('Bank Central Asia (BCA)'));
        expect(body['account_number'], equals('5432109876'));
        expect(body['account_name'], equals('John Doe'));
        expect(body['notes'], equals('Honor tim'));

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'wd-new-1',
              'organizer_id': 'org-1',
              'amount': 1500000.0,
              'bank_name': 'Bank Central Asia (BCA)',
              'account_number': '5432109876',
              'account_name': 'John Doe',
              'notes': 'Honor tim',
              'status': 'PENDING',
              'created_at': '2026-08-27T08:00:00Z',
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        final wd = await withdrawalService.requestWithdrawal(
          token: 'tok_abc',
          amount: 1500000.0,
          bankName: 'Bank Central Asia (BCA)',
          accountNumber: '5432109876',
          accountName: 'John Doe',
          notes: 'Honor tim',
        );

        expect(wd.id, equals('wd-new-1'));
        expect(wd.amount, equals(1500000.0));
        expect(wd.status, equals('PENDING'));
        expect(wd.notes, equals('Honor tim'));
      }, () => mockClient);
    });

    test('requestWithdrawal throws API error message on 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Saldo tidak mencukupi untuk penarikan ini.'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(() async {
        expect(
          () => withdrawalService.requestWithdrawal(
            token: 'tok_abc',
            amount: 999999999.0,
            bankName: 'BCA',
            accountNumber: '111',
            accountName: 'John',
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Saldo tidak mencukupi'))),
        );
      }, () => mockClient);
    });
  });
}
