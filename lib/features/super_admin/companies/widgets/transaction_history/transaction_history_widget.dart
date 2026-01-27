import 'package:flutter/material.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/models/payment.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

import 'widgets/transaction_empty_state.dart';
import 'widgets/transaction_header.dart';
import 'widgets/transaction_list_item.dart';
import 'widgets/transaction_toggle_button.dart';

/// Widget for displaying transaction history as a list
class TransactionHistoryWidget extends StatelessWidget {
  final List<Payment> transactions;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onGiveFreeEvents;

  const TransactionHistoryWidget({
    super.key,
    required this.transactions,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onGiveFreeEvents,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return TransactionEmptyState(
        onGiveFreeEvents: onGiveFreeEvents,
      );
    }

    return _TransactionHistoryContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TransactionHeader(
            transactionCount: transactions.length,
            onGiveFreeEvents: onGiveFreeEvents,
          ),
          const Divider(height: 1),
          _buildTransactionList(context),
          if (transactions.length > 3)
            TransactionToggleButton(
              isExpanded: isExpanded,
              totalCount: transactions.length,
              onToggle: onToggleExpand,
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final displayedTransactions = (isExpanded || transactions.length <= 3)
        ? transactions
        : transactions.take(3).toList();

    return Column(
      children: displayedTransactions.asMap().entries.map((entry) {
        return TransactionListItem(
          transaction: entry.value,
          index: entry.key,
          isPhone: isPhone,
        );
      }).toList(),
    );
  }
}

/// Container widget for the transaction history
class _TransactionHistoryContainer extends StatelessWidget {
  final Widget child;

  const _TransactionHistoryContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
