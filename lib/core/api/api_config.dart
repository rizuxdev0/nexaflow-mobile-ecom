class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://192.168.1.65:3003/api/v1',
  );
  static const String tokenKey = 'nexaflow_shop_token';
  static const String customerKey = 'nexaflow_shop_customer';
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
