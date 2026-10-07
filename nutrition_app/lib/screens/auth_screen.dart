import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});

  final GoTrueClient auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Introdu adresa de email și parola.';
      });
      return;
    }

    if (_isSignUp && password != _confirmPasswordController.text) {
      setState(() {
        _message = 'Parolele nu coincid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      if (_isSignUp) {
        final response = await widget.auth.signUp(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (response.session == null) {
          setState(() {
            _message = 'Cont creat. Verifică emailul pentru a confirma contul.';
          });
        }
      } else {
        await widget.auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException {
      if (!mounted) return;

      setState(() {
        _message = _isSignUp
            ? 'Nu am putut crea contul. Verifică datele introduse.'
            : 'Nu am putut autentifica contul. Verifică emailul și parola.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message = 'A apărut o eroare. Încearcă din nou.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _message = null;
      _confirmPasswordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? 'Creează cont' : 'Autentificare')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: _isSignUp
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onSubmitted: _isSignUp || _isLoading
                      ? null
                      : (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Parolă'),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _isLoading ? null : (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Confirmă parola',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Creează cont' : 'Autentificare'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _switchMode,
                  child: Text(
                    _isSignUp
                        ? 'Ai deja cont? Autentifică-te'
                        : 'Nu ai cont? Creează unul',
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
