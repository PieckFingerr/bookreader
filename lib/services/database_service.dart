// lib/services/database_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/novel_model.dart';
import '../models/chapter_model.dart';
import '../models/bookmark_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'light_novel.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        is_admin INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE novels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        description TEXT NOT NULL,
        cover_url TEXT NOT NULL,
        genres TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ongoing',
        view_count INTEGER DEFAULT 0,
        rating REAL DEFAULT 0.0,
        rating_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        novel_id INTEGER NOT NULL,
        chapter_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (novel_id) REFERENCES novels (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        novel_id INTEGER NOT NULL,
        last_chapter_id INTEGER,
        last_chapter_number INTEGER,
        updated_at TEXT NOT NULL,
        UNIQUE(user_id, novel_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (novel_id) REFERENCES novels (id) ON DELETE CASCADE
      )
    ''');

    // Seed admin account
    final adminHash = _hashPassword('admin123');
    await db.insert('users', {
      'username': 'admin',
      'email': 'admin@lightnovel.app',
      'password_hash': adminHash,
      'is_admin': 1,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed sample data
    await _seedSampleData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _seedSampleData(Database db) async {
    final now = DateTime.now();

    final novels = [
      {
        'title': 'Kiếm Lai',
        'author': 'Phong Hỏa Hí Chư Hầu',
        'description': 'Một câu chuyện về hành trình tu tiên của một cậu bé nghèo khổ vùng biên thùy, từng bước leo lên đỉnh cao của thế giới võ lâm. Với ý chí kiên định và thanh kiếm trong tay, Trần Bình bước vào con đường mà vô số người mơ ước nhưng chỉ rất ít người có thể đi đến cuối cùng.',
        'cover_url': 'https://picsum.photos/seed/novel1/300/450',
        'genres': 'Tiên hiệp,Hành động,Phiêu lưu',
        'status': 'ongoing',
        'view_count': 125430,
        'rating': 4.7,
        'rating_count': 3210,
      },
      {
        'title': 'Cô Gái Đến Từ Hôm Qua',
        'author': 'Nguyễn Nhật Ánh',
        'description': 'Một câu chuyện ngọt ngào về tình yêu tuổi học trò trong sáng, về những kỷ niệm không thể nào quên của thời thanh xuân. Tiểu Lan và Thịnh – hai tâm hồn gặp nhau trong một chiều mưa phố nhỏ, cùng nhau viết nên câu chuyện tình đầu đẹp như một bài thơ.',
        'cover_url': 'https://picsum.photos/seed/novel2/300/450',
        'genres': 'Lãng mạn,Học đường,Tình cảm',
        'status': 'completed',
        'view_count': 89200,
        'rating': 4.9,
        'rating_count': 5621,
      },
      {
        'title': 'Overlord: Chúa Tể Bóng Tối',
        'author': 'Kugane Maruyama',
        'description': 'Khi trò chơi YGGDRASIL kết thúc, Momonga – một game thủ huyền thoại – bỗng nhiên tỉnh dậy trong thế giới game với tư cách là nhân vật của mình. Không thể đăng xuất, không có liên lạc với thế giới thực, anh phải tồn tại và thống trị trong một thế giới hoàn toàn xa lạ.',
        'cover_url': 'https://picsum.photos/seed/novel3/300/450',
        'genres': 'Isekai,Fantasy,Hành động',
        'status': 'ongoing',
        'view_count': 201560,
        'rating': 4.8,
        'rating_count': 7890,
      },
      {
        'title': 'Re:Zero - Bắt Đầu Lại Ở Dị Thế Giới',
        'author': 'Tappei Nagatsuki',
        'description': 'Subaru Natsuki – một thanh niên không có gì đặc biệt – đột nhiên bị triệu hoán đến một thế giới kỳ ảo. Sức mạnh duy nhất anh có là "Trở về từ cái chết" – mỗi khi qua đời, anh lại sống lại ở một thời điểm trước đó và phải đối mặt lại với thử thách.',
        'cover_url': 'https://picsum.photos/seed/novel4/300/450',
        'genres': 'Isekai,Drama,Fantasy',
        'status': 'ongoing',
        'view_count': 178900,
        'rating': 4.6,
        'rating_count': 4532,
      },
      {
        'title': 'Bí Ẩn Tòa Lâu Đài Cổ',
        'author': 'Nguyễn Văn Minh',
        'description': 'Thám tử trẻ Minh Tuấn nhận được một lá thư bí ẩn mời anh đến tòa lâu đài cổ kính ở vùng núi hẻo lánh. Khi đến nơi, anh phát hiện ra một chuỗi những bí ẩn chưa được giải đáp từ hàng chục năm trước. Mỗi căn phòng là một bí mật, mỗi bước chân là một nguy hiểm rình rập.',
        'cover_url': 'https://picsum.photos/seed/novel5/300/450',
        'genres': 'Trinh thám,Huyền bí,Kinh dị',
        'status': 'completed',
        'view_count': 56700,
        'rating': 4.3,
        'rating_count': 1234,
      },
      {
        'title': 'Thần Cấp Thăng Cấp Hệ Thống',
        'author': 'Thiên Tằm Thổ Đậu',
        'description': 'Lâm Phàm – một thanh niên bình thường – bỗng một ngày nhận được hệ thống thần cấp, cho phép anh thăng cấp nhanh chóng trong thế giới tu tiên đầy nguy hiểm. Từ kẻ không có căn cơ tu luyện, anh từng bước chinh phục mọi đỉnh cao, đối mặt với những kẻ thù mạnh nhất.',
        'cover_url': 'https://picsum.photos/seed/novel6/300/450',
        'genres': 'Hệ thống,Tiên hiệp,Phiêu lưu',
        'status': 'ongoing',
        'view_count': 312000,
        'rating': 4.5,
        'rating_count': 9876,
      },
    ];

    for (final novel in novels) {
      final novelId = await db.insert('novels', {
        ...novel,
        'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      for (int i = 1; i <= 5; i++) {
        await db.insert('chapters', {
          'novel_id': novelId,
          'chapter_number': i,
          'title': 'Chương $i: ${_getChapterTitle(i)}',
          'content': _generateChapterContent(novel['title'] as String, i),
          'created_at': now.subtract(Duration(days: 30 - i)).toIso8601String(),
        });
      }
    }
  }

  String _getChapterTitle(int chapter) {
    final titles = [
      'Khởi Đầu Mới',
      'Cuộc Gặp Gỡ Định Mệnh',
      'Thử Thách Đầu Tiên',
      'Bí Ẩn Được Hé Lộ',
      'Con Đường Phía Trước',
    ];
    return titles[(chapter - 1) % titles.length];
  }

  String _generateChapterContent(String novelTitle, int chapter) {
    return '''Đây là nội dung chương $chapter của "$novelTitle".

Ánh bình minh len lỏi qua khe cửa sổ nhỏ, chiếu những tia nắng vàng nhạt lên tấm chăn bạc màu. Nhân vật chính từ từ mở mắt, trong lòng vẫn còn đang suy nghĩ về những gì đã xảy ra ngày hôm qua.

"Hôm nay lại là một ngày mới," anh tự nhủ, ngồi dậy và nhìn ra ngoài cửa sổ. Bầu trời trong xanh, không một gợn mây, như thể đang hứa hẹn một ngày đẹp trời.

Bước xuống từ chiếc giường gỗ cũ kỹ, tiếng ván sàn kẽo kẹt vang lên trong căn nhà yên tĩnh. Nhà không còn ai ngoài anh – như thường lệ. Sự cô đơn đã trở thành người bạn đồng hành quen thuộc từ lâu rồi.

Sau khi rửa mặt qua loa bằng chậu nước lạnh, anh khoác chiếc áo khoác cũ lên người và bước ra ngoài. Con đường làng buổi sáng vắng vẻ, chỉ có tiếng chim hót và gió thổi qua những tán cây xanh mướt.

"Lại bắt đầu thôi," anh nói khẽ, bước những bước dứt khoát trên con đường đất dẫn ra phía trước, nơi vận mệnh đang chờ đợi anh.

Phía xa xa, đỉnh núi mờ ảo trong sương sớm, bí ẩn và hùng vĩ. Đó là nơi anh phải đến. Đó là nơi tất cả bắt đầu – và có thể, cũng là nơi tất cả kết thúc.

Nhưng anh không sợ. Chưa bao giờ sợ. Bởi vì kẻ không có gì để mất thì cũng không có gì để sợ mất đi thêm nữa.

Bước chân anh dứt khoát hơn. Quyết tâm hơn. Và cuộc hành trình – dù dài bao nhiêu, dù khó khăn bao nhiêu – đã thực sự bắt đầu.

*Tiếp theo sẽ là Chương ${chapter + 1}...*''';
  }

  // ==================== SESSION METHODS ====================

  Future<void> saveSession(int userId) async {
    final db = await database;
    await db.insert(
      'sessions',
      {'user_id': userId, 'created_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getSessionUser() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT u.* FROM users u
      INNER JOIN sessions s ON s.user_id = u.id
      LIMIT 1
    ''');
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('sessions');
  }

  // ==================== USER METHODS ====================

  String hashPassword(String password) => _hashPassword(password);

  Future<UserModel?> login(String username, String password) async {
    final db = await database;
    final hash = _hashPassword(password);
    final result = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password_hash = ?',
      whereArgs: [username, username, hash],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<bool> register(String username, String email, String password) async {
    final db = await database;
    try {
      final hash = _hashPassword(password);
      await db.insert('users', {
        'username': username,
        'email': email,
        'password_hash': hash,
        'is_admin': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> usernameExists(String username) async {
    final db = await database;
    final result = await db.query('users', where: 'username = ?', whereArgs: [username]);
    return result.isNotEmpty;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty;
  }

  // ==================== NOVEL METHODS ====================

  Future<List<NovelModel>> getAllNovels({String? genre, String? status, String? search}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      where = 'title LIKE ? OR author LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }
    if (genre != null && genre.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'genres LIKE ?';
      whereArgs.add('%$genre%');
    }
    if (status != null && status.isNotEmpty) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'status = ?';
      whereArgs.add(status);
    }

    final result = await db.query(
      'novels',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'updated_at DESC',
    );
    return result.map((e) => NovelModel.fromMap(e)).toList();
  }

  Future<NovelModel?> getNovelById(int id) async {
    final db = await database;
    final result = await db.query('novels', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return NovelModel.fromMap(result.first);
  }

  Future<int> insertNovel(NovelModel novel) async {
    final db = await database;
    return db.insert('novels', novel.toMap()..remove('id'));
  }

  Future<int> updateNovel(NovelModel novel) async {
    final db = await database;
    return db.update('novels', novel.toMap(), where: 'id = ?', whereArgs: [novel.id]);
  }

  Future<int> deleteNovel(int id) async {
    final db = await database;
    return db.delete('novels', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementViewCount(int novelId) async {
    final db = await database;
    await db.rawUpdate('UPDATE novels SET view_count = view_count + 1 WHERE id = ?', [novelId]);
  }

  // ==================== CHAPTER METHODS ====================

  Future<List<ChapterModel>> getChaptersByNovelId(int novelId) async {
    final db = await database;
    final result = await db.query(
      'chapters',
      where: 'novel_id = ?',
      whereArgs: [novelId],
      orderBy: 'chapter_number ASC',
    );
    return result.map((e) => ChapterModel.fromMap(e)).toList();
  }

  Future<ChapterModel?> getChapterById(int id) async {
    final db = await database;
    final result = await db.query('chapters', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return ChapterModel.fromMap(result.first);
  }

  Future<int> insertChapter(ChapterModel chapter) async {
    final db = await database;
    return db.insert('chapters', chapter.toMap()..remove('id'));
  }

  Future<int> updateChapter(ChapterModel chapter) async {
    final db = await database;
    return db.update('chapters', chapter.toMap(), where: 'id = ?', whereArgs: [chapter.id]);
  }

  Future<int> deleteChapter(int id) async {
    final db = await database;
    return db.delete('chapters', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getChapterCount(int novelId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chapters WHERE novel_id = ?',
      [novelId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== BOOKMARK METHODS ====================

  Future<List<Map<String, dynamic>>> getBookmarksWithNovels(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT b.*, n.title, n.author, n.cover_url, n.status, n.genres
      FROM bookmarks b
      JOIN novels n ON b.novel_id = n.id
      WHERE b.user_id = ?
      ORDER BY b.updated_at DESC
    ''', [userId]);
  }

  Future<BookmarkModel?> getBookmark(int userId, int novelId) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'user_id = ? AND novel_id = ?',
      whereArgs: [userId, novelId],
    );
    if (result.isEmpty) return null;
    return BookmarkModel.fromMap(result.first);
  }

  Future<void> upsertBookmark({
    required int userId,
    required int novelId,
    int? lastChapterId,
    int? lastChapterNumber,
  }) async {
    final db = await database;
    final existing = await getBookmark(userId, novelId);
    if (existing == null) {
      await db.insert('bookmarks', {
        'user_id': userId,
        'novel_id': novelId,
        'last_chapter_id': lastChapterId,
        'last_chapter_number': lastChapterNumber,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'bookmarks',
        {
          'last_chapter_id': lastChapterId ?? existing.lastChapterId,
          'last_chapter_number': lastChapterNumber ?? existing.lastChapterNumber,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  Future<void> removeBookmark(int userId, int novelId) async {
    final db = await database;
    await db.delete('bookmarks', where: 'user_id = ? AND novel_id = ?', whereArgs: [userId, novelId]);
  }
}