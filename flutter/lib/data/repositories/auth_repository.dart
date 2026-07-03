import 'package:get/get.dart';
import '../../app/config/api_config.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';


class AuthRepository {
  final ApiProvider _api = Get.find<ApiProvider>();
  final StorageProvider _storage = Get.find<StorageProvider>();

  /// Login for doctor or patient using clinic ID + identifier + password.
  /// Returns the full response map on success.
  ///

  Future<Map<String, dynamic>> clinicLogin({
    required String clinicId,
    required String identifier,
    required String password,
  }) async {
    final data = await _api.post(
      ApiConfig.clinicLogin,
      body: {
        'clinic_id': clinicId,
        'identifier': identifier,
        'password': password,
      },
    );

    // Persist tokens and user info
    await _storage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
    await _storage.saveUserInfo(
      clinicId: data['clinic_id'],
      role: data['role'],
    );

    return Map<String, dynamic>.from(data);
  }
  Future<Map<String, dynamic>> resolveClinicByCode(String code) async {
    final encoded = Uri.encodeComponent(code);
    final res = await _api.get('/api/v1/join/resolve/code/$encoded');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> resolveBranchBySlug(String slug) async {
    final encoded = Uri.encodeComponent(slug);
    final res = await _api.get('/api/v1/join/resolve/branch/$encoded');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> resolveGroupBySlug(String slug) async {
    final encoded = Uri.encodeComponent(slug);
    final res = await _api.get('/api/v1/join/resolve/group/$encoded');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> searchClinics(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final res = await _api.get('/api/v1/join/search?q=$encoded');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getMyClinics() async {
    final res = await _api.get('/api/v1/auth/my-clinics/');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> switchClinic(String clinicId) async {
    final data = await _api.post(
      '/api/v1/auth/switch-clinic/',
      body: {
        'clinic_id': clinicId,
      },
    );

    final map = Map<String, dynamic>.from(data as Map);

    await _storage.saveTokens(
      accessToken: map['access_token'],
      refreshToken: map['refresh_token'],
    );

    await _storage.saveUserInfo(
      clinicId: map['clinic_id'],
      role: map['role'],
    );

    return map;
  }


  /// Patient self-registration
  Future<Map<String, dynamic>> registerPatient({
    required String clinicId,
    required String name,
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'clinic_id': clinicId,
      'name': name,
      'password': password,
    };
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phone_number'] = phoneNumber;
    }

    final data = await _api.post(ApiConfig.patientRegister, body: body);
    return Map<String, dynamic>.from(data);
  }

  /// Check if the user has a saved session
  Future<bool> hasSession() async {
    return await _storage.hasValidSession();
  }

  /// Get the saved user role
  Future<String?> getSavedRole() async {
    return await _storage.getUserRole();
  }

  /// Get the saved clinic ID
  Future<String?> getSavedClinicId() async {
    return await _storage.getClinicId();
  }

  /// Logout — clear cookie + local storage
  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } catch (_) {
      // Even if the API call fails, clear local data
    }
    await _storage.clearAll();
  }
}
