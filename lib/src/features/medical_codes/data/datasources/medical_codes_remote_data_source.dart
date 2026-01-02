import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/entities/medical_code.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/import_all_result.dart';
import '../models/medical_code_model.dart';
import '../models/import_result_model.dart';
import '../models/import_all_result_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

abstract class MedicalCodesRemoteDataSource {
  Future<List<MedicalCode>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
    String? contentId,
  });
  Future<MedicalCode> getMedicalCodeById(String id);
  Future<ImportResult> importMedicalCodes(String filePath, String? contentId);
  Future<ImportAllResult> importAll({
    required String medicalCodesFilePath,
    String? contentsFilePath,
    String? category,
    String? bodySystem,
  });
  Future<List<Map<String, dynamic>>> exportMedicalCodes();
  Future<MedicalCode> createMedicalCode(Map<String, dynamic> data);
  Future<MedicalCode> updateMedicalCode(String id, Map<String, dynamic> data);
  Future<void> deleteMedicalCode(String id);
}

class MedicalCodesRemoteDataSourceImpl implements MedicalCodesRemoteDataSource {
  final DioClient dioClient;

  MedicalCodesRemoteDataSourceImpl(this.dioClient);

  @override
  Future<List<MedicalCode>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
    String? contentId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': 20,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (contentId != null && contentId.isNotEmpty) {
        queryParams['content_id'] = contentId;
      }

      final response = await dioClient.dio.get(
        '/medical-codes',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final codes = (data['data'] as List<dynamic>?)
              ?.map((e) => MedicalCodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return codes;
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load medical codes');
    }
  }

  @override
  Future<MedicalCode> getMedicalCodeById(String id) async {
    try {
      final response = await dioClient.dio.get('/medical-codes/$id');
      final data = response.data as Map<String, dynamic>;
      return MedicalCodeModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to load medical code');
    }
  }

  @override
  Future<ImportResult> importMedicalCodes(
      String filePath, String? contentId) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (contentId != null) 'content_id': contentId,
      });

      final response =
          await dioClient.dio.post('/admin/medical-codes/import', data: formData);
      final data = response.data as Map<String, dynamic>;
      return ImportResultModel.fromJson(data);
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to import medical codes');
    }
  }

  @override
  Future<ImportAllResult> importAll({
    required String medicalCodesFilePath,
    String? contentsFilePath,
    String? category,
    String? bodySystem,
  }) async {
    try {
      debugPrint('📤 Preparing import all request...');
      debugPrint('📁 Medical codes file path: $medicalCodesFilePath');
      debugPrint('📁 Contents file path: $contentsFilePath');
      
      // Verify medical codes file exists
      final medicalCodesFile = File(medicalCodesFilePath);
      if (!await medicalCodesFile.exists()) {
        throw ApiException('Medical codes file not found: $medicalCodesFilePath');
      }
      
      // Verify contents file exists if provided
      if (contentsFilePath != null && contentsFilePath.isNotEmpty) {
        final contentsFile = File(contentsFilePath);
        if (!await contentsFile.exists()) {
          throw ApiException('Contents file not found: $contentsFilePath');
        }
      }
      
      final formData = FormData.fromMap({
        'medical_codes_file': await MultipartFile.fromFile(medicalCodesFilePath),
        if (contentsFilePath != null && contentsFilePath.isNotEmpty)
          'contents_file': await MultipartFile.fromFile(contentsFilePath),
        if (category != null && category.isNotEmpty) 'category': category,
        if (bodySystem != null && bodySystem.isNotEmpty) 'body_system': bodySystem,
      });

      final endpoint = '/admin/import-all';
      final fullUrl = '${dioClient.dio.options.baseUrl}$endpoint';
      debugPrint('🌐 Sending POST request to: $endpoint');
      debugPrint('🌐 Full URL will be: $fullUrl');
      final response =
          await dioClient.dio.post(endpoint, data: formData);
      
      debugPrint('✅ Response received: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');
      
      final data = response.data as Map<String, dynamic>;
      
      // Check if response has status field
      if (data['status'] == 'error') {
        throw ApiException(
          data['message'] as String? ?? 'Import failed',
          statusCode: response.statusCode,
        );
      }
      
      // Verify required fields exist
      if (!data.containsKey('medical_codes')) {
        throw ApiException(
          'Invalid response: medical_codes field missing',
          statusCode: response.statusCode,
        );
      }
      
      return ImportAllResultModel.fromJson(data);
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.type}');
      debugPrint('❌ Message: ${e.message}');
      debugPrint('❌ Status Code: ${e.response?.statusCode}');
      debugPrint('❌ Response Data: ${e.response?.data}');
      
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          final errorMessage = responseData['message'] as String? ?? 
              (e.response!.statusCode == 404 
                  ? 'Endpoint not found. Please check server configuration.' 
                  : 'Failed to import all');
          throw ApiException(
            errorMessage,
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to import all: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportMedicalCodes() async {
    try {
      final response = await dioClient.dio.get('/admin/export/medical-codes');
      final data = response.data as Map<String, dynamic>;
      final rows = data['data'] as List<dynamic>? ?? [];
      return rows.map((e) => (e as Map).cast<String, dynamic>()).toList();
    } on DioException catch (e) {
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Export medical codes failed');
    }
  }

  @override
  Future<MedicalCode> createMedicalCode(Map<String, dynamic> data) async {
    try {
      final response = await dioClient.dio.post('/admin/medical-codes', data: data);
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] != 'success') {
        throw ApiException(responseData['message'] as String? ?? 'Failed to create medical code');
      }
      return MedicalCodeModel.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to create medical code',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to create medical code: ${e.message}');
    }
  }

  @override
  Future<MedicalCode> updateMedicalCode(String id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.dio.put('/admin/medical-codes/$id', data: data);
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] != 'success') {
        throw ApiException(responseData['message'] as String? ?? 'Failed to update medical code');
      }
      return MedicalCodeModel.fromJson(responseData['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to update medical code',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to update medical code: ${e.message}');
    }
  }

  @override
  Future<void> deleteMedicalCode(String id) async {
    try {
      final response = await dioClient.dio.delete('/admin/medical-codes/$id');
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['status'] != 'success') {
        throw ApiException(responseData['message'] as String? ?? 'Failed to delete medical code');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          throw ApiException(
            responseData['message'] as String? ?? 'Failed to delete medical code',
            statusCode: e.response!.statusCode,
          );
        }
      }
      throw e.error is Exception
          ? e.error as Exception
          : ApiException('Failed to delete medical code: ${e.message}');
    }
  }
}

