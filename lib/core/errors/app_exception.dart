class AppException implements Exception {
  const AppException(this.message, {this.code, this.fieldErrors = const {}});
  final String message;
  final String? code;
  final Map<String, List<String>> fieldErrors;
  @override
  String toString() => message;
}
