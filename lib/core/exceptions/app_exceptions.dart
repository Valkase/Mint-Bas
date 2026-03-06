class InsufficientFundsException implements Exception {
  final String message;

  InsufficientFundsException(this.message);

  @override
  String toString() => message;
}