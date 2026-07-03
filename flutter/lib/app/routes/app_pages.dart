import 'package:get/get.dart';

import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/auth/views/splash_screen.dart';
import '../../modules/auth/views/clinic_id_screen.dart';
import '../../modules/auth/views/login_screen.dart';
import '../../modules/auth/views/register_screen.dart';

import '../../modules/patient/bindings/patient_binding.dart';
import '../../modules/patient/views/join_redirect_screen.dart';
import '../../modules/patient/views/patient_shell.dart';
import '../../modules/patient/views/doctor_detail_screen.dart';
import '../../modules/patient/views/remaining_screens.dart';

import '../../modules/doctor/bindings/doctor_binding.dart';
import '../../modules/doctor/views/doctor_shell.dart';
import '../../modules/doctor/views/doctor_all_screens.dart';

import '../../modules/shared/views/shared_screens.dart';

import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: '/join/branch/:slug',
      page: () => const JoinRedirectScreen(),
    ),
    GetPage(
      name: '/join/group/:slug',
      page: () => const JoinRedirectScreen(),
    ),
    GetPage(
      name: '/join/code/:code',
      page: () => const JoinRedirectScreen(),
    ),
    // Auth
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen(), binding: AuthBinding()),
    GetPage(name: AppRoutes.clinicId, page: () => ClinicIdScreen(), binding: AuthBinding()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),

    // Patient
    GetPage(
      name: AppRoutes.patient,
      page: () => const PatientShell(),
      binding: PatientBinding(),
      children: [
        GetPage(name: '/doctor-detail', page: () => const DoctorDetailScreen()),
        GetPage(name: '/booking', page: () => const BookingScreen()),
        GetPage(name: '/chat', page: () => const PatientChatScreen()),
        GetPage(name: '/prescriptions', page: () => const PrescriptionsScreen()),
        GetPage(name: '/review', page: () => const ReviewScreen()),
        GetPage(name: '/edit-profile', page: () => const EditProfileScreen()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen()),
        GetPage(name: '/announcements', page: () => const AnnouncementsScreen()),
      ],
    ),

    // Doctor
    GetPage(
      name: AppRoutes.doctor,
      page: () => const DoctorShell(),
      binding: DoctorBinding(),
      children: [
        GetPage(name: '/chat', page: () => const DoctorChatScreen()),
        GetPage(name: '/add-prescription', page: () => const AddPrescriptionScreen()),
        GetPage(name: '/prescriptions', page: () => const PrescriptionsScreen()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen()),
        GetPage(name: '/announcements', page: () => const AnnouncementsScreen()),
      ],
    ),
  ];

}
