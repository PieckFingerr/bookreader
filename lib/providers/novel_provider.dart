// lib/providers/novel_provider.dart
import 'package:flutter/foundation.dart';
import '../models/novel_model.dart';
import '../models/chapter_model.dart';
import '../services/database_service.dart';

class NovelProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<NovelModel> _novels = [];
  List<NovelModel> _filteredNovels = [];
  NovelModel? _selectedNovel;
  List<ChapterModel> _chapters = [];
  ChapterModel? _currentChapter;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedGenre = '';
  String _selectedStatus = '';

  List<NovelModel> get novels => _filteredNovels.isEmpty && _searchQuery.isEmpty && _selectedGenre.isEmpty && _selectedStatus.isEmpty
      ? _novels
      : _filteredNovels;
  List<NovelModel> get allNovels => _novels;
  NovelModel? get selectedNovel => _selectedNovel;
  List<ChapterModel> get chapters => _chapters;
  ChapterModel? get currentChapter => _currentChapter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedGenre => _selectedGenre;
  String get selectedStatus => _selectedStatus;

  Future<void> loadNovels() async {
    _isLoading = true;
    notifyListeners();
    try {
      _novels = await _db.getAllNovels();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchNovels(String query) async {
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();
    try {
      _filteredNovels = await _db.getAllNovels(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        genre: _selectedGenre.isEmpty ? null : _selectedGenre,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _selectedGenre.isEmpty && _selectedStatus.isEmpty) {
      _filteredNovels = [];
    } else {
      _filteredNovels = _novels.where((n) {
        bool matchSearch = _searchQuery.isEmpty ||
            n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            n.author.toLowerCase().contains(_searchQuery.toLowerCase());
        bool matchGenre = _selectedGenre.isEmpty || n.genres.contains(_selectedGenre);
        bool matchStatus = _selectedStatus.isEmpty || n.status == _selectedStatus;
        return matchSearch && matchGenre && matchStatus;
      }).toList();
    }
  }

  void filterByGenre(String genre) {
    _selectedGenre = genre;
    _applyFilters();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedGenre = '';
    _selectedStatus = '';
    _filteredNovels = [];
    notifyListeners();
  }

  Future<void> selectNovel(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      _selectedNovel = await _db.getNovelById(id);
      _chapters = await _db.getChaptersByNovelId(id);
      await _db.incrementViewCount(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChapter(int chapterId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentChapter = await _db.getChapterById(chapterId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  ChapterModel? getNextChapter() {
    if (_currentChapter == null) return null;
    final index = _chapters.indexWhere((c) => c.id == _currentChapter!.id);
    if (index < _chapters.length - 1) return _chapters[index + 1];
    return null;
  }

  ChapterModel? getPreviousChapter() {
    if (_currentChapter == null) return null;
    final index = _chapters.indexWhere((c) => c.id == _currentChapter!.id);
    if (index > 0) return _chapters[index - 1];
    return null;
  }

  // ADMIN OPERATIONS
  Future<bool> addNovel(NovelModel novel) async {
    try {
      final id = await _db.insertNovel(novel);
      final newNovel = novel.copyWith(id: id);
      _novels.insert(0, newNovel);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNovel(NovelModel novel) async {
    try {
      await _db.updateNovel(novel);
      final idx = _novels.indexWhere((n) => n.id == novel.id);
      if (idx != -1) _novels[idx] = novel;
      if (_selectedNovel?.id == novel.id) _selectedNovel = novel;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNovel(int id) async {
    try {
      await _db.deleteNovel(id);
      _novels.removeWhere((n) => n.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addChapter(ChapterModel chapter) async {
    try {
      final id = await _db.insertChapter(chapter);
      final newChapter = chapter.copyWith(id: id);
      _chapters.add(newChapter);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateChapter(ChapterModel chapter) async {
    try {
      await _db.updateChapter(chapter);
      final idx = _chapters.indexWhere((c) => c.id == chapter.id);
      if (idx != -1) _chapters[idx] = chapter;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteChapter(int id) async {
    try {
      await _db.deleteChapter(id);
      _chapters.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> getChapterCount(int novelId) => _db.getChapterCount(novelId);
}
