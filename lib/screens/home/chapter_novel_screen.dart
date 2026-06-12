// lib/screens/my_novels/chapter_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chapter_model.dart';
import '../../models/novel_model.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class ChapterManagerScreen extends StatefulWidget {
  final NovelModel novel;
  final int userId;
  final bool isAdmin;

  const ChapterManagerScreen({
    super.key,
    required this.novel,
    required this.userId,
    required this.isAdmin,
  });

  @override
  State<ChapterManagerScreen> createState() => _ChapterManagerScreenState();
}

class _ChapterManagerScreenState extends State<ChapterManagerScreen> {
  List<ChapterModel> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService().getChapters(widget.novel.id!);
      if (mounted) setState(() { _chapters = list; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('❌ $msg'),
      backgroundColor: Colors.red[700],
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ $msg'),
      backgroundColor: Colors.green[700],
    ));
  }

  // Mở dialog thêm hoặc sửa chương
  void _openChapterDialog({ChapterModel? chapter}) {
    final titleCtrl = TextEditingController(text: chapter?.title ?? '');
    final contentCtrl = TextEditingController(text: chapter?.content ?? '');
    final isEdit = chapter != null;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? 'Chỉnh sửa Chương ${chapter.chapterNumber}'
                    : 'Thêm chương mới',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: GoogleFonts.nunito(),
                decoration: InputDecoration(
                  labelText: 'Tiêu đề chương',
                  labelStyle: GoogleFonts.nunito(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 10,
                style: GoogleFonts.nunito(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nội dung chương',
                  labelStyle: GoogleFonts.nunito(color: AppTheme.textSecondary),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('HỦY', style: GoogleFonts.nunito(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final content = contentCtrl.text.trim();
                      if (title.isEmpty || content.isEmpty) {
                        _showError('Vui lòng điền đầy đủ tiêu đề và nội dung!');
                        return;
                      }
                      Navigator.pop(ctx);
                      try {
                        if (isEdit) {
                          await DatabaseService().updateChapter(
                            chapterId: chapter.id!,
                            title: title,
                            content: content,
                            userId: widget.userId,
                          );
                          _showSuccess('Đã cập nhật chương thành công!');
                        } else {
                          await DatabaseService().createChapter(
                            novelId: widget.novel.id!,
                            title: title,
                            content: content,
                            userId: widget.userId,
                          );
                          _showSuccess('Đã thêm chương mới thành công!');
                        }
                        _loadChapters();
                      } catch (e) {
                        _showError(e.toString().replaceAll('Exception: ', ''));
                      }
                    },
                    child: Text(
                      isEdit ? 'LƯU THAY ĐỔI' : 'ĐĂNG CHƯƠNG',
                      style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteChapter(ChapterModel chapter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Xóa chương?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc muốn xóa vĩnh viễn "Chương ${chapter.chapterNumber}: ${chapter.title}"?',
          style: GoogleFonts.nunito(),
        ),
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
                await DatabaseService().deleteChapter(
                  chapterId: chapter.id!,
                  userId: widget.userId,
                );
                _showSuccess('Đã xóa chương và cập nhật lại số thứ tự.');
                _loadChapters();
              } catch (e) {
                _showError(e.toString().replaceAll('Exception: ', ''));
              }
            },
            child: Text('XÓA', style: GoogleFonts.nunito(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý chương',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              widget.novel.title,
              style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (widget.isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text('ADMIN', style: GoogleFonts.nunito(
                      color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _chapters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded, size: 64, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có chương nào.\nHãy thêm chương đầu tiên!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(color: AppTheme.textHint, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final ch = _chapters[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.15),
                          child: Text(
                            '${ch.chapterNumber}',
                            style: GoogleFonts.nunito(
                                color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          ch.title,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${ch.createdAt.day}/${ch.createdAt.month}/${ch.createdAt.year}',
                          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textHint),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                              tooltip: 'Sửa chương',
                              onPressed: () async {
                                // Load nội dung đầy đủ trước khi mở dialog sửa
                                try {
                                  final full = await DatabaseService().getChapterDetails(ch.id!);
                                  if (full != null && mounted) _openChapterDialog(chapter: full);
                                } catch (e) {
                                  _showError('Không thể tải nội dung chương.');
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                              tooltip: 'Xóa chương',
                              onPressed: () => _confirmDeleteChapter(ch),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChapterDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'THÊM CHƯƠNG',
          style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}