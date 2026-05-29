# 📚 NoveLit – Light Novel Reader App

Ứng dụng đọc Light Novel được xây dựng bằng Flutter, lưu trữ offline bằng SQLite.

---

## ✨ Tính năng

### 👤 Người dùng thường
- **Đăng ký / Đăng nhập** (lưu session tự động)
- **Trang chủ** – Xem truyện nổi bật, lọc theo thể loại
- **Chi tiết truyện** – Xem mô tả, đánh giá, danh sách chương
- **Đọc truyện** – Giao diện đọc tối giản, chỉnh cỡ chữ, chuyển chương nhanh
- **Tủ sách** – Bookmark truyện, lưu tiến độ đọc (chương đang đọc)
- **Tìm kiếm** – Tìm theo tên/tác giả, lọc thể loại + trạng thái

### 🛡️ Quản trị viên (Admin)
- Toàn bộ quyền người dùng +
- **Quản lý truyện**: Thêm / Sửa / Xoá truyện
- **Quản lý chương**: Thêm / Sửa / Xoá chương theo từng truyện
- Truy cập qua tab **Cá nhân → Quản trị nội dung**

---

## 🚀 Cài đặt & Chạy

### Yêu cầu
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio hoặc VS Code

### Bước 1: Lấy dependencies
```bash
cd light_novel_app
flutter pub get
```

### Bước 2: Chạy app
```bash
flutter run
```

---

## 🔐 Tài khoản mặc định

| Loại        | Username | Password  |
|-------------|----------|-----------|
| Admin       | admin    | admin123  |
| Tự đăng ký | *(tạo mới trong app)* | |

---

## 🗄️ Cấu trúc cơ sở dữ liệu (SQLite)

```
users          – id, username, email, password_hash, is_admin
novels         – id, title, author, description, cover_url, genres, status, view_count, rating
chapters       – id, novel_id, chapter_number, title, content
bookmarks      – id, user_id, novel_id, last_chapter_id, last_chapter_number
```

---

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                    # Entry point
├── models/
│   ├── user_model.dart
│   ├── novel_model.dart
│   ├── chapter_model.dart
│   └── bookmark_model.dart
├── services/
│   └── database_service.dart    # SQLite CRUD
├── providers/
│   ├── auth_provider.dart       # Đăng nhập / đăng ký
│   ├── novel_provider.dart      # Truyện + chương
│   └── bookmark_provider.dart   # Tủ sách
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart     # Bottom nav
│   │   ├── discover_tab.dart    # Tab khám phá
│   │   ├── bookmarks_tab.dart   # Tab tủ sách
│   │   └── profile_tab.dart     # Tab cá nhân
│   ├── reader/
│   │   ├── novel_detail_screen.dart
│   │   └── reader_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   └── admin/
│       └── admin_screen.dart    # Quản trị (novel + chapter forms)
├── widgets/
│   └── novel_card.dart          # NovelCard, NovelListTile, GenreChip
└── utils/
    └── app_theme.dart           # Theme, màu sắc, constants
```

---

## 📦 Dependencies chính

| Package | Mục đích |
|---------|----------|
| `sqflite` | SQLite local database |
| `provider` | State management |
| `shared_preferences` | Lưu session |
| `google_fonts` | Font Playfair Display + Nunito |
| `crypto` | Hash mật khẩu SHA-256 |
| `cached_network_image` | Ảnh bìa từ URL |

---

## 🎨 Thiết kế

- **Phong cách**: Sáng thanh lịch, lấy cảm hứng từ sách in
- **Font chính**: Playfair Display (tiêu đề) + Nunito (body) + Merriweather (đọc truyện)  
- **Màu chủ đạo**: Xanh rừng (#2D6A4F) + Vàng cát (#D4A373)
- **Dữ liệu mẫu**: 6 truyện với 5 chương mỗi truyện được seed tự động

---

## 🔧 Mở rộng

Bạn có thể dễ dàng thêm:
- **Rating/Review**: Thêm bảng `reviews` và màn hình đánh giá
- **Dark mode**: Thêm `DarkTheme` trong `app_theme.dart`
- **Thông báo chương mới**: Dùng `flutter_local_notifications`
- **Đồng bộ đám mây**: Thay SQLite bằng Supabase/Firebase
