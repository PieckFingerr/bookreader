// lib/providers/novel_provider.dart
import 'package:flutter/foundation.dart';
import '../models/novel_model.dart';
import '../models/chapter_model.dart';
import '../services/database_service.dart';

class NovelProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<NovelModel> _novels = [];
  List<NovelModel> _filteredNovels = [];
  List<NovelModel> _myNovels = [];
  List<NovelModel> get myNovels => _myNovels;
  NovelModel? _selectedNovel;
  List<ChapterModel> _chapters = [];
  ChapterModel? _currentChapter;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedGenre = '';
  String _selectedStatus = '';

  List<NovelModel> get novels =>
      _filteredNovels.isEmpty &&
          _searchQuery.isEmpty &&
          _selectedGenre.isEmpty &&
          _selectedStatus.isEmpty
      ? _novels
      : _filteredNovels;
  List<NovelModel> get allNovels => _novels;
  NovelModel? get currentNovel => _selectedNovel; // 💡 Gốc gọi là selectedNovel hoặc currentNovel dựa theo UI
  List<ChapterModel> get currentChapters => _chapters;
  ChapterModel? get currentChapter => _currentChapter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNovels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // 💡 ĐÃ SỬA: Lấy danh sách truyện từ SQL Server qua mạng LAN
      _novels = await _db.getNovels();
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectNovel(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 💡 ĐÃ SỬA: Gọi API lấy chi tiết truyện và danh sách chương từ Server Node.js
      _selectedNovel = await _db.getNovelById(id);
      _chapters = await _db.getChapters(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadChapterDetails(int chapterId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 💡 ĐÃ SỬA: Lấy nội dung chi tiết của chương truyện qua mạng
      _currentChapter = await _db.getChapterDetails(chapterId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void searchNovels(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void filterByGenre(String genre) {
    _selectedGenre = genre;
    _applyFilter();
    notifyListeners();
  }

  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredNovels = _novels.where((novel) {
      final matchesSearch = novel.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          novel.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGenre = _selectedGenre.isEmpty || novel.genres.contains(_selectedGenre);
      final matchesStatus = _selectedStatus.isEmpty || novel.status == _selectedStatus;
      return matchesSearch && matchesGenre && matchesStatus;
    }).toList();
  }
}