import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<DatabaseProvider>(
      builder: (context, db, _) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(db),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(db.weeklyCalories.length == 1 ? '🔥 KONSUMSI KALORI HARI INI' : '🔥 KONSUMSI KALORI ${db.weeklyCalories.length} HARI'),
                          const SizedBox(height: 10),
                          _buildWeeklyChart(db, auth),
                          const SizedBox(height: 24),
                          _sectionLabel('🥗 PROPORSI MAKRONUTRISI HARI INI'),
                          const SizedBox(height: 10),
                          _buildMacroDonut(db),
                          const SizedBox(height: 24),
                          _sectionLabel('📊 RINGKASAN HARIAN & KESEHATAN'),
                          const SizedBox(height: 10),
                          _buildSummaryCards(db, auth),
                          const SizedBox(height: 24),
                          _sectionLabel('🍽️ DISTRIBUSI ASUPAN MAKAN'),
                          const SizedBox(height: 10),
                          _buildMealDistribution(db),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      );

  SliverAppBar _buildAppBar(DatabaseProvider db) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF8E44AD),
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
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C3483), Color(0xFF8E44AD), Color(0xFF9B59B6)],
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
                            const Text('📊', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Statistik Nutrisi',
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
                          'Analisis Pola Makan',
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
                        const Text('🔥', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          'Hari ini',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildWeeklyChart(DatabaseProvider db, AuthProvider auth) {
    final data = db.weeklyCalories;
    final labels = db.weekDayLabels;

    // Guard: show placeholder if data is not yet loaded
    if (data.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        height: 220,
        child: Center(
          child: Text(
            'Memuat data...',
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[400]),
          ),
        ),
      );
    }

    final todayIndex = data.length - 1;
    final maxRaw = data.reduce((a, b) => a > b ? a : b);
    // Ensure maxY is at least 500 so the chart doesn't look odd on day-one with no food logged
    final maxY = (maxRaw < 300 ? 2200 : maxRaw + 400).ceilToDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(color: AppTheme.border, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.dmSans(fontSize: 9, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        final isToday = i == todayIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                              color: isToday ? AppTheme.primary : Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(data.length, (i) {
                  final isToday = i == todayIndex;
                  final overTarget = data[i] > auth.targetCalories;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i],
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        color: overTarget
                            ? AppTheme.red.withValues(alpha: 0.85)
                            : (isToday ? AppTheme.primary : AppTheme.primaryLight.withValues(alpha: 0.5)),
                      ),
                    ],
                  );
                }),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: auth.targetCalories,
                      color: AppTheme.primary.withValues(alpha: 0.45),
                      strokeWidth: 1.2,
                      dashArray: [5, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                        labelResolver: (_) => 'Target',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDonut(DatabaseProvider db) {
    final carbs = db.totalCarbsToday * 4;
    final protein = db.totalProteinToday * 4;
    final fat = db.totalFatToday * 9;
    final total = carbs + protein + fat;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: total == 0
                ? Center(
                    child: Text(
                      'Belum ada\ndata makan',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey[400]),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: carbs,
                          color: AppTheme.primaryLight,
                          radius: 20,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: protein,
                          color: AppTheme.blue,
                          radius: 20,
                          title: '',
                        ),
                        PieChartSectionData(
                          value: fat,
                          color: AppTheme.amber,
                          radius: 20,
                          title: '',
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _macroLegend('Karbohidrat', AppTheme.primaryLight, '${db.totalCarbsToday.toInt()}g', total > 0 ? '${((carbs / total) * 100).toInt()}%' : '0%'),
                const SizedBox(height: 12),
                _macroLegend('Protein', AppTheme.blue, '${db.totalProteinToday.toInt()}g', total > 0 ? '${((protein / total) * 100).toInt()}%' : '0%'),
                const SizedBox(height: 12),
                _macroLegend('Lemak', AppTheme.amber, '${db.totalFatToday.toInt()}g', total > 0 ? '${((fat / total) * 100).toInt()}%' : '0%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroLegend(String label, Color color, String value, String pct) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
          ),
        ),
        Text(value, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            pct,
            style: GoogleFonts.dmSans(fontSize: 10, color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(DatabaseProvider db, AuthProvider auth) {
    final bmi = auth.weightKg / ((auth.heightCm / 100) * (auth.heightCm / 100));
    String bmiLabel = bmi < 18.5 ? 'Kurus' : bmi < 25 ? 'Normal' : bmi < 30 ? 'Gemuk' : 'Obesitas';
    Color bmiColor = bmi < 18.5 ? AppTheme.blue : bmi < 25 ? AppTheme.primary : AppTheme.amber;

    return Column(
      children: [
        Row(
          children: [
            _summaryCard('Kalori Masuk', '${db.totalCaloriesToday.toInt()} kcal', Icons.restaurant_rounded, AppTheme.primarySurface, AppTheme.primary),
            const SizedBox(width: 10),
            _summaryCard('Kalori Keluar', '${db.caloriesBurned.toInt()} kcal', Icons.directions_run_rounded, AppTheme.redSurface, AppTheme.red),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _summaryCard('Kalori Bersih', '${(db.totalCaloriesToday - db.caloriesBurned).toInt()} kcal', Icons.calculate_rounded, AppTheme.blueSurface, AppTheme.blue),
            const SizedBox(width: 10),
            _summaryCard('BMI Tubuh', '${bmi.toStringAsFixed(1)} - $bmiLabel', Icons.monitor_weight_rounded, AppTheme.amberSurface, bmiColor),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDistribution(DatabaseProvider db) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: mealTypes.map((meal) {
          final logs = db.logsByMeal(meal.id);
          final cal = logs.fold(0.0, (s, l) => s + l.totalCalories);
          final pct = db.totalCaloriesToday > 0 ? cal / db.totalCaloriesToday : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: meal.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(meal.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            meal.label,
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${cal.toInt()} kcal',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: meal.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.toDouble(),
                          minHeight: 6,
                          backgroundColor: AppTheme.surface,
                          valueColor: AlwaysStoppedAnimation(meal.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
