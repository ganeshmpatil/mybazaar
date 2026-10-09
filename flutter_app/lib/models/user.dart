class User {
  final int id;
  final String mobile;
  final String? name;
  final String? email;
  final String role;

  User({
    required this.id,
    required this.mobile,
    this.name,
    this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      mobile: json['mobile'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}

class Address {
  final int id;
  final String? label;
  final String fullAddress;
  final String? pincode;
  final String? city;
  final bool isDefault;

  Address({
    required this.id,
    this.label,
    required this.fullAddress,
    this.pincode,
    this.city,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      label: json['label'],
      fullAddress: json['full_address'],
      pincode: json['pincode'],
      city: json['city'],
      isDefault: json['is_default'] ?? false,
    );
  }
}

class AuthResponse {
  final String accessToken;
  final int userId;
  final String? name;
  final bool isNewUser;

  AuthResponse({
    required this.accessToken,
    required this.userId,
    this.name,
    required this.isNewUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      userId: json['user_id'],
      name: json['name'],
      isNewUser: json['is_new_user'],
    );
  }
}
