// lib/screens/home/profile_tab.dart

import 'package:bookreader/screens/home/my_novels_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import '../admin/admin_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.surfaceVariant,
                  child: const Icon(Icons.person_outline_rounded, size: 44, color: AppTheme.textHint),
                ),
                const SizedBox(height: 20),
                Text(
                  'Chưa đăng nhập',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để xem tủ sách cá nhân và quản lý nội dung đăng truyện',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 160,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = auth.currentUser!;
    final List<_MenuItem> items = [
      _MenuItem(
        icon: Icons.auto_stories_rounded,
        label: 'Truyện của tôi',
        color: AppTheme.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MyNovelsScreen(userId: user.id!)),
        ),
      ),
      if (auth.isAdmin)
        _MenuItem(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Quản trị hệ thống',
          color: AppTheme.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          ),
        ),
      _MenuItem(
        icon: Icons.logout_rounded,
        label: 'Đăng xuất',
        color: Colors.redAccent,
        onTap: () {
          context.read<AuthProvider>().logout();
          context.read<BookmarkProvider>().clear();
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài Khoản',
                style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: auth.isAdmin ? AppTheme.accent.withOpacity(0.15) : AppTheme.primary.withOpacity(0.15),
                    child: Icon(
                      auth.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                      size: 32,
                      color: auth.isAdmin ? AppTheme.accent : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.nunito(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: items.map((item) {
                    final isLast = items.last == item;
                    return Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon, color: item.color, size: 20),
                          ),
                          title: Text(item.label, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
                          onTap: item.onTap,
                        ),
                        if (!isLast) const Divider(height: 1, indent: 60),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, required this.color, required this.onTap});
}