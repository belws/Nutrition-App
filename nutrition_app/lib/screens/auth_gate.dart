import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/food_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../models/user_profile.dart';
import 'user_profile_screen.dart';
import 'auth_screen.dart';
import 'food_catalog_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.repository,
    required this.profileRepository,
    required this.auth,
  });

  final FoodRepository repository;
  final UserProfileRepository profileRepository;
  final GoTrueClient auth;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          return AuthScreen(auth: auth);
        }

        return _ProfileGate(
          key: ValueKey(session.user.id),
          userId: session.user.id,
          profileRepository: profileRepository,
          repository: repository,
          auth: auth,
        );
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({
    super.key,
    required this.userId,
    required this.profileRepository,
    required this.repository,
    required this.auth,
  });

  final String userId;
  final UserProfileRepository profileRepository;
  final FoodRepository repository;
  final GoTrueClient auth;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<UserProfile?> _lookup;
  UserProfile? _saved;
  bool _signingOut = false;
  String? _signOutError;

  @override
  void initState() {
    super.initState();
    _lookup = widget.profileRepository.getProfile(widget.userId);
  }

  Future<void> _signOut() async {
    setState(() {
      _signingOut = true;
      _signOutError = null;
    });
    try {
      await widget.auth.signOut();
    } catch (_) {
      if (mounted) {
        setState(() {
          _signingOut = false;
          _signOutError = 'Nu am putut face deconectarea. Încearcă din nou.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _lookup,
      builder: (context, snapshot) {
        if (_saved != null ||
            (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError &&
                snapshot.data != null)) {
          return FoodCatalogScreen(
            repository: widget.repository,
            onSignOut: widget.auth.signOut,
          );
        }
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return UserProfileScreen(
            userId: widget.userId,
            repository: widget.profileRepository,
            onSignOut: widget.auth.signOut,
            onSaved: (profile) {
              if (!mounted ||
                  widget.auth.currentSession?.user.id != widget.userId) {
                return;
              }
              setState(() => _saved = profile);
            },
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil nutrițional'),
            actions: [
              IconButton(
                onPressed: _signingOut ? null : _signOut,
                tooltip: 'Deconectare',
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (snapshot.connectionState != ConnectionState.done)
                  const CircularProgressIndicator()
                else ...[
                  const Text('Nu am putut încărca profilul.'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _lookup = widget.profileRepository.getProfile(
                          widget.userId,
                        );
                      });
                    },
                    child: const Text('Încearcă din nou'),
                  ),
                ],
                if (_signOutError != null) Text(_signOutError!),
              ],
            ),
          ),
        );
      },
    );
  }
}
