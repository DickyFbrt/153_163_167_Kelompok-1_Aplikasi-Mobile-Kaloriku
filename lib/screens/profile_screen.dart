import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../models/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final db = context.watch<DatabaseProvider>();
    final bmi = auth.heightCm > 0
        ? auth.weightKg / ((auth.heightCm / 100) * (auth.heightCm / 100))
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, auth),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildStatsRow(auth, db, bmi),
                    const SizedBox(height: 6),
                    _buildAchievements(db),
                    const SizedBox(height: 6),
                    _buildBodyCard(auth, bmi),
                    const SizedBox(height: 6),
                    _buildSectionTitle('⚙️  Pengaturan Akun'),
                    _buildSettingsCard(context, auth),
                    const SizedBox(height: 6),
                    _buildSectionTitle('ℹ️  Tentang Aplikasi'),
                    _buildAboutCard(),
                    const SizedBox(height: 20),
                    _buildLogoutButton(context, auth),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── SLIVER HEADER ───────────────────────
  SliverAppBar _buildSliverHeader(BuildContext context, AuthProvider auth) {
    final initial =
        auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : '?';
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: const Color(0xFF1A7A45),
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
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 4, bottom: 12),
          child: GestureDetector(
            onTap: () => _showEditProfile(context, auth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Edit', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F5C33),
                    Color(0xFF1A7A45),
                    Color(0xFF27AE60),
                    Color(0xFF2ECC71),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Profile content
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 36, 0, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF52D68A), Color(0xFF1ABC9C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border:
                            Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.dmSerifDisplay(
                              fontSize: 38, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.userName.isNotEmpty ? auth.userName : 'Pengguna',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        auth.email,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  // ─────────────────────── STATS ROW ───────────────────────
  Widget _buildStatsRow(
      AuthProvider auth, DatabaseProvider db, double bmi) {
    final bmiLabel = bmi < 18.5
        ? 'Kurus'
        : bmi < 25
            ? 'Normal'
            : bmi < 30
                ? 'Gemuk'
                : 'Obesitas';
    final bmiColor = bmi < 18.5
        ? AppTheme.blue
        : bmi < 25
            ? AppTheme.primary
            : AppTheme.amber;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        children: [
          _statCard('🎯', '${auth.targetCalories.toInt()}',
              'Target kcal', AppTheme.primarySurface, AppTheme.primary),
          const SizedBox(width: 8),
          _statCard('⚖️', bmi.toStringAsFixed(1), 'BMI · $bmiLabel',
              AppTheme.amberSurface, bmiColor),
          const SizedBox(width: 8),
          _statCard('💧', '${db.waterGlasses}/${db.waterGoal}',
              'Air (gelas)', AppTheme.blueSurface, AppTheme.blue),
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label,
      Color bg, Color accentColor) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: accentColor.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  height: 1),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── ACHIEVEMENTS ───────────────────────
  Widget _buildAchievements(DatabaseProvider db) {
    final logged = db.totalCaloriesToday > 0;
    final waterDone = db.waterGlasses >= db.waterGoal;
    final hasActivity = db.caloriesBurned > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PENCAPAIAN HARI INI',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey[500],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _badge('🍽️', 'Makan\nDicatat', logged),
                const SizedBox(width: 10),
                _badge('💧', 'Air\nTerpenuhi', waterDone),
                const SizedBox(width: 10),
                _badge('🏃', 'Aktivitas\nDilakukan', hasActivity),
                const SizedBox(width: 10),
                _badge('⭐', 'Target\nTercapai',
                    db.totalCaloriesToday <= db.waterGoal * 250),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String emoji, String label, bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primarySurface
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Text(emoji,
                style: TextStyle(
                    fontSize: 22,
                    color: active ? null : null)),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: active
                    ? AppTheme.primary
                    : Colors.grey[400],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── BODY INFO ───────────────────────
  Widget _buildBodyCard(AuthProvider auth, double bmi) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'DATA TUBUH',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showEditProfile(context, auth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded,
                            size: 12, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text('Edit',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _infoTile(Icons.monitor_weight_outlined,
                        'Berat Badan', '${auth.weightKg} kg',
                        AppTheme.primarySurface, AppTheme.primary)),
                const SizedBox(width: 8),
                Expanded(
                    child: _infoTile(Icons.height_rounded,
                        'Tinggi Badan', '${auth.heightCm.toInt()} cm',
                        AppTheme.blueSurface, AppTheme.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _infoTile(Icons.cake_outlined, 'Usia',
                        '${auth.age} tahun',
                        AppTheme.amberSurface, AppTheme.amber)),
                const SizedBox(width: 8),
                Expanded(
                    child: _infoTile(Icons.person_outline_rounded,
                        'Jenis Kelamin', auth.gender,
                        AppTheme.redSurface, AppTheme.red)),
              ],
            ),
            const SizedBox(height: 12),
            // BMI visual bar
            _buildBmiBar(bmi),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiBar(double bmi) {
    final clampedBmi = bmi.clamp(15.0, 35.0);
    final pct = ((clampedBmi - 15) / 20).clamp(0.0, 1.0);
    final bmiLabel = bmi < 18.5
        ? 'Kurus'
        : bmi < 25
            ? 'Normal'
            : bmi < 30
                ? 'Gemuk'
                : 'Obesitas';
    final bmiColor = bmi < 18.5
        ? AppTheme.blue
        : bmi < 25
            ? AppTheme.primary
            : AppTheme.amber;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Indeks Massa Tubuh (BMI)',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: Colors.grey[600])),
              Row(
                children: [
                  Text(bmi.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: bmiColor)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(bmiLabel,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: bmiColor)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              // Background gradient bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3498DB),
                      Color(0xFF2ECC71),
                      Color(0xFFF39C12),
                      Color(0xFFE74C3C),
                    ],
                  ),
                ),
              ),
              // Indicator
              Positioned(
                left: (pct * (MediaQuery.of(context).size.width - 80))
                    .clamp(0.0,
                        MediaQuery.of(context).size.width - 80)
                    .toDouble(),
                top: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: bmiColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: bmiColor.withValues(alpha: 0.4),
                          blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('<18.5',
                  style: GoogleFonts.dmSans(
                      fontSize: 9, color: Colors.grey[400])),
              Text('18.5',
                  style: GoogleFonts.dmSans(
                      fontSize: 9, color: Colors.grey[400])),
              Text('25',
                  style: GoogleFonts.dmSans(
                      fontSize: 9, color: Colors.grey[400])),
              Text('30+',
                  style: GoogleFonts.dmSans(
                      fontSize: 9, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.15), blurRadius: 4),
              ],
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 9, color: Colors.grey[600])),
                const SizedBox(height: 1),
                Text(value,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── SETTINGS ───────────────────────
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _settingsTile(
              icon: Icons.person_outline_rounded,
              iconBg: AppTheme.primarySurface,
              iconColor: AppTheme.primary,
              label: 'Edit Profil & Target',
              subtitle: 'Nama, berat, tinggi, dan target kalori',
              onTap: () => _showEditProfile(context, auth),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.lock_outline_rounded,
              iconBg: AppTheme.blueSurface,
              iconColor: AppTheme.blue,
              label: 'Ubah Password',
              subtitle: 'Perbarui password akun kamu',
              onTap: () => _showChangePassword(context, auth),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.notifications_none_rounded,
              iconBg: AppTheme.amberSurface,
              iconColor: AppTheme.amber,
              label: 'Notifikasi',
              subtitle: 'Pengingat makan & minum air',
              onTap: () => _showComingSoon(context),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.language_rounded,
              iconBg: const Color(0xFFE8F8F5),
              iconColor: const Color(0xFF1ABC9C),
              label: 'Bahasa',
              subtitle: 'Bahasa Indonesia',
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _settingsTile(
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFFE8F4FD),
              iconColor: const Color(0xFF2980B9),
              label: 'Versi Aplikasi',
              subtitle: 'KaloriKu+ v1.0.0 · Build 2026',
              onTap: null,
            ),
            _divider(),
            _settingsTile(
              icon: Icons.privacy_tip_outlined,
              iconBg: AppTheme.primarySurface,
              iconColor: AppTheme.primary,
              label: 'Kebijakan Privasi',
              subtitle: 'Bagaimana data kamu digunakan',
              onTap: () => _showComingSoon(context),
            ),
            _divider(),
            _settingsTile(
              icon: Icons.star_outline_rounded,
              iconBg: AppTheme.amberSurface,
              iconColor: AppTheme.amber,
              label: 'Beri Rating',
              subtitle: 'Bantu kami dengan bintang 5 ⭐',
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 72,
        endIndent: 16,
        color: AppTheme.border,
      );

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text('Keluar dari Akun',
              style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDEDEC),
            foregroundColor: AppTheme.red,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                  color: AppTheme.red, width: 1),
            ),
          ),
          onPressed: () => _confirmLogout(context, auth),
        ),
      ),
    );
  }

  // ─────────────────────── DIALOGS ───────────────────────
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              child:
                  const Icon(Icons.logout_rounded, color: AppTheme.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Keluar?',
                style: GoogleFonts.dmSerifDisplay(fontSize: 22)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Batal',
                style: GoogleFonts.dmSans(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Keluar',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.userName);
    final weightCtrl =
        TextEditingController(text: auth.weightKg.toString());
    final heightCtrl =
        TextEditingController(text: auth.heightCm.toInt().toString());
    final ageCtrl = TextEditingController(text: auth.age.toString());
    String gender = auth.gender;
    bool isLoading = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Edit Profil & Target',
                        style:
                            GoogleFonts.dmSerifDisplay(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 20),
                _sheetField('Nama Lengkap', nameCtrl, TextInputType.name),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _sheetField(
                          'Berat (kg)',
                          weightCtrl,
                          const TextInputType.numberWithOptions(
                              decimal: true))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _sheetField(
                          'Tinggi (cm)',
                          heightCtrl,
                          const TextInputType.numberWithOptions(
                              decimal: true))),
                ]),
                const SizedBox(height: 12),
                _sheetField(
                    'Usia (tahun)', ageCtrl, TextInputType.number),
                const SizedBox(height: 12),
                Text('Jenis Kelamin',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
                const SizedBox(height: 8),
                Row(
                    children:
                        ['Laki-laki', 'Perempuan'].map((g) {
                  final sel = g == gender;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setS(() => gender = g),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: g == 'Laki-laki' ? 8 : 0),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primarySurface
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : AppTheme.border),
                        ),
                        child: Text(
                          g == 'Laki-laki' ? '♂ Laki-laki' : '♀ Perempuan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: sel
                                  ? AppTheme.primary
                                  : Colors.grey[600]),
                        ),
                      ),
                    ),
                  );
                }).toList()),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.redSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(error!,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppTheme.red))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              setS(() =>
                                  error = 'Nama tidak boleh kosong.');
                              return;
                            }
                            final w =
                                double.tryParse(weightCtrl.text);
                            final h =
                                double.tryParse(heightCtrl.text);
                            final a = int.tryParse(ageCtrl.text);
                            if (w == null ||
                                w <= 0 ||
                                h == null ||
                                h <= 0 ||
                                a == null ||
                                a <= 0) {
                              setS(() => error =
                                  'Masukkan data berat, tinggi, dan usia yang valid.');
                              return;
                            }
                            setS(() {
                              isLoading = true;
                              error = null;
                            });
                            final cal =
                                AuthProvider.estimateCalories(
                                    weight: w,
                                    height: h,
                                    age: a,
                                    gender: gender);
                            final result = await auth.updateProfile(
                              name: nameCtrl.text.trim(),
                              weight: w,
                              height: h,
                              age: a,
                              gender: gender,
                              targetCalories: cal,
                            );
                            if (result != null) {
                              setS(() {
                                isLoading = false;
                                error = result;
                              });
                              return;
                            }
                            if (context.mounted) {
                              await context
                                  .read<DatabaseProvider>()
                                  .updateWaterGoal(8);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text('Simpan Perubahan',
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
      String label, TextEditingController ctrl, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          obscureText: type == TextInputType.visiblePassword,
          style: GoogleFonts.dmSans(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppTheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  void _showChangePassword(BuildContext context, AuthProvider auth) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool isLoading = false;
    bool isResetSent = false;
    bool isDirectChangeLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.blueSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: AppTheme.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Ubah Password',
                        style:
                            GoogleFonts.dmSerifDisplay(fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                    'Ubah langsung atau kirim link reset ke email kamu.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 20),
                if (isResetSent) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryBorder),
                    ),
                    child: Column(
                      children: [
                        const Text('📧',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Link reset dikirim!',
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary)),
                        const SizedBox(height: 6),
                        Text(
                            'Link reset password telah dikirim ke:\n${auth.email}',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.grey[600]),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Tutup',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else ...[
                  _sheetField('Password Lama', oldCtrl,
                      TextInputType.visiblePassword),
                  const SizedBox(height: 12),
                  _sheetField('Password Baru', newCtrl,
                      TextInputType.visiblePassword),
                  const SizedBox(height: 12),
                  _sheetField('Konfirmasi Password Baru', confirmCtrl,
                      TextInputType.visiblePassword),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.redSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                AppTheme.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(error!,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppTheme.red))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isDirectChangeLoading || isLoading
                          ? null
                          : () async {
                              if (oldCtrl.text.isEmpty ||
                                  newCtrl.text.isEmpty ||
                                  confirmCtrl.text.isEmpty) {
                                setS(() => error =
                                    'Semua kolom password wajib diisi.');
                                return;
                              }
                              if (newCtrl.text != confirmCtrl.text) {
                                setS(() => error =
                                    'Password baru tidak cocok.');
                                return;
                              }
                              if (newCtrl.text.length < 6) {
                                setS(() => error =
                                    'Password minimal 6 karakter.');
                                return;
                              }
                              setS(() {
                                isDirectChangeLoading = true;
                                error = null;
                              });
                              final result = await auth.changePassword(
                                  oldCtrl.text, newCtrl.text);
                              if (result != null) {
                                setS(() {
                                  isDirectChangeLoading = false;
                                  error = result;
                                });
                                return;
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isDirectChangeLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text('Simpan Password Baru',
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppTheme.border)),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('ATAU',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold)),
                      ),
                      const Expanded(
                          child: Divider(color: AppTheme.border)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isLoading || isDirectChangeLoading
                          ? null
                          : () async {
                              setS(() {
                                isLoading = true;
                                error = null;
                              });
                              final result =
                                  await AuthProvider.resetPassword(
                                      auth.email);
                              if (result == null) {
                                setS(() {
                                  isLoading = false;
                                  isResetSent = true;
                                });
                              } else {
                                setS(() {
                                  isLoading = false;
                                  error = result;
                                });
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary, strokeWidth: 2))
                          : const Icon(Icons.mail_outline_rounded,
                              size: 18),
                      label: Text('Kirim Link Reset ke Email',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.primary, width: 1.2),
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🚀', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('Segera hadir!', style: GoogleFonts.dmSans()),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
