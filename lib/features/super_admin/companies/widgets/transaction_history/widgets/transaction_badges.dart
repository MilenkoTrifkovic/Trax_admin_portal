import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trax_admin_portal/helper/app_spacing.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
import 'package:trax_admin_portal/theme/styled_app_text.dart';

/// Badge for displaying payment status
class TransactionStatusBadge extends StatelessWidget {
  final String? status;

  const TransactionStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Badge for free credit/gift transactions
class FreeCreditBadge extends StatelessWidget {
  const FreeCreditBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs(context),
        vertical: AppSpacing.xxxs(context),
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 11,
            color: Colors.amber.shade700,
          ),
          SizedBox(width: 3),
          AppText.styledMetaSmall(
            context,
            'Gift',
            color: Colors.amber.shade700,
            weight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Row widget for displaying and copying transaction ID
class TransactionIdRow extends StatelessWidget {
  final String transactionId;

  const TransactionIdRow({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: () => _copyToClipboard(context),
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

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transactionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction ID copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Badge showing number of events
class EventsBadge extends StatelessWidget {
  final int events;
  final bool isFreeCredit;

  const EventsBadge({
    super.key,
    required this.events,
    this.isFreeCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm(context),
        vertical: AppSpacing.xxxs(context),
      ),
      decoration: BoxDecoration(
        color: isFreeCredit
            ? Colors.amber.withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event,
            size: 14,
            color: isFreeCredit ? Colors.amber.shade700 : AppColors.primary,
          ),
          SizedBox(width: 4),
          AppText.styledBodySmall(
            context,
            '$events events',
            color: isFreeCredit ? Colors.amber.shade700 : AppColors.primary,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
