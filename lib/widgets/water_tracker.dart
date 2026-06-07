import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_theme.dart';

class WaterTracker extends StatelessWidget {
  final int current;
  final int goal;
  final ValueChanged<int> onTap; // called with the new absolute count
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final ValueChanged<int>? onGoalChanged; // called with the new goal value

  const WaterTracker({
    super.key,
    required this.current,
    required this.goal,
    required this.onTap,
    this.onIncrement,
    this.onDecrement,
    this.onGoalChanged,
  });

  // How many millilitres per glass
  static const int _mlPerGlass = 250;

  @override
  Widget build(BuildContext context) {
    final double progress = goal == 0 ? 0 : (current / goal).clamp(0.0, 1.0);
    final bool isGoalReached = current >= goal;
    final int totalMl = current * _mlPerGlass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: summary + goal editor ─────────────────────
        _buildHeader(isGoalReached, totalMl),
        const SizedBox(height: 16),

        // ── Progress bar ──────────────────────────────────────────
        _buildProgressBar(progress, isGoalReached),
        const SizedBox(height: 18),

        // ── Glass grid ───────────────────────────────────────────
        _buildGlassGrid(),
        const SizedBox(height: 18),

        // ── Quick action buttons ──────────────────────────────────
        _buildQuickActions(context, isGoalReached),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isGoalReached, int totalMl) {
    return Row(
      children: [
        // Left: icon + current/goal text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: AppTheme.blue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              '$current',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: isGoalReached
                                    ? AppTheme.blue
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              ' / $goal gelas',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: Colors.grey[500]),
                            ),
                            if (isGoalReached)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '✓ Tercapai!',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '$totalMl ml dikonsumsi hari ini',
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Right: WHO Target Badge (icon only)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.blue.withValues(alpha: 0.15)),
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.blue,
            size: 14,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Progress bar
  // ─────────────────────────────────────────────────────────────────
  Widget _buildProgressBar(double progress, bool isGoalReached) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(
                isGoalReached
                    ? AppTheme.blue
                    : AppTheme.blue.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}% dari target',
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
            ),
            Text(
              '${goal * _mlPerGlass} ml target',
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Glass grid (max 20)
  // Aturan: hanya bisa menambah. Tap kotak yang sudah biru = no-op.
  // ─────────────────────────────────────────────────────────────────
  Widget _buildGlassGrid() {
    final displayGoal = goal.clamp(1, 20);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(displayGoal, (i) {
        final isFilled = i < current;
        final isPartial = i == current && current < goal;

        return GestureDetector(
          onTap: () {
            if (current >= goal) return;
            if (isFilled) {
              // sudah diminum, tidak bisa dikurangi
              return;
            }

            // kotak kosong/partial => tambah 1 gelas
            HapticFeedback.lightImpact();
            onTap(i + 1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: 34,
            height: 40,
            decoration: BoxDecoration(
              color: isFilled
                  ? AppTheme.blue
                  : (isPartial
                      ? AppTheme.blue.withValues(alpha: 0.08)
                      : Colors.grey[100]),
              border: Border.all(
                color: isFilled
                    ? AppTheme.blue
                    : (isPartial
                        ? AppTheme.blue.withValues(alpha: 0.35)
                        : Colors.grey[300]!),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: AppTheme.blue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isFilled
                    ? Container(
                        key: const ValueKey(true),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        ' ',
                        key: ValueKey(false),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Quick action buttons (big + and -)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, bool isGoalReached) {
    final bool isMax = current >= goal;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: !isMax
            ? () {
                HapticFeedback.mediumImpact();
                if (onIncrement != null) onIncrement!();
              }
            : null,
        icon: Icon(
          isMax ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
          size: 18,
        ),
        label: Text(
          isMax ? 'Target Tercapai! 🎉' : 'Minum Segelas (+250 ml)',
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.green[50],
          disabledForegroundColor: Colors.green[700],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isMax ? BorderSide(color: Colors.green[200]!) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
