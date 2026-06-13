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

  // Mở màn hình editor đầy đủ thay vì dialog nhỏ
  void _openChapterEditor({ChapterModel? chapter}) async {
    ChapterModel? fullChapter = chapter;

    // Nếu sửa, load nội dung đầy đủ trước
    if (chapter != null) {
      try {
        fullChapter = await DatabaseService().getChapterDetails(chapter.id!);
      } catch (e) {
        _showError('Không thể tải nội dung chương.');
        return;
      }
    }

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterEditorScreen(
          novel: widget.novel,
          userId: widget.userId,
          chapter: fullChapter,
        ),
      ),
    );

    if (result == true) {
      _loadChapters();
      _showSuccess(chapter == null ? 'Đã thêm chương mới thành công!' : 'Đã cập nhật chương thành công!');
    }
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
                              onPressed: () => _openChapterEditor(chapter: ch),
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
        onPressed: () => _openChapterEditor(),
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

// ============================================================
// MÀN HÌNH EDITOR CHƯƠNG — có toolbar chèn ảnh
// ============================================================
class _ChapterEditorScreen extends StatefulWidget {
  final NovelModel novel;
  final int userId;
  final ChapterModel? chapter;

  const _ChapterEditorScreen({
    required this.novel,
    required this.userId,
    this.chapter,
  });

  @override
  State<_ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<_ChapterEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _contentFocus = FocusNode();
  bool _isSaving = false;
  bool _showImageHelper = false; // Toggle hướng dẫn cú pháp ảnh

  bool get isEdit => widget.chapter != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _titleCtrl.text = widget.chapter!.title;
      _contentCtrl.text = widget.chapter!.content;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // Chèn tag [img]...[/img] vào vị trí con trỏ hiện tại
  void _insertImageTag(String url) {
    final ctrl = _contentCtrl;
    final text = ctrl.text;
    final sel = ctrl.selection;

    // Vị trí con trỏ hợp lệ thì chèn tại đó, không thì chèn cuối
    final insertPos = sel.isValid ? sel.baseOffset : text.length;

    // Tự động xuống dòng nếu chưa có
    final before = text.substring(0, insertPos);
    final after = text.substring(insertPos);
    final prefix = (before.isNotEmpty && !before.endsWith('\n')) ? '\n' : '';
    final suffix = (after.isNotEmpty && !after.startsWith('\n')) ? '\n' : '';

    final tag = '$prefix[img]$url[/img]$suffix';
    final newText = before + tag + after;
    final newOffset = insertPos + tag.length;

    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  // Dialog nhập URL ảnh
  void _showInsertImageDialog() {
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.image_rounded, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text('Chèn ảnh minh hoạ',
                style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: urlCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'https://i.imgur.com/...',
                hintStyle: GoogleFonts.nunito(color: AppTheme.textHint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.textHint),
              ),
              style: GoogleFonts.nunito(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppTheme.accent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dùng link từ imgur.com, imgbb.com hoặc postimages.org để ảnh hiển thị được.',
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('HỦY', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.add_photo_alternate_rounded,
                color: Colors.white, size: 16),
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              _insertImageTag(url);
            },
            label: Text('CHÈN ẢNH',
                style: GoogleFonts.nunito(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền tiêu đề và nội dung!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (isEdit) {
        await DatabaseService().updateChapter(
          chapterId: widget.chapter!.id!,
          title: title,
          content: content,
          userId: widget.userId,
        );
      } else {
        await DatabaseService().createChapter(
          novelId: widget.novel.id!,
          title: title,
          content: content,
          userId: widget.userId,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEdit
              ? 'Sửa Chương ${widget.chapter!.chapterNumber}'
              : 'Thêm Chương Mới',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, color: AppTheme.primary),
              label: Text(
                isEdit ? 'LƯU' : 'ĐĂNG',
                style: GoogleFonts.nunito(
                    color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── TOOLBAR ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Nút chèn ảnh chính
                _ToolbarButton(
                  icon: Icons.add_photo_alternate_rounded,
                  label: 'Chèn ảnh',
                  color: AppTheme.primary,
                  onTap: _showInsertImageDialog,
                ),
                const SizedBox(width: 4),
                // Nút xuống dòng (tiện cho mobile)
                _ToolbarButton(
                  icon: Icons.keyboard_return_rounded,
                  label: 'Xuống dòng',
                  color: AppTheme.textSecondary,
                  onTap: () {
                    final ctrl = _contentCtrl;
                    final pos = ctrl.selection.isValid
                        ? ctrl.selection.baseOffset
                        : ctrl.text.length;
                    final newText = ctrl.text.substring(0, pos) +
                        '\n\n' +
                        ctrl.text.substring(pos);
                    ctrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: pos + 2),
                    );
                  },
                ),
                const Spacer(),
                // Toggle hướng dẫn cú pháp
                GestureDetector(
                  onTap: () => setState(() => _showImageHelper = !_showImageHelper),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _showImageHelper
                          ? AppTheme.primary.withOpacity(0.12)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showImageHelper ? AppTheme.primary : AppTheme.divider,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 14,
                          color: _showImageHelper
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cú pháp',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showImageHelper
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── HƯỚNG DẪN CÚ PHÁP (ẩn/hiện) ────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showImageHelper
                ? Container(
                    width: double.infinity,
                    color: AppTheme.accentLight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cú pháp chèn ảnh vào nội dung:',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Text(
                            '[img]https://i.imgur.com/abc.jpg[/img]',
                            style: GoogleFonts.sourceCodePro != null
                                ? const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryDark,
                                    fontFamily: 'monospace',
                                  )
                                : const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryDark,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '💡 Nhấn "Chèn ảnh" để tự động tạo tag tại vị trí con trỏ.',
                          style: GoogleFonts.nunito(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── NỘI DUNG FORM ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tiêu đề chương
                  TextField(
                    controller: _titleCtrl,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề chương *',
                      labelStyle: GoogleFonts.nunito(color: AppTheme.textSecondary),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nội dung chương
                  TextField(
                    controller: _contentCtrl,
                    focusNode: _contentFocus,
                    maxLines: null,
                    minLines: 20,
                    keyboardType: TextInputType.multiline,
                    style: GoogleFonts.merriweather(
                        fontSize: 14, height: 1.9, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Nội dung chương *',
                      labelStyle: GoogleFonts.nunito(color: AppTheme.textSecondary),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      helperText:
                          'Nhấn "Chèn ảnh" trên toolbar để thêm ảnh minh hoạ',
                      helperStyle: GoogleFonts.nunito(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget nút toolbar nhỏ gọn
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}