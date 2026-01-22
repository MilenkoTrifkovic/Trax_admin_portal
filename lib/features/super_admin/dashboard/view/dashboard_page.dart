import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trax_admin_portal/controller/auth_controller/auth_controller.dart';
import 'package:trax_admin_portal/features/super_admin/dashboard/controllers/dashboard_controller.dart';
import 'package:trax_admin_portal/features/super_admin/dashboard/widgets/dashboard_empty_state.dart';
import 'package:trax_admin_portal/features/super_admin/dashboard/widgets/metric_card.dart';
import 'package:trax_admin_portal/helper/screen_size.dart';
import 'package:trax_admin_portal/theme/app_colors.dart';

/// Main dashboard page for super admin
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController controller;
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DashboardController());
    authController = Get.find<AuthController>();
  }

  @override
  void dispose() {
    Get.delete<DashboardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildHeader(),
            
            const SizedBox(height: 32),
            
            // Dashboard Content
            Expanded(
              child: Obx(() {
                // Show loading indicator when loading and no data
                if (controller.isLoading.value && _hasNoData()) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                // Show empty state when not loading and no data
                if (!controller.isLoading.value && _hasNoData()) {
                  return DashboardEmptyState(
                    onRefresh: controller.refreshDashboard,
                  );
                }
                
                // Show dashboard content
                return _buildDashboardContent(context);
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Check if all metrics are zero
  bool _hasNoData() {
    return controller.guestsCount.value == 0 &&
        controller.eventsCount.value == 0 &&
        controller.organisationsCount.value == 0 &&
        controller.salesPeopleCount.value == 0;
  }
  
  /// Build page header
  Widget _buildHeader() {
    final isSalesPerson = authController.isSalesPerson;
    final isPhone = ScreenSize.isPhone(context);
    final subtitle = isSalesPerson
        ? 'Small wins add up. Take a moment to see what you’ve achieved.'
        : 'Overview of your admin portal';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: isPhone ? 24.0 : 28.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: isPhone ? 13.0 : 14.0,
                color: AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        ),
        const SizedBox(width: 12),
        // Refresh Button
        Obx(() => IconButton(
          onPressed: controller.isLoading.value 
              ? null 
              : controller.refreshDashboard,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Dashboard',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            foregroundColor: AppColors.primary,
          ),
        )),
      ],
    );
  }
  
  /// Build dashboard content with responsive grid
  Widget _buildDashboardContent(BuildContext context) {
    final isMobile = ScreenSize.isPhone(context);
    final isSalesPerson = authController.isSalesPerson;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Section
          Text(
            'Key Metrics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Metrics Grid - using LayoutBuilder + Wrap for content-based sizing
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              // Calculate card width based on screen size
              // Mobile: full width, Tablet: 2 cards, Desktop: 3-4 cards
              final cardWidth = isMobile 
                  ? availableWidth 
                  : (availableWidth < 900 
                      ? (availableWidth - 16) / 2 
                      : (isSalesPerson 
                          ? (availableWidth - 32) / 3 
                          : (availableWidth - 48) / 4));
              
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  // Guests Card
                  SizedBox(
                    width: cardWidth,
                    child: Obx(() => MetricCard(
                      icon: Icons.people_outline,
                      label: 'Total Guests',
                      value: controller.guestsCount.value,
                      iconColor: const Color(0xFF2563EB),
                      isLoading: controller.isLoading.value,
                    )),
                  ),
                  
                  // Events Card
                  SizedBox(
                    width: cardWidth,
                    child: Obx(() => MetricCard(
                      icon: Icons.event_outlined,
                      label: 'Total Events',
                      value: controller.eventsCount.value,
                      iconColor: const Color(0xFF10B981),
                      isLoading: controller.isLoading.value,
                    )),
                  ),
                  
                  // Organisations Card
                  SizedBox(
                    width: cardWidth,
                    child: Obx(() => MetricCard(
                      icon: Icons.business_outlined,
                      label: 'Total Organisations',
                      value: controller.organisationsCount.value,
                      iconColor: const Color(0xFFF59E0B),
                      isLoading: controller.isLoading.value,
                    )),
                  ),
                  
                  // Sales People Card (hidden for salespeople)
                  if (!isSalesPerson)
                    SizedBox(
                      width: cardWidth,
                      child: Obx(() => MetricCard(
                        icon: Icons.badge_outlined,
                        label: 'Total Sales People',
                        value: controller.salesPeopleCount.value,
                        iconColor: const Color(0xFF8B5CF6),
                        isLoading: controller.isLoading.value,
                      )),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
