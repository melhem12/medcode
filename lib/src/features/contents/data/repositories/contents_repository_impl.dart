import 'package:dartz/dartz.dart';
import '../../domain/repositories/contents_repository.dart';
import '../../domain/entities/content_node.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/contents_remote_data_source.dart';
import '../datasources/contents_local_data_source.dart';
import '../../../medical_codes/domain/entities/import_result.dart';

class ContentsRepositoryImpl implements ContentsRepository {
  final ContentsRemoteDataSource remoteDataSource;
  final ContentsLocalDataSource localDataSource;

  ContentsRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<Either<Failure, List<ContentNode>>> getContents() async {
    try {
      final contents = await remoteDataSource.getContents();
      await localDataSource.cacheContents(contents);
      return Right(contents);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      final cached = await localDataSource.getCachedContents();
      if (cached.isNotEmpty) {
        return Right(cached);
      }
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> exportContents() async {
    try {
      return await remoteDataSource.exportContents();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Either<Failure, ImportResult>> importContents(String filePath) async {
    try {
      final result = await remoteDataSource.importContents(filePath);
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
  Future<Either<Failure, ContentNode>> createContent(Map<String, dynamic> data) async {
    try {
      final content = await remoteDataSource.createContent(data);
      return Right(content);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContentNode>> updateContent(String id, Map<String, dynamic> data) async {
    try {
      final content = await remoteDataSource.updateContent(id, data);
      return Right(content);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContent(String id) async {
    try {
      await remoteDataSource.deleteContent(id);
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

