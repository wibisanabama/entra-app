class TicketTier {
  final String id;
  final String eventId;
  final String name;
  final num price;
  final int capacity;
  final int sold;
  final String description;

  TicketTier({
    required this.id,
    required this.eventId,
    required this.name,
    required this.price,
    required this.capacity,
    this.sold = 0,
    required this.description,
  });

  factory TicketTier.fromJson(Map<String, dynamic> json) {
    num parsedPrice = 0;
    if (json['price'] is num) {
      parsedPrice = json['price'];
    } else if (json['price'] is String) {
      parsedPrice = num.tryParse(json['price']) ?? 0;
    }

    int parsedCap = 0;
    if (json['capacity'] is int) {
      parsedCap = json['capacity'];
    } else if (json['quantity'] is int) {
      parsedCap = json['quantity'];
    } else if (json['capacity'] is num) {
      parsedCap = (json['capacity'] as num).toInt();
    } else if (json['capacity'] is String) {
      parsedCap = int.tryParse(json['capacity']) ?? 0;
    }

    int parsedSold = 0;
    if (json['sold'] is int) {
      parsedSold = json['sold'];
    } else if (json['sold'] is num) {
      parsedSold = (json['sold'] as num).toInt();
    }

    return TicketTier(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      name: json['name'] ?? 'Tiket Masuk',
      price: parsedPrice,
      capacity: parsedCap,
      sold: parsedSold,
      description: json['description'] ?? '',
    );
  }

  int get remaining => (capacity - sold).clamp(0, capacity);
  double get fillRate => capacity > 0 ? (sold / capacity).clamp(0.0, 1.0) : 0.0;
  bool get isSoldOut => capacity > 0 && sold >= capacity;
}
