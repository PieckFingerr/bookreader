// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/novel_provider.dart';
import 'providers/bookmark_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NovelProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ],
      child: MaterialApp(
        title: 'NoveLit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().addListener(_onAuthChanged);
    _init();
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    final bookmarks = context.read<BookmarkProvider>();
    if (!auth.isLoggedIn) {
      bookmarks.clear();  // clear khi logout
    } else if (auth.currentUser != null) {
      // Bọc thêm try catch phòng hờ lỗi No element dính kết nối
      try {
        bookmarks.loadBookmarks(auth.currentUser!.id!);  // load khi login
      } catch (_) {}
    }
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.tryAutoLogin();
    if (auth.isLoggedIn) {
      // 🏆 SỬA TẠI ĐÂY: Bọc try-catch bảo vệ ứng dụng không bị sập khi khởi động
      try {
        await context.read<BookmarkProvider>().loadBookmarks(auth.currentUser!.id!);
      } catch (e) {
        debugPrint("Lỗi nạp danh sách bookmark khởi tạo: $e");
      }
    }
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded, size: 64, color: Color(0xFF2D6A4F)),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            ],
          ),
        ),
      );
    }

    // Khi khởi tạo xong thì điều hướng thẳng vào màn hình Home
    return const HomeScreen(); 
  }
}