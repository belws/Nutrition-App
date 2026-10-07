import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/food_repository.dart';
import 'auth_screen.dart';
import 'food_catalog_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.repository, required this.auth});

  final FoodRepository repository;
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

        return FoodCatalogScreen(
          repository: repository,
          onSignOut: auth.signOut,
        );
      },
    );
  }
}
