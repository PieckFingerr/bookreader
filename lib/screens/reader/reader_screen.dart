// lib/screens/reader/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../utils/app_theme.dart';

class ReaderScreen extends StatefulWidget {
  final int novelId;
  final int chapterId;

  const ReaderScreen({super.key, required this.novelId, required this.chapterId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showControls = true;
  double _fontSize = 16;
  bool _settingsOpen = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NovelProvider>().loadChapter(widget.chapterId);
      _saveProgress();
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _saveProgress() {
    final auth = context.read<AuthProvider>();
    final novels = context.read<NovelProvider>();
    if (!auth.isLoggedIn || novels.currentChapter == null) return;
    context.read<BookmarkProvider>().updateReadingProgress(
      userId: auth.currentUser!.id!,
      novelId: widget.novelId,
      chapterId: novels.currentChapter!.id!,
      chapterNumber: novels.currentChapter!.chapterNumber,
    );
  }

  Future<void> _goToChapter(int chapterId) async {
    _scrollCtrl.jumpTo(0);
    await context.read<NovelProvider>().loadChapter(chapterId);
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NovelProvider>(
      builder: (context, novels, _) {
        final chapter = novels.currentChapter;
        final prev = novels.getPreviousChapter();
        final next = novels.getNextChapter();

        return Scaffold(
          backgroundColor: const Color(0xFFFAF6EF),
          body: GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: Stack(
              children: [
                // Content
                if (novels.isLoading)
                  const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                else if (chapter != null)
                  SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(height: 1, color: AppTheme.divider),
                        const SizedBox(height: 24),
                        Text(
                          chapter.content,
                          style: GoogleFonts.merriweather(
                            fontSize: _fontSize,
                            color: AppTheme.textPrimary,
                            height: 2.0,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Navigation at bottom
                        Row(
                          children: [
                            if (prev != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _goToChapter(prev.id!),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: const Text('Trước'),
                                ),
                              ),
                            if (prev != null && next != null)
                              const SizedBox(width: 12),
                            if (next != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _goToChapter(next.id!),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text('Tiếp theo'),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Top bar
                AnimatedSlide(
                  offset: _showControls ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 8,
                      right: 8,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            chapter?.title ?? '',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_fields_rounded),
                          onPressed: () => setState(() => _settingsOpen = !_settingsOpen),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom nav
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSlide(
                    offset: _showControls ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 8,
                        left: 20,
                        right: 20,
                        top: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            onPressed: prev == null ? null : () => _goToChapter(prev.id!),
                            color: AppTheme.primary,
                            disabledColor: AppTheme.textHint,
                          ),
                          Text(
                            chapter != null
                                ? 'Chương ${chapter.chapterNumber} / ${novels.chapters.length}'
                                : '',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed: next == null ? null : () => _goToChapter(next.id!),
                            color: AppTheme.primary,
                            disabledColor: AppTheme.textHint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Font settings panel
                if (_settingsOpen)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    right: 12,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cỡ chữ',
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded),
                                onPressed: _fontSize > 12
                                    ? () => setState(() => _fontSize -= 1)
                                    : null,
                                color: AppTheme.primary,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${_fontSize.toInt()}px',
                                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded),
                                onPressed: _fontSize < 24
                                    ? () => setState(() => _fontSize += 1)
                                    : null,
                                color: AppTheme.primary,
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
