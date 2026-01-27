import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/payment.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

import 'transaction_mobile_content.dart';
import 'transaction_desktop_content.dart';

/// A single transaction item in the list
class TransactionListItem extends StatelessWidget {
  final Payment transaction;
  final int index;
  final bool isPhone;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.index,
    required this.isPhone,
  });

  @override
  Widget build(BuildContext context) {
    final isEven = index.isEven;
    final isDesktop = ScreenSize.isDesktop(context);
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return Container(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.symmetric(
              context,
              horizontalPadding: Sizes.lg,
              verticalPadding: Sizes.md,
            ),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.surfaceCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: isDesktop
          ? TransactionDesktopContent(
              transaction: transaction,
              dateFormatter: dateFormatter,
              timeFormatter: timeFormatter,
            )
          : TransactionMobileContent(
              transaction: transaction,
              dateFormatter: dateFormatter,
              timeFormatter: timeFormatter,
            ),
    );
  }
}
