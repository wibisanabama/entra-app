class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isVerified = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['full_name'] ?? json['name'] ?? '').toString(),
      role: (json['role'] ?? 'customer').toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isVerified: json['is_verified'] == true || json['is_verified'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  bool get isOrganizer => role == 'organizer' || role == 'admin';
}
