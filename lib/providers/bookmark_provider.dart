// lib/providers/bookmark_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/novel_model.dart';

class BookmarkItem {
  final int bookmarkId;
  final int novelId;
  final String title;
  final String author;
  final String coverUrl;
  final String status;
  final List<String> genres;
  final int? lastChapterNumber;
  final DateTime updatedAt;

  BookmarkItem({
    required this.bookmarkId,
    required this.novelId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.status,
    required this.genres,
    this.lastChapterNumber,
    required this.updatedAt,
  });
}

class BookmarkProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<BookmarkItem> _bookmarks = [];
  Set<int> _bookmarkedNovelIds = {};
  bool _isLoading = false;

  List<BookmarkItem> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;

  bool isBookmarked(int novelId) => _bookmarkedNovelIds.contains(novelId);

  Future<void> loadBookmarks(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await _db.getBookmarksWithNovels(userId);
      _bookmarks = raw.map((m) => BookmarkItem(
        bookmarkId: m['id'] as int,
        novelId: m['novel_id'] as int,
        title: m['title'] as String,
        author: m['author'] as String,
        coverUrl: m['cover_url'] as String,
        status: m['status'] as String,
        genres: (m['genres'] as String).split(',').where((g) => g.isNotEmpty).toList(),
        lastChapterNumber: m['last_chapter_number'] as int?,
        updatedAt: DateTime.parse(m['updated_at'] as String),
      )).toList();
      _bookmarkedNovelIds = _bookmarks.map((b) => b.novelId).toSet();
    } catch (e) {
      // ignore
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleBookmark(int userId, int novelId) async {
    if (_bookmarkedNovelIds.contains(novelId)) {
      await _db.removeBookmark(userId, novelId);
      _bookmarkedNovelIds.remove(novelId);
      _bookmarks.removeWhere((b) => b.novelId == novelId);
    } else {
      await _db.upsertBookmark(userId: userId, novelId: novelId);
      _bookmarkedNovelIds.add(novelId);
      await loadBookmarks(userId);
      return;
    }
    notifyListeners();
  }

  Future<void> updateReadingProgress({
    required int userId,
    required int novelId,
    required int chapterId,
    required int chapterNumber,
  }) async {
    await _db.upsertBookmark(
      userId: userId,
      novelId: novelId,
      lastChapterId: chapterId,
      lastChapterNumber: chapterNumber,
    );
    if (!_bookmarkedNovelIds.contains(novelId)) {
      _bookmarkedNovelIds.add(novelId);
    }
    final idx = _bookmarks.indexWhere((b) => b.novelId == novelId);
    if (idx != -1) {
      final old = _bookmarks[idx];
      _bookmarks[idx] = BookmarkItem(
        bookmarkId: old.bookmarkId,
        novelId: old.novelId,
        title: old.title,
        author: old.author,
        coverUrl: old.coverUrl,
        status: old.status,
        genres: old.genres,
        lastChapterNumber: chapterNumber,
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }
}
