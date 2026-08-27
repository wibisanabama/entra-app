import 'dart:convert';

/// Utility class for normalizing QR code payloads.
/// Supports plain ticket codes, JSON objects, and URL formats.
class QrNormalizer {
  static String normalize(String rawPayload) {
    var trimmed = rawPayload.trim();
    if (trimmed.isEmpty) return '';

    // 1. Try parsing JSON format
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final code = decoded['ticket_code'] ??
              decoded['code'] ??
              decoded['ticket_id'] ??
              decoded['ticketId'] ??
              decoded['id'] ??
              (decoded['ticket'] is Map
                  ? (decoded['ticket']['code'] ?? decoded['ticket']['ticket_code'])
                  : null) ??
              (decoded['data'] is Map
                  ? (decoded['data']['ticket_code'] ?? decoded['data']['code'])
                  : null);
          if (code != null && code.toString().trim().isNotEmpty) {
            return code.toString().trim();
          }
        }
      } catch (_) {
        // Fall back to plain string or URL parsing
      }
    }

    // 2. Try parsing URL format
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        // Check query parameters
        final queryParams = uri.queryParameters;
        if (queryParams.containsKey('code') && queryParams['code']!.trim().isNotEmpty) {
          return queryParams['code']!.trim();
        }
        if (queryParams.containsKey('ticket_code') && queryParams['ticket_code']!.trim().isNotEmpty) {
          return queryParams['ticket_code']!.trim();
        }
        if (queryParams.containsKey('ticket') && queryParams['ticket']!.trim().isNotEmpty) {
          return queryParams['ticket']!.trim();
        }
        if (queryParams.containsKey('ticketId') && queryParams['ticketId']!.trim().isNotEmpty) {
          return queryParams['ticketId']!.trim();
        }
        if (queryParams.containsKey('id') && queryParams['id']!.trim().isNotEmpty) {
          return queryParams['id']!.trim();
        }

        // Check path segments
        final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return segments.last.trim();
        }
      } catch (_) {
        // Fall back to trimmed string
      }
    }

    return trimmed;
  }
}
