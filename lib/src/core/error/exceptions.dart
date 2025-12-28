/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
  
  @override
  String toString() => message;
}

/// Exception thrown when API calls fail
class ApiException extends AppException {
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;
  
  ApiException(
    String message, {
    this.statusCode,
    this.fieldErrors,
  }) : super(message);
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  NetworkException(String message) : super(message);
}

/// Exception thrown when local storage operations fail
class LocalStorageException extends AppException {
  LocalStorageException(String message) : super(message);
}

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  AuthenticationException(String message) : super(message);
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;
  
  ValidationException(String message, this.fieldErrors) : super(message);
}




