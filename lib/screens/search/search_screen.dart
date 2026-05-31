// lib/screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/novel_card.dart';
import '../reader/novel_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedGenre = '';
  String _selectedStatus = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    context.read<NovelProvider>().searchNovels(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm truyện, tác giả...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            hintStyle: GoogleFonts.nunito(
              color: AppTheme.textHint,
              fontSize: 16,
            ),
          ),
          style: GoogleFonts.nunito(fontSize: 16, color: AppTheme.textPrimary),
          onChanged: _search,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchCtrl.clear();
                _search('');
              },
            ),
        ],
      ),
      body: Consumer<NovelProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(bottom: BorderSide(color: AppTheme.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Genre filter
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterChip(
                            label: 'Tất cả',
                            selected: _selectedGenre.isEmpty,
                            onTap: () {
                              setState(() => _selectedGenre = '');
                              provider.filterByGenre('');
                              _search(_searchCtrl.text);
                            },
                          ),
                          const SizedBox(width: 6),
                          ...kAllGenres.map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _FilterChip(
                                label: g,
                                selected: _selectedGenre == g,
                                onTap: () {
                                  setState(
                                    () => _selectedGenre = _selectedGenre == g
                                        ? ''
                                        : g,
                                  );
                                  provider.filterByGenre(_selectedGenre);
                                  _search(_searchCtrl.text);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Status filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatusChip(
                            label: 'Tất cả',
                            selected: _selectedStatus.isEmpty,
                            onTap: () {
                              setState(() => _selectedStatus = '');
                              provider.filterByStatus('');
                            },
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Đang ra',
                            selected: _selectedStatus == 'ongoing',
                            color: AppTheme.primary,
                            onTap: () {
                              setState(
                                () => _selectedStatus =
                                    _selectedStatus == 'ongoing'
                                    ? ''
                                    : 'ongoing',
                              );
                              provider.filterByStatus(_selectedStatus);
                            },
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Hoàn thành',
                            selected: _selectedStatus == 'completed',
                            color: AppTheme.success,
                            onTap: () {
                              setState(
                                () => _selectedStatus =
                                    _selectedStatus == 'completed'
                                    ? ''
                                    : 'completed',
                              );
                              provider.filterByStatus(_selectedStatus);
                            },
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Tạm dừng',
                            selected: _selectedStatus == 'hiatus',
                            color: AppTheme.warning,
                            onTap: () {
                              setState(
                                () => _selectedStatus =
                                    _selectedStatus == 'hiatus' ? '' : 'hiatus',
                              );
                              provider.filterByStatus(_selectedStatus);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Results
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : provider.novels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy kết quả',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thử tìm kiếm với từ khoá khác',
                              style: GoogleFonts.nunito(
                                color: AppTheme.textHint,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.46,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: provider.novels.length,
                        itemBuilder: (context, i) {
                          final novel = provider.novels[i];
                          return NovelCard(
                            novel: novel,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NovelDetailScreen(novelId: novel.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    this.color = AppTheme.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppTheme.divider),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
