import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../models/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String email;
  final bool isGoogleUser;
  final String googleName;

  const OnboardingScreen({
    super.key,
    required this.email,
    this.isGoogleUser = false,
    this.googleName = '',
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Form fields
  final _nameCtrl = TextEditingController();
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(text: '60');
  final _heightCtrl = TextEditingController(text: '165');
  final _ageCtrl = TextEditingController(text: '20');
  String _gender = 'Laki-laki';
  double _estimatedCalories = 2150;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _progressAnim;
  late Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressValue = Tween<double>(begin: 1 / _totalPages, end: 1 / _totalPages)
        .animate(CurvedAnimation(parent: _progressAnim, curve: Curves.easeInOut));
    _emailCtrl = TextEditingController(text: widget.email);
    if (widget.isGoogleUser) {
      _nameCtrl.text = widget.googleName;
    }
    _recalcCalories();
  }

  @override
  void dispose() {
    _progressAnim.dispose();
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _recalcCalories() {
    final w = double.tryParse(_weightCtrl.text) ?? 60;
    final h = double.tryParse(_heightCtrl.text) ?? 165;
    final a = int.tryParse(_ageCtrl.text) ?? 20;
    setState(() {
      _estimatedCalories = AuthProvider.estimateCalories(
        weight: w,
        height: h,
        age: a,
        gender: _gender,
      );
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
      final newProgress = (_currentPage + 1) / _totalPages;
      _progressValue = Tween<double>(
        begin: _progressValue.value,
        end: newProgress,
      ).animate(CurvedAnimation(parent: _progressAnim, curve: Curves.easeInOut));
      _progressAnim.forward(from: 0);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
      final newProgress = (_currentPage + 1) / _totalPages;
      _progressValue = Tween<double>(
        begin: _progressValue.value,
        end: newProgress,
      ).animate(CurvedAnimation(parent: _progressAnim, curve: Curves.easeInOut));
      _progressAnim.forward(from: 0);
    }
  }

  Future<void> _handleFinish() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    
    final String? error;
    if (widget.isGoogleUser) {
      error = await auth.registerWithGoogleProfile(
        name: _nameCtrl.text.trim(),
        weight: double.tryParse(_weightCtrl.text) ?? 60,
        height: double.tryParse(_heightCtrl.text) ?? 165,
        age: int.tryParse(_ageCtrl.text) ?? 20,
        gender: _gender,
        targetCalories: _estimatedCalories,
      );
    } else {
      error = await auth.register(
        email: email.isNotEmpty ? email : '${_nameCtrl.text.trim().toLowerCase().replaceAll(' ', '')}@kalorikuplus.app',
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        weight: double.tryParse(_weightCtrl.text) ?? 60,
        height: double.tryParse(_heightCtrl.text) ?? 165,
        age: int.tryParse(_ageCtrl.text) ?? 20,
        gender: _gender,
        targetCalories: _estimatedCalories,
      );
    }

    if (error != null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      }
    } else {
      if (mounted) {
        try {
          final db = context.read<DatabaseProvider>();
          await db.reload().timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('Error reloading database on onboarding finish: $e');
        }

        if (mounted) {
          setState(() => _isLoading = false);
          final nav = Navigator.of(context);
          nav.pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const HomeScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: Color(0xFF1A1A1A)),
                  ),
                )
              else
                const SizedBox(width: 36),
              const Spacer(),
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressValue.value,
                  minHeight: 4,
                  backgroundColor: AppTheme.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Page 1: Nama & Password ---
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hai! Siapa namamu?',
              style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text(widget.isGoogleUser
              ? 'Konfirmasi nama lengkap untuk melengkapi profil sehatmu.'
              : 'Buat akun untuk memulai perjalanan sehatmu.',
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 32),
          _label('Nama lengkap'),
          const SizedBox(height: 8),
          _inputField(
            controller: _nameCtrl,
            hint: 'Contoh: Dandi Ardiansyah',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _label('Email'),
          const SizedBox(height: 8),
          _inputField(
            controller: _emailCtrl,
            hint: 'kamu@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: widget.isGoogleUser,
          ),
          if (!widget.isGoogleUser) ...[
            const SizedBox(height: 16),
            _label('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: GoogleFonts.dmSans(fontSize: 14),
              decoration: _inputDeco(
                hint: 'Minimal 6 karakter',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorWidget(),
          ],
        ],
      ),
    );
  }

  // --- Page 2: Data Fisik ---
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data tubuhmu',
              style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Kami gunakan untuk menghitung kebutuhan kalori harianmu.',
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Berat (kg)'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _weightCtrl,
                      hint: '60',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalcCalories(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Tinggi (cm)'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _heightCtrl,
                      hint: '165',
                      icon: Icons.height_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalcCalories(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Usia'),
                    const SizedBox(height: 8),
                    _inputField(
                      controller: _ageCtrl,
                      hint: '20',
                      icon: Icons.cake_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalcCalories(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Jenis Kelamin'),
                    const SizedBox(height: 8),
                    _genderDropdown(),
                  ],
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _errorWidget(),
          ],
        ],
      ),
    );
  }

  // --- Page 3: Konfirmasi Kalori ---
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target kalorimu',
              style: GoogleFonts.dmSerifDisplay(fontSize: 26, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Berdasarkan data tubuhmu, ini rekomendasi target harianmu.',
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 32),
          // Kalori card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(
                  '${_estimatedCalories.toInt()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Text(
                  'kcal / hari',
                  style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Ringkasan data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _summaryRow('👤', 'Nama', _nameCtrl.text.isEmpty ? '-' : _nameCtrl.text),
                const Divider(height: 20),
                _summaryRow('⚖️', 'Berat', '${_weightCtrl.text} kg'),
                const Divider(height: 20),
                _summaryRow('📏', 'Tinggi', '${_heightCtrl.text} cm'),
                const Divider(height: 20),
                _summaryRow('🎂', 'Usia', '${_ageCtrl.text} tahun'),
                const Divider(height: 20),
                _summaryRow('🚻', 'Gender', _gender),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBorder),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Target ini bisa kamu ubah kapan saja di halaman Profil.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppTheme.primary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Link ke login
          GestureDetector(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (r) => false,
            ),
            child: Center(
              child: Text.rich(
                TextSpan(
                  text: 'Sudah punya akun? ',
                  style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600]),
                  children: [
                    TextSpan(
                      text: 'Masuk di sini',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _errorWidget(),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!isLast) {
                    // Validasi page 1
                    if (_currentPage == 0) {
                      if (_nameCtrl.text.trim().isEmpty) {
                        setState(() => _errorMessage = 'Nama tidak boleh kosong.');
                        return;
                      }
                      final emailInput = _emailCtrl.text.trim();
                      if (emailInput.isEmpty || !emailInput.contains('@')) {
                        setState(() => _errorMessage = 'Format email tidak valid.');
                        return;
                      }
                      if (!widget.isGoogleUser) {
                        if (_passwordCtrl.text.length < 6) {
                          setState(() => _errorMessage = 'Password minimal 6 karakter.');
                          return;
                        }
                        // Cek apakah email sudah terdaftar
                        final sudahAda = await AuthProvider.isEmailRegistered(emailInput);
                        if (sudahAda) {
                          setState(() => _errorMessage = 'Email ini sudah terdaftar. Silakan login.');
                          return;
                        }
                      }
                      setState(() => _errorMessage = null);
                    }
                    _nextPage();
                  } else {
                    _handleFinish();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            disabledBackgroundColor: AppTheme.primaryLight.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  isLast ? 'Mulai Sekarang 🚀' : 'Lanjutkan',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A)),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onChanged: onChanged,
      style: GoogleFonts.dmSans(fontSize: 14),
      decoration: _inputDeco(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey[400]),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  Widget _genderDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _gender,
      style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF1A1A1A)),
      decoration: _inputDeco(hint: '', icon: Icons.wc_rounded).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 20),
      ),
      items: ['Laki-laki', 'Perempuan']
          .map((g) => DropdownMenuItem(
                value: g,
                child: Text(
                  g,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 13),
                ),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() => _gender = v);
          _recalcCalories();
        }
      },
    );
  }

  Widget _summaryRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _errorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.redSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}
