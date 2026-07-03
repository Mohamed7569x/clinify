import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;
import '../../app/config/api_config.dart';
import '../../core/errors/api_exceptions.dart';
import '../../core/network/api_interceptor.dart';

class ApiProvider extends GetxService {
  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(ApiInterceptor(_dio));
  }

  // ── GET ──
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST ──
  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PUT ──
  Future<dynamic> put(
    String path, {
    dynamic body,
  }) async {
    try {
      final response = await _dio.put(path, data: body);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── PATCH ──
  Future<dynamic> patch(
    String path, {
    dynamic body,
  }) async {
    try {
      final response = await _dio.patch(path, data: body);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── DELETE ──
  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── POST form (for manager login which uses OAuth2 form) ──
  Future<dynamic> postForm(
    String path, {
    required Map<String, dynamic> formData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: FormData.fromMap(formData),
        options: Options(contentType: 'application/x-www-form-urlencoded'),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error Handler ──
  ApiException _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    String message = 'Something went wrong.';

    if (data is Map<String, dynamic>) {
      message = data['detail']?.toString() ?? message;
      // Handle validation errors
      if (data['detail'] is List) {
        final errors = data['detail'] as List;
        message = errors.map((e) => e['msg'] ?? '').join(', ');
      }
    }

    switch (statusCode) {
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      default:
        return ApiException(message, statusCode: statusCode);
    }
  }
}
