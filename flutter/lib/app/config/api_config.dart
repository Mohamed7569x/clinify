class ApiConfig {
  // ── Change this to your server URL ──
  static const String baseUrl = 'https://clinify.space-x-tv.shop'; // Android emulator → localhost
  // static const String baseUrl = 'http://localhost:8000';   // iOS simulator
  // static const String baseUrl = 'https://your-domain.com'; // Production

  static const String apiPrefix = '/api/v1';
  static const Duration timeout = Duration(seconds: 30);

  // ── Auth ──
  static const String managerLogin = '$apiPrefix/auth/manager/login/';
  static const String clinicLogin = '$apiPrefix/auth/clinic/login/';
  static const String patientRegister = '$apiPrefix/auth/patient/register/';
  static const String refreshToken = '$apiPrefix/auth/refresh/';
  static const String logout = '$apiPrefix/auth/logout/';

  // ── Clinic ──
  static const String clinicProfile = '$apiPrefix/clinic/profile';
  static const String clinicDashboard = '$apiPrefix/clinic/dashboard';

  // ── Doctors ──
  static const String doctors = '$apiPrefix/doctors/';

  // ── Patients ──
  static const String patients = '$apiPrefix/patients/';
  static const String patientMe = '$apiPrefix/patients/me';

  // ── Specialties ──
  static const String specialties = '$apiPrefix/specialties/';

  // ── Appointments ──
  static const String appointments = '$apiPrefix/appointments/';
  static const String availableSlots = '$apiPrefix/appointments/available-slots';

  // ── Notifications ──
  static const String notifications = '$apiPrefix/notifications/';
  static const String notificationsUnreadCount = '$apiPrefix/notifications/unread-count';
  static const String notificationsReadAll = '$apiPrefix/notifications/read-all';

  // ── Announcements ──
  static const String announcements = '$apiPrefix/announcements/';

  // ── Schedules ──
  static const String schedules = '$apiPrefix/schedules/';
  static const String blockedSlots = '$apiPrefix/blocked-slots/';
}
