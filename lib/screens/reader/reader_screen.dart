// lib/screens/reader/reader_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String? _selectedVoice;
  List<Map<String, String>> _viVoices = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NovelProvider>().loadChapter(widget.chapterId);
      _saveProgress();
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });

    // Load danh sách giọng tiếng Việt
    final voices = await _tts.getVoices;
    final viVoices = (voices as List)
        .where((v) => (v['locale'] as String? ?? '').startsWith('vi'))
        .map((v) => {'name': v['name'] as String, 'locale': v['locale'] as String})
        .toList();
    if (mounted) {
      setState(() {
        _viVoices = viVoices;
        if (viVoices.isNotEmpty) _selectedVoice = viVoices.first['name'];
      });
    }
  }

  Future<void> _toggleTts(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      if (_selectedVoice != null) {
        await _tts.setVoice({'name': _selectedVoice!, 'locale': 'vi-VN'});
      }
      await _tts.speak(text);
      setState(() => _isSpeaking = true);
    }
  }

  @override
  void dispose() {
    _tts.stop();
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
    await _tts.stop();
    setState(() => _isSpeaking = false);
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
                  CustomScrollView(
                    controller: _scrollCtrl,
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
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
                              const Spacer(),
                              const SizedBox(height: 16),
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
                      ),
                    ],
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
                        // Nút TTS
                        IconButton(
                          icon: Icon(
                            _isSpeaking
                                ? Icons.stop_circle_rounded
                                : Icons.record_voice_over_rounded,
                          ),
                          color: _isSpeaking ? AppTheme.error : AppTheme.textPrimary,
                          onPressed: chapter != null
                              ? () => _toggleTts(chapter.content)
                              : null,
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

                // Settings panel (cỡ chữ + chọn giọng)
                if (_settingsOpen)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 60,
                    right: 12,
                    child: Container(
                      width: 240,
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
                          // Cỡ chữ
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

                          // Chọn giọng đọc
                          if (_viVoices.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'Giọng đọc',
                              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: _selectedVoice,
                              isExpanded: true,
                              underline: Container(height: 1, color: AppTheme.divider),
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.textPrimary,
                              ),
                              items: _viVoices
                                  .map((v) => DropdownMenuItem(
                                        value: v['name'],
                                        child: Text(
                                          v['name']!,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (name) async {
                                setState(() => _selectedVoice = name);
                                await _tts.setVoice({
                                  'name': name!,
                                  'locale': 'vi-VN',
                                });
                              },
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy giọng tiếng Việt trên thiết bị',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
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