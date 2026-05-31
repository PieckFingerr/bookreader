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
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NovelModel.fromMap(Map<String, dynamic> map) => NovelModel(
        id: map['id'],
        title: map['title'],
        author: map['author'],
        description: map['description'],
        coverUrl: map['cover_url'],
        genres: (map['genres'] as String).split(',').where((g) => g.isNotEmpty).toList(),
        status: map['status'],
        viewCount: map['view_count'] ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: map['rating_count'] ?? 0,
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );

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
      );

  String get statusLabel {
    switch (status) {
      case 'ongoing': return 'Đang ra';
      case 'completed': return 'Hoàn thành';
      case 'hiatus': return 'Tạm dừng';
      default: return status;
    }
  }
}