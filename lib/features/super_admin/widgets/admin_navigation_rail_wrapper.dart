import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';
import 'package:trax_admin_portal/view/admin/widgets/sidebar.dart';
import 'package:trax_admin_portal/view/admin/widgets/sidebar_nav_tiles.dart';

/// Navigation rail wrapper for Super Admin
/// Contains only Events route and Logout button
class AdminNavigationRailWrapper extends StatefulWidget {
  final Widget child;
  const AdminNavigationRailWrapper({
    super.key,
    required this.child,
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
    if (location.startsWith(AppRoute.superAdminEvents.path)) return 0;
    return 0;
  }

  Future<void> _onTap(BuildContext context, int index) async {
    switch (index) {
      case 0:
        // Events
        pushAndRemoveAllRoute(AppRoute.superAdminEvents, context);
        return;
      case 1:
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
        label: 'Events',
        icon: Icons.event_outlined,
        selectedIcon: Icons.event,
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
