import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';
import 'package:trax_admin_portal/view/admin/widgets/sidebar.dart';
import 'package:trax_admin_portal/view/admin/widgets/sidebar_nav_tiles.dart';

/// Navigation rail wrapper for Super Admin and Sales Person
/// Contains Dashboard, Events, Sales People (conditionally), and Logout
class AdminNavigationRailWrapper extends StatefulWidget {
  final Widget child;
  final bool hideSalesPeople;
  final AppRoute dashboardRoute;
  final AppRoute eventsRoute;
  
  const AdminNavigationRailWrapper({
    super.key,
    required this.child,
    this.hideSalesPeople = false,
    required this.dashboardRoute,
    required this.eventsRoute,
  });

  @override
  State<AdminNavigationRailWrapper> createState() =>
      _AdminNavigationRailWrapperState();
}

class _AdminNavigationRailWrapperState extends State<AdminNavigationRailWrapper>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();

  late final AnimationController _introCtrl;
  late final Animation<Offset> _sidebarSlide;
  late final Animation<double> _sidebarFade;
  late final Animation<double> _contentFade;

  static bool _hasPlayedIntro = false;
  bool _isExpanded = true; // Track expanded/collapsed state
  bool _initialStateSet = false;

  int _selectedIndexForLocation(String location) {
    if (location.startsWith(widget.dashboardRoute.path)) return 0;
    if (location.startsWith(widget.eventsRoute.path)) return 1;
    if (!widget.hideSalesPeople && location.startsWith(AppRoute.superAdminSalesPeople.path)) return 2;
    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async {
    // Adjust index mapping based on whether Sales People is hidden
    if (widget.hideSalesPeople) {
      switch (index) {
        case 0:
          // Dashboard
          pushAndRemoveAllRoute(widget.dashboardRoute, context);
          return;
        case 1:
          // Events
          pushAndRemoveAllRoute(widget.eventsRoute, context);
          return;
        case 2:
          // Logout
          try {
            await authController.logout();
          } catch (_) {}
          if (context.mounted) {
            pushAndRemoveAllRoute(AppRoute.welcome, context);
          }
          return;
      }
    } else {
      switch (index) {
        case 0:
          // Dashboard
          pushAndRemoveAllRoute(widget.dashboardRoute, context);
          return;
        case 1:
          // Events
          pushAndRemoveAllRoute(widget.eventsRoute, context);
          return;
        case 2:
          // Sales People
          pushAndRemoveAllRoute(AppRoute.superAdminSalesPeople, context);
          return;
        case 3:
          // Logout
          try {
            await authController.logout();
          } catch (_) {}
          if (context.mounted) {
            pushAndRemoveAllRoute(AppRoute.welcome, context);
          }
          return;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _sidebarSlide = Tween<Offset>(
      begin: const Offset(-0.18, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));

    _sidebarFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _contentFade = CurvedAnimation(
      parent: _introCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );

    if (_hasPlayedIntro) {
      _introCtrl.value = 1;
    } else {
      _hasPlayedIntro = true;
      _introCtrl.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Set initial collapsed state for phones
    if (!_initialStateSet) {
      _initialStateSet = true;
      if (ScreenSize.isPhone(context)) {
        _isExpanded = false;
      }
    }
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final int selectedIndex = _selectedIndexForLocation(location);

    // Auto-collapse on phone screens
    final bool isPhone = ScreenSize.isPhone(context);
    final bool shouldBeExpanded = isPhone ? _isExpanded : _isExpanded;

    final items = <NavItemData>[
      const NavItemData(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      const NavItemData(
        label: 'Events',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
      ),
      if (!widget.hideSalesPeople)
        const NavItemData(
          label: 'Sales People',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
        ),
      const NavItemData(
        label: 'Logout',
        icon: Icons.logout_outlined,
        selectedIcon: Icons.logout,
      ),
    ];

    // Super Admin title
    const organisationName = 'Super Admin';

    final sidebarWidget = SlideTransition(
      position: _sidebarSlide,
      child: FadeTransition(
        opacity: _sidebarFade,
        child: Sidebar(
          selectedIndex: selectedIndex,
          items: items,
          onTap: (i) => _onTap(context, i),
          isExpanded: shouldBeExpanded,
          organisationName: organisationName,
          organisationPhotoUrl: null, // No photo for super admin
          onToggleExpand: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
      ),
    );

    final contentWidget = FadeTransition(
      opacity: _contentFade,
      child: widget.child,
    );

    // On phone: Stack layout (overlay) | On larger screens: Row layout (push)
    if (isPhone) {
      return Stack(
        children: [
          // Content with left padding when collapsed (pushes content)
          Padding(
            padding: EdgeInsets.only(left: _isExpanded ? 0 : 72.0),
            child: contentWidget,
          ),

          // Backdrop/scrim when expanded
          if (_isExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),

          // Navigation rail (overlay)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: sidebarWidget,
          ),
        ],
      );
    }

    // Larger screens: Row layout (pushes content)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sidebarWidget,
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: contentWidget),
      ],
    );
  }
}
