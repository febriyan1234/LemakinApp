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
    final cleanUsername = emailOrUsername.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Username and password cannot be empty');
    }

    _token = 'mock_jwt_token_for_admin_session_${DateTime.now().millisecondsSinceEpoch}';
    
    // Parse name from email username or use cleanUsername directly
    final parts = cleanUsername.split('@');
    final rawName = parts[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
    _adminName = rawName.isNotEmpty
        ? rawName.split(' ').map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join(' ')
        : 'Admin';

    return _token;
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
