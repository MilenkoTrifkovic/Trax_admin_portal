import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

/// Empty state widget shown when no sales people exist
class SalesPeopleEmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;
  
  const SalesPeopleEmptyState({
    super.key,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'No Sales People Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start by adding your first sales person',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Sales Person'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
