class OrganizerBalance {
  final double totalRevenue;
  final double totalWithdrawn;
  final double availableBalance;
  final double pendingAmount;
  final double paidAmount;
  final int totalRequests;

  OrganizerBalance({
    required this.totalRevenue,
    required this.totalWithdrawn,
    required this.availableBalance,
    required this.pendingAmount,
    required this.paidAmount,
    required this.totalRequests,
  });

  factory OrganizerBalance.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return OrganizerBalance(
      totalRevenue: parseDouble(json['total_revenue']),
      totalWithdrawn: parseDouble(json['total_withdrawn']),
      availableBalance: parseDouble(json['available_balance']),
      pendingAmount: parseDouble(json['pending_amount']),
      paidAmount: parseDouble(json['paid_amount']),
      totalRequests: parseInt(json['total_requests']),
    );
  }

  factory OrganizerBalance.empty() {
    return OrganizerBalance(
      totalRevenue: 0.0,
      totalWithdrawn: 0.0,
      availableBalance: 0.0,
      pendingAmount: 0.0,
      paidAmount: 0.0,
      totalRequests: 0,
    );
  }
}
