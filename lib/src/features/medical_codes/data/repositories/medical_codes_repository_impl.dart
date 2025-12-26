import 'package:dartz/dartz.dart';
import '../../domain/repositories/medical_codes_repository.dart';
import '../../domain/entities/medical_code.dart';
import '../../domain/entities/import_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/medical_codes_remote_data_source.dart';

class MedicalCodesRepositoryImpl implements MedicalCodesRepository {
  final MedicalCodesRemoteDataSource remoteDataSource;

  MedicalCodesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<MedicalCode>>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
  }) async {
    try {
      final codes = await remoteDataSource.getMedicalCodes(
        page: page,
        search: search,
        category: category,
      );
      return Right(codes);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicalCode>> getMedicalCodeById(String id) async {
    try {
      final code = await remoteDataSource.getMedicalCodeById(id);
      return Right(code);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ImportResult>> importMedicalCodes(
    String filePath,
    String? contentId,
  ) async {
    try {
      final result = await remoteDataSource.importMedicalCodes(filePath, contentId);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportMedicalCodes() async {
    try {
      return await remoteDataSource.exportMedicalCodes();
    } catch (e) {
      return [];
    }
  }
}


