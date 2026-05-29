// lib/models/bookmark_model.dart
class BookmarkModel {
  final int? id;
  final int userId;
  final int novelId;
  final int? lastChapterId;
  final int? lastChapterNumber;
  final DateTime updatedAt;

  BookmarkModel({
    this.id,
    required this.userId,
    required this.novelId,
    this.lastChapterId,
    this.lastChapterNumber,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'novel_id': novelId,
        'last_chapter_id': lastChapterId,
        'last_chapter_number': lastChapterNumber,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory BookmarkModel.fromMap(Map<String, dynamic> map) => BookmarkModel(
        id: map['id'],
        userId: map['user_id'],
        novelId: map['novel_id'],
        lastChapterId: map['last_chapter_id'],
        lastChapterNumber: map['last_chapter_number'],
        updatedAt: DateTime.parse(map['updated_at']),
      );

  BookmarkModel copyWith({
    int? id,
    int? userId,
    int? novelId,
    int? lastChapterId,
    int? lastChapterNumber,
    DateTime? updatedAt,
  }) =>
      BookmarkModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        novelId: novelId ?? this.novelId,
        lastChapterId: lastChapterId ?? this.lastChapterId,
        lastChapterNumber: lastChapterNumber ?? this.lastChapterNumber,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
