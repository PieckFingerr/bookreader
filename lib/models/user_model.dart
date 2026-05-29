// lib/models/user_model.dart
class UserModel {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;
  final bool isAdmin;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.isAdmin = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'is_admin': isAdmin ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        username: map['username'],
        email: map['email'],
        passwordHash: map['password_hash'],
        isAdmin: map['is_admin'] == 1,
        createdAt: DateTime.parse(map['created_at']),
      );

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? passwordHash,
    bool? isAdmin,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        passwordHash: passwordHash ?? this.passwordHash,
        isAdmin: isAdmin ?? this.isAdmin,
        createdAt: createdAt ?? this.createdAt,
      );
}
