import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trax_admin_portal/helper/app_padding.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/payment.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';
import 'package:trax_admin_portal/utils/enums/sizes.dart';

/// Widget for displaying transaction history as a list
class TransactionHistoryWidget extends StatelessWidget {
  final List<Payment> transactions;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const TransactionHistoryWidget({
    super.key,
    required this.transactions,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    if (transactions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, isPhone),
          const Divider(height: 1),
          // Transaction list
          if (isExpanded || transactions.length <= 3)
            ...transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              return _buildTransactionItem(
                  context, transaction, index, isPhone);
            })
          else
            ...transactions.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              return _buildTransactionItem(
                  context, transaction, index, isPhone);
            }),
          // Show more/less button
          if (transactions.length > 3) _buildToggleButton(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: AppPadding.all(context, paddingType: Sizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          AppSpacing.verticalMd(context),
          AppText.styledBodyMedium(
            context,
            'No transactions yet',
            color: AppColors.textMuted,
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalXs(context),
          AppText.styledBodySmall(
            context,
            'Transactions will appear here once the company makes a purchase.',
            color: AppColors.textMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPhone) {
    return Padding(
      padding: isPhone
          ? AppPadding.all(context, paddingType: Sizes.md)
          : AppPadding.symmetric(
              context,
              horizontalPadding: Sizes.lg,
              verticalPadding: Sizes.md,
            ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isPhone ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.receipt_long,
              color: AppColors.primaryAccent,
              size: isPhone ? 18 : 20,
            ),
          ),
          AppSpacing.horizontalSm(context),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.styledBodyMedium(
                  context,
                  'Transaction History',
                  color: AppColors.primary,
                  weight: FontWeight.w600,
                ),
                AppText.styledMetaSmall(
                  context,
                  '${transactions.length} transaction${transactions.length != 1 ? 's' : ''}',
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Payment transaction,
    int index,
    bool isPhone,
  ) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final isEven = index.isEven;

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
      child: isPhone
          ? _buildMobileTransactionContent(
              context, transaction, dateFormatter, timeFormatter)
          : _buildDesktopTransactionContent(
              context, transaction, dateFormatter, timeFormatter),
    );
  }

  Widget _buildMobileTransactionContent(
    BuildContext context,
    Payment transaction,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Package name and status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText.styledBodyMedium(
                context,
                transaction.metadata?.packageName ??
                    transaction.productName ??
                    'Purchase',
                weight: FontWeight.w600,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(context, transaction.paymentStatus),
          ],
        ),
        AppSpacing.verticalXs(context),
        // Transaction ID row
        if (transaction.transactionId != null &&
            transaction.transactionId!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs(context)),
            child: _buildTransactionIdRow(context, transaction.transactionId!),
          ),
        // Middle row: Date and email
        Row(
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
        ),
        AppSpacing.verticalXs(context),
        // Bottom row: Amount and events
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: AppColors.success),
                AppText.styledBodyMedium(
                  context,
                  transaction.formattedAmount,
                  color: AppColors.success,
                  weight: FontWeight.w600,
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm(context),
                vertical: AppSpacing.xxxs(context),
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  AppText.styledBodySmall(
                    context,
                    '${transaction.events} events',
                    color: AppColors.primary,
                    weight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTransactionContent(
    BuildContext context,
    Payment transaction,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    return Row(
      children: [
        // Date column
        SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledBodySmall(
                context,
                transaction.createdAt != null
                    ? dateFormatter.format(transaction.createdAt!)
                    : 'Unknown',
                weight: FontWeight.w500,
              ),
              AppText.styledMetaSmall(
                context,
                transaction.createdAt != null
                    ? timeFormatter.format(transaction.createdAt!)
                    : '',
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        // Transaction ID column
        Expanded(
          flex: 2,
          child: transaction.transactionId != null &&
                  transaction.transactionId!.isNotEmpty
              ? _buildTransactionIdRow(context, transaction.transactionId!)
              : AppText.styledMetaSmall(
                  context,
                  'No ID',
                  color: AppColors.textMuted,
                ),
        ),
        AppSpacing.horizontalMd(context),
        // Package/Product column
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.styledBodyMedium(
                context,
                transaction.metadata?.packageName ??
                    transaction.productName ??
                    'Purchase',
                weight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              if (transaction.userEmail != null)
                AppText.styledMetaSmall(
                  context,
                  transaction.userEmail!,
                  color: AppColors.textMuted,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Events column
        SizedBox(
          width: 100,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm(context),
              vertical: AppSpacing.xxxs(context),
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppText.styledBodySmall(
              context,
              '${transaction.events} events',
              color: AppColors.primary,
              weight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        AppSpacing.horizontalMd(context),
        // Amount column
        SizedBox(
          width: 100,
          child: AppText.styledBodyMedium(
            context,
            transaction.formattedAmount,
            color: AppColors.success,
            weight: FontWeight.w600,
            textAlign: TextAlign.right,
          ),
        ),
        AppSpacing.horizontalMd(context),
        // Status column
        SizedBox(
          width: 80,
          child: _buildStatusBadge(context, transaction.paymentStatus),
        ),
      ],
    );
  }

  Widget _buildTransactionIdRow(BuildContext context, String transactionId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.receipt_outlined,
          size: 14,
          color: AppColors.textMuted,
        ),
        SizedBox(width: 4),
        Flexible(
          child: SelectableText(
            transactionId,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
          ),
        ),
        SizedBox(width: 4),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: transactionId));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Transaction ID copied to clipboard'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.copy,
              size: 14,
              color: AppColors.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String? status) {
    Color bgColor;
    Color textColor;
    String displayStatus;

    switch (status?.toLowerCase()) {
      case 'paid':
      case 'succeeded':
      case 'complete':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        displayStatus = 'Paid';
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        displayStatus = 'Pending';
        break;
      case 'failed':
      case 'canceled':
        bgColor = AppColors.inputError.withOpacity(0.1);
        textColor = AppColors.inputError;
        displayStatus = 'Failed';
        break;
      default:
        bgColor = AppColors.textMuted.withOpacity(0.1);
        textColor = AppColors.textMuted;
        displayStatus = status ?? 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm(context),
        vertical: AppSpacing.xxxs(context),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AppText.styledMetaSmall(
        context,
        displayStatus,
        color: textColor,
        weight: FontWeight.w600,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return InkWell(
      onTap: onToggleExpand,
      child: Container(
        width: double.infinity,
        padding: AppPadding.symmetric(
          context,
          horizontalPadding: Sizes.md,
          verticalPadding: Sizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.primaryAccent,
            ),
            AppSpacing.horizontalXs(context),
            AppText.styledBodySmall(
              context,
              isExpanded
                  ? 'Show less'
                  : 'Show all ${transactions.length} transactions',
              color: AppColors.primaryAccent,
              weight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}
