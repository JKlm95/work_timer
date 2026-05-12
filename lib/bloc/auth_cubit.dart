import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/auth_native_sync.dart';
import '../services/auth_service.dart';
import '../services/user_email_index_service.dart';
import '../services/user_profile_repository.dart';

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
  AuthCubit(
    this._authService, {
    UserEmailIndexService? userEmailIndex,
    UserProfileRepository? userProfileRepository,
  }) : _userEmailIndex = userEmailIndex ?? UserEmailIndexService(),
       _profileRepo = userProfileRepository ?? UserProfileRepository(),
       super(AuthState.initial()) {
    _sub = _authService.authStateChanges.listen((user) async {
      emit(AuthState(loading: false, user: user));
      await syncAuthSignedInToNativePrefs(user != null);
      if (user != null) {
        unawaited(_syncUserEmailIndex(user));
      }
    });
  }

  final AuthService _authService;
  final UserEmailIndexService _userEmailIndex;
  final UserProfileRepository _profileRepo;
  StreamSubscription<User?>? _sub;

  Future<void> _syncUserEmailIndex(User user) async {
    try {
      final profile = await _profileRepo.load(user.uid);
      await _userEmailIndex.upsertForUser(user, profile: profile);
    } catch (e, st) {
      debugPrint('AuthCubit._syncUserEmailIndex: $e\n$st');
      await _userEmailIndex.upsertForUser(user, profile: null);
    }
  }

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
