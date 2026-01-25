import 'package:flutter/material.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';
// Removed unused imports after About/Contact navigation removal
import 'package:trax_admin_portal/utils/navigation/app_routes.dart';
import 'package:trax_admin_portal/utils/constantsOld.dart';
import 'package:trax_admin_portal/utils/navigation/routes.dart';

AppBar welcomeAppBar(BuildContext context) {
  return AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 70,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            pushAndRemoveAllRoute(AppRoute.welcome, context);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 20, left: 10),
            child: Image.asset(
              ConstantsOld.lightLogo,
              height: 50,
              color: AppColors.primaryOld(context),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  // Removed About and Contact navigation (only super admin/sales allowed)
                ],
              )
            ],
          ),
        )
      ],
    ),
  );
}
