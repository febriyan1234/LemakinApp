abstract class AdminAuthLocalDataSource {
  Future<String?> login(String emailOrUsername, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<String?> getAdminName();
}

class AdminAuthLocalDataSourceImpl implements AdminAuthLocalDataSource {
  String? _token;
  String? _adminName;

  @override
  Future<String?> login(String emailOrUsername, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final cleanEmail = emailOrUsername.trim().toLowerCase();
    
    if ((cleanEmail == 'admin' && password == 'admin123') ||
        (cleanEmail == 'admin@lemakin.com' && password == 'password123')) {
      _token = 'mock_jwt_token_for_admin_session_${DateTime.now().millisecondsSinceEpoch}';
      _adminName = 'Super Admin';
      return _token;
    } else {
      throw Exception('Invalid email/username or password');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _token = null;
    _adminName = null;
  }

  @override
  Future<bool> isLoggedIn() async {
    return _token != null;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<String?> getAdminName() async {
    return _adminName;
  }
}
