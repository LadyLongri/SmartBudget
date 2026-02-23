import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService;

  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<void> login({required String email, required String password}) async {
    await _authService.login(email: email, password: password);
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _authService.register(email: email, password: password);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<String?> getIdToken() {
    return _authService.getIdToken();
  }
}
