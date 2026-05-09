import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/auth_native_sync.dart';
import '../services/auth_service.dart';

class AuthState {
  const AuthState({required this.loading, required this.user});

  final bool loading;
  final User? user;

  factory AuthState.initial() => const AuthState(loading: true, user: null);

  AuthState copyWith({bool? loading, User? user}) {
    return AuthState(loading: loading ?? this.loading, user: user);
  }
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService) : super(AuthState.initial()) {
    _sub = _authService.authStateChanges.listen((user) async {
      emit(AuthState(loading: false, user: user));
      await syncAuthSignedInToNativePrefs(user != null);
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _sub;

  Future<void> signIn({required String email, required String password}) {
    return _authService.signIn(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _authService.signUp(email: email, password: password);
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> sendPasswordResetEmail({required String email}) {
    return _authService.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
