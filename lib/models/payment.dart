import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a payment/transaction document from Firestore
class Payment {
  final String? id;
  final int amount;
  final String? companyId;
  final DateTime? createdAt;
  final String? currency;
  final int events;
  final bool isDisabled;
  final PaymentMetadata? metadata;
  final DateTime? modifiedAt;
  final String? organisationId;
  final String? paymentIntentId;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? productName;
  final String? packageName;
  final String? receiptUrl;
  final String? stripeCustomerId;
  final String? subscriptionId;
  final String? transactionId;
  final String? userEmail;
  final String? userId;

  // Free credit fields
  final bool isAssignedBySuperAdmin;
  final bool isFreeCredit;
  final String? assignedByEmail;
  final String? assignedByName;
  final String? assignedByUserId;
  final String? note;

  Payment({
    this.id,
    required this.amount,
    this.companyId,
    this.createdAt,
    this.currency,
    required this.events,
    this.isDisabled = false,
    this.metadata,
    this.modifiedAt,
    this.organisationId,
    this.paymentIntentId,
    this.paymentMethod,
    this.paymentStatus,
    this.productName,
    this.packageName,
    this.receiptUrl,
    this.stripeCustomerId,
    this.subscriptionId,
    this.transactionId,
    this.userEmail,
    this.userId,
    this.isAssignedBySuperAdmin = false,
    this.isFreeCredit = false,
    this.assignedByEmail,
    this.assignedByName,
    this.assignedByUserId,
    this.note,
  });

  /// Check if this is a free credit (assigned by super admin)
  bool get isFree => isAssignedBySuperAdmin || isFreeCredit || amount == 0;

  factory Payment.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Payment(
      id: docId ?? json['id'] as String?,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      companyId: json['companyId'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      currency: json['currency'] as String?,
      events: (json['events'] as num?)?.toInt() ?? 0,
      isDisabled: json['isDisabled'] as bool? ?? false,
      metadata: json['metadata'] != null
          ? PaymentMetadata.fromJson(
              Map<String, dynamic>.from(json['metadata']))
          : null,
      modifiedAt: _parseTimestamp(json['modifiedAt']),
      organisationId: json['organisationId'] as String?,
      paymentIntentId: json['paymentIntentId'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      productName: json['productName'] as String?,
      packageName: json['packageName'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      stripeCustomerId: json['stripeCustomerId'] as String?,
      subscriptionId: json['subscriptionId'] as String?,
      transactionId: json['transactionId'] as String?,
      userEmail: json['userEmail'] as String?,
      userId: json['userId'] as String?,
      // Free credit fields
      isAssignedBySuperAdmin: json['isAssignedBySuperAdmin'] as bool? ?? false,
      isFreeCredit: json['isFreeCredit'] as bool? ?? false,
      assignedByEmail: json['assignedByEmail'] as String?,
      assignedByName: json['assignedByName'] as String?,
      assignedByUserId: json['assignedByUserId'] as String?,
      note: json['note'] as String?,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Map) {
      // Handle Firestore timestamp format from cloud function
      final seconds = value['_seconds'] as int?;
      final nanoseconds = value['_nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
        );
      }
    }
    return null;
  }

  /// Display type for the transaction
  String get displayType => isFree ? 'Free Credit' : 'Purchase';

  /// Display source - who made the payment or who assigned the credit
  String get displaySource {
    if (isAssignedBySuperAdmin) {
      return 'Gifted by ${assignedByName ?? assignedByEmail ?? 'Super Admin'}';
    }
    return userEmail ?? 'Unknown';
  }

  /// Display package name with fallback
  String get displayPackageName {
    if (isFree) {
      return 'Free Events';
    }
    return packageName ?? productName ?? 'Event Package';
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      if (companyId != null) 'companyId': companyId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (currency != null) 'currency': currency,
      'events': events,
      'isDisabled': isDisabled,
      if (metadata != null) 'metadata': metadata!.toJson(),
      if (modifiedAt != null) 'modifiedAt': Timestamp.fromDate(modifiedAt!),
      if (organisationId != null) 'organisationId': organisationId,
      if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      if (productName != null) 'productName': productName,
      if (packageName != null) 'packageName': packageName,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      if (stripeCustomerId != null) 'stripeCustomerId': stripeCustomerId,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      if (transactionId != null) 'transactionId': transactionId,
      if (userEmail != null) 'userEmail': userEmail,
      if (userId != null) 'userId': userId,
      'isAssignedBySuperAdmin': isAssignedBySuperAdmin,
      'isFreeCredit': isFreeCredit,
      if (assignedByEmail != null) 'assignedByEmail': assignedByEmail,
      if (assignedByName != null) 'assignedByName': assignedByName,
      if (assignedByUserId != null) 'assignedByUserId': assignedByUserId,
      if (note != null) 'note': note,
    };
  }

  /// Formatted amount with currency
  String get formattedAmount {
    if (isFree) {
      return 'Free';
    }
    final currencySymbol = _getCurrencySymbol(currency);
    // Amount is in cents, convert to dollars
    final amountInDollars = amount / 100;
    return '$currencySymbol${amountInDollars.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String? currency) {
    switch (currency?.toLowerCase()) {
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      case 'gbp':
        return '£';
      default:
        return '\$';
    }
  }

  @override
  String toString() {
    return 'Payment(id: $id, amount: $amount, organisationId: $organisationId, paymentStatus: $paymentStatus)';
  }
}

/// Metadata associated with a payment
class PaymentMetadata {
  final String? events;
  final String? organisationId;
  final String? packageName;
  final String? userEmail;
  final String? userId;

  PaymentMetadata({
    this.events,
    this.organisationId,
    this.packageName,
    this.userEmail,
    this.userId,
  });

  factory PaymentMetadata.fromJson(Map<String, dynamic> json) {
    return PaymentMetadata(
      events: json['events'] as String?,
      organisationId: json['organisationId'] as String?,
      packageName: json['packageName'] as String?,
      userEmail: json['userEmail'] as String?,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (events != null) 'events': events,
      if (organisationId != null) 'organisationId': organisationId,
      if (packageName != null) 'packageName': packageName,
      if (userEmail != null) 'userEmail': userEmail,
      if (userId != null) 'userId': userId,
    };
  }
}
