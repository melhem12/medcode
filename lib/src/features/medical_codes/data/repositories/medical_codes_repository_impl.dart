import 'package:dartz/dartz.dart';
import '../../domain/repositories/medical_codes_repository.dart';
import '../../domain/entities/medical_code.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/import_all_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/medical_codes_remote_data_source.dart';
import '../datasources/medical_codes_local_data_source.dart';

class MedicalCodesRepositoryImpl implements MedicalCodesRepository {
  final MedicalCodesRemoteDataSource remoteDataSource;
  final MedicalCodesLocalDataSource localDataSource;

  MedicalCodesRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, List<MedicalCode>>> getMedicalCodes({
    int page = 1,
    String? search,
    String? category,
    String? contentId,
  }) async {
    try {
      final codes = await remoteDataSource.getMedicalCodes(
        page: page,
        search: search,
        category: category,
        contentId: contentId,
      );
      await localDataSource.cacheMedicalCodes(codes);
      return Right(codes);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      var cached = await localDataSource.getCachedMedicalCodes();
      if (cached.isNotEmpty) {
        if (search != null && search.isNotEmpty) {
          final q = search.toLowerCase();
          cached = cached.where((code) {
            final inCode = code.code.toLowerCase().contains(q);
            final inDesc = code.description.toLowerCase().contains(q);
            final inCat = code.category?.toLowerCase().contains(q) ?? false;
            return inCode || inDesc || inCat;
          }).toList();
        }
        if (category != null && category.isNotEmpty) {
          cached = cached.where((code) => code.category == category).toList();
        }
        if (contentId != null && contentId.isNotEmpty) {
          cached = cached
              .where((code) => code.contentId?.toString() == contentId)
              .toList();
        }
        return Right(cached);
      }
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
      final cached = await localDataSource.getCachedMedicalCodes();
      final match = cached.where((item) => item.id == id).toList();
      if (match.isNotEmpty) {
        return Right(match.first);
      }
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
  Future<Either<Failure, ImportAllResult>> importAll({
    required String medicalCodesFilePath,
    String? contentsFilePath,
    String? category,
    String? bodySystem,
  }) async {
    try {
      final result = await remoteDataSource.importAll(
        medicalCodesFilePath: medicalCodesFilePath,
        contentsFilePath: contentsFilePath,
        category: category,
        bodySystem: bodySystem,
      );
      // Clear local cache after successful import all
      await localDataSource.cacheMedicalCodes([]);
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

  @override
  Future<Either<Failure, MedicalCode>> createMedicalCode(Map<String, dynamic> data) async {
    try {
      final code = await remoteDataSource.createMedicalCode(data);
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
  Future<Either<Failure, MedicalCode>> updateMedicalCode(String id, Map<String, dynamic> data) async {
    try {
      final code = await remoteDataSource.updateMedicalCode(id, data);
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
  Future<Either<Failure, void>> deleteMedicalCode(String id) async {
    try {
      await remoteDataSource.deleteMedicalCode(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

