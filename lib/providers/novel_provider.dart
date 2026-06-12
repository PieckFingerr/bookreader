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
  
  // 🏆 ĐÃ SỬA: Đổi tên getter thành currentNovel và currentChapters để khớp 100% với file novel_detail_screen.dart
  NovelModel? get currentNovel => _selectedNovel;
  NovelModel? get selectedNovel => _selectedNovel; // Giữ phòng hờ các màn hình khác gọi
  List<ChapterModel> get currentChapters => _chapters;
  List<ChapterModel> get chapters => _chapters; // Giữ phòng hờ các màn hình khác gọi
  
  ChapterModel? get currentChapter => _currentChapter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNovels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
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
      _selectedNovel = await _db.getNovelById(id);
      // Gọi API Node.js lấy danh sách chương của bộ truyện từ SQL Server
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
      _currentChapter = await _db.getChapterDetails(chapterId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMyNovels(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await loadNovels();
      _myNovels = _novels.where((novel) => novel.createdBy == userId).toList();
      _applyFilter();
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

  // Thêm vào trong class NovelProvider
  Future<void> addNovel(NovelModel novel, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.createNovel(novel);
      // Tải lại toàn bộ danh sách truyện từ Server để đồng bộ hóa local state
      await loadNovels();
      // Cập nhật lại danh sách "Truyện của tôi"
      _myNovels = _novels.where((n) => n.createdBy == userId).toList();
    } catch (e) {
      _error = e.toString();
      rethrow; // Ném ngược ra ngoài để UI catch hiển thị thông báo lỗi
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editNovel(NovelModel novel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.updateNovel(novel);
      await loadNovels(); // Kích hoạt nạp lại dữ liệu đồng bộ
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeNovel(int novelId, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.deleteNovel(novelId, userId);
      await loadNovels(); // Đồng bộ hóa làm sạch UI
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}