class BadRequestException implements Exception {
  final String message;
  BadRequestException({this.message = 'Bad Request'});
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException({this.message = 'Unauthorized'});
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException({this.message = 'Forbidden Error'});
}

class InternalServerErrorException implements Exception {
  final String message;
  InternalServerErrorException({this.message = 'Internal Server Error'});
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException({this.message = 'Not Found'});
}

class ConflictException implements Exception {
  final String message;
  ConflictException({this.message = 'Conflict'});
}
