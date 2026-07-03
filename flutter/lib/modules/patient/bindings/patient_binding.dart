import 'package:get/get.dart';
import '../controllers/patient_controllers.dart';
import '../../shared/controllers/notification_controller.dart';

class PatientBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true → controllers are recreated if disposed, but not duplicated
    Get.lazyPut<PatientHomeController>(() => PatientHomeController(), fenix: true);
    Get.lazyPut<PatientShellController>(() => PatientShellController(), fenix: true);
    Get.lazyPut<DoctorListController>(() => DoctorListController(), fenix: true);
    Get.lazyPut<PatientAppointmentsController>(() => PatientAppointmentsController(), fenix: true);
    Get.lazyPut<PatientProfileController>(() => PatientProfileController(), fenix: true);
    Get.lazyPut<NotificationController>(() => NotificationController(), fenix: true);
  }
}