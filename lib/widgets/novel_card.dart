// lib/widgets/novel_card.dart
import 'package:flutter/material.dart';
import '../../models/novel_model.dart';
import '../../utils/app_theme.dart';

class NovelCard extends StatelessWidget {
  final NovelModel novel;
  final VoidCallback? onTap;

  const NovelCard({
    super.key,
    required this.novel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Phần ảnh bìa và Tag trạng thái (Chiếm phần lớn không gian phía trên)
            Expanded(
              flex: 3, // Định hình tỷ lệ cho ảnh bìa cố định, tránh bóp nghẹt phần chữ
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: novel.coverUrl.isNotEmpty
                        ? Image.network(
                            novel.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.book_rounded, size: 40, color: Colors.grey),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.book_rounded, size: 40, color: Colors.grey),
                          ),
                  ),
                  // Tag trạng thái (ongoing / completed)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: novel.status.toLowerCase() == 'completed'
                            ? Colors.green
                            : Colors.teal[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        novel.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Phần thông tin chữ bên dưới (Được bọc cẩn thận chống tràn)
            Expanded(
              flex: 2, // Đảm bảo phần chữ luôn có đủ không gian cố định hiển thị
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy các phần tử giãn đều nhau theo chiều dọc
                  children: [
                    // Tên Truyện
                    Text(
                      novel.title,
                      maxLines: 2, // Cho phép xuống tối đa 2 dòng
                      overflow: TextOverflow.ellipsis, // Quá dài sẽ tự cắt bằng dấu "..."
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    
                    // Khoảng trống co giãn nhẹ giữa các dòng thông tin
                    const SizedBox(height: 2),

                    // Tên Tác Giả
                    Text(
                      novel.author,
                      maxLines: 1, // Tác giả bắt buộc nằm trên 1 dòng
                      overflow: TextOverflow.ellipsis, // Quá dài tự thêm "..."
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                    const Spacer(), // Tự động đẩy phần Rating xuống sát đáy của khung chữ

                    // Điểm Đánh Giá (Rating)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          novel.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}