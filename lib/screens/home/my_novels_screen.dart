// lib/screens/my_novels/my_novels_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../utils/app_theme.dart';

class MyNovelsScreen extends StatefulWidget {
  final int userId;
  const MyNovelsScreen({super.key, required this.userId});

  @override
  State<MyNovelsScreen> createState() => _MyNovelsScreenState();
}

class _MyNovelsScreenState extends State<MyNovelsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 💡 ĐÃ SỬA: Đồng bộ tải dữ liệu truyện chữ qua API SQL Server nội bộ chung
      context.read<NovelProvider>().loadNovels();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovelProvider>();
    // Lọc danh sách truyện do chính user này tạo dựa trên trường createdBy từ SQL Server về
    final userNovels = provider.allNovels.where((n) => n.createdBy == widget.userId).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Truyện của tôi',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : userNovels.isEmpty
              ? Center(
                  child: Text(
                    'Bạn chưa đăng bộ truyện chữ nào.',
                    style: GoogleFonts.nunito(color: AppTheme.textHint),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userNovels.length,
                  itemBuilder: (context, index) {
                    final novel = userNovels[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(novel.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                        subtitle: Text(novel.author, style: GoogleFonts.nunito(fontSize: 13)),
                      ),
                    );
                  },
                ),
    );
  }
}