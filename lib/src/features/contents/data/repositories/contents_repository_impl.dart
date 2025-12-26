import 'package:dartz/dartz.dart';
import '../../domain/repositories/contents_repository.dart';
import '../../domain/entities/content_node.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/contents_remote_data_source.dart';

class ContentsRepositoryImpl implements ContentsRepository {
  final ContentsRemoteDataSource remoteDataSource;

  ContentsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ContentNode>>> getContents() async {
    try {
      final contents = await remoteDataSource.getContents();
      return Right(contents);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
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
}


