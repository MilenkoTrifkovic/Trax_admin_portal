import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Card widget for displaying event statistics including total, purchased, and remaining events
class EventsStatsCard extends StatelessWidget {
  final int totalEvents;
  final int purchasedEvents;
  final int remainingEvents;

  const EventsStatsCard({
    super.key,
    required this.totalEvents,
    required this.purchasedEvents,
    required this.remainingEvents,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final isDesktop = ScreenSize.isDesktop(context);

    return Container(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.all(context, paddingType: Sizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isPhone ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event,
                  color: AppColors.primary,
                  size: isPhone ? 20 : 24,
                ),
              ),
              AppSpacing.horizontalMd(context),
              Expanded(
                child: AppText.styledBodyMedium(
                  context,
                  'Event Statistics',
                  color: AppColors.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AppSpacing.verticalMd(context),
          const Divider(height: 1),
          AppSpacing.verticalMd(context),
          // Stats grid - stacked on phone/tablet, side-by-side on desktop only
          isDesktop ? _buildDesktopStats(context) : _buildMobileStats(context),
        ],
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context) {
    return Column(
      children: [
        _buildStatRow(
          context,
          icon: Icons.event_available,
          label: 'Total Events',
          value: totalEvents.toString(),
          color: AppColors.primary,
        ),
        AppSpacing.verticalSm(context),
        _buildStatRow(
          context,
          icon: Icons.shopping_cart_outlined,
          label: 'Purchased',
          value: purchasedEvents.toString(),
          color: AppColors.success,
        ),
        AppSpacing.verticalSm(context),
        _buildStatRow(
          context,
          icon: Icons.inventory_2_outlined,
          label: 'Remaining',
          value: remainingEvents.toString(),
          color: _getRemainingColor(),
        ),
      ],
    );
  }

  Widget _buildDesktopStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.event_available,
            label: 'Total Events',
            value: totalEvents.toString(),
            color: AppColors.primary,
          ),
        ),
        AppSpacing.horizontalMd(context),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.shopping_cart_outlined,
            label: 'Purchased',
            value: purchasedEvents.toString(),
            color: AppColors.success,
          ),
        ),
        AppSpacing.horizontalMd(context),
        Expanded(
          child: _buildStatItem(
            context,
            icon: Icons.inventory_2_outlined,
            label: 'Remaining',
            value: remainingEvents.toString(),
            color: _getRemainingColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppPadding.symmetric(
        context,
        horizontalPadding: Sizes.sm,
        verticalPadding: Sizes.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          AppSpacing.horizontalSm(context),
          Expanded(
            child: AppText.styledBodySmall(
              context,
              label,
              color: AppColors.textMuted,
              weight: FontWeight.w500,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm(context),
              vertical: AppSpacing.xxxs(context),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText.styledBodyMedium(
              context,
              value,
              color: color,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          AppSpacing.verticalSm(context),
          AppText.styledMetaSmall(
            context,
            label,
            color: AppColors.textMuted,
            weight: FontWeight.w500,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalXs(context),
          AppText.styledHeadingMedium(
            context,
            value,
            color: color,
          ),
        ],
      ),
    );
  }

  Color _getRemainingColor() {
    if (remainingEvents > 10) {
      return AppColors.success;
    } else if (remainingEvents > 0) {
      return Colors.orange;
    } else if (remainingEvents == 0) {
      return AppColors.textMuted;
    } else {
      return AppColors.inputError;
    }
  }
}
