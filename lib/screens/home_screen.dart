import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/database_provider.dart';
import '../providers/auth_provider.dart';
import '../models/app_theme.dart';
import '../widgets/macro_bar.dart';
import '../widgets/water_tracker.dart';
import '../widgets/meal_section.dart';
import 'add_food_screen.dart';
import 'stats_screen.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnim;
  late AnimationController _cardsAnim;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();

    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));

    _cardsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _cardsFade = CurvedAnimation(parent: _cardsAnim, curve: Curves.easeOut);

    // Start animations with a stagger
    _headerAnim.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _cardsAnim.forward();
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _cardsAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, db, _) {
        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, db),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _cardsFade,
                  child: Column(
                    children: [
                      _buildCalorieRing(context, db),
                      _buildStatsRow(context, db),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      _buildWaterSection(context, db),
                      const SizedBox(height: 16),
                      _buildMealsSection(context, db),
                      const SizedBox(height: 16),
                      _buildTipCard(db),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(context),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, DatabaseProvider db) {
    final now = DateTime.now();
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
    final auth = context.read<AuthProvider>();
    final name = auth.userName.isNotEmpty ? auth.userName.split(' ')[0] : 'Sahabat';
    final hour = now.hour;
    final greeting = hour < 11 ? 'Selamat pagi' : hour < 15 ? 'Selamat siang' : hour < 18 ? 'Selamat sore' : 'Selamat malam';
    final greetEmoji = hour < 11 ? '🌤️' : hour < 15 ? '☀️' : hour < 18 ? '🌇' : '🌙';

    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      backgroundColor: const Color(0xFF1A7A45),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: FadeTransition(
          opacity: _headerFade,
          child: SlideTransition(
            position: _headerSlide,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A7A45), Color(0xFF27AE60), Color(0xFF2ECC71)],
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(greetEmoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  '$greeting, $name!',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'KaloriKu+',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 28,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              dateStr,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _confirmLogout(context, auth),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
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

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.redSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Keluar?', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
          ],
        ),
        content: Text(
          'Kamu akan keluar dari akun KaloriKu+.',
          style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600]),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Batal', style: GoogleFonts.dmSans(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Keluar', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRing(BuildContext context, DatabaseProvider db) {
    final auth = context.read<AuthProvider>();
    final target = auth.targetCalories;
    final consumed = db.totalCaloriesToday;
    final burned = db.caloriesBurned;
    final effectiveBudget = target + burned;
    final progress = (consumed / effectiveBudget).clamp(0.0, 1.0);
    final remaining = (effectiveBudget - consumed).clamp(0, effectiveBudget);
    final isOver = consumed > effectiveBudget;
    final ringColor = isOver ? AppTheme.red : AppTheme.primary;

    String statusEmoji;
    String statusText;
    Color statusColor;
    if (isOver) {
      statusEmoji = '😅';
      statusText = 'Melebihi target!';
      statusColor = AppTheme.red;
    } else if (progress > 0.85) {
      statusEmoji = '🔥';
      statusText = 'Hampir penuh!';
      statusColor = AppTheme.amber;
    } else if (progress > 0.5) {
      statusEmoji = '😊';
      statusText = 'Berjalan bagus!';
      statusColor = AppTheme.primary;
    } else if (progress > 0) {
      statusEmoji = '👍';
      statusText = 'Tetap semangat!';
      statusColor = AppTheme.blue;
    } else {
      statusEmoji = '🌟';
      statusText = 'Mulai mencatat!';
      statusColor = AppTheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 62,
                  lineWidth: 11,
                  percent: progress,
                  backgroundColor: AppTheme.primarySurface,
                  progressColor: ringColor,
                  circularStrokeCap: CircularStrokeCap.round,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        consumed.toInt().toString(),
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          height: 1,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Row(
                    children: [
                      Text(statusEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Target info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target',
                              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
                            ),
                            Text(
                              '${target.toInt()} kcal',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppTheme.border,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOver ? 'Kelebihan' : 'Sisa',
                              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
                            ),
                            Text(
                              '${remaining.toInt()} kcal',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isOver ? AppTheme.red : AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MacroBar(label: 'Karbo', value: db.totalCarbsToday, max: 250, unit: 'g', color: AppTheme.primaryLight),
                  const SizedBox(height: 6),
                  MacroBar(label: 'Protein', value: db.totalProteinToday, max: 80, unit: 'g', color: AppTheme.blue),
                  const SizedBox(height: 6),
                  MacroBar(label: 'Lemak', value: db.totalFatToday, max: 65, unit: 'g', color: AppTheme.amber),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, DatabaseProvider db) {
    final auth = context.read<AuthProvider>();
    final effectiveBudget = auth.targetCalories + db.caloriesBurned;
    final remaining = (effectiveBudget - db.totalCaloriesToday).clamp(0, effectiveBudget);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(child: _miniStatCard('🔥', '${remaining.toInt()}', 'Sisa kcal', AppTheme.redSurface, AppTheme.red)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard('🏃', '${db.caloriesBurned.toInt()}', 'Dibakar', AppTheme.blueSurface, AppTheme.blue)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard('⚖️', '${auth.weightKg}', 'Berat (kg)', AppTheme.amberSurface, AppTheme.amber)),
          const SizedBox(width: 8),
          Expanded(child: _miniStatCard('💧', '${db.waterGlasses}/${db.waterGoal}', 'Air', AppTheme.primarySurface, AppTheme.primary)),
        ],
      ),
    );
  }

  Widget _miniStatCard(String emoji, String value, String label, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 9, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AKSI CEPAT',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _quickActionBtn(context, icon: Icons.restaurant_rounded, label: 'Sarapan', color: const Color(0xFF2ECC71), bg: const Color(0xFFE8F8F0), mealId: 'breakfast'),
              const SizedBox(width: 8),
              _quickActionBtn(context, icon: Icons.wb_sunny_rounded, label: 'Siang', color: const Color(0xFF3498DB), bg: const Color(0xFFEBF5FB), mealId: 'lunch'),
              const SizedBox(width: 8),
              _quickActionBtn(context, icon: Icons.cookie_rounded, label: 'Snack', color: const Color(0xFFF39C12), bg: const Color(0xFFFEF5E7), mealId: 'snack'),
              const SizedBox(width: 8),
              _quickActionBtn(context, icon: Icons.nights_stay_rounded, label: 'Malam', color: const Color(0xFF9B59B6), bg: const Color(0xFFF5EEF8), mealId: 'dinner'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionBtn(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required String mealId,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddFoodScreen(defaultMeal: mealId)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterSection(BuildContext context, DatabaseProvider db) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'AIR MINUM',
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.blue.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WaterTracker(
                current: db.waterGlasses,
                goal: db.waterGoal,
                onTap: (i) => db.setWaterGlasses(i),
                onIncrement: () => db.incrementWater(),
                onDecrement: () => db.decrementWater(),
                onGoalChanged: (newGoal) => db.updateWaterGoal(newGoal),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection(BuildContext context, DatabaseProvider db) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'CATATAN MAKAN',
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: mealTypes
                  .map((meal) => MealSection(
                        mealConfig: meal,
                        logs: db.logsByMeal(meal.id),
                        onDelete: (id) => db.removeFoodLog(id),
                        onAdd: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddFoodScreen(defaultMeal: meal.id)),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(DatabaseProvider db) {
    const tipEmojis = ['💡', '🥗', '🏃', '💪', '🌿', '✨'];
    final tipEmoji = tipEmojis[DateTime.now().hour % tipEmojis.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(tipEmoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips hari ini ✨',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    db.healthTip,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFoodScreen()),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      height: 72,
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, icon: Icons.home_rounded, label: 'Beranda', isActive: true, onTap: () {}),
          _navItem(context, icon: Icons.bar_chart_rounded, label: 'Statistik', isActive: false, onTap: () {
            Navigator.push(context, _fadeRoute(const StatsScreen()));
          }),
          const SizedBox(width: 48), // FAB notch space
          _navItem(context, icon: Icons.sports_rounded, label: 'Olahraga', isActive: false, onTap: () {
            Navigator.push(context, _fadeRoute(const ActivityScreen()));
          }),
          _navItem(context, icon: Icons.person_rounded, label: 'Profil', isActive: false, onTap: () {
            Navigator.push(context, _fadeRoute(const ProfileScreen()));
          }),
        ],
      ),
    );
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );

  Widget _navItem(BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isActive ? AppTheme.primary : Colors.grey[400]),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
