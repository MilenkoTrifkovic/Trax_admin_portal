import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

/// A card widget displaying a single metric with icon, label, and value
class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color iconColor;
  final bool isLoading;
  
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);
    
    final cardPadding = isPhone ? 16.0 : (isTablet ? 20.0 : 24.0);
    final iconContainerPadding = isPhone ? 10.0 : 12.0;
    final iconSize = isPhone ? 24.0 : 28.0;
    final labelFontSize = isPhone ? 13.0 : 14.0;
    final valueFontSize = isPhone ? 24.0 : (isTablet ? 28.0 : 32.0);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
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
      child: isPhone 
          ? _buildHorizontalLayout(
              iconContainerPadding: iconContainerPadding,
              iconSize: iconSize,
              labelFontSize: labelFontSize,
              valueFontSize: valueFontSize,
            )
          : _buildVerticalLayout(
              iconContainerPadding: iconContainerPadding,
              iconSize: iconSize,
              labelFontSize: labelFontSize,
              valueFontSize: valueFontSize,
            ),
    );
  }
  
  /// Horizontal layout for mobile screens
  Widget _buildHorizontalLayout({
    required double iconContainerPadding,
    required double iconSize,
    required double labelFontSize,
    required double valueFontSize,
  }) {
    return Row(
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(iconContainerPadding),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Label and Value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              isLoading
                  ? SizedBox(
                      height: valueFontSize,
                      width: valueFontSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Text(
                      value.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Vertical layout for tablet/desktop screens
  Widget _buildVerticalLayout({
    required double iconContainerPadding,
    required double iconSize,
    required double labelFontSize,
    required double valueFontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          padding: EdgeInsets.all(iconContainerPadding),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Label
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: labelFontSize,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Value
        isLoading
            ? SizedBox(
                height: valueFontSize,
                width: valueFontSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
      ],
    );
  }
}
