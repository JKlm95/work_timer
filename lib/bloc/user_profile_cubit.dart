import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/user_profile.dart';
import '../services/user_email_index_service.dart';
import '../services/user_profile_repository.dart';

enum ProfileSaveResult { success, profileWriteFailed, indexSyncFailed }

class UserProfileState {
  const UserProfileState({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.loading = false,
    this.saving = false,
    this.errorMessage,
  });

  final String firstName;
  final String lastName;
  final String email;
  final bool loading;
  final bool saving;
  final String? errorMessage;

  UserProfileState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserProfileState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit({
    required this.uid,
    required UserProfileRepository profileRepository,
    required UserEmailIndexService emailIndex,
    FirebaseAuth? firebaseAuth,
  }) : _repo = profileRepository,
       _emailIndex = emailIndex,
       _auth = firebaseAuth ?? FirebaseAuth.instance,
       super(const UserProfileState()) {
    unawaited(load());
  }

  final String uid;
  final UserProfileRepository _repo;
  final UserEmailIndexService _emailIndex;
  final FirebaseAuth _auth;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    final user = _auth.currentUser;
    final email = user?.email?.trim() ?? '';
    try {
      final p = await _repo.load(uid);
      emit(
        state.copyWith(
          loading: false,
          firstName: p?.firstName ?? '',
          lastName: p?.lastName ?? '',
          email: email,
        ),
      );
    } catch (e, st) {
      debugPrint('UserProfileCubit.load: $e\n$st');
      emit(
        state.copyWith(
          loading: false,
          email: email,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<ProfileSaveResult> save({
    required String firstName,
    required String lastName,
  }) async {
    if (!UserProfile.hasAnyName(firstName, lastName)) {
      return ProfileSaveResult.profileWriteFailed;
    }
    final user = _auth.currentUser;
    if (user == null) return ProfileSaveResult.profileWriteFailed;
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      return ProfileSaveResult.profileWriteFailed;
    }

    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _repo.save(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
    } catch (e, st) {
      debugPrint('UserProfileCubit.save profile: $e\n$st');
      emit(state.copyWith(saving: false, errorMessage: e.toString()));
      return ProfileSaveResult.profileWriteFailed;
    }

    final display = UserProfile.composeDisplayName(firstName, lastName);
    if (display.isNotEmpty) {
      try {
        await user.updateDisplayName(display);
        await user.reload();
      } catch (e, st) {
        debugPrint('UserProfileCubit.updateDisplayName: $e\n$st');
      }
    }

    final reloaded = _auth.currentUser ?? user;
    final profileAfter = UserProfile(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      displayName: display,
      email: email,
    );
    final indexOk = await _emailIndex.upsertForUser(
      reloaded,
      profile: profileAfter,
    );

    emit(
      state.copyWith(
        saving: false,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email,
      ),
    );

    if (!indexOk) {
      debugPrint('UserProfileCubit.save: userEmailIndex sync failed');
      return ProfileSaveResult.indexSyncFailed;
    }
    return ProfileSaveResult.success;
  }
}
