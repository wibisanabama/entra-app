class OrganizerBalance {
  final double grossRevenue;
  final double platformFeePercent;
  final double platformFeeAmount;
  final double netRevenue;
  final double totalRevenue;
  final double totalWithdrawn;
  final double availableBalance;
  final double pendingAmount;
  final double paidAmount;
  final int totalRequests;

  OrganizerBalance({
    this.grossRevenue = 0.0,
    this.platformFeePercent = 5.0,
    this.platformFeeAmount = 0.0,
    this.netRevenue = 0.0,
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

    final gross = parseDouble(json['gross_revenue']);
    final feePercent = json['platform_fee_percent'] != null
        ? parseDouble(json['platform_fee_percent'])
        : 5.0;
    final feeAmount = parseDouble(json['platform_fee_amount']);
    final net = parseDouble(json['net_revenue']);
    final totalRev = parseDouble(json['total_revenue']);

    return OrganizerBalance(
      grossRevenue: gross > 0 ? gross : (net > 0 ? net : totalRev),
      platformFeePercent: feePercent > 0 ? feePercent : 5.0,
      platformFeeAmount: feeAmount,
      netRevenue: net > 0 ? net : totalRev,
      totalRevenue: totalRev,
      totalWithdrawn: parseDouble(json['total_withdrawn']),
      availableBalance: parseDouble(json['available_balance']),
      pendingAmount: parseDouble(json['pending_amount']),
      paidAmount: parseDouble(json['paid_amount']),
      totalRequests: parseInt(json['total_requests']),
    );
  }

  factory OrganizerBalance.empty() {
    return OrganizerBalance(
      grossRevenue: 0.0,
      platformFeePercent: 5.0,
      platformFeeAmount: 0.0,
      netRevenue: 0.0,
      totalRevenue: 0.0,
      totalWithdrawn: 0.0,
      availableBalance: 0.0,
      pendingAmount: 0.0,
      paidAmount: 0.0,
      totalRequests: 0,
    );
  }
}
