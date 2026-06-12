// lib/services/database_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/novel_model.dart';
import '../models/chapter_model.dart';
import '../models/bookmark_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String baseUrl = "http://192.168.1.254:5000/api";
  static const Duration networkTimeout = Duration(seconds: 7);

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

      debugPrint("LOGIN STATUS: ${response.statusCode}");
      debugPrint("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data['user']);
      }
      return null;
    } catch (e) {
      debugPrint("LOGIN ERROR: $e");
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

  Future<void> createNovel(NovelModel novel) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/novels"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": novel.title,
          // author KHÔNG gửi lên — server tự lấy username của createdBy
          "description": novel.description,
          "coverUrl": novel.coverUrl,
          "genres": novel.genres.join(','),
          "status": novel.status,
          "createdBy": novel.createdBy,
        }),
      ).timeout(networkTimeout);

      if (response.statusCode != 201) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Không thể tạo truyện mới.");
      }
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<void> updateNovel(NovelModel novel) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/novels/${novel.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": novel.title,
          "description": novel.description,
          "coverUrl": novel.coverUrl,
          "genres": novel.genres.join(','),
          "status": novel.status,
          "createdBy": novel.createdBy,
        }),
      ).timeout(networkTimeout);

      if (response.statusCode != 200) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Không thể thực hiện chỉnh sửa.");
      }
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  Future<void> deleteNovel(int novelId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/novels/$novelId/$userId"),
      ).timeout(networkTimeout);

      if (response.statusCode != 200) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Không thể xóa dữ liệu truyện.");
      }
    } catch (e) {
      _handleNetworkError(e);
    }
  }

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
  // 3. CÁC HÀM CHO CHƯƠNG TRUYỆN (CHAPTERS) — CÓ CRUD ĐẦY ĐỦ
  // ============================================================================

  Future<List<ChapterModel>> getChapters(int novelId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/novels/$novelId/chapters")).timeout(networkTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
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

  /// Thêm chương mới — server tự tính chapter_number tiếp theo
  /// [userId] dùng để server xác thực quyền (chủ sở hữu hoặc admin)
  Future<void> createChapter({
    required int novelId,
    required String title,
    required String content,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/novels/$novelId/chapters"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "content": content,
          "userId": userId,
        }),
      ).timeout(networkTimeout);

      if (response.statusCode != 201) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Không thể thêm chương mới.");
      }
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  /// Cập nhật nội dung chương — server kiểm tra quyền qua [userId]
  Future<void> updateChapter({
    required int chapterId,
    required String title,
    required String content,
    required int userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/chapters/$chapterId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "content": content,
          "userId": userId,
        }),
      ).timeout(networkTimeout);

      if (response.statusCode != 200) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Không thể cập nhật chương.");
      }
    } catch (e) {
      _handleNetworkError(e);
    }
  }

  /// Xóa chương — server tự đánh lại số thứ tự sau khi xóa
  Future<void> deleteChapter({
    required int chapterId,
    required int userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/chapters/$chapterId/$userId"),
      ).timeout(networkTimeout);

      if (response.statusCode != 200) {
        final errData = jsonDecode(response.body);
        throw Exception(errData['message'] ?? "Không thể xóa chương.");
      }
    } catch (e) {
      _handleNetworkError(e);
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
  // 5. ĐÁNH GIÁ TRUYỆN - GỌI STORED PROCEDURE (🏆 ĐIỂM GIỎI)
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