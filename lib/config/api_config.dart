class ApiConfig {
  // Backend API base URL — production Cloud Run
  // NestJS backend on the production VPS (routes are versioned under /api/v1)
  static const String baseUrl = 'http://72.60.190.211:4000/api/v1';

  // Authentication
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Driver packages
  static String driverPackages(int driverId) => '/drivers/$driverId/packages';

  // Driver actions (from mobile app)
  static const String driverDeliver = '/drivers/deliver';
  static const String driverFail = '/drivers/fail';
  static const String driverRecordCall = '/drivers/record-call';

  // Ramassage (pickup)
  static const String ramassage = '/drivers/ramassage';
  static const String driverPickupCollected = '/drivers/pickup-collected';
}
