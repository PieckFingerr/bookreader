// lib/screens/my_novels/add_novel_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/novel_model.dart';
import '../../providers/novel_provider.dart';
import '../../utils/app_theme.dart';

class AddNovelScreen extends StatefulWidget {
  final int userId;
  final NovelModel? novel; // Nếu truyền tham số novel -> Tự động chuyển sang chế độ SỬA TRUYỆN

  const AddNovelScreen({super.key, required this.userId, this.novel});

  @override
  State<AddNovelScreen> createState() => _AddNovelScreenState();
}

class _AddNovelScreenState extends State<AddNovelScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _coverCtrl;
  
  late String _selectedStatus;
  final List<String> _genres = [];
  final List<String> _availableGenres = ['Tập Kích', 'Tiên Hiệp', 'Huyền Huyễn', 'Đô Thị', 'Khoa Huyễn', 'Kiếm Hiệp'];

  bool get isEditMode => widget.novel != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: isEditMode ? widget.novel!.title : '');
    _descCtrl = TextEditingController(text: isEditMode ? widget.novel!.description : '');
    _coverCtrl = TextEditingController(text: isEditMode ? widget.novel!.coverUrl : '');
    _selectedStatus = isEditMode ? widget.novel!.status.toLowerCase() : 'ongoing';
    if (isEditMode) {
      _genres.addAll(widget.novel!.genres);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final novelData = NovelModel(
      id: isEditMode ? widget.novel!.id : null,
      title: _titleCtrl.text.trim(),
      author: isEditMode ? widget.novel!.author : 'Hệ thống tự điền', 
      description: _descCtrl.text.trim(),
      coverUrl: _coverCtrl.text.trim(),
      genres: _genres.isEmpty ? ['Truyện Chữ'] : _genres,
      status: _selectedStatus,
      createdAt: isEditMode ? widget.novel!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: widget.userId,
    );

    try {
      if (isEditMode) {
        await context.read<NovelProvider>().editNovel(novelData);
      } else {
        await context.read<NovelProvider>().addNovel(novelData, widget.userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? '🎉 Cập nhật truyện thành công!' : '🎉 Đăng truyện mới thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Thất bại: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<NovelProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Chỉnh Sửa Truyện' : 'Đăng Truyện Mới',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Tên truyện *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Không được bỏ trống tên truyện' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _coverCtrl,
                      decoration: const InputDecoration(labelText: 'Link ảnh bìa (URL)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Mô tả tóm tắt nội dung', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Text('Trạng thái truyện:', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'ongoing', child: Text('Đang tiến hành (Ongoing)')),
                        DropdownMenuItem(value: 'completed', child: Text('Hoàn thành (Completed)')),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v ?? 'ongoing'),
                    ),
                    const SizedBox(height: 16),
                    Text('Chọn Thể loại truyện:', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: _availableGenres.map((g) {
                        final isSelected = _genres.contains(g);
                        return FilterChip(
                          label: Text(g),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selected ? _genres.add(g) : _genres.remove(g);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        onPressed: _submit,
                        child: Text(
                          isEditMode ? 'LƯU THAY ĐỔI' : 'ĐĂNG TRUYỆN',
                          style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}