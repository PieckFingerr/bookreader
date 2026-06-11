// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/novel_provider.dart';
import '../../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NovelProvider>().loadNovels();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Quản trị hệ thống', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: Consumer<NovelProvider>(
        builder: (context, provider, _) {
          return Center(
            child: Text(
              'Trang quản trị vận hành trên SQL Server\nTổng số truyện: ${provider.allNovels.length}',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15, color: AppTheme.textSecondary),
            ),
          );
        },
      ),
    );
  }
}