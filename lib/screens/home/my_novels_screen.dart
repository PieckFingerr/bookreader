// lib/screens/my_novels/my_novels_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/novel_model.dart';
import '../../models/chapter_model.dart';
import '../../utils/app_theme.dart';

class MyNovelsScreen extends StatefulWidget {
  final int userId;
  const MyNovelsScreen({super.key, required this.userId});

  @override
  State<MyNovelsScreen> createState() => _MyNovelsScreenState();
}

class _MyNovelsScreenState extends State<MyNovelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovelProvider>().loadMyNovels(widget.userId);
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
        title: Text(
          'Truyện của tôi',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Truyện đã đăng'),
            Tab(text: 'Quản lý chương'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MyNovelsTab(userId: widget.userId),
          _MyChaptersTab(userId: widget.userId),
        ],
      ),
    );
  }
}

// ==================== MY NOVELS TAB ====================

class _MyNovelsTab extends StatelessWidget {
  final int userId;
  const _MyNovelsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<NovelProvider>(
      builder: (context, provider, _) {
        final myNovels = provider.myNovels;

        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showNovelForm(context, null),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Đăng truyện mới',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : myNovels.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: myNovels.length,
                  itemBuilder: (context, i) {
                    return _NovelItem(
                      novel: myNovels[i],
                      onEdit: () => _showNovelForm(context, myNovels[i]),
                      onDelete: () =>
                          _confirmDelete(context, myNovels[i], provider),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 44,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có truyện nào',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy bắt đầu chia sẻ câu chuyện của bạn\nvới cộng đồng độc giả!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showNovelForm(context, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Đăng truyện đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NovelModel novel,
    NovelProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xoá truyện',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xoá "${novel.title}"?\nTất cả chương sẽ bị xoá vĩnh viễn.',
          style: GoogleFonts.nunito(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Huỷ',
              style: GoogleFonts.nunito(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text('Xoá', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deleteNovel(novel.id!);
      await provider.loadMyNovels(userId);
    }
  }

  void _showNovelForm(BuildContext context, NovelModel? novel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyNovelFormScreen(novel: novel, createdBy: userId),
      ),
    ).then((_) {
      // Reload sau khi quay lại
      context.read<NovelProvider>().loadMyNovels(userId);
    });
  }
}

// ==================== NOVEL ITEM CARD ====================

class _NovelItem extends StatelessWidget {
  final NovelModel novel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NovelItem({
    required this.novel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 72,
              height: 100,
              child: Image.network(
                novel.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surfaceVariant,
                  child: const Icon(
                    Icons.book,
                    size: 28,
                    color: AppTheme.textHint,
                  ),
                ),
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    novel.author,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusBadge(status: novel.status, label: novel.statusLabel),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppTheme.starColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            novel.rating.toStringAsFixed(1),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye_outlined,
                            size: 12,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatNumber(novel.viewCount),
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: AppTheme.primary,
                ),
                onPressed: onEdit,
                tooltip: 'Chỉnh sửa',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppTheme.error,
                ),
                onPressed: onDelete,
                tooltip: 'Xoá',
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  Color get _color {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'hiatus':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _color,
        ),
      ),
    );
  }
}

// ==================== MY CHAPTERS TAB ====================

class _MyChaptersTab extends StatefulWidget {
  final int userId;
  const _MyChaptersTab({required this.userId});

  @override
  State<_MyChaptersTab> createState() => _MyChaptersTabState();
}

class _MyChaptersTabState extends State<_MyChaptersTab> {
  int? _selectedNovelId;

  @override
  Widget build(BuildContext context) {
    return Consumer<NovelProvider>(
      builder: (context, provider, _) {
        final myNovels = provider.myNovels;

        return Scaffold(
          backgroundColor: AppTheme.background,
          floatingActionButton: _selectedNovelId == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () =>
                      _showChapterForm(context, _selectedNovelId!, null),
                  backgroundColor: AppTheme.primary,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    'Thêm chương',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                child: myNovels.isEmpty
                    ? _buildNoNovelHint(context)
                    : DropdownButtonFormField<int>(
                        value: _selectedNovelId,
                        decoration: const InputDecoration(
                          labelText: 'Chọn truyện để quản lý chương',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        items: myNovels
                            .map(
                              (n) => DropdownMenuItem(
                                value: n.id,
                                child: Text(
                                  n.title,
                                  style: GoogleFonts.nunito(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
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
                    ? _buildSelectHint()
                    : provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : provider.chapters.isEmpty
                    ? _buildNoChapterHint(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: provider.chapters.length,
                        itemBuilder: (context, i) {
                          final ch = provider.chapters[i];
                          return _ChapterItem(
                            chapter: ch,
                            onEdit: () => _showChapterForm(
                              context,
                              _selectedNovelId!,
                              ch,
                            ),
                            onDelete: () =>
                                _confirmDeleteChapter(context, ch, provider),
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

  Widget _buildNoNovelHint(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bạn chưa đăng truyện nào. Hãy sang tab "Truyện đã đăng" để tạo truyện trước.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.list_alt_rounded,
            size: 52,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 14),
          Text(
            'Chọn truyện để xem và thêm chương',
            style: GoogleFonts.nunito(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChapterHint(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 52,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có chương nào',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút bên dưới để thêm chương đầu tiên.',
            style: GoogleFonts.nunito(
              color: AppTheme.textHint,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteChapter(
    BuildContext context,
    ChapterModel chapter,
    NovelProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xoá chương',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn có chắc muốn xoá "${chapter.title}" không?',
          style: GoogleFonts.nunito(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Huỷ',
              style: GoogleFonts.nunito(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Xoá', style: GoogleFonts.nunito()),
          ),
        ],
      ),
    );
    if (confirm == true) await provider.deleteChapter(chapter.id!);
  }

  void _showChapterForm(
    BuildContext context,
    int novelId,
    ChapterModel? chapter,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MyChapterFormScreen(novelId: novelId, chapter: chapter),
      ),
    );
  }
}

// ==================== CHAPTER ITEM ====================

class _ChapterItem extends StatelessWidget {
  final ChapterModel chapter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChapterItem({
    required this.chapter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${chapter.chapterNumber}',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${chapter.content.length} ký tự',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
            onPressed: onEdit,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppTheme.error,
            ),
            onPressed: onDelete,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ==================== NOVEL FORM (user version) ====================

class MyNovelFormScreen extends StatefulWidget {
  final NovelModel? novel;
  final int createdBy;

  const MyNovelFormScreen({
    super.key,
    this.novel,
    required this.createdBy,
  });

  @override
  State<MyNovelFormScreen> createState() => _MyNovelFormScreenState();
}

class _MyNovelFormScreenState extends State<MyNovelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _coverCtrl;
  List<String> _selectedGenres = [];
  String _status = 'ongoing';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final n = widget.novel;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _authorCtrl = TextEditingController(text: n?.author ?? '');
    _descCtrl = TextEditingController(text: n?.description ?? '');
    _coverCtrl = TextEditingController(
      text: n?.coverUrl ??
          'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/300/450',
    );
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

    setState(() => _isSaving = true);
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
        createdBy: widget.createdBy,
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

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.novel == null ? 'Đã đăng truyện thành công!' : 'Đã cập nhật!',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.novel != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Chỉnh sửa truyện' : 'Đăng truyện mới',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Đăng'),
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
              // Cover preview
              if (_coverCtrl.text.isNotEmpty) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _coverCtrl.text,
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildField('Tên truyện *', _titleCtrl, 'VD: Kiếm Lai, Overlord...'),
              const SizedBox(height: 16),
              _buildField('Tác giả *', _authorCtrl, 'Tên tác giả hoặc bút danh'),
              const SizedBox(height: 16),
              _buildField(
                'URL ảnh bìa',
                _coverCtrl,
                'https://...',
                required: false,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildField(
                'Mô tả truyện *',
                _descCtrl,
                'Giới thiệu ngắn gọn về nội dung truyện...',
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Status
              Text(
                'Trạng thái',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
              Text(
                'Thể loại *',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Chọn ít nhất 1 thể loại',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kAllGenres.map((g) {
                  final selected = _selectedGenres.contains(g);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedGenres.remove(g);
                      } else {
                        _selectedGenres.add(g);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.getGenreColor(g).withOpacity(0.15)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.getGenreColor(g)
                              : AppTheme.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        g,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.getGenreColor(g)
                              : AppTheme.textSecondary,
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

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    bool required = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
          onChanged: onChanged,
          validator: required
              ? (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng điền trường này' : null
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppTheme.divider,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CHAPTER FORM (user version) ====================

class MyChapterFormScreen extends StatefulWidget {
  final int novelId;
  final ChapterModel? chapter;

  const MyChapterFormScreen({
    super.key,
    required this.novelId,
    this.chapter,
  });

  @override
  State<MyChapterFormScreen> createState() => _MyChapterFormScreenState();
}

class _MyChapterFormScreenState extends State<MyChapterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _numberCtrl;
  bool _isSaving = false;

  int get _contentLength => _contentCtrl.text.length;

  @override
  void initState() {
    super.initState();
    final ch = widget.chapter;
    _titleCtrl = TextEditingController(text: ch?.title ?? '');
    _contentCtrl = TextEditingController(text: ch?.content ?? '');
    _numberCtrl = TextEditingController(
      text: ch?.chapterNumber.toString() ?? '',
    );
    _contentCtrl.addListener(() => setState(() {}));
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

    setState(() => _isSaving = true);
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

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.chapter == null ? 'Đã thêm chương!' : 'Đã cập nhật chương!',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.chapter != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Chỉnh sửa chương' : 'Thêm chương mới',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Đăng chương'),
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
              // Chapter number
              Text(
                'Số chương',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'VD: 1'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập số chương';
                  if (int.tryParse(v) == null) return 'Phải là số nguyên';
                  if (int.parse(v) <= 0) return 'Số chương phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Tiêu đề chương *',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'VD: Chương 1: Khởi Đầu Mới',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),

              // Content
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nội dung *',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$_contentLength ký tự',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: _contentLength > 0
                          ? AppTheme.primary
                          : AppTheme.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentCtrl,
                maxLines: 20,
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung chương tại đây...',
                  alignLabelWithHint: true,
                ),
                style: GoogleFonts.merriweather(
                  fontSize: 14,
                  height: 1.8,
                  color: AppTheme.textPrimary,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập nội dung' : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}