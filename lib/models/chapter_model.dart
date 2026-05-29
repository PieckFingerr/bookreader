// lib/models/chapter_model.dart
class ChapterModel {
  final int? id;
  final int novelId;
  final int chapterNumber;
  final String title;
  final String content;
  final DateTime createdAt;

  ChapterModel({
    this.id,
    required this.novelId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'novel_id': novelId,
        'chapter_number': chapterNumber,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChapterModel.fromMap(Map<String, dynamic> map) => ChapterModel(
        id: map['id'],
        novelId: map['novel_id'],
        chapterNumber: map['chapter_number'],
        title: map['title'],
        content: map['content'],
        createdAt: DateTime.parse(map['created_at']),
      );

  ChapterModel copyWith({
    int? id,
    int? novelId,
    int? chapterNumber,
    String? title,
    String? content,
    DateTime? createdAt,
  }) =>
      ChapterModel(
        id: id ?? this.id,
        novelId: novelId ?? this.novelId,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
}
