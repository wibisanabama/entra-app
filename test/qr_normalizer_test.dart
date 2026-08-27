import 'package:flutter_test/flutter_test.dart';
import 'package:entra_app/utils/qr_normalizer.dart';

void main() {
  group('QrNormalizer Unit Tests', () {
    test('Returns plain ticket code directly after trimming', () {
      expect(QrNormalizer.normalize('TCK-12345678'), equals('TCK-12345678'));
      expect(QrNormalizer.normalize('  TCK-87654321  \n'), equals('TCK-87654321'));
      expect(QrNormalizer.normalize('a1b2c3d4-e5f6-7890-abcd-ef1234567890'), equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
    });

    test('Handles empty and whitespace strings', () {
      expect(QrNormalizer.normalize(''), equals(''));
      expect(QrNormalizer.normalize('   '), equals(''));
    });

    test('Extracts ticket code from URL query parameters', () {
      expect(
        QrNormalizer.normalize('https://entra.id/checkin?code=TCK-URL-001'),
        equals('TCK-URL-001'),
      );
      expect(
        QrNormalizer.normalize('https://entra.id/gate?ticket_code=TCK-URL-002&gate=1'),
        equals('TCK-URL-002'),
      );
      expect(
        QrNormalizer.normalize('https://entra.id/verify?ticket=TCK-URL-003'),
        equals('TCK-URL-003'),
      );
      expect(
        QrNormalizer.normalize('http://localhost:3000/checkin?id=TCK-URL-004'),
        equals('TCK-URL-004'),
      );
    });

    test('Extracts ticket code from URL path segments', () {
      expect(
        QrNormalizer.normalize('https://entra.id/t/TCK-PATH-001'),
        equals('TCK-PATH-001'),
      );
      expect(
        QrNormalizer.normalize('https://entra.id/tickets/TCK-PATH-002'),
        equals('TCK-PATH-002'),
      );
      expect(
        QrNormalizer.normalize('https://entra.id/events/ev-123/tickets/TCK-PATH-003/'),
        equals('TCK-PATH-003'),
      );
    });

    test('Extracts ticket code from JSON payloads', () {
      expect(
        QrNormalizer.normalize('{"ticket_code": "TCK-JSON-001"}'),
        equals('TCK-JSON-001'),
      );
      expect(
        QrNormalizer.normalize('{"code": "TCK-JSON-002", "eventId": "ev-1"}'),
        equals('TCK-JSON-002'),
      );
      expect(
        QrNormalizer.normalize('{"ticketId": "TCK-JSON-003"}'),
        equals('TCK-JSON-003'),
      );
      expect(
        QrNormalizer.normalize('{"ticket": {"code": "TCK-JSON-004"}}'),
        equals('TCK-JSON-004'),
      );
      expect(
        QrNormalizer.normalize('{"data": {"ticket_code": "TCK-JSON-005"}}'),
        equals('TCK-JSON-005'),
      );
    });

    test('Gracefully falls back when JSON is malformed or missing code field', () {
      expect(
        QrNormalizer.normalize('{invalid_json: true}'),
        equals('{invalid_json: true}'),
      );
      expect(
        QrNormalizer.normalize('{"other_field": "123"}'),
        equals('{"other_field": "123"}'),
      );
    });
  });
}
