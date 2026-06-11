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

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  String? _selectedVoice;
  List<Map<String, String>> _viVoices = [];
  double _speechRate = 0.5;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _initTts();
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

  Future<void> _initTts() async {
    try {
      final voices = await _tts.getVoices;
      if (voices != null) {
        final List<Map<String, String>> vi = [];
        for (var v in voices) {
          if (v['locale']?.toString().contains('vi') ?? false) {
            vi.add({'name': v['name'] ?? '', 'locale': v['locale'] ?? ''});
          }
        }
        setState(() {
          _viVoices = vi;
          if (vi.isNotEmpty) _selectedVoice = vi.first['name'];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Consumer<NovelProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || provider.currentChapter == null) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final chapter = provider.currentChapter!;
          // 💡 ĐÃ SỬA: Khớp đúng tên biến currentNovel và currentChapters của NovelProvider mới
          final novel = provider.currentNovel; 
          final chaps = provider.currentChapters;

          return Stack(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chương ${chapter.chapterNumber}: ${chapter.title}',
                        style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        chapter.content,
                        style: GoogleFonts.merriweather(fontSize: _fontSize, height: 1.8, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showControls) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AppBar(
                    backgroundColor: Colors.white.withOpacity(0.95),
                    elevation: 0,
                    foregroundColor: AppTheme.textPrimary,
                    title: Text(novel?.title ?? '', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}