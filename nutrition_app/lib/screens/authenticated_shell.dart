import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/food_repository.dart';
import '../repositories/user_profile_repository.dart';
import 'food_catalog_screen.dart';
import 'profile_screen.dart';

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({
    super.key,
    required this.profile,
    required this.email,
    required this.repository,
    required this.profileRepository,
    required this.onSignOut,
  });
  final UserProfile profile;
  final String? email;
  final FoodRepository repository;
  final UserProfileRepository profileRepository;
  final Future<void> Function() onSignOut;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  int _tab = 0;
  late UserProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        FoodCatalogScreen(
          repository: widget.repository,
          onSignOut: widget.onSignOut,
        ),
        ProfileScreen(
          profile: _profile,
          email: widget.email,
          active: _tab == 1,
          repository: widget.profileRepository,
          onSignOut: widget.onSignOut,
          onSaved: (profile) {
            if (!mounted || profile.userId != _profile.userId) {
              return;
            }
            setState(() => _profile = profile);
          },
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu),
          label: 'Catalog',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
    ),
  );
}
