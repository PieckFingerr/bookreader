// lib/models/novel_model.dart
class NovelModel {
  final int? id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final List<String> genres;
  final String status; // ongoing, completed, hiatus
  final int viewCount;
  final double rating;
  final int ratingCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;

  NovelModel({
    this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.genres,
    required this.status,
    this.viewCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'description': description,
        'cover_url': coverUrl,
        'genres': genres.join(','),
        'status': status,
        'view_count': viewCount,
        'rating': rating,
        'rating_count': ratingCount,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NovelModel.fromMap(Map<String, dynamic> map) {
    return NovelModel(
      id: map['id'] as int?,
      title: map['title']?.toString() ?? '',
      author: map['author']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      // 🏆 ĐÃ SỬA: Đọc cả hai trường 'cover_url' hoặc 'coverUrl' để tương thích hoàn toàn với Web API Node.js
      coverUrl: map['cover_url']?.toString() ?? map['coverUrl']?.toString() ?? '',
      genres: map['genres'] is List
          ? List<String>.from(map['genres'])
          : (map['genres']?.toString().split(',').where((g) => g.trim().isNotEmpty).toList() ?? []),
      status: map['status']?.toString() ?? 'ongoing',
      // Đọc an toàn các biến số và ngày tháng từ driver mssql của SQL Server gửi qua mạng
      viewCount: map['view_count'] != null ? int.parse(map['view_count'].toString()) : (map['viewCount'] ?? 0),
      rating: map['rating'] != null ? double.parse(map['rating'].toString()) : ((map['rating'] as num?)?.toDouble() ?? 0.0),
      ratingCount: map['rating_count'] != null ? int.parse(map['rating_count'].toString()) : (map['ratingCount'] ?? 0),
      // 🏆 ĐÃ SỬA: Bổ sung trường này bị thiếu ngầm trong hàm fromMap cũ của bạn
      createdBy: map['created_by'] as int?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'].toString()) : DateTime.now(),
    );
  }

  NovelModel copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    List<String>? genres,
    String? status,
    int? viewCount,
    double? rating,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
  }) =>
      NovelModel(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        genres: genres ?? this.genres,
        status: status ?? this.status,
        viewCount: viewCount ?? this.viewCount,
        rating: rating ?? this.rating,
        ratingCount: ratingCount ?? this.ratingCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
      );
}