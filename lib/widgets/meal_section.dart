import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/food_model.dart';
import '../models/app_theme.dart';

class MealSection extends StatelessWidget {
  final MealConfig mealConfig;
  final List<FoodLog> logs;
  final ValueChanged<String> onDelete;
  final VoidCallback onAdd;

  const MealSection({
    super.key,
    required this.mealConfig,
    required this.logs,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final totalCal = logs.fold(0.0, (s, l) => s + l.totalCalories);
    final isLast = mealConfig == mealTypes.last;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: AppTheme.border, width: 0.8),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: mealConfig.surface, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(mealConfig.emoji, style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mealConfig.label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(
                        logs.isEmpty ? 'Belum ada catatan' : '${totalCal.toInt()} kcal · ${logs.length} item',
                        style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: mealConfig.color),
                    ),
                    child: Icon(Icons.add, size: 16, color: mealConfig.color),
                  ),
                ),
              ],
            ),
          ),
          if (logs.isNotEmpty)
            ...logs.map((log) => Dismissible(
              key: Key(log.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: AppTheme.redSurface,
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.red),
              ),
              onDismissed: (_) => onDelete(log.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Text(log.food.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.food.name, style: GoogleFonts.dmSans(fontSize: 12)),
                          Text(
                            '${log.servings == log.servings.truncate() ? log.servings.toInt() : log.servings} porsi',
                            style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Text('${log.totalCalories.toInt()} kcal', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: mealConfig.color)),
                  ],
                ),
              ),
            )),
          if (logs.isEmpty)
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
