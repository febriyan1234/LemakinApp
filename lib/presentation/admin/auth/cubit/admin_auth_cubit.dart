import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/admin_auth_repository.dart';
import 'admin_auth_state.dart';

class AdminAuthCubit extends Cubit<AdminAuthState> {
  final AdminAuthRepository authRepository;

  AdminAuthCubit({required this.authRepository}) : super(AdminAuthInitial()) {
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    final isLoggedIn = await authRepository.isLoggedIn();
    if (isLoggedIn) {
      final token = await authRepository.getToken();
      final adminName = await authRepository.getAdminName();
      if (token != null && adminName != null) {
        emit(AdminAuthAuthenticated(token: token, adminName: adminName));
      } else {
        emit(const AdminAuthUnauthenticated());
      }
    } else {
      emit(const AdminAuthUnauthenticated());
    }
  }

  Future<void> login(String emailOrUsername, String password) async {
    if (emailOrUsername.trim().isEmpty || password.isEmpty) {
      emit(const AdminAuthUnauthenticated(errorMessage: 'Email/Username and password are required'));
      return;
    }

    emit(AdminAuthLoading());
    try {
      final token = await authRepository.login(emailOrUsername, password);
      final adminName = await authRepository.getAdminName();
      if (token != null && adminName != null) {
        emit(AdminAuthAuthenticated(token: token, adminName: adminName));
      } else {
        emit(const AdminAuthUnauthenticated(errorMessage: 'Authentication failed'));
      }
    } catch (e) {
      emit(AdminAuthUnauthenticated(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> logout() async {
    emit(AdminAuthLoading());
    await authRepository.logout();
    emit(const AdminAuthUnauthenticated());
  }
}
