import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_theme.dart';
import '../models/activity_model.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with TickerProviderStateMixin {
  final _minutesCtrl = TextEditingController();
  String _selectedActivityKey = 'jogging';
  bool _isSaving = false;
  List<ActivityLog> _todayLogs = [];
  bool _isLoadingLogs = true;

  late AnimationController _headerAnim;
  late AnimationController _bodyAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _bodyFade;

  static const Map<String, Map<String, dynamic>> _activityCatalog = {
    'jogging': {
      'label': 'Jogging / Lari Santai',
      'met': 7.0,
      'emoji': '🏃',
      'color': Color(0xFF2ECC71),
      'bg': Color(0xFFE8F8F0),
    },
    'brisk_walking': {
      'label': 'Jalan Cepat',
      'met': 4.5,
      'emoji': '🚶',
      'color': Color(0xFF3498DB),
      'bg': Color(0xFFEBF5FB),
    },
    'soccer': {
      'label': 'Sepak Bola (Rekreasi)',
      'met': 7.5,
      'emoji': '⚽',
      'color': Color(0xFFE74C3C),
      'bg': Color(0xFFFDEDEC),
    },
    'push_up': {
      'label': 'Push up / Calisthenics',
      'met': 6.0,
      'emoji': '💪',
      'color': Color(0xFF9B59B6),
      'bg': Color(0xFFF5EEF8),
    },
    'squat': {
      'label': 'Squat / Latihan Beban',
      'met': 5.0,
      'emoji': '🏋️',
      'color': Color(0xFFF39C12),
      'bg': Color(0xFFFEF5E7),
    },
  };

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));

    _bodyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bodyFade = CurvedAnimation(parent: _bodyAnim, curve: Curves.easeOut);

    _headerAnim.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _bodyAnim.forward();
    });

    _loadTodayLogs();
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _headerAnim.dispose();
    _bodyAnim.dispose();
    super.dispose();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTodayLogs() async {
    setState(() => _isLoadingLogs = true);
    final dbProvider = context.read<DatabaseProvider>();
    final logs = await dbProvider.getActivityLogsForDate(_todayKey());
    if (mounted) {
      setState(() {
        _todayLogs = logs;
        _isLoadingLogs = false;
      });
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final dbProvider = context.read<DatabaseProvider>();

    final minutesRaw = _minutesCtrl.text.trim();
    final minutes = double.tryParse(minutesRaw);
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Masukkan durasi menit yang valid.', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final catalog = _activityCatalog[_selectedActivityKey]!;
    final met = (catalog['met'] as num).toDouble();
    final calories = met * 3.5 * auth.weightKg / 200 * minutes;

    setState(() => _isSaving = true);
    try {
      final dateKey = _todayKey();

      await dbProvider.addActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: dateKey,
        activityType: _selectedActivityKey,
        minutes: minutes,
        met: met,
        caloriesBurned: calories,
        loggedAt: DateTime.now(),
      );

      await dbProvider.reload();
      await _loadTodayLogs();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(catalog['emoji'] as String, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Aktivitas tersimpan! (+${calories.toInt()} kcal)', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      _minutesCtrl.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan aktivitas: $e', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteLog(ActivityLog log) async {
    final dbProvider = context.read<DatabaseProvider>();
    final catalog = _activityCatalog[log.activityType] ?? {
      'emoji': '🏃',
      'label': 'Olahraga',
    };

    try {
      await dbProvider.removeActivityLog(log.id, log.caloriesBurned);
      await dbProvider.reload();
      await _loadTodayLogs();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktivitas ${catalog['label']} dihapus!', style: GoogleFonts.dmSans()),
          backgroundColor: Colors.grey[850],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus aktivitas: $e', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final db = context.watch<DatabaseProvider>();

    final catalog = _activityCatalog[_selectedActivityKey]!;
    final met = (catalog['met'] as num).toDouble();

    double previewCalories = 0;
    final minutes = double.tryParse(_minutesCtrl.text.trim());
    if (minutes != null && minutes > 0) {
      previewCalories = met * 3.5 * auth.weightKg / 200 * minutes;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(db),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _bodyFade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputCard(met, previewCalories),
                    const SizedBox(height: 24),
                    _buildTodayLogsSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(DatabaseProvider db) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2980B9),
      elevation: 0,
      leadingWidth: 52,
      leading: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 4),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A6EA0), Color(0xFF2980B9), Color(0xFF3498DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(56, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const Text('🏃', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  'Pembakaran Kalori',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Aktivitas & Olahraga',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 24,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              '${db.caloriesBurned.toInt()} kcal',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(double met, double previewCalories) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Catat Aktivitas Baru',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Activity Type drop-down
          DropdownButtonFormField<String>(
            initialValue: _selectedActivityKey,
            style: GoogleFonts.dmSans(color: const Color(0xFF1A1A1A), fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Pilih Olahraga / Kegiatan',
              labelStyle: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[500]),
              filled: true,
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.blue, width: 1.5),
              ),
            ),
            items: _activityCatalog.entries.map((e) {
              final data = e.value;
              return DropdownMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: data['bg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(data['emoji'] as String, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      data['label'] as String,
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedActivityKey = v);
            },
          ),
          const SizedBox(height: 16),
          // Minutes input
          TextFormField(
            controller: _minutesCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.dmSans(fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Durasi Latihan (menit)',
              labelStyle: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[500]),
              hintText: 'Masukkan angka, misal: 30',
              hintStyle: GoogleFonts.dmSans(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: AppTheme.surface,
              prefixIcon: const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.blue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Preview container
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: previewCalories > 0
                  ? AppTheme.blueSurface
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: previewCalories > 0
                    ? AppTheme.blue.withValues(alpha: 0.2)
                    : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: previewCalories > 0
                        ? AppTheme.blue.withValues(alpha: 0.12)
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 20,
                    color: previewCalories > 0 ? AppTheme.blue : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewCalories > 0
                            ? 'Estimasi Kalori Terbakar'
                            : 'Kalkulator Kalori',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: previewCalories > 0 ? AppTheme.blue : Colors.grey[600],
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewCalories > 0
                            ? '+${previewCalories.toInt()} kcal'
                            : 'Masukkan menit di atas',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: previewCalories > 0 ? const Color(0xFF1A1A1A) : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    'MET ${met.toStringAsFixed(1)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[750],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Aktivitas',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'RIWAYAT LATIHAN HARI INI',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _isLoadingLogs
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.blue, strokeWidth: 3),
                ),
              )
            : _todayLogs.isEmpty
                ? _buildEmptyLogsState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _todayLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildActivityLogCard(_todayLogs[i]),
                  ),
      ],
    );
  }

  Widget _buildActivityLogCard(ActivityLog log) {
    final catalog = _activityCatalog[log.activityType] ?? {
      'label': log.activityType,
      'emoji': '🏃',
      'color': AppTheme.blue,
      'bg': AppTheme.blueSurface,
    };
    final bg = catalog['bg'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(catalog['emoji'] as String, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catalog['label'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.minutes.toInt()} menit · MET ${log.met.toStringAsFixed(1)}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${log.caloriesBurned.toInt()} kcal',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.red,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _confirmDelete(log),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ActivityLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Aktivitas?', style: GoogleFonts.dmSerifDisplay(fontSize: 18)),
        content: Text(
          'Aktivitas ini akan dihapus dari catatan pembakaran kalori hari ini.',
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.dmSans(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteLog(log);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hapus', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLogsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🍃', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            'Belum ada aktivitas hari ini',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ayo catat latihanmu agar target kalori bertambah!',
            style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
