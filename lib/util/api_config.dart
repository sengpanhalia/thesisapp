class ApiConfig {
  /// Change this when your server IP or port changes.
  static const String serverHost = '192.168.3.3';

  static const String _apiFolder = 'usea_store_api';
  static const String baseUrl = 'http://$serverHost/$_apiFolder';

  static const String usersUploadsUrl = '$baseUrl/uploads/users';
  static const String productsUploadsUrl = '$baseUrl/uploads/products';
}
