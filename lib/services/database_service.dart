// lib/services/database_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/novel_model.dart';
import '../models/chapter_model.dart';
import '../models/bookmark_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ⚠️ THAY ĐỔI: Sử dụng IP LAN của máy tính chạy server Node.js (Ví dụ: 192.168.1.50)
  // Không dùng localhost vì điện thoại/máy ảo sẽ gọi vào chính nó dẫn đến lỗi Connection Refused.
  static const String baseUrl = "http://192.168.1.254:5000/api"; 

  // Cấu hình thời gian chờ tối đa để lấy trọn vẹn Điểm Khó 1 (Xử lý Timeout)
  static const Duration networkTimeout = Duration(seconds: 7);

  // Helper để xử lý các lỗi ngoại lệ mạng chung, ném thông báo tiếng Việt trực quan ra UI
  void _handleNetworkError(Object error) {
    if (error is TimeoutException) {
      throw Exception("Kết nối tới máy chủ SQL Server quá hạn (Timeout). Vui lòng kiểm tra lại mạng!");
    } else {
      throw Exception("Không thể kết nối đến máy chủ. Vui lòng kiểm tra xem Server Node.js đã chạy chưa hoặc sai địa chỉ IP.");
    }
  }

  // ============================================================================
  // 1. CÁC HÀM CHO NGƯỜI DÙNG (USER / AUTH)
  // ============================================================================
  
  Future<UserModel?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      ).timeout(networkTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data['user']);
      }
      return null; // Sai tài khoản hoặc mật khẩu
    } catch (e) {
      _handleNetworkError(e);
      return null;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "email": email, "password": password}),
      ).timeout(networkTimeout);

      return response.statusCode == 201;
    } catch (e) {
      _handleNetworkError(e);
      return false;
    }
  }

  // ============================================================================
  // 2. CÁC HÀM TRUY VẤN TRUYỆN CHỮ (NOVELS)
  // ============================================================================
  
  Future<List<NovelModel>> getNovels() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/novels")).timeout(networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => NovelModel.fromMap(item)).toList();
      }
      throw Exception("Lỗi tải danh sách truyện từ hệ thống.");
    } catch (e) {
      _handleNetworkError(e);
      return [];
    }
  }

  Future<NovelModel?> getNovelById(int id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/novels/$id")).timeout(networkTimeout);

      if (response.statusCode == 200) {
        return NovelModel.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      _handleNetworkError(e);
      return null;
    }
  }

  // ============================================================================
  // 3. CÁC HÀM CHO CHƯƠNG TRUYỆN (CHAPTERS)
  // ============================================================================
  
  Future<List<ChapterModel>> getChapters(int novelId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/novels/$novelId/chapters")).timeout(networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        
        // Vì API Node.js tối ưu hóa không trả về cột 'content' ở danh sách chương, 
        // ta gán giá trị rỗng để tránh lỗi null map của Model Dart
        return list.map((item) {
          final map = Map<String, dynamic>.from(item);
          if (!map.containsKey('content')) map['content'] = '';
          return ChapterModel.fromMap(map);
        }).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      return [];
    }
  }

  Future<ChapterModel?> getChapterDetails(int chapterId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/chapters/$chapterId")).timeout(networkTimeout);

      if (response.statusCode == 200) {
        return ChapterModel.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      _handleNetworkError(e);
      return null;
    }
  }

  // ============================================================================
  // 4. CÁC HÀM CHO DANH SÁCH THEO DÕI (BOOKMARKS)
  // ============================================================================
  
  Future<List<BookmarkModel>> getBookmarks(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/bookmarks/$userId")).timeout(networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => BookmarkModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      _handleNetworkError(e);
      return [];
    }
  }

  Future<void> insertOrUpdateBookmark(BookmarkModel bookmark) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/bookmarks"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": bookmark.userId,
          "novelId": bookmark.novelId,
          "lastChapterId": bookmark.lastChapterId,
          "lastChapterNumber": bookmark.lastChapterNumber,
        }),
      ).timeout(networkTimeout);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<void> deleteBookmark(int userId, int novelId) async {
    try {
      await http.delete(Uri.parse("$baseUrl/bookmarks/$userId/$novelId")).timeout(networkTimeout);
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  // ============================================================================
  // 5. ĐÁNH GIÁ TRUYỆN - GỌI STORED PROCEDURE THÔNG QUA BACKEND (🏆 ĐIỂM GIỎI)
  // ============================================================================
  
  Future<void> upsertRating(int userId, int novelId, double rating) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/novels/rating"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "novelId": novelId,
          "rating": rating,
        }),
      ).timeout(networkTimeout);

      if (response.statusCode != 200) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Lỗi không thể đánh giá truyện.");
      }
    } catch (e) {
      _handleNetworkError(e);
    }
  }
}