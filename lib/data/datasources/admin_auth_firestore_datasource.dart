import 'package:firebase_auth/firebase_auth.dart';
import 'admin_auth_local_datasource.dart';

class AdminAuthFirestoreDataSourceImpl implements AdminAuthLocalDataSource {
  final FirebaseAuth _firebaseAuth;

  AdminAuthFirestoreDataSourceImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<String?> login(String emailOrUsername, String password) async {
    String email = emailOrUsername.trim().toLowerCase();
    if (!email.contains('@')) {
      email = '$email@lemakin.com'; // Default mapping to email
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user?.uid;
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<String?> getToken() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  @override
  Future<String?> getAdminName() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return user.displayName ?? user.email ?? 'Admin';
    }
    return null;
  }
}
