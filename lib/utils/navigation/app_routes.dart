// Routes definition using enums for better type safety and organization
enum AppRoute {

  // Base routes
  welcome('/welcome'),
  signup('/signup'),
  emailVerification('/email-verification'),

  // Super Admin routes
  superAdmin('/super-admin'),
  superAdminDashboard('/super-admin-dashboard'),
  superAdminEvents('/super-admin-events'),
  superAdminEventDetails('/super-admin-event-details/:eventId', 'eventId'),
  superAdminSalesPeople('/super-admin-sales-people'),
  superAdminManagement('/super-admin-management'),

  // Sales Person routes
  salesPerson('/sales-person'),
  salesPersonDashboard('/sales-person-dashboard'),
  salesPersonEvents('/sales-person-events'),
  salesPersonEventDetails('/sales-person-event-details/:eventId', 'eventId');

  static AppRoute? fromPath(String path) {
    final clean = path.split('?').first;

    AppRoute? best;
    int bestLen = -1;

    for (final r in AppRoute.values) {
      final base = r.path.split('/:').first; // e.g. /host-question-sets
      final matches = clean == base || clean.startsWith('$base/');
      if (matches && base.length > bestLen) {
        best = r;
        bestLen = base.length;
      }
    }
    return best;
  }

  final String path;
  final String? placeholder;

  const AppRoute(this.path, [this.placeholder]);
}
