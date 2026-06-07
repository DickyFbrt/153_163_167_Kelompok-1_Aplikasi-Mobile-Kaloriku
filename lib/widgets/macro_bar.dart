// lib/widgets/macro_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String unit;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 38,
          child: Text(
            '${value.toInt()}$unit',
            style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
