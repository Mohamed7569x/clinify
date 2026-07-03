import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../app/config/api_config.dart';
import '../../data/providers/storage_provider.dart';

class ApiInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  ApiInterceptor(this._dio);

  StorageProvider get _storage => Get.find<StorageProvider>();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Attach token to every request except auth endpoints
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          _forceLogout();
          return handler.next(err);
        }

        // Call refresh endpoint
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
        final response = await refreshDio.post(
          ApiConfig.refreshToken,
          options: Options(headers: {'Cookie': 'refresh_token=$refreshToken'}),
        );

        if (response.statusCode == 200) {
          final newAccess = response.data['access_token'];
          final newRefresh = response.data['refresh_token'];

          await _storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );

          // Retry the original request with new token
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccess';

          final retryResponse = await _dio.fetch(retryOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        } else {
          _forceLogout();
        }
      } catch (_) {
        _forceLogout();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }

  void _forceLogout() {
    _isRefreshing = false;
    _storage.clearAll();
    Get.offAllNamed('/clinic-id');
  }
}
