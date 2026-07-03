import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../app/config/app_constants.dart';

class StorageProvider extends GetxService {
  late final FlutterSecureStorage _storage;

  @override
  void onInit() {
    super.onInit();
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
  }

  // ── Token ──

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  // ── User Info ──

  Future<void> saveUserInfo({
    required String clinicId,
    required String role,
    String? name,
    String? email,
  }) async {
    await _storage.write(key: AppConstants.clinicIdKey, value: clinicId);
    await _storage.write(key: AppConstants.userRoleKey, value: role);
    if (name != null) {
      await _storage.write(key: AppConstants.userNameKey, value: name);
    }
    if (email != null) {
      await _storage.write(key: AppConstants.userEmailKey, value: email);
    }
  }

  Future<String?> getClinicId() async {
    return await _storage.read(key: AppConstants.clinicIdKey);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: AppConstants.userRoleKey);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: AppConstants.userNameKey);
  }

  // ── Session Check ──

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final role = await getUserRole();
    return token != null && token.isNotEmpty && role != null;
  }

  // ── Clear ──

  Future<void> clearAll() async {
    // Save FCM token before clearing — it should persist across logout
    final fcm = await getFcmToken();
    await _storage.deleteAll();
    if (fcm != null) await saveFcmToken(fcm);
  }

  // ── FCM Token ──

  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: 'fcm_token', value: token);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: 'fcm_token');
  }
}