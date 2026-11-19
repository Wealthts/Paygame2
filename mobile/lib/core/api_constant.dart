/// Shared server and storage constants for Mobile API clients.
/// Keep report endpoints as server-relative paths; ApiService adds baseUrl.
abstract final class ApiConstant {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authResetPassword = '/api/auth/reset-password';

  static const String games = '/api/games';
  static const String packages = '/api/packages';
  static const String orders = '/api/orders';
  static const String payments = '/api/payments';
  static const String points = '/api/points';
  static const String coupons = '/api/coupons';
  static const String userCoupons = '/api/user-coupons';
  static const String receipts = '/api/receipts';
  static const String users = '/api/users';

  // Admin report endpoints share one place for route names and tests.
  static const String adminReportsSummary = '/api/admin/reports/summary';
  static const String adminReportsMonthlyRevenue =
      '/api/admin/reports/monthly-revenue';
  static const String adminReportsTopGames = '/api/admin/reports/top-games';
  static const String adminReportsOrderStatuses =
      '/api/admin/reports/order-statuses';

  static const String authTokenKey = 'auth_token';
  static const String authUserKey = 'auth_user';
}
