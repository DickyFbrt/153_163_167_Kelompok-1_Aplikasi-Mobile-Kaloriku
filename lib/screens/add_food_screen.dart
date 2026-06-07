import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/database_provider.dart';
import '../models/food_model.dart';
import '../models/app_theme.dart';

class AddFoodScreen extends StatefulWidget {
  final String defaultMeal;
  const AddFoodScreen({super.key, this.defaultMeal = 'breakfast'});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String? _selectedCategory;
  FoodItem? _selectedFood;
  double _servings = 1.0;
  late String _selectedMeal;
  late AnimationController _sheetAnim;
  late Animation<Offset> _sheetSlide;
  final _searchCtrl = TextEditingController();

  final List<String> _categories = [
    'Semua', 'Karbohidrat', 'Protein', 'Sayuran',
    'Buah', 'Snack', 'Minuman', 'Makanan Berat'
  ];

  final Map<String, String> _categoryEmojis = {
    'Semua': '✨',
    'Karbohidrat': '🍚',
    'Protein': '🥩',
    'Sayuran': '🥬',
    'Buah': '🍎',
    'Snack': '🍿',
    'Minuman': '🥤',
    'Makanan Berat': '🍛',
  };

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.defaultMeal;
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FoodItem> get filteredFoods {
    return foodDatabase.where((f) {
      final matchSearch = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == null ||
          _selectedCategory == 'Semua' ||
          f.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  void _selectFood(FoodItem food) {
    if (_selectedFood?.id == food.id) {
      setState(() => _selectedFood = null);
      _sheetAnim.reverse();
    } else {
      setState(() {
        _selectedFood = food;
        _servings = 1.0;
      });
      _sheetAnim.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFF1A1A1A),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Makanan',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: const Color(0xFF1A1A1A)),
            ),
            Text(
              '${filteredFoods.length} pilihan tersedia',
              style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    _buildMealSelector(),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildCategoryFilter(),
                  ],
                ),
              ),
              Expanded(
                child: filteredFoods.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredFoods.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildFoodCard(filteredFoods[i]),
                      ),
              ),
            ],
          ),
          // Slide-up bottom sheet for add action
          if (_selectedFood != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _sheetSlide,
                child: _buildBottomAction(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.dmSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari makanan, misal: ayam, nasi...',
          hintStyle: GoogleFonts.dmSans(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(Icons.close_rounded, color: Colors.grey[400], size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = (_selectedCategory ?? 'Semua') == cat;
          final emoji = _categoryEmojis[cat] ?? '•';
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : Colors.white,
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    cat,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: selected ? Colors.white : Colors.grey[700],
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealSelector() {
    return Row(
      children: mealTypes.map((m) {
        final selected = _selectedMeal == m.id;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMeal = m.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: m == mealTypes.last ? 0 : 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? m.color : AppTheme.surface,
                border: Border.all(
                  color: selected ? m.color : AppTheme.border,
                  width: selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: m.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    m.label.split(' ').first,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: selected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFoodCard(FoodItem food) {
    final isSelected = _selectedFood?.id == food.id;
    final mealCfg = getMealConfig(_selectedMeal);

    return GestureDetector(
      onTap: () => _selectFood(food),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? mealCfg.surface : Colors.white,
          border: Border.all(
            color: isSelected ? mealCfg.color : AppTheme.border,
            width: isSelected ? 1.5 : 0.8,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mealCfg.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? mealCfg.color.withValues(alpha: 0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(food.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _macroBadge('K', '${food.carbs.toStringAsFixed(0)}g', const Color(0xFF2ECC71)),
                      const SizedBox(width: 4),
                      _macroBadge('P', '${food.protein.toStringAsFixed(0)}g', const Color(0xFF3498DB)),
                      const SizedBox(width: 4),
                      _macroBadge('L', '${food.fat.toStringAsFixed(0)}g', const Color(0xFFF39C12)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${food.calories.toInt()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? mealCfg.color : AppTheme.primary,
                    height: 1,
                  ),
                ),
                Text(
                  'kcal',
                  style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: mealCfg.color, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _macroBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.dmSans(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Makanan tidak ditemukan',
            style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba kata kunci lain',
            style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    final food = _selectedFood!;
    final totalCal = (food.calories * _servings).toInt();
    final mealCfg = getMealConfig(_selectedMeal);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: mealCfg.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(food.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$totalCal kcal untuk $_servings porsi',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: mealCfg.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Serving selector
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _servingBtn(Icons.remove_rounded, () {
                      if (_servings > 0.5) setState(() => _servings -= 0.5);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        _servings == _servings.truncate()
                            ? '${_servings.toInt()}x'
                            : '${_servings}x',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    _servingBtn(Icons.add_rounded, () {
                      if (_servings < 10) setState(() => _servings += 0.5);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<DatabaseProvider>().addFoodLog(food, _servings, _selectedMeal);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Text(food.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${food.name} ditambahkan ke ${mealCfg.label}!',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: mealCfg.color,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(12),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Text(mealCfg.emoji, style: const TextStyle(fontSize: 16)),
              label: Text(
                'Tambah ke ${mealCfg.label}',
                style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: mealCfg.color,
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

  Widget _servingBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primary),
      ),
    );
  }
}
