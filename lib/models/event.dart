import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:trax_admin_portal/utils/enums/event_type.dart';
import 'package:trax_admin_portal/utils/enums/event_status.dart';
import 'package:trax_admin_portal/utils/enums/menu_category.dart';

class Event {
  final bool? isDisabled;
  final String? eventId;
  final String organisationId;
  final String venueId;
  final ServiceType serviceType;
  final String name;
  final String address;
  final int capacity;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime rsvpDeadline;
  final String eventType;
  final String timezone;
  final LatLng? location;
  final EventStatus status;
  List<MenuCategory> selectableCategories;
  List<String>? selectedMenus;

  // NEW fields required by controllers
  final String? selectedMenuId;
  final List<String>? selectedMenuItemIds;
  final String? selectedDemographicQuestionSetId;

  // Optional fields
  final XFile? coverImage;
  String? coverImageUrl;
  String? coverImageDownloadUrl;
  final String? description;
  final String? dressCode;
  final String? plannerEmail;
  final String? specialNotes;
  final bool hideHostInfo;
  final int maxInviteByGuest; // Maximum number of guests each invitee can bring (0-5)
  
  // Invitation letter fields
  final String? invitationLetterPath; // Storage path for the invitation letter file
  final String? invitationLetterUrl; // Download URL for the invitation letter file
  
  // Invitation code field
  final String? invitationCode; // Unique invitation code (e.g., WE2390RT)

  Event({
    this.isDisabled,
    this.eventId,
    required this.organisationId,
    required this.venueId,
    required this.serviceType,
    required this.name,
    required this.address,
    required this.capacity,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.rsvpDeadline,
    required this.eventType,
    required this.timezone,
    this.location,
    this.status = EventStatus.draft,
    this.coverImage,
    this.coverImageUrl,
    this.coverImageDownloadUrl,
    this.description,
    this.dressCode,
    this.plannerEmail,
    this.specialNotes,
    this.hideHostInfo = false,
    this.maxInviteByGuest = 0, // Default to 0
    this.selectableCategories = const [],
    this.selectedMenus,
    // new fields
    this.selectedMenuId,
    this.selectedMenuItemIds,
    this.selectedDemographicQuestionSetId,
    // invitation letter fields
    this.invitationLetterPath,
    this.invitationLetterUrl,
    // invitation code field
    this.invitationCode,
  });

  /// Creates an Event instance from a Firestore document
  factory Event.fromFirestore(dynamic doc) {
    final data = doc.data();

    // Safely parse location map (if present)
    final locMap = data['location'] as Map<String, dynamic>?;
    final location = locMap != null &&
            locMap['latitude'] != null &&
            locMap['longitude'] != null
        ? LatLng(
            (locMap['latitude'] as num).toDouble(),
            (locMap['longitude'] as num).toDouble(),
          )
        : null;

    // Parse timestamps (defensive: check existence)
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return (value).toDate();
      if (value is DateTime) return value;
      throw ArgumentError('Unsupported timestamp value: $value');
    }

    final startDateTime = data['startDateTime'] != null
        ? parseTimestamp(data['startDateTime'])
        : DateTime.now();
    final endDateTime = data['endDateTime'] != null
        ? parseTimestamp(data['endDateTime'])
        : DateTime.now();
    final rsvpDeadline = data['rsvpDeadline'] != null
        ? parseTimestamp(data['rsvpDeadline'])
        : DateTime.now();

    // read lists safely
    final selectedMenusList = (data['selectedMenus'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();

    final selectedMenuItemIdsList =
        (data['selectedMenuItemIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList();

    return Event(
      eventId: data['eventId'] as String?,
      organisationId: data['organisationId'] as String,
      venueId: data['venueId'] as String,
      name: data['name'] as String,
      address: data['address'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      date:
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
      startTime: TimeOfDay.fromDateTime(startDateTime),
      endTime: TimeOfDay.fromDateTime(endDateTime),
      rsvpDeadline: rsvpDeadline,
      eventType: data['eventType'] as String? ?? '',
      timezone: data['timezone'] as String? ?? 'UTC',
      location: location,
      status:
          EventStatusExtension.fromString(data['status'] as String? ?? 'draft'),
      coverImageUrl: data['coverImageUrl'] as String?,
      description: data['description'] as String?,
      dressCode: data['dressCode'] as String?,
      plannerEmail: data['plannerEmail'] as String?,
      specialNotes: data['specialNotes'] as String?,
      hideHostInfo: data['hideHostInfo'] as bool? ?? false,
      maxInviteByGuest: (data['maxInviteByGuest'] as num?)?.toInt() ?? 0,
      isDisabled: data['isDisabled'] as bool?,
      serviceType: ServiceType.values.firstWhere(
        (e) => e.name == (data['serviceType']),
        orElse: () => ServiceType.buffet,
      ),
      selectableCategories: (data['selectableMenuCategories'] as List<dynamic>?)
              ?.map((name) =>
                  MenuCategory.values.firstWhere((e) => e.name == name))
              .toList() ??
          [],
      selectedMenus: selectedMenusList,
      // NEW fields
      selectedMenuId: data['selectedMenuId'] as String?,
      selectedMenuItemIds: selectedMenuItemIdsList,
      selectedDemographicQuestionSetId:
          data['selectedDemographicQuestionSetId'] as String?,
      // invitation letter fields
      invitationLetterPath: data['invitationLetterPath'] as String?,
      invitationLetterUrl: data['invitationLetterUrl'] as String?,
      // invitation code field
      invitationCode: data['invitationCode'] as String?,
    );
  }



  /// Converts the Event instance to a JSON map for Firestore storage
  Map<String, dynamic> toJson() {
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    return {
      'eventId': eventId ?? '',
      'organisationId': organisationId,
      'venueId': venueId,
      'name': name,
      'address': address,
      'capacity': capacity,
      'startDateTime': Timestamp.fromDate(startDateTime.toUtc()),
      'endDateTime': Timestamp.fromDate(endDateTime.toUtc()),
      'rsvpDeadline': Timestamp.fromDate(rsvpDeadline.toUtc()),
      'eventType': eventType,
      'timezone': timezone,
      'location': location != null
          ? {
              'latitude': location!.latitude,
              'longitude': location!.longitude,
            }
          : null,
      'description': description,
      'dressCode': dressCode,
      'plannerEmail': plannerEmail,
      'specialNotes': specialNotes,
      'hideHostInfo': hideHostInfo,
      'maxInviteByGuest': maxInviteByGuest,
      'coverImageUrl': coverImageUrl,
      'serviceType': serviceType.name,
      'status': status.statusName,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'selectableMenuCategories':
          selectableCategories.map((e) => e.name).toList(),
      'selectedMenus': selectedMenus ?? [],
      // NEW fields included
      'selectedMenuId': selectedMenuId,
      'selectedMenuItemIds': selectedMenuItemIds ?? [],
      'selectedDemographicQuestionSetId': selectedDemographicQuestionSetId,
      'isDisabled': isDisabled ?? false,
      // invitation letter fields
      'invitationLetterPath': invitationLetterPath,
      'invitationLetterUrl': invitationLetterUrl,
      // invitation code field
      'invitationCode': invitationCode,
    };
  }

  /// Creates a copy of this Event with the specified fields replaced
  Event copyWith({
    String? eventId,
    String? id,
    String? organisationId,
    String? venueId,
    ServiceType? serviceType,
    String? name,
    String? address,
    int? capacity,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? rsvpDeadline,
    String? eventType,
    String? timezone,
    LatLng? location,
    EventStatus? status,
    XFile? coverImage,
    String? coverImageUrl,
    String? coverImageDownloadUrl,
    String? description,
    String? dressCode,
    String? plannerEmail,
    String? specialNotes,
    bool? hideHostInfo,
    int? maxInviteByGuest,
    List<MenuCategory>? selectableCategories,
    bool? isDisabled,
    // NEW copyWith options:
    List<String>? selectedMenus,
    String? selectedMenuId,
    List<String>? selectedMenuItemIds,
    String? selectedDemographicQuestionSetId,
    // invitation letter options
    String? invitationLetterPath,
    String? invitationLetterUrl,
    // invitation code option
    String? invitationCode,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      organisationId: organisationId ?? this.organisationId,
      venueId: venueId ?? this.venueId,
      serviceType: serviceType ?? this.serviceType,
      name: name ?? this.name,
      address: address ?? this.address,
      capacity: capacity ?? this.capacity,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rsvpDeadline: rsvpDeadline ?? this.rsvpDeadline,
      eventType: eventType ?? this.eventType,
      timezone: timezone ?? this.timezone,
      location: location ?? this.location,
      status: status ?? this.status,
      coverImage: coverImage ?? this.coverImage,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageDownloadUrl:
          coverImageDownloadUrl ?? this.coverImageDownloadUrl,
      description: description ?? this.description,
      dressCode: dressCode ?? this.dressCode,
      plannerEmail: plannerEmail ?? this.plannerEmail,
      specialNotes: specialNotes ?? this.specialNotes,
      hideHostInfo: hideHostInfo ?? this.hideHostInfo,
      maxInviteByGuest: maxInviteByGuest ?? this.maxInviteByGuest,
      selectableCategories: selectableCategories ?? this.selectableCategories,
      isDisabled: isDisabled ?? this.isDisabled,
      selectedMenus: selectedMenus ?? this.selectedMenus,
      selectedMenuId: selectedMenuId ?? this.selectedMenuId,
      selectedMenuItemIds: selectedMenuItemIds ?? this.selectedMenuItemIds,
      selectedDemographicQuestionSetId: selectedDemographicQuestionSetId ??
          this.selectedDemographicQuestionSetId,
      invitationLetterPath: invitationLetterPath ?? this.invitationLetterPath,
      invitationLetterUrl: invitationLetterUrl ?? this.invitationLetterUrl,
      invitationCode: invitationCode ?? this.invitationCode,
    );
  }

  @override
  String toString() {
    return '''
Event {
  eventId: $eventId
  invitationCode: $invitationCode
  organisationId: $organisationId
  serviceType: $serviceType
  name: $name
  address: $address
  capacity: $capacity
  date: $date
  startTime: $startTime
  endTime: $endTime
  rsvpDeadline: $rsvpDeadline
  eventType: $eventType
  timezone: $timezone
  location: $location
  status: $status
  coverImage: ${coverImage?.path}
  description: $description
  dressCode: $dressCode
  plannerEmail: $plannerEmail
  specialNotes: $specialNotes
  hideHostInfo: $hideHostInfo
  downloadURL: $coverImageDownloadUrl
  selectableCategories: $selectableCategories
  selectedMenus: $selectedMenus
  selectedMenuId: $selectedMenuId
  selectedMenuItemIds: $selectedMenuItemIds
  selectedDemographicQuestionSetId: $selectedDemographicQuestionSetId
  isDisabled: $isDisabled
}''';
  }
}
