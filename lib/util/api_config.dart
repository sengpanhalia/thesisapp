class ApiConfig {
  /// Change this when your server IP or port changes.
  static const String serverHost = '172.16.1.105';

  static const String _apiFolder = 'haroteyApi';
  static const String baseUrl = 'http://$serverHost/$_apiFolder';

  static const String usersUploadsUrl = '$baseUrl/uploads/users';
  static const String productsUploadsUrl = '$baseUrl/uploads/products';
}
