import 'package:dio/dio.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class ApiInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept-Language'] = 'ar';

    // Attach JWT Bearer token if available
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // On 401, clear token — user needs to re-login
    if (err.response?.statusCode == 401) {
      SecureStorage.clearAll();
    }
    super.onError(err, handler);
  }
}