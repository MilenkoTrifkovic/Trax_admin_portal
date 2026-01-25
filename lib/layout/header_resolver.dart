import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/widgets/app_bar_custom.dart';

/// Returns the header widget for a given route state.
/// 
/// For super admin and sales person portal - simplified header resolution
Widget getPageHeader(GoRouterState state, {BuildContext? context}) {
  // Use context-based state if available for more accurate location
  final location = context != null 
      ? GoRouterState.of(context).uri.toString()
      : state.matchedLocation;
  
  print('Header resolver - location: $location');
  
  // Super admin and sales person don't need headers for event list pages
  if (location == AppRoute.superAdminEvents.path) {
    return const SizedBox.shrink();
  }
  
  if (location == AppRoute.salesPersonEvents.path) {
    return const SizedBox.shrink();
  }
  

  return const SizedBox.shrink();
}

/// Extracts eventId from a path like /event-details/abc123/guest-preview
String? _extractEventIdFromPath(String path) {
  final regex = RegExp(r'/event-details/([^/]+)');
  final match = regex.firstMatch(path);
  return match?.group(1);
}
