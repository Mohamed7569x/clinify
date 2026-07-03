class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Session expired. Please log in again.'])
      : super(message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'You do not have permission.'])
      : super(message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Not found.'])
      : super(message, statusCode: 404);
}

class ConflictException extends ApiException {
  ConflictException([String message = 'Already exists.'])
      : super(message, statusCode: 409);
}

class ServerException extends ApiException {
  ServerException([String message = 'Server error. Please try again later.'])
      : super(message, statusCode: 500);
}

class NetworkException extends ApiException {
  NetworkException([String message = 'No internet connection.'])
      : super(message);
}
