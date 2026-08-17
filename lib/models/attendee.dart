class Attendee {
  final String id;
  final String orderId;
  final String userId;
  final String eventId;
  final String ticketTypeId;
  final String ticketCode;
  final String status; // 'ACTIVE', 'USED', etc.
  final String createdAt;
  final String userName;
  final String userEmail;

  Attendee({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.eventId,
    required this.ticketTypeId,
    required this.ticketCode,
    required this.status,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;
    return Attendee(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? '',
      eventId: json['event_id'] ?? '',
      ticketTypeId: json['ticket_type_id'] ?? '',
      ticketCode: json['ticket_code'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['created_at'] ?? '',
      userName: userJson?['name'] ?? json['user_name'] ?? 'Pengunjung',
      userEmail: userJson?['email'] ?? json['user_email'] ?? '',
    );
  }

  bool get isCheckedIn => status.toUpperCase() == 'USED' || status.toUpperCase() == 'CHECKED_IN';

  Attendee copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? eventId,
    String? ticketTypeId,
    String? ticketCode,
    String? status,
    String? createdAt,
    String? userName,
    String? userEmail,
  }) {
    return Attendee(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      ticketCode: ticketCode ?? this.ticketCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
