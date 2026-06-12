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
        username: map['username'] ?? '',
        email: map['email'] ?? '',
        // 🏆 ĐÃ SỬA: Nếu map['password_hash'] bị null thì mặc định gán chuỗi rỗng "" để triệt tiêu lỗi cast type 'Null'
        passwordHash: map['password_hash'] ?? '',
        // 💡 ĐÃ SỬA: Hỗ trợ kiểm tra linh hoạt cả kiểu số 1/0 từ SQL Server hoặc kiểu bool trực tiếp
        isAdmin: map['is_admin'] == 1 || map['is_admin'] == true,
        createdAt: map['created_at'] != null 
            ? DateTime.parse(map['created_at']) 
            : DateTime.now(),
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