// lib/providers/bookmark_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/bookmark_model.dart';

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

  void clear() {
    _bookmarks = [];
    _bookmarkedNovelIds = {};
    notifyListeners();
  }

  Future<void> loadBookmarks(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await _db.getBookmarks(userId);
      _bookmarks = list.map((b) {
        return BookmarkItem(
          bookmarkId: b.id ?? 0,
          novelId: b.novelId,
          // Dùng trực tiếp field đã map đúng trong BookmarkModel
          title: b.novelTitle ?? 'Truyện chữ',
          author: b.novelAuthor ?? '',
          coverUrl: b.novelCover ?? '',
          status: 'ongoing',
          genres: [],
          lastChapterNumber: b.lastChapterNumber,
          updatedAt: b.updatedAt,
        );
      }).toList();
      _bookmarkedNovelIds = _bookmarks.map((b) => b.novelId).toSet();
    } catch (e) {
      debugPrint('Lỗi load bookmarks: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleBookmark(int userId, int novelId) async {
    if (_bookmarkedNovelIds.contains(novelId)) {
      await _db.deleteBookmark(userId, novelId);
      _bookmarkedNovelIds.remove(novelId);
      _bookmarks.removeWhere((b) => b.novelId == novelId);
      notifyListeners();
    } else {
      final newBookmark = BookmarkModel(
        userId: userId,
        novelId: novelId,
        updatedAt: DateTime.now(),
      );
      await _db.insertOrUpdateBookmark(newBookmark);
      // Load lại để lấy đầy đủ thông tin novel từ JOIN
      await loadBookmarks(userId);
    }
  }

  Future<void> updateReadingProgress({
    required int userId,
    required int novelId,
    required int chapterId,
    required int chapterNumber,
  }) async {
    final progressBookmark = BookmarkModel(
      userId: userId,
      novelId: novelId,
      lastChapterId: chapterId,
      lastChapterNumber: chapterNumber,
      updatedAt: DateTime.now(),
    );
    await _db.insertOrUpdateBookmark(progressBookmark);
    if (!_bookmarkedNovelIds.contains(novelId)) {
      _bookmarkedNovelIds.add(novelId);
    }
    notifyListeners();
  }
}