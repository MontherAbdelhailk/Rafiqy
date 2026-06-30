import 'package:dio/dio.dart';

abstract class ApiConsumer {
  Future<dynamic> get(String path, {Object? data, Map<String, dynamic>? queryParameters,Options? options});
  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? queryParameters, bool isFormData = false});
  Future<dynamic> patch(String path, {Object? data, Map<String, dynamic>? queryParameters, bool isFormData = false});
  Future<dynamic> delete(String path, {Object? data, Map<String, dynamic>? queryParameters});
}