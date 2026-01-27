import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/models/payment.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

import 'transaction_badges.dart';

/// Mobile layout content for a transaction item
class TransactionMobileContent extends StatelessWidget {
  final Payment transaction;
  final DateFormat dateFormatter;
  final DateFormat timeFormatter;

  const TransactionMobileContent({
    super.key,
    required this.transaction,
    required this.dateFormatter,
    required this.timeFormatter,
  });

  bool get isFreeCredit => transaction.isFree;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopRow(context),
        AppSpacing.verticalXs(context),
        if (isFreeCredit && transaction.isAssignedBySuperAdmin)
          _buildAssignedByRow(context),
        if (transaction.note != null && transaction.note!.isNotEmpty)
          _buildNoteRow(context),
        if (!isFreeCredit &&
            transaction.transactionId != null &&
            transaction.transactionId!.isNotEmpty)
          _buildTransactionIdRow(context),
        _buildDateRow(context),
        AppSpacing.verticalXs(context),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (isFreeCredit) ...[
                Icon(
                  Icons.card_giftcard,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                SizedBox(width: 6),
              ],
              Expanded(
                child: AppText.styledBodyMedium(
                  context,
                  transaction.displayPackageName,
                  weight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        isFreeCredit
            ? const FreeCreditBadge()
            : TransactionStatusBadge(status: transaction.paymentStatus),
      ],
    );
  }

  Widget _buildAssignedByRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs(context)),
      child: Row(
        children: [
          Icon(Icons.person, size: 14, color: Colors.amber.shade700),
          SizedBox(width: 4),
          Expanded(
            child: AppText.styledMetaSmall(
              context,
              transaction.displaySource,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs(context)),
      child: Row(
        children: [
          Icon(Icons.note, size: 14, color: AppColors.textMuted),
          SizedBox(width: 4),
          Expanded(
            child: AppText.styledMetaSmall(
              context,
              transaction.note!,
              color: AppColors.textMuted,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionIdRow(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs(context)),
      child: TransactionIdRow(transactionId: transaction.transactionId!),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 14, color: AppColors.textMuted),
        AppSpacing.horizontalXs(context),
        AppText.styledMetaSmall(
          context,
          transaction.createdAt != null
              ? '${dateFormatter.format(transaction.createdAt!)} at ${timeFormatter.format(transaction.createdAt!)}'
              : 'Unknown date',
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isFreeCredit ? Icons.card_giftcard : Icons.attach_money,
              size: 16,
              color: isFreeCredit ? Colors.amber.shade700 : AppColors.success,
            ),
            AppText.styledBodyMedium(
              context,
              transaction.formattedAmount,
              color: isFreeCredit ? Colors.amber.shade700 : AppColors.success,
              weight: FontWeight.w600,
            ),
          ],
        ),
        EventsBadge(
          events: transaction.events,
          isFreeCredit: isFreeCredit,
        ),
      ],
    );
  }
}
