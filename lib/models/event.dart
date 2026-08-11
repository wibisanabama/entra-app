class EventModel {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String venueId;
  final String organizerId;
  final String startDate;
  final String endDate;
  final String bannerUrl;
  final String status;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.venueId,
    required this.organizerId,
    required this.startDate,
    required this.endDate,
    required this.bannerUrl,
    required this.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id'] ?? '',
      venueId: json['venue_id'] ?? '',
      organizerId: json['organizer_id'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      status: json['status'] ?? 'DRAFT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'venue_id': venueId,
      'organizer_id': organizerId,
      'start_date': startDate,
      'end_date': endDate,
      'banner_url': bannerUrl,
      'status': status,
    };
  }

  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
}
