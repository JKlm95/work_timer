import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/timer_cubit.dart';
import '../bloc/user_profile_cubit.dart';
import '../utils/auth_error_localizer.dart';
import '../services/legal_consent_repository.dart';
import '../services/live_status_app_binding.dart';
import '../services/live_status_service.dart';
import '../services/user_email_index_service.dart';
import '../services/user_profile_repository.dart';
import '../services/work_repository.dart';
import '../widgets/splash_loading_view.dart';
import 'home_shell.dart';
import 'legal_consent_screen.dart';

enum _PostAuthPhase {
  /// Przed pierwszym rozstrzygnięciem lub po wylogowaniu.
  idle,

  /// Sprawdzanie `users/{uid}/legal/consents`.
  checkingLegal,

  /// Wymagana akceptacja w UI.
  needsLegalUi,

  /// Nie udało się odczytać dokumentu zgód (np. offline).
  legalFetchFailed,

  /// Inicjalizacja `TimerCubit` (splash jak dotychczas).
  initializingTimer,

  /// Zgoda OK i cubity gotowe — główna aplikacja.
  ready,
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.repository,
    required this.userProfileRepository,
    required this.userEmailIndex,
    required this.liveStatus,
  });

  final WorkRepository repository;
  final UserProfileRepository userProfileRepository;
  final UserEmailIndexService userEmailIndex;
  final LiveStatusService liveStatus;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  TimerCubit? _timerCubit;
  UserProfileCubit? _profileCubit;
  String? _loadedUid;
  _PostAuthPhase _phase = _PostAuthPhase.idle;
  final LegalConsentRepository _legalConsentRepository =
      LegalConsentRepository();

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

  Future<void> _bootstrapTimerForUser(String uid) async {
    final sw = Stopwatch()..start();
    final cubit = TimerCubit(
      uid: uid,
      repository: widget.repository,
      liveStatus: widget.liveStatus,
    );
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
      _phase = _PostAuthPhase.ready;
    });
  }

  Future<void> _onAuthChanged(AuthState state) async {
    if (state.loading) return;
    if (state.user == null) {
      await _disposeTimer();
      if (mounted) {
        setState(() => _phase = _PostAuthPhase.idle);
      }
      return;
    }
    final uid = state.user!.uid;

    if (_phase == _PostAuthPhase.ready &&
        _timerCubit != null &&
        _loadedUid == uid) {
      return;
    }

    await _disposeTimer();
    if (!mounted) return;

    setState(() => _phase = _PostAuthPhase.checkingLegal);

    final gate = await _legalConsentRepository.checkGate(uid);
    if (!mounted) return;

    switch (gate) {
      case LegalConsentGate.satisfied:
        setState(() => _phase = _PostAuthPhase.initializingTimer);
        await _bootstrapTimerForUser(uid);
        break;
      case LegalConsentGate.needsAcceptance:
        setState(() => _phase = _PostAuthPhase.needsLegalUi);
        break;
      case LegalConsentGate.fetchFailed:
        setState(() => _phase = _PostAuthPhase.legalFetchFailed);
        break;
    }
  }

  Future<void> _retryLegalCheck(String uid) async {
    setState(() => _phase = _PostAuthPhase.checkingLegal);
    final gate = await _legalConsentRepository.checkGate(uid);
    if (!mounted) return;
    switch (gate) {
      case LegalConsentGate.satisfied:
        setState(() => _phase = _PostAuthPhase.initializingTimer);
        await _bootstrapTimerForUser(uid);
        break;
      case LegalConsentGate.needsAcceptance:
        setState(() => _phase = _PostAuthPhase.needsLegalUi);
        break;
      case LegalConsentGate.fetchFailed:
        setState(() => _phase = _PostAuthPhase.legalFetchFailed);
        break;
    }
  }

  Future<void> _afterLegalConsent(String uid) async {
    if (!mounted) return;
    setState(() => _phase = _PostAuthPhase.initializingTimer);
    await _bootstrapTimerForUser(uid);
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

          final uid = state.user!.uid;

          switch (_phase) {
            case _PostAuthPhase.idle:
            case _PostAuthPhase.checkingLegal:
            case _PostAuthPhase.initializingTimer:
              return const SplashLoadingView();
            case _PostAuthPhase.legalFetchFailed:
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                appBar: AppBar(title: Text(l10n.legalScreenTitle)),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.legalCheckFailed,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => unawaited(_retryLegalCheck(uid)),
                          child: Text(l10n.legalRetry),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () =>
                              unawaited(context.read<AuthCubit>().signOut()),
                          child: Text(l10n.signOut),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            case _PostAuthPhase.needsLegalUi:
              return LegalConsentScreen(
                uid: uid,
                repository: _legalConsentRepository,
                onConsentSaved: () => unawaited(_afterLegalConsent(uid)),
                onSignOut: () {
                  unawaited(context.read<AuthCubit>().signOut());
                },
              );
            case _PostAuthPhase.ready:
              if (_timerCubit == null || _profileCubit == null) {
                return const SplashLoadingView();
              }
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: _timerCubit!),
                  BlocProvider.value(value: _profileCubit!),
                ],
                child: _TimerResumeSyncScope(
                  liveStatus: widget.liveStatus,
                  child: HomeShell(
                    onSignOut: context.read<AuthCubit>().signOut,
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

class _TimerResumeSyncScope extends StatefulWidget {
  const _TimerResumeSyncScope({required this.liveStatus, required this.child});

  final LiveStatusService liveStatus;
  final Widget child;

  @override
  State<_TimerResumeSyncScope> createState() => _TimerResumeSyncScopeState();
}

class _TimerResumeSyncScopeState extends State<_TimerResumeSyncScope>
    with WidgetsBindingObserver {
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LiveStatusAppBinding.lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    _heartbeat = Timer.periodic(const Duration(seconds: 45), (_) {
      _onHeartbeatTick();
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onHeartbeatTick() {
    if (!mounted) return;
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final foreground =
        LiveStatusAppBinding.lifecycle == AppLifecycleState.resumed;
    final runState = context.read<TimerCubit>().state.runState;
    final timerNotIdle = runState != TimerRunState.idle;
    if (!foreground && !timerNotIdle) return;
    unawaited(widget.liveStatus.heartbeat(user.uid));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      LiveStatusAppBinding.lifecycle = state;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final cubit = context.read<TimerCubit>();
      if (kDebugMode) {
        debugPrint(
          '[LiveStatus] lifecycle=$state preSync runState=${cubit.state.runState.name}',
        );
      }
      if (state == AppLifecycleState.resumed) {
        await cubit.syncFromNativeStoresOnResume();
        await widget.liveStatus.syncFromTimerState(cubit.state);
      } else if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached) {
        await widget.liveStatus.syncFromTimerState(cubit.state);
      }
      if (kDebugMode) {
        debugPrint(
          '[LiveStatus] lifecycle=$state postSync runState=${cubit.state.runState.name}',
        );
      }
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
