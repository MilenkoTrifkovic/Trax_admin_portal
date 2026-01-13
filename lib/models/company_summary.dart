/// Model representing a company summary with event counts and salesperson info
class CompanySummary {
  final String organisationId;
  final String companyName;
  final int eventCount;
  final String? salesPersonId;
  final String? salesPersonName;
  final String? salesPersonEmail;
  final DateTime? createdAt;

  CompanySummary({
    required this.organisationId,
    required this.companyName,
    required this.eventCount,
    this.salesPersonId,
    this.salesPersonName,
    this.salesPersonEmail,
    this.createdAt,
  });

  factory CompanySummary.fromMap(Map<String, dynamic> map) {
    return CompanySummary(
      organisationId: map['organisationId'] as String,
      companyName: map['companyName'] as String,
      eventCount: map['eventCount'] as int? ?? 0,
      salesPersonId: map['salesPersonId'] as String?,
      salesPersonName: map['salesPersonName'] as String?,
      salesPersonEmail: map['salesPersonEmail'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organisationId': organisationId,
      'companyName': companyName,
      'eventCount': eventCount,
      'salesPersonId': salesPersonId,
      'salesPersonName': salesPersonName,
      'salesPersonEmail': salesPersonEmail,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  CompanySummary copyWith({
    String? organisationId,
    String? companyName,
    int? eventCount,
    String? salesPersonId,
    String? salesPersonName,
    String? salesPersonEmail,
    DateTime? createdAt,
  }) {
    return CompanySummary(
      organisationId: organisationId ?? this.organisationId,
      companyName: companyName ?? this.companyName,
      eventCount: eventCount ?? this.eventCount,
      salesPersonId: salesPersonId ?? this.salesPersonId,
      salesPersonName: salesPersonName ?? this.salesPersonName,
      salesPersonEmail: salesPersonEmail ?? this.salesPersonEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CompanySummary(organisationId: $organisationId, companyName: $companyName, eventCount: $eventCount, salesPersonName: $salesPersonName)';
  }
}
