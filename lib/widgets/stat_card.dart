import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: Colors.grey[700]), maxLines: 2),
        ],
      ),
    );
  }
}
