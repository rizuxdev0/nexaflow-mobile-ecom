import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/storage/auth_storage.dart';

/// Auth state
class AuthState {
  final Customer? customer;
  final bool isLoading;
  final String? error;

  const AuthState({this.customer, this.isLoading = false, this.error});

  bool get isAuthenticated => customer != null;

  AuthState copyWith({Customer? customer, bool? isLoading, String? error, bool clearCustomer = false}) {
    return AuthState(
      customer: clearCustomer ? null : (customer ?? this.customer),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState(isLoading: true)) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final savedCustomer = await AuthStorage.getCustomer();
      if (savedCustomer != null) {
        state = AuthState(customer: Customer.fromJson(savedCustomer));
        // Refresh from server to get latest points/photo
        await checkAuth();
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> checkAuth() async {
    try {
      final response = await _api.get('/customers/me');
      final responseData = response.data as Map<String, dynamic>;
      final actualData = responseData.containsKey('data') ? responseData['data'] : responseData;
      final customer = Customer.fromJson(actualData as Map<String, dynamic>);
      await AuthStorage.saveCustomer(customer.toJson());
      state = state.copyWith(customer: customer);
    } catch (e) {
      print('CheckAuth error: $e');
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
        'source': 'ecommerce',
      });
      
      final rawResponse = response.data as Map<String, dynamic>;
      final data = rawResponse.containsKey('data') ? rawResponse['data'] as Map<String, dynamic> : rawResponse;
      final token = data['token'] as String;
      
      await AuthStorage.saveToken(token);
      
      // Fetch the REAL customer record (loyalty, profile pic, etc.)
      await checkAuth();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Email ou mot de passe incorrect');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      final rawResponse = response.data as Map<String, dynamic>;
      final data = rawResponse.containsKey('data') ? rawResponse['data'] as Map<String, dynamic> : rawResponse;
      final token = data['token'] as String;

      await AuthStorage.saveToken(token);
      
      // Wait a bit for sync if needed, but usually it's immediate
      await checkAuth();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur lors de l\'inscription');
    }
  }

  Future<void> logout() async {
    try {
      await AuthStorage.deleteToken();
      await AuthStorage.deleteCustomer();
      await AuthStorage.clearAll();
    } catch (_) {
      // Ignore storage errors on logout
    } finally {
      state = const AuthState();
    }
  }
}

/// Providers


final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
