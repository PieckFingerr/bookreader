// lib/screens/home/discover_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/novel_card.dart';
import '../reader/novel_detail_screen.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  @override
  void initState() {
    super.initState();
    // 🏆 SỬA LỖI CHÍ MẠNG: Bọc hàm load truyện trong addPostFrameCallback 
    // để đưa lệnh ra ngoài chu kỳ build, triệt tiêu hoàn toàn lỗi sập giao diện ở Ảnh 2.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NovelProvider>().loadNovels();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<NovelProvider>(
          builder: (context, provider, _) {
            // Nếu đang tải và danh sách truyện trống thì hiện vòng xoay loading
            if (provider.isLoading && provider.allNovels.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            // Trường hợp danh sách trống do bộ lọc hoặc lỗi nạp dữ liệu
            if (provider.allNovels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 48, color: AppTheme.textHint),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy truyện nào',
                      style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => provider.loadNovels(),
                      child: const Text('Tải lại'),
                    )
                  ],
                ),
              );
            }

            // 🏆 ĐÃ SỬA: Hiển thị danh sách truyện mượt mà chuẩn xác
            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                await provider.loadNovels();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.explore_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Khám Phá',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.52,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          // Sử dụng danh sách allNovels thô giống màn hình tìm kiếm để hiển thị tuyệt đối chính xác
                          final novel = provider.allNovels[i];
                          return NovelCard(
                            novel: novel,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NovelDetailScreen(novelId: novel.id!),
                              ),
                            ),
                          );
                        },
                        childCount: provider.allNovels.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}