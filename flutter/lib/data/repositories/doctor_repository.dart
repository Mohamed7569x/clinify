import 'package:get/get.dart';
import '../../app/config/api_config.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../models/doctor_model.dart';
import '../models/other_models.dart';
import '../providers/api_provider.dart';
import '../providers/cache_service.dart';

class DoctorRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  String _doctorsKey() {
    final auth = Get.find<AuthController>();
    final clinicId = auth.selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.doctors(clinicId);
  }

  Future<List<DoctorModel>> listDoctors({bool forceRefresh = false}) async {
    final data = await _c.cacheFirst(
      key: _doctorsKey(),
      fetch: () => _api.get(ApiConfig.doctors),
      maxAge: const Duration(minutes: 10),
      forceRefresh: forceRefresh,
    );

    return (data as List)
        .map(
          (j) => DoctorModel.fromJson(
        Map<String, dynamic>.from(j),
      ),
    )
        .toList();
  }

  Future<DoctorModel> getDoctor(String userId) async {
    final data = await _api.get('${ApiConfig.doctors}/$userId');
    return DoctorModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Slots are real-time — never cached
  Future<List<AvailableSlotModel>> getAvailableSlots({
    required String doctorId,
    required String date,
  }) async {
    final data = await _api.get(
      ApiConfig.availableSlots,
      queryParams: {
        'doctor_id': doctorId,
        'target_date': date,
      },
    );

    return (data as List)
        .map(
          (j) => AvailableSlotModel.fromJson(
        Map<String, dynamic>.from(j),
      ),
    )
        .toList();
  }
}