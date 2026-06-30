import 'package:dio/dio.dart';
import 'package:rafiq/core/errors/error_handling.dart';
import 'package:rafiq/core/networking/api_intersectors.dart';
import 'api_consumer.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    // Using 10.0.2.2 allows the Android Emulator to connect to localhost:5000.
    // If you are testing on a real device, replace this with your machine's IP address.
    dio.options.baseUrl = "http://10.0.2.2:5000/api/"; 
    dio.interceptors.add(ApiInterceptors()); 
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  @override
  Future delete(String path, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.delete(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      handleDioException(e); // ميثود بتهندل أخطاء السيرفر
    }
  }

@override
Future get(String path, {Object? data, Map<String, dynamic>? queryParameters, Options? options}) async {
  try {
    final response = await dio.get(
      path, 
      data: data, 
      queryParameters: queryParameters, 
      options: options, 
    );
    return response.data;
  } on DioException catch (e) {
    handleDioException(e);
  }
}
  @override
  Future post(String path, {Object? data, Map<String, dynamic>? queryParameters, bool isFormData = false}) async {
    try {
      final response = await dio.post(
        path,
        data: (isFormData && data is! FormData)
            ? FormData.fromMap(data as Map<String, dynamic>)
            : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }

  @override
  Future patch(String path, {Object? data, Map<String, dynamic>? queryParameters, bool isFormData = false}) async {
    try {
      final response = await dio.patch(
        path,
        data: isFormData ? FormData.fromMap(data as Map<String, dynamic>) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioException(e);
    }
  }
}