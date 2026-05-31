// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../models/novel_model.dart';
import '../../models/chapter_model.dart';
import '../../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Quản trị nội dung',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Truyện'),
            Tab(text: 'Chương'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _NovelsTab(),
          _ChaptersTab(),
        ],
      ),
    );
  }
}

// ==================== NOVELS TAB ====================
class _NovelsTab extends StatelessWidget {
  const _NovelsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<NovelProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showNovelForm(context, null),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('Thêm truyện', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: provider.allNovels.length,
                  itemBuilder: (context, i) {
                    final novel = provider.allNovels[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48,
                              height: 68,
                              child: Image.network(
                                novel.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.surfaceVariant,
                                  child: const Icon(Icons.book, size: 20, color: AppTheme.textHint),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  novel.title,
                                  style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  novel.author,
                                  style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  novel.statusLabel,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: novel.status == 'completed'
                                        ? AppTheme.success
                                        : novel.status == 'hiatus'
                                            ? AppTheme.warning
                                            : AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (val) {
                              if (val == 'edit') _showNovelForm(context, novel);
                              if (val == 'delete') _confirmDelete(context, novel.id!, novel.title, provider);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [
                                  const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text('Chỉnh sửa', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                ]),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                                  const SizedBox(width: 8),
                                  Text('Xoá', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppTheme.error)),
                                ]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id, String title, NovelProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá truyện', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xoá "$title"? Tất cả chương sẽ bị xoá.', style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Xoá', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteNovel(id);
  }

  void _showNovelForm(BuildContext context, NovelModel? novel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NovelFormScreen(novel: novel, createdBy: null),
      ),
    );
  }
}

// ==================== CHAPTERS TAB ====================
class _ChaptersTab extends StatefulWidget {
  const _ChaptersTab();

  @override
  State<_ChaptersTab> createState() => _ChaptersTabState();
}

class _ChaptersTabState extends State<_ChaptersTab> {
  int? _selectedNovelId;

  @override
  Widget build(BuildContext context) {
    return Consumer<NovelProvider>(
      builder: (context, provider, _) {
        final novels = provider.allNovels;
        final chapters = _selectedNovelId != null && provider.selectedNovel?.id == _selectedNovelId
            ? provider.chapters
            : [];

        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButton: _selectedNovelId == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showChapterForm(context, _selectedNovelId!, null),
                  backgroundColor: AppTheme.primary,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text('Thêm chương',
                      style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
          body: Column(
            children: [
              // Novel selector
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(bottom: BorderSide(color: AppTheme.divider)),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedNovelId,
                  decoration: const InputDecoration(
                    labelText: 'Chọn truyện',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  items: novels
                      .map((n) => DropdownMenuItem(
                            value: n.id,
                            child: Text(n.title,
                                style: GoogleFonts.nunito(fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() => _selectedNovelId = id);
                    if (id != null) provider.selectNovel(id);
                  },
                ),
              ),
              // Chapters list
              Expanded(
                child: _selectedNovelId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.list_alt_rounded, size: 48, color: AppTheme.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Chọn truyện để xem chương',
                              style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : provider.isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                            itemCount: provider.chapters.length,
                            itemBuilder: (context, i) {
                              final ch = provider.chapters[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.divider),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${ch.chapterNumber}',
                                        style: GoogleFonts.nunito(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ch.title,
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      onSelected: (val) {
                                        if (val == 'edit') _showChapterForm(context, _selectedNovelId!, ch);
                                        if (val == 'delete') _confirmDeleteChapter(context, ch.id!, provider);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(children: [
                                            const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                                            const SizedBox(width: 8),
                                            Text('Sửa', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                          ]),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
                                            const SizedBox(width: 8),
                                            Text('Xoá', style: GoogleFonts.nunito(color: AppTheme.error, fontWeight: FontWeight.w600)),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteChapter(BuildContext context, int id, NovelProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá chương', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xoá chương này không?', style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Huỷ', style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Xoá', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteChapter(id);
  }

  void _showChapterForm(BuildContext context, int novelId, ChapterModel? chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChapterFormScreen(novelId: novelId, chapter: chapter)),
    );
  }
}

// ==================== NOVEL FORM ====================
class NovelFormScreen extends StatefulWidget {
  final NovelModel? novel;
  final int? createdBy;
  const NovelFormScreen({super.key, this.novel, this.createdBy});

  @override
  State<NovelFormScreen> createState() => _NovelFormScreenState();
}

class _NovelFormScreenState extends State<NovelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _coverCtrl;
  List<String> _selectedGenres = [];
  String _status = 'ongoing';

  @override
  void initState() {
    super.initState();
    final n = widget.novel;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _authorCtrl = TextEditingController(text: n?.author ?? '');
    _descCtrl = TextEditingController(text: n?.description ?? '');
    _coverCtrl = TextEditingController(
        text: n?.coverUrl ?? 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/300/450');
    _selectedGenres = List.from(n?.genres ?? []);
    _status = n?.status ?? 'ongoing';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 thể loại')),
      );
      return;
    }

    final provider = context.read<NovelProvider>();
    final now = DateTime.now();
    bool success;

    if (widget.novel == null) {
      final novel = NovelModel(
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        coverUrl: _coverCtrl.text.trim(),
        genres: _selectedGenres,
        status: _status,
        createdAt: now,
        updatedAt: now,
      );
      success = await provider.addNovel(novel, createdBy: widget.createdBy);
    } else {
      final novel = widget.novel!.copyWith(
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        coverUrl: _coverCtrl.text.trim(),
        genres: _selectedGenres,
        status: _status,
        updatedAt: now,
      );
      success = await provider.updateNovel(novel);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.novel == null ? 'Đã thêm truyện!' : 'Đã cập nhật!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.novel == null ? 'Thêm truyện mới' : 'Chỉnh sửa truyện',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Tên truyện *', _titleCtrl, 'Nhập tên truyện...'),
              const SizedBox(height: 16),
              _buildField('Tác giả *', _authorCtrl, 'Nhập tên tác giả...'),
              const SizedBox(height: 16),
              _buildField('URL ảnh bìa', _coverCtrl, 'https://...', required: false),
              const SizedBox(height: 16),
              _buildField('Mô tả *', _descCtrl, 'Nhập mô tả truyện...', maxLines: 5),
              const SizedBox(height: 20),
              // Status
              Text('Trạng thái', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatusOption('ongoing', 'Đang ra', AppTheme.primary),
                  const SizedBox(width: 10),
                  _buildStatusOption('completed', 'Hoàn thành', AppTheme.success),
                  const SizedBox(width: 10),
                  _buildStatusOption('hiatus', 'Tạm dừng', AppTheme.warning),
                ],
              ),
              const SizedBox(height: 20),
              // Genres
              Text('Thể loại *', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllGenres.map((g) {
                  final selected = _selectedGenres.contains(g);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) _selectedGenres.remove(g);
                      else _selectedGenres.add(g);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.getGenreColor(g).withOpacity(0.15) : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppTheme.getGenreColor(g) : AppTheme.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        g,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppTheme.getGenreColor(g) : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          validator: required
              ? (v) => v == null || v.trim().isEmpty ? 'Vui lòng điền trường này' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildStatusOption(String value, String label, Color color) {
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? color : AppTheme.divider, width: selected ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CHAPTER FORM ====================
class ChapterFormScreen extends StatefulWidget {
  final int novelId;
  final ChapterModel? chapter;
  const ChapterFormScreen({super.key, required this.novelId, this.chapter});

  @override
  State<ChapterFormScreen> createState() => _ChapterFormScreenState();
}

class _ChapterFormScreenState extends State<ChapterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _numberCtrl;

  @override
  void initState() {
    super.initState();
    final ch = widget.chapter;
    _titleCtrl = TextEditingController(text: ch?.title ?? '');
    _contentCtrl = TextEditingController(text: ch?.content ?? '');
    _numberCtrl = TextEditingController(text: ch?.chapterNumber.toString() ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<NovelProvider>();
    bool success;

    if (widget.chapter == null) {
      final ch = ChapterModel(
        novelId: widget.novelId,
        chapterNumber: int.parse(_numberCtrl.text),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      success = await provider.addChapter(ch);
    } else {
      final ch = widget.chapter!.copyWith(
        chapterNumber: int.parse(_numberCtrl.text),
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );
      success = await provider.updateChapter(ch);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.chapter == null ? 'Đã thêm chương!' : 'Đã cập nhật!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.chapter == null ? 'Thêm chương mới' : 'Chỉnh sửa chương',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text('Lưu'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Số chương', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'VD: 1'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập số chương';
                  if (int.tryParse(v) == null) return 'Phải là số nguyên';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Tiêu đề chương *', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(hintText: 'VD: Chương 1: Khởi Đầu'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              Text('Nội dung *', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 20,
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung chương...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
