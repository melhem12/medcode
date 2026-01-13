import 'package:equatable/equatable.dart';

/// Base failure class for all app failures
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
  
  @override
  String toString() => message;
}

/// Failure for server/API errors
class ServerFailure extends Failure {
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;
  
  const ServerFailure(
    String message, {
    this.statusCode,
    this.fieldErrors,
  }) : super(message);
  
  @override
  List<Object> get props => [message, statusCode ?? 0];
}

/// Failure for network errors
class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

/// Failure for local storage errors
class LocalStorageFailure extends Failure {
  const LocalStorageFailure(String message) : super(message);
}

/// Failure for authentication errors
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  
  const ValidationFailure(String message, this.fieldErrors) : super(message);
  
  @override
  List<Object> get props => [message, fieldErrors];
}





















