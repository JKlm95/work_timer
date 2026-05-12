import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/timer_cubit.dart';
import '../bloc/user_profile_cubit.dart';
import '../utils/auth_error_localizer.dart';
import '../services/user_email_index_service.dart';
import '../services/user_profile_repository.dart';
import '../services/work_repository.dart';
import '../widgets/splash_loading_view.dart';
import 'home_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.repository,
    required this.userProfileRepository,
    required this.userEmailIndex,
  });

  final WorkRepository repository;
  final UserProfileRepository userProfileRepository;
  final UserEmailIndexService userEmailIndex;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  TimerCubit? _timerCubit;
  UserProfileCubit? _profileCubit;
  String? _loadedUid;

  Future<void> _disposeTimer() async {
    final c = _timerCubit;
    final p = _profileCubit;
    _timerCubit = null;
    _profileCubit = null;
    _loadedUid = null;
    if (p != null) {
      await p.close();
    }
    if (c != null) {
      await c.close();
    }
  }

  Future<void> _onAuthChanged(AuthState state) async {
    if (state.loading) return;
    if (state.user == null) {
      await _disposeTimer();
      if (mounted) setState(() {});
      return;
    }
    final uid = state.user!.uid;
    if (_timerCubit != null && _loadedUid == uid) return;

    await _disposeTimer();

    final sw = Stopwatch()..start();
    final cubit = TimerCubit(uid: uid, repository: widget.repository);
    final profileCubit = UserProfileCubit(
      uid: uid,
      profileRepository: widget.userProfileRepository,
      emailIndex: widget.userEmailIndex,
    );
    try {
      await cubit.init().timeout(const Duration(seconds: 15));
    } catch (_) {}

    final ms = sw.elapsedMilliseconds;
    const minSplashMs = 520;
    if (ms < minSplashMs) {
      await Future<void>.delayed(Duration(milliseconds: minSplashMs - ms));
    }

    if (!mounted) {
      await cubit.close();
      await profileCubit.close();
      return;
    }

    setState(() {
      _timerCubit = cubit;
      _profileCubit = profileCubit;
      _loadedUid = uid;
    });
  }

  @override
  void dispose() {
    unawaited(_disposeTimer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (a, b) {
        if (b.loading) return false;
        if (a.loading && !b.loading) return true;
        if (a.user?.uid != b.user?.uid) return true;
        return false;
      },
      listener: (context, state) {
        unawaited(_onAuthChanged(state));
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.loading) {
            return const SplashLoadingView();
          }
          if (state.user == null) {
            return const _AuthScreen();
          }
          if (_timerCubit == null || _profileCubit == null) {
            return const SplashLoadingView();
          }
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: _timerCubit!),
              BlocProvider.value(value: _profileCubit!),
            ],
            child: _TimerResumeSyncScope(
              child: HomeShell(onSignOut: context.read<AuthCubit>().signOut),
            ),
          );
        },
      ),
    );
  }
}

class _TimerResumeSyncScope extends StatefulWidget {
  const _TimerResumeSyncScope({required this.child});

  final Widget child;

  @override
  State<_TimerResumeSyncScope> createState() => _TimerResumeSyncScopeState();
}

class _TimerResumeSyncScopeState extends State<_TimerResumeSyncScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<TimerCubit>().syncFromNativeStoresOnResume();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AuthScreen extends StatefulWidget {
  const _AuthScreen();

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await context.read<AuthCubit>().signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        await context.read<AuthCubit>().signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _error = localizedAuthError(e, l10n));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _openPasswordResetDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _PasswordResetDialog(
        initialEmail: _emailCtrl.text.trim(),
        authCubit: context.read<AuthCubit>(),
      ),
    );
    if (!mounted || sent != true) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.authResetSnack)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(labelText: l10n.authEmail),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.authValEmailRequired;
                        }
                        if (!v.contains('@')) return l10n.authValEmailInvalid;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(labelText: l10n.authPassword),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return l10n.authValPasswordShort;
                        }
                        return null;
                      },
                    ),
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _submitting
                              ? null
                              : _openPasswordResetDialog,
                          child: Text(l10n.authForgotPassword),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(
                        _isSignUp ? l10n.authSignUp : l10n.authSignIn,
                      ),
                    ),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? l10n.authToggleToSignIn
                            : l10n.authToggleToSignUp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({
    required this.initialEmail,
    required this.authCubit,
  });

  final String initialEmail;
  final AuthCubit authCubit;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authCubit.sendPasswordResetEmail(email: _emailCtrl.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loading = false;
        _error = localizedAuthError(e, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.authResetTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.authResetBody),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(labelText: l10n.authEmail),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.authValEmailRequired;
                }
                if (!v.contains('@')) return l10n.authValEmailInvalid;
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _send,
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authResetSend),
        ),
      ],
    );
  }
}
