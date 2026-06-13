// lib/screens/reader/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../models/chapter_model.dart';
import '../../utils/app_theme.dart';

// ============================================================
// PARSER — tách nội dung thành danh sách block text/image
// ============================================================

abstract class _ContentBlock {}

class _TextBlock extends _ContentBlock {
  final String text;
  _TextBlock(this.text);
}

class _ImageBlock extends _ContentBlock {
  final String url;
  _ImageBlock(this.url);
}

/// Phân tích nội dung có chứa [img]url[/img]
/// thành danh sách các block Text và Image xen kẽ nhau.
List<_ContentBlock> _parseContent(String raw) {
  final blocks = <_ContentBlock>[];
  final pattern = RegExp(r'\[img\](.*?)\[/img\]', dotAll: true);
  int lastEnd = 0;

  for (final match in pattern.allMatches(raw)) {
    // Đoạn text trước ảnh
    if (match.start > lastEnd) {
      final text = raw.substring(lastEnd, match.start).trim();
      if (text.isNotEmpty) blocks.add(_TextBlock(text));
    }
    // Block ảnh
    final url = match.group(1)?.trim() ?? '';
    if (url.isNotEmpty) blocks.add(_ImageBlock(url));
    lastEnd = match.end;
  }

  // Đoạn text còn lại sau ảnh cuối
  if (lastEnd < raw.length) {
    final text = raw.substring(lastEnd).trim();
    if (text.isNotEmpty) blocks.add(_TextBlock(text));
  }

  // Nếu không có tag ảnh nào → trả về nguyên 1 block text
  if (blocks.isEmpty) blocks.add(_TextBlock(raw));

  return blocks;
}

// ============================================================
// WIDGET HIỂN THỊ ẢNH với loading + error state
// ============================================================

class _NovelImage extends StatelessWidget {
  final String url;

  const _NovelImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF313244),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFFCBA6F7),
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF313244),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_rounded,
                      color: Colors.white38, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Không tải được ảnh',
                    style: GoogleFonts.nunito(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// READER SCREEN
// ============================================================

class ReaderScreen extends StatefulWidget {
  final int novelId;
  final int chapterId;

  const ReaderScreen(
      {super.key, required this.novelId, required this.chapterId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showControls = true;
  double _fontSize = 16;
  final ScrollController _scrollCtrl = ScrollController();

  static const Color _readerBg = Color(0xFF1E1E2E);
  static const Color _readerText = Color(0xFFCDD6F4);
  static const Color _readerTitle = Color(0xFFCBA6F7);
  static const Color _navBg = Color(0xFF181825);
  static const Color _navAccent = Color(0xFFCBA6F7);

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<NovelProvider>();
      await prov.loadChapterDetails(widget.chapterId);

      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn && prov.currentChapter != null) {
        await context.read<BookmarkProvider>().updateReadingProgress(
              userId: auth.currentUser!.id!,
              novelId: widget.novelId,
              chapterId: prov.currentChapter!.id!,
              chapterNumber: prov.currentChapter!.chapterNumber,
            );
      }
    });
  }

  Future<void> _goToChapter(int chapterId) async {
    _scrollCtrl.jumpTo(0);
    final prov = context.read<NovelProvider>();
    await prov.loadChapterDetails(chapterId);

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && prov.currentChapter != null) {
      await context.read<BookmarkProvider>().updateReadingProgress(
            userId: auth.currentUser!.id!,
            novelId: widget.novelId,
            chapterId: prov.currentChapter!.id!,
            chapterNumber: prov.currentChapter!.chapterNumber,
          );
    }
  }

  void _showChapterList(List<ChapterModel> chapters, int currentId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _navBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('Danh sách chương',
              style: GoogleFonts.playfairDisplay(
                  color: _navAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (ctx, i) {
                final ch = chapters[i];
                final isCurrent = ch.id == currentId;
                return ListTile(
                  selected: isCurrent,
                  selectedTileColor: _navAccent.withOpacity(0.1),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        isCurrent ? _navAccent : Colors.white12,
                    child: Text('${ch.chapterNumber}',
                        style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? _navBg : _readerText)),
                  ),
                  title: Text(ch.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          color: isCurrent ? _navAccent : _readerText,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (!isCurrent) _goToChapter(ch.id!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _navBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Cỡ chữ',
                  style: GoogleFonts.nunito(
                      color: _readerText, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _fontSize = (_fontSize - 1).clamp(12, 24);
                      setModal(() {});
                    }),
                    icon: const Icon(Icons.text_decrease_rounded,
                        color: _navAccent),
                  ),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12,
                      max: 24,
                      divisions: 12,
                      activeColor: _navAccent,
                      inactiveColor: Colors.white12,
                      onChanged: (v) => setState(() {
                        _fontSize = v;
                        setModal(() {});
                      }),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _fontSize = (_fontSize + 1).clamp(12, 24);
                      setModal(() {});
                    }),
                    icon: const Icon(Icons.text_increase_rounded,
                        color: _navAccent),
                  ),
                  Text('${_fontSize.round()}pt',
                      style: GoogleFonts.nunito(
                          color: _readerText, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Build danh sách widget từ các block đã parse
  List<Widget> _buildContentWidgets(String rawContent) {
    final blocks = _parseContent(rawContent);
    return blocks.map((block) {
      if (block is _ImageBlock) {
        return _NovelImage(url: block.url);
      } else if (block is _TextBlock) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            block.text,
            style: GoogleFonts.merriweather(
              fontSize: _fontSize,
              height: 1.9,
              color: _readerText,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NovelProvider>(
      builder: (context, provider, _) {
        final chapter = provider.currentChapter;
        final novel = provider.currentNovel;
        final chaps = provider.currentChapters;

        final currentIndex = chapter != null
            ? chaps.indexWhere((c) => c.id == chapter.id)
            : -1;
        final hasPrev = currentIndex > 0;
        final hasNext =
            currentIndex >= 0 && currentIndex < chaps.length - 1;

        return Scaffold(
          backgroundColor: _readerBg,
          appBar: _showControls
              ? AppBar(
                  backgroundColor: _navBg,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: _readerText, size: 18),
                      ),
                    ),
                  ),
                  title: chapter == null
                      ? null
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              novel?.title ?? '',
                              style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _readerText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Chương ${chapter.chapterNumber}/${chaps.length}',
                              style: GoogleFonts.nunito(
                                  fontSize: 11, color: Colors.white38),
                            ),
                          ],
                        ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded,
                          size: 20, color: _readerText),
                      tooltip: 'Cỡ chữ',
                      onPressed: _showSettingsPanel,
                    ),
                  ],
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: Colors.white10),
                  ),
                )
              : null,

          bottomNavigationBar: chapter == null
              ? null
              : _showControls
                  ? Container(
                      decoration: const BoxDecoration(
                        color: _navBg,
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          height: 64,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _NavButton(
                                icon: Icons.arrow_back_ios_rounded,
                                label: 'Trước',
                                enabled: hasPrev,
                                accentColor: _navAccent,
                                onTap: hasPrev
                                    ? () => _goToChapter(
                                        chaps[currentIndex - 1].id!)
                                    : null,
                              ),
                              _NavButton(
                                icon: Icons.format_list_bulleted_rounded,
                                label: 'Chương',
                                enabled: true,
                                accentColor: _navAccent,
                                onTap: () =>
                                    _showChapterList(chaps, chapter.id!),
                              ),
                              _NavButton(
                                icon: Icons.arrow_forward_ios_rounded,
                                label: 'Sau',
                                enabled: hasNext,
                                accentColor: _navAccent,
                                onTap: hasNext
                                    ? () => _goToChapter(
                                        chaps[currentIndex + 1].id!)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,

          body: provider.isLoading || chapter == null
              ? const Center(
                  child:
                      CircularProgressIndicator(color: _navAccent))
              : GestureDetector(
                  onTap: () =>
                      setState(() => _showControls = !_showControls),
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding:
                        const EdgeInsets.fromLTRB(20, 32, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề chương
                        Text(
                          'Chương ${chapter.chapterNumber}: ${chapter.title}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            color: _readerTitle,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── NỘI DUNG: render text xen ảnh ──────────
                        ..._buildContentWidgets(chapter.content),

                        const SizedBox(height: 40),
                        // Nút chuyển chương cuối trang
                        Row(
                          children: [
                            Expanded(
                              child: hasPrev
                                  ? OutlinedButton.icon(
                                      onPressed: () => _goToChapter(
                                          chaps[currentIndex - 1].id!),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _navAccent,
                                        side: BorderSide(
                                            color: _navAccent
                                                .withOpacity(0.5)),
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                      ),
                                      icon: const Icon(
                                          Icons.arrow_back_ios_rounded,
                                          size: 14),
                                      label: Text('Chương trước',
                                          style: GoogleFonts.nunito(
                                              fontSize: 13)),
                                    )
                                  : const SizedBox(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: hasNext
                                  ? ElevatedButton.icon(
                                      onPressed: () => _goToChapter(
                                          chaps[currentIndex + 1].id!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _navAccent,
                                        foregroundColor: _navBg,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                      ),
                                      icon: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14),
                                      label: Text('Chương sau',
                                          style: GoogleFonts.nunito(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    )
                                  : Center(
                                      child: Text('Hết chương 🎉',
                                          style: GoogleFonts.nunito(
                                              color: _navAccent,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color accentColor;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? accentColor : Colors.white24;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.nunito(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}