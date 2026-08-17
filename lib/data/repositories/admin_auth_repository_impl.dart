import '../../domain/repositories/admin_auth_repository.dart';
import '../datasources/admin_auth_local_datasource.dart';

class AdminAuthRepositoryImpl implements AdminAuthRepository {
  final AdminAuthLocalDataSource localDataSource;

  AdminAuthRepositoryImpl({required this.localDataSource});

  @override
  Future<String?> login(String emailOrUsername, String password) {
    return localDataSource.login(emailOrUsername, password);
  }

  @override
  Future<void> logout() {
    return localDataSource.logout();
  }

  @override
  Future<bool> isLoggedIn() {
    return localDataSource.isLoggedIn();
  }

  @override
  Future<String?> getToken() {
    return localDataSource.getToken();
  }

  @override
  Future<String?> getAdminName() {
    return localDataSource.getAdminName();
  }
}
