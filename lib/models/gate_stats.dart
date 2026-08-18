class GateStats {
  final String eventId;
  final int totalTickets;
  final int checkedIn;
  final int remaining;
  final double checkinRate;
  final String status;

  GateStats({
    required this.eventId,
    required this.totalTickets,
    required this.checkedIn,
    required this.remaining,
    required this.checkinRate,
    required this.status,
  });

  factory GateStats.fromJson(Map<String, dynamic> json) {
    return GateStats(
      eventId: json['event_id'] as String? ?? '',
      totalTickets: (json['total_tickets'] as num?)?.toInt() ?? 0,
      checkedIn: (json['checked_in'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      checkinRate: (json['checkin_rate'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'NOT_STARTED',
    );
  }
}
