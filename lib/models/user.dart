class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String userType;
  final String? status;
  final int? wilayaId;
  final int? communeId;
  final bool isAvailable;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.userType,
    this.status,
    this.wilayaId,
    this.communeId,
    this.isAvailable = true,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      userType: json['user_type'] ?? 'driver',
      status: json['status'],
      wilayaId: json['wilaya_id'],
      communeId: json['commune_id'],
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'user_type': userType,
      'status': status,
      'wilaya_id': wilayaId,
      'commune_id': communeId,
      'is_available': isAvailable,
    };
  }
}
