// lib/screens/reader/novel_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart'; // 💡 ĐÃ SỬA: Chuyển sang import tương đối tránh lỗi sai tên Package
import '../../providers/novel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../utils/app_theme.dart';
import 'reader_screen.dart';

class NovelDetailScreen extends StatefulWidget {
  final int novelId;
  const NovelDetailScreen({super.key, required this.novelId});

  @override
  State<NovelDetailScreen> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends State<NovelDetailScreen> {
  bool _descExpanded = false;
  double? _userRating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<NovelProvider>().selectNovel(widget.novelId);
      if (mounted) {
        setState(() => _userRating = null); // Đồng bộ loại bỏ hàm kiểm tra rating sqlite cũ
      }
    });
  }

  Future<void> _submitRating(double value) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá!')),
      );
      return;
    }

    setState(() => _userRating = value);

    try {
      final db = DatabaseService();
      // Gọi API thực thi Stored Procedure tính điểm trên SQL Server
      await db.upsertRating(auth.currentUser!.id!, widget.novelId, value);

      if (mounted) {
        await context.read<NovelProvider>().selectNovel(widget.novelId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá truyện thành công!'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userRating = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: Text(
          'Chi tiết truyện',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Consumer3<NovelProvider, AuthProvider, BookmarkProvider>(
        builder: (context, novelProv, authProv, bookmarkProv, child) {
          final novel = novelProv.currentNovel;
          final chapters = novelProv.currentChapters;

          if (novel == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
            );
          }

          final isBookmarked = bookmarkProv.isBookmarked(novel.id!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 110,
                        height: 160,
                        color: Colors.grey[300],
                        child: novel.coverUrl.isNotEmpty
                            ? Image.network(novel.coverUrl, fit: BoxFit.cover)
                            : const Icon(Icons.book, size: 40, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            novel.title,
                            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tác giả: ${novel.author}',
                            style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: novel.status == 'ongoing' ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              novel.status == 'ongoing' ? 'Đang ra' : 'Hoàn thành',
                              style: GoogleFonts.nunito(fontSize: 12, color: novel.status == 'ongoing' ? const Color(0xFF2E7D32) : const Color(0xFF1565C0), fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: chapters.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReaderScreen(novelId: novel.id!, chapterId: chapters.first.id!),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Đọc từ đầu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D6A4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () async {
                        if (!authProv.isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập!')));
                          return;
                        }
                        await bookmarkProv.toggleBookmark(authProv.currentUser!.id!, novel.id!);
                      },
                      icon: Icon(
                        isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                        color: isBookmarked ? const Color(0xFF2D6A4F) : AppTheme.textSecondary,
                      ),
                      iconSize: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatsRow(novel.viewCount, novel.rating, novel.ratingCount, _userRating, _submitRating),
                const SizedBox(height: 24),
                if (novel.genres.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: novel.genres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E0D8)),
                        ),
                        child: Text(genre, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                Text('Giới thiệu', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _descExpanded = !_descExpanded),
                  child: Text(
                    novel.description,
                    style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                    maxLines: _descExpanded ? null : 4,
                    overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Danh sách chương', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    Text('${chapters.length} chương', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                if (chapters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('Truyện chưa có chương nào.', style: GoogleFonts.nunito(color: AppTheme.textHint))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: chapters.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E0D8)),
                    itemBuilder: (context, index) {
                      final chap = chapters[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Chương ${chap.chapterNumber}: ${chap.title}',
                          style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReaderScreen(novelId: novel.id!, chapterId: chap.id!)),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(int views, double rating, int ratingCount, double? userRating, Function(double) onRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E0D8))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lượt xem', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textHint, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(views.toString(), style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ],
              ),
              Container(width: 1, height: 30, color: const Color(0xFFE5E0D8)),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.starColor, size: 24),
                  const SizedBox(width: 4),
                  Text(rating.toStringAsFixed(1), style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(width: 6),
                  Text('($ratingCount lượt)', style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E0D8)),
          const SizedBox(height: 12),
          Text(userRating == null ? 'Đánh giá của bạn:' : 'Bạn đã đánh giá:', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final starValue = (i + 1).toDouble();
              final filled = userRating != null && starValue <= userRating;
              return GestureDetector(
                onTap: () => onRate(starValue),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded, color: filled ? AppTheme.starColor : AppTheme.textHint, size: 36),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}