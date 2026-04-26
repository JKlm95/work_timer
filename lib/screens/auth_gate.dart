import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_cubit.dart';
import '../bloc/timer_cubit.dart';
import '../services/work_repository.dart';
import 'home_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.repository});

  final WorkRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.user == null) {
          return const _AuthScreen();
        }
        return _SignedInScope(uid: state.user!.uid, repository: repository);
      },
    );
  }
}

class _SignedInScope extends StatefulWidget {
  const _SignedInScope({required this.uid, required this.repository});

  final String uid;
  final WorkRepository repository;

  @override
  State<_SignedInScope> createState() => _SignedInScopeState();
}

class _SignedInScopeState extends State<_SignedInScope> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(widget.uid),
      create: (_) =>
          TimerCubit(uid: widget.uid, repository: widget.repository)..init(),
      child: HomeShell(onSignOut: context.read<AuthCubit>().signOut),
    );
  }
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
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logowanie')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Podaj e-mail';
                      if (!v.contains('@')) return 'Niepoprawny e-mail';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Hasło'),
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Hasło min. 6 znaków';
                      }
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_isSignUp ? 'Załóż konto' : 'Zaloguj'),
                  ),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Masz konto? Zaloguj się'
                          : 'Nie masz konta? Załóż',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
