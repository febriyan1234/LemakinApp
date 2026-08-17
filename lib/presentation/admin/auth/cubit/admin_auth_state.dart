import 'package:equatable/equatable.dart';

abstract class AdminAuthState extends Equatable {
  const AdminAuthState();

  @override
  List<Object?> get props => [];
}

class AdminAuthInitial extends AdminAuthState {}

class AdminAuthLoading extends AdminAuthState {}

class AdminAuthAuthenticated extends AdminAuthState {
  final String token;
  final String adminName;

  const AdminAuthAuthenticated({required this.token, required this.adminName});

  @override
  List<Object?> get props => [token, adminName];
}

class AdminAuthUnauthenticated extends AdminAuthState {
  final String? errorMessage;

  const AdminAuthUnauthenticated({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
