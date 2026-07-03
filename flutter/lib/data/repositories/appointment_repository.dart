import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../app/config/api_config.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../models/appointment_model.dart';
import '../providers/api_provider.dart';
import '../providers/cache_service.dart';

class AppointmentRepository {
  final _api = Get.find<ApiProvider>();
  final _c = Get.find<CacheService>();

  String _appointmentsKey() {
    final auth = Get.find<AuthController>();
    final clinicId = auth.selectedClinic.value?.clinicId?.trim();

    if (clinicId == null || clinicId.isEmpty) {
      throw Exception('No active clinic selected');
    }

    return CK.appointments(clinicId);
  }

  Future<List<AppointmentModel>> listAppointments({
    String? status,
    String? date,
    bool forceRefresh = false,
  }) async {
    final params = <String, dynamic>{};

    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (date != null && date.isNotEmpty) {
      params['date'] = date;
    }

    // Only cache the full unfiltered list
    final useCache = params.isEmpty;

    if (useCache) {
      final data = await _c.cacheFirst(
        key: _appointmentsKey(),
        fetch: () => _api.get(
          '${ApiConfig.appointments}/mobile',
          queryParams: params,
        ),
        maxAge: const Duration(minutes: 3),
        forceRefresh: forceRefresh,
      );

      return (data as List)
          .map(
            (j) => AppointmentModel.fromJson(
          Map<String, dynamic>.from(j),
        ),
      )
          .toList();
    }

    // Filtered requests are always fresh
    debugPrint(
        'listAppointments -> selectedClinic='
            '${Get.find<AuthController>().selectedClinic.value?.clinicId}'
    );
    final data = await _api.get(
      '${ApiConfig.appointments}/mobile',
      queryParams: params,
    );

    return (data as List)
        .map(
          (j) => AppointmentModel.fromJson(
        Map<String, dynamic>.from(j),
      ),
    )
        .toList();
  }

  Future<AppointmentModel> getAppointment(String id) async {
    final data = await _api.get('${ApiConfig.appointments}/$id');
    return AppointmentModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required String date,
    required String startTime,
  }) async {
    final data = await _api.post(
      '${ApiConfig.appointments}/',
      body: {
        'doctor_id': doctorId,
        'date': date,
        'start_time': startTime,
      },
    );

    await _c.remove(_appointmentsKey());

    return AppointmentModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<AppointmentModel> updateStatus({
    required String appointmentId,
    required String status,
    String? cancellationReason,
    String? consultationNotes,
  }) async {
    final body = <String, dynamic>{
      'status': status,
    };

    if (cancellationReason != null) {
      body['cancellation_reason'] = cancellationReason;
    }
    if (consultationNotes != null) {
      body['consultation_notes'] = consultationNotes;
    }

    final data = await _api.put(
      '${ApiConfig.appointments}/$appointmentId/status',
      body: body,
    );

    await _c.remove(_appointmentsKey());

    return AppointmentModel.fromJson(Map<String, dynamic>.from(data));
  }
}