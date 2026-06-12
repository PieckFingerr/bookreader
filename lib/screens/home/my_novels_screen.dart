// lib/screens/my_novels/my_novels_screen.dart
import 'package:bookreader/screens/home/chapter_novel_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/novel_model.dart';
import '../../providers/novel_provider.dart';
import '../../utils/app_theme.dart';
import '../home/add_novels_screen.dart';
import '../home/chapter_novel_screen.dart';

class MyNovelsScreen extends StatefulWidget {
  final int userId;
  final int isAdmin; // 0: Thường, 1: Admin

  const MyNovelsScreen({super.key, required this.userId, required this.isAdmin});

  @override
  State<MyNovelsScreen> createState() => _MyNovelsScreenState();
}

class _MyNovelsScreenState extends State<MyNovelsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool get isSystemAdmin => widget.isAdmin == 1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: isSystemAdmin ? 2 : 1, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refreshData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovelProvider>().loadNovels();
    });
  }

  void _confirmDelete(BuildContext context, NovelModel novel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận xóa', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn gỡ bỏ vĩnh viễn bộ truyện "${novel.title}" khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('HỦY', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final ownerId = isSystemAdmin ? (novel.createdBy ?? widget.userId) : widget.userId;
                await context.read<NovelProvider>().removeNovel(novel.id!, ownerId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 Đã xóa vĩnh viễn bộ truyện khỏi hệ thống.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Không thể xóa: ${e.toString().replaceAll("Exception: ", "")}')),
                  );
                }
              }
            },
            child: Text('XÓA TRUYỆN', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NovelProvider>();
    final personalNovels = provider.allNovels.where((n) => n.createdBy == widget.userId).toList();
    final allSystemNovels = provider.allNovels;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isSystemAdmin ? 'Quản Trị Nội Dung' : 'Sáng Tác Của Tôi',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        bottom: isSystemAdmin
            ? TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.person_pin_rounded), text: 'Truyện của tôi'),
                  Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Quản lý hệ thống'),
                ],
              )
            : null,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : isSystemAdmin
              ? TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildNovelList(personalNovels, "Bạn chưa đăng bộ truyện nào."),
                    _buildNovelList(allSystemNovels, "Hệ thống cơ sở dữ liệu trống."),
                  ],
                )
              : _buildNovelList(personalNovels, "Bạn chưa đăng bộ truyện chữ nào."),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddNovelScreen(userId: widget.userId)),
        ).then((_) => _refreshData()),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('ĐĂNG TRUYỆN', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNovelList(List<NovelModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.nunito(color: AppTheme.textHint, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final novel = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    novel.coverUrl.isNotEmpty
                        ? novel.coverUrl
                        : 'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=100',
                    width: 45,
                    height: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 45,
                      height: 65,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book),
                    ),
                  ),
                ),
                title: Text(
                  novel.title,
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Tác giả = username người tạo (server đã tự gán)
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          novel.author,
                          style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      novel.status == 'ongoing' ? '🟠 Đang ra' : '🟢 Hoàn thành',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: novel.status == 'ongoing' ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                      tooltip: 'Sửa thông tin truyện',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddNovelScreen(userId: widget.userId, novel: novel),
                        ),
                      ).then((_) => _refreshData()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                      tooltip: 'Xóa truyện',
                      onPressed: () => _confirmDelete(context, novel),
                    ),
                  ],
                ),
              ),

              // ── Nút Quản lý chương ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChapterManagerScreen(
                        novel: novel,
                        userId: widget.userId,
                        isAdmin: isSystemAdmin,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: Text(
                    'QUẢN LÝ CHƯƠNG',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}