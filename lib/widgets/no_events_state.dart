import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

/// Read-only state widget for when an organization has no events.
///
/// This is typically used by super admins viewing organizations
/// that haven't created any events yet. Unlike [EmptyState], this
/// widget doesn't offer any action buttons and is purely informational.
class NoEventsState extends StatelessWidget {
  final String? organizationName;
  final String? imageAsset;

  const NoEventsState({
    super.key,
    this.organizationName,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight > 0
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  Icons.event_busy,
                  size: 80,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),

                // Spacing
                AppSpacing.verticalMd(context),

                // Heading
                AppText.styledHeadingLarge(
                  context,
                  'No Events Yet',
                  textAlign: TextAlign.center,
                  color: AppColors.primary,
                  weight: FontWeight.w600,
                ),

                // Spacing
                AppSpacing.verticalSm(context),

                // Description text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: AppText.styledBodyLarge(
                    context,
                    organizationName != null
                        ? '$organizationName hasn\'t created any events yet.'
                        : 'This organization hasn\'t created any events yet.',
                    textAlign: TextAlign.center,
                    color: AppColors.textMuted,
                  ),
                ),

                // Additional info
                AppSpacing.verticalSm(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: AppText.styledBodyMedium(
                    context,
                    'Events will appear here once they are created.',
                    textAlign: TextAlign.center,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
