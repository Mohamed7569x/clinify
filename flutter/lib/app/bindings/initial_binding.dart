import 'package:get/get.dart';
import '../../data/providers/api_provider.dart';
import '../../data/providers/storage_provider.dart';
import '../../data/providers/cache_service.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/shared/controllers/notification_controller.dart';
// Uncomment after Firebase setup:
import '../../firebase_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StorageProvider(), permanent: true);
    Get.put(ApiProvider(), permanent: true);
    Get.put(CacheService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    // Uncomment after Firebase setup:
    Get.put(FirebaseService(), permanent: true);
    Get.lazyPut<NotificationController>(() => NotificationController(), fenix: true);
  }
}