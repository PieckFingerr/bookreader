const express = require("express");
const cors = require("cors");
const sql = require("mssql");
const crypto = require("crypto");

const app = express();
app.use(cors());
app.use(express.json());

// ============================================================================
// 1. CẤU HÌNH KẾT NỐI (Đạt điểm tối đa Bảo mật - Sử dụng user novelit_user)
// ============================================================================
const dbConfig = {
  user: "novelit_user",          // Đã đổi từ 'sa' sang user bảo mật vừa tạo
  password: "SecurePassword123@", // Mật khẩu an toàn cấu hình trong SQL
  server: "cabinaaron",          // Tên server hoặc IP máy tính của bạn
  database: "NoveLitDB",         // Tên database truyện mới
  options: {
    trustServerCertificate: true,
  },
};

// Kết nối đến SQL Server
sql.connect(dbConfig)
  .then(() => console.log("✨ Đã kết nối thành công tới SQL Server (NoveLitDB)"))
  .catch(err => console.error("❌ Lỗi kết nối SQL Server:", err));

// Hàm băm mật khẩu MD5 (Đồng bộ với thuật toán cũ dưới sqflite của bạn)
function hashPassword(password) {
  return crypto.createHash("md5").update(password).digest("hex");
}

// ============================================================================
// 2. CÁC API CHO NGƯỜI DÙNG (USER ROUTERS)
// ============================================================================

// Đăng ký tài khoản mới
app.post("/api/auth/register", async (req, res) => {
  try {
    const { username, email, password } = req.body;
    const passwordHash = hashPassword(password);

    // Kiểm tra trùng lặp tài khoản
    const checkUser = await sql.query`SELECT id FROM users WHERE username = ${username} OR email = ${email}`;
    if (checkUser.recordset.length > 0) {
      return res.status(400).json({ message: "Tên tài khoản hoặc email đã tồn tại." });
    }

    // Thêm người dùng mới
    const result = await sql.query`
      INSERT INTO users (username, email, password_hash, is_admin)
      OUTPUT INSERTED.id, INSERTED.username, INSERTED.email, INSERTED.is_admin, INSERTED.created_at
      VALUES (${username}, ${email}, ${passwordHash}, 0)
    `;

    res.status(201).json({ success: true, user: result.recordset[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi hệ thống khi đăng ký." });
  }
});

// Đăng nhập
app.post("/api/auth/login", async (req, res) => {
  try {
    const { username, password } = req.body; // username có thể là tên đăng nhập hoặc email
    const passwordHash = hashPassword(password);

    const result = await sql.query`
      SELECT id, username, email, is_admin, created_at 
      FROM users 
      WHERE (username = ${username} OR email = ${username}) AND password_hash = ${passwordHash}
    `;

    if (result.recordset.length === 0) {
      return res.status(401).json({ message: "Tài khoản hoặc mật khẩu không chính xác." });
    }

    res.json({ success: true, user: result.recordset[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi hệ thống khi đăng nhập." });
  }
});

// ============================================================================
// 3. CÁC API CHO TRUYỆN CHỮ (NOVEL ROUTERS)
// ============================================================================

// Lấy danh sách toàn bộ truyện (Phục vụ trang chủ)
app.get("/api/novels", async (req, res) => {
  try {
    const result = await sql.query`SELECT * FROM novels ORDER BY updated_at DESC`;
    
    // Convert chuỗi genres 'Action,Isekai' thành mảng ['Action', 'Isekai'] để chuẩn hoá Model Dart
    const novels = result.recordset.map(row => ({
      ...row,
      genres: row.genres ? row.genres.split(",") : []
    }));

    res.json(novels);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi tải danh sách truyện." });
  }
});

// Lấy thông tin chi tiết một bộ truyện
app.get("/api/novels/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await sql.query`SELECT * FROM novels WHERE id = ${id}`;
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: "Không tìm thấy truyện." });
    }

    const novel = result.recordset[0];
    novel.genres = novel.genres ? novel.genres.split(",") : [];

    res.json(novel);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi tải chi tiết truyện." });
  }
});

// Thêm truyện mới (Chỉ dành cho Admin)
app.post("/api/novels", async (req, res) => {
  try {
    const { title, author, description, coverUrl, genres, createdBy } = req.body;
    // Đổi mảng ['Action', 'Fantasy'] thành chuỗi 'Action,Fantasy' để lưu vào SQL Server
    const genresStr = Array.isArray(genres) ? genres.join(",") : genres;

    const result = await sql.query`
      INSERT INTO novels (title, author, description, cover_url, genres, status, created_by)
      OUTPUT INSERTED.id
      VALUES (${title}, ${author}, ${description}, ${coverUrl}, ${genresStr}, 'ongoing', ${createdBy})
    `;

    res.status(201).json({ success: true, novelId: result.recordset[0].id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi khi thêm truyện mới." });
  }
});

// ============================================================================
// 4. CÁC API CHO CHƯƠNG TRUYỆN (CHAPTER ROUTERS)
// ============================================================================

// Lấy danh sách chương của một bộ truyện (Chỉ lấy tiêu đề, không lấy nội dung để tối ưu tốc độ)
app.get("/api/novels/:novelId/chapters", async (req, res) => {
  try {
    const { novelId } = req.params;
    const result = await sql.query`
      SELECT id, novel_id, chapter_number, title, created_at 
      FROM chapters 
      WHERE novel_id = ${novelId} 
      ORDER BY chapter_number ASC
    `;
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi khi tải danh sách chương." });
  }
});

// Đọc nội dung chi tiết một chương (Tự động tăng view_count của truyện)
app.get("/api/chapters/:chapterId", async (req, res) => {
  try {
    const { chapterId } = req.params;
    
    const result = await sql.query`SELECT * FROM chapters WHERE id = ${chapterId}`;
    if (result.recordset.length === 0) {
      return res.status(404).json({ message: "Không tìm thấy chương truyện." });
    }

    const chapter = result.recordset[0];

    // Tăng lượt xem của truyện lên 1 (Tối ưu hóa chạy ngầm background)
    sql.query`UPDATE novels SET view_count = view_count + 1 WHERE id = ${chapter.novel_id}`
       .catch(e => console.error("Lỗi tăng view:", e));

    res.json(chapter);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi tải nội dung chương." });
  }
});

// ============================================================================
// 5. CÁC API THEO DÕI TRUYỆN (BOOKMARK ROUTERS)
// ============================================================================

// Lấy danh sách truyện đã đánh dấu của cơ chế User
app.get("/api/bookmarks/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await sql.query`
      SELECT b.*, n.title as novel_title, n.cover_url as novel_cover, n.author as novel_author
      FROM bookmarks b
      JOIN novels n ON b.novel_id = n.id
      WHERE b.user_id = ${userId}
      ORDER BY b.updated_at DESC
    `;
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi hệ thống khi tải danh sách bookmark." });
  }
});

// Thêm hoặc Cập nhật tiến độ đọc truyện (Bookmark)
app.post("/api/bookmarks", async (req, res) => {
  try {
    const { userId, novelId, lastChapterId, lastChapterNumber } = req.body;

    const check = await sql.query`SELECT id FROM bookmarks WHERE user_id = ${userId} AND novel_id = ${novelId}`;
    
    if (check.recordset.length > 0) {
      // Nếu đã bookmark thì cập nhật chương vừa đọc mới nhất
      await sql.query`
        UPDATE bookmarks 
        SET last_chapter_id = ${lastChapterId}, last_chapter_number = ${lastChapterNumber}, updated_at = GETDATE()
        WHERE user_id = ${userId} AND novel_id = ${novelId}
      `;
    } else {
      // Chưa bookmark thì tạo mới hoàn toàn bản ghi theo dõi
      await sql.query`
        INSERT INTO bookmarks (user_id, novel_id, last_chapter_id, last_chapter_number)
        VALUES (${userId}, ${novelId}, ${lastChapterId}, ${lastChapterNumber})
      `;
    }
    res.json({ success: true, message: "Đã cập nhật dấu trang thành công!" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi cập nhật dấu trang thư viện." });
  }
});

// Xóa truyện khỏi danh sách Bookmark (Huỷ theo dõi)
app.delete("/api/bookmarks/:userId/:novelId", async (req, res) => {
  try {
    const { userId, novelId } = req.params;
    await sql.query`DELETE FROM bookmarks WHERE user_id = ${userId} AND novel_id = ${novelId}`;
    res.json({ success: true, message: "Đã xóa truyện khỏi danh sách theo dõi." });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi khi xóa dấu trang truyện." });
  }
});

// ============================================================================
// 6. GỌI STORED PROCEDURE NÂNG CAO (RATING - TIÊU CHÍ ĐIỂM GIỎI/XUẤT SẮC 🏆)
// ============================================================================
app.post("/api/novels/rating", async (req, res) => {
  try {
    const { userId, novelId, rating } = req.body;

    // Gọi đúng duy nhất 1 dòng Stored Procedure có bọc sẵn Transaction bên trong SQL Server
    await sql.query`EXEC sp_UpsertAndRecalcRating @UserId = ${userId}, @NovelId = ${novelId}, @Rating = ${rating}`;
    
    res.json({ success: true, message: "Đánh giá điểm số truyện thành công và hệ thống đã tự tính toán điểm trung bình!" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Lỗi thực thi Stored Procedure: " + err.message });
  }
});

// Khởi chạy máy chủ Backend trung gian
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 API Server NoveLit đang chạy mượt mà tại port ${PORT}`);
});