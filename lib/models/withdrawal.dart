class Withdrawal {
  final String id;
  final String organizerId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String status;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Withdrawal({
    required this.id,
    required this.organizerId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.status,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    String? parsePgText(dynamic val) {
      if (val == null) return null;
      if (val is String) return val.isNotEmpty ? val : null;
      if (val is Map && val['Valid'] == true && val['String'] is String) {
        return val['String'];
      }
      return null;
    }

    return Withdrawal(
      id: json['id']?.toString() ?? '',
      organizerId: json['organizer_id']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      bankName: json['bank_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      rejectionReason: parsePgText(json['rejection_reason']),
      notes: parsePgText(json['notes']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
