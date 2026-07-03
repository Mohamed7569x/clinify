import 'package:get/get.dart';
import '../controllers/doctor_controllers.dart';
import '../../shared/controllers/notification_controller.dart';

class DoctorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DoctorHomeController>(() => DoctorHomeController());
    Get.lazyPut<DoctorAppointmentsController>(
        () => DoctorAppointmentsController());
    Get.lazyPut<ScheduleController>(() => ScheduleController());
    Get.lazyPut<DoctorProfileController>(() => DoctorProfileController());
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
