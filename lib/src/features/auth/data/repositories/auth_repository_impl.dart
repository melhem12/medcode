import 'package:dartz/dartz.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final DioClient dioClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.dioClient,
  });

  @override
  Future<Either<Failure, AuthResponse>> login(
      String email, String password) async {
    try {
      final response = await remoteDataSource.login(email, password);
      // Set token in DioClient immediately to avoid race conditions
      await dioClient.setAuthToken(response.token);
      await localDataSource.cacheAuthToken(response.token);
      await localDataSource.cacheUser(response.user);
      return Right(response);
    } on ApiException catch (e) {
      return Left(ServerFailure(
        e.message,
        statusCode: e.statusCode,
        fieldErrors: e.fieldErrors,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> register(
      Map<String, dynamic> payload) async {
    try {
      final response = await remoteDataSource.register(payload);
      // Set token in DioClient immediately to avoid race conditions
      await dioClient.setAuthToken(response.token);
      await localDataSource.cacheAuthToken(response.token);
      await localDataSource.cacheUser(response.user);
      return Right(response);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message, e.fieldErrors));
    } on ApiException catch (e) {
      return Left(ServerFailure(
        e.message,
        statusCode: e.statusCode,
        fieldErrors: e.fieldErrors,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await dioClient.clearAuthToken();
      await localDataSource.clearAuthToken();
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> checkAuthStatus() async {
    try {
      final token = await localDataSource.getAuthToken();
      final user = await localDataSource.getCachedUser();
      
      // If token exists but no user cached, clear token
      if (token != null && user == null) {
        await localDataSource.clearAuthToken();
        return const Right(null);
      }
      
      // Return cached user if both token and user exist
      return Right(user);
    } catch (e) {
      return Left(LocalStorageFailure(e.toString()));
    }
  }
}

