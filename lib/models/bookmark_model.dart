// lib/models/bookmark_model.dart
class BookmarkModel {
  final int? id;
  final int userId;
  final int novelId;
  final int? lastChapterId;
  final int? lastChapterNumber;
  final DateTime updatedAt;

  // Fields từ JOIN với bảng novels (chỉ có khi gọi GET /bookmarks/:userId)
  final String? novelTitle;
  final String? novelCover;
  final String? novelAuthor;

  BookmarkModel({
    this.id,
    required this.userId,
    required this.novelId,
    this.lastChapterId,
    this.lastChapterNumber,
    required this.updatedAt,
    this.novelTitle,
    this.novelCover,
    this.novelAuthor,
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
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'].toString())
            : DateTime.now(),
        // Các field JOIN từ API bookmark
        novelTitle: map['novel_title']?.toString(),
        novelCover: map['novel_cover']?.toString(),
        novelAuthor: map['novel_author']?.toString(),
      );

  BookmarkModel copyWith({
    int? id,
    int? userId,
    int? novelId,
    int? lastChapterId,
    int? lastChapterNumber,
    DateTime? updatedAt,
    String? novelTitle,
    String? novelCover,
    String? novelAuthor,
  }) =>
      BookmarkModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        novelId: novelId ?? this.novelId,
        lastChapterId: lastChapterId ?? this.lastChapterId,
        lastChapterNumber: lastChapterNumber ?? this.lastChapterNumber,
        updatedAt: updatedAt ?? this.updatedAt,
        novelTitle: novelTitle ?? this.novelTitle,
        novelCover: novelCover ?? this.novelCover,
        novelAuthor: novelAuthor ?? this.novelAuthor,
      );
}