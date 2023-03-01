class ConfigException implements Exception {
  const ConfigException(this.cause);
  final String cause;

  @override
  String toString() {
    return cause;
  }
}
