abstract class AdminAuthRepository {
  Future<String?> login(String emailOrUsername, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<String?> getAdminName();
}
