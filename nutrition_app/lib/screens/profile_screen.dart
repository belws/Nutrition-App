import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../widgets/profile_controls.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.email,
    required this.repository,
    required this.onSaved,
    required this.onSignOut,
    this.active = true,
  });
  final bool active;
  final UserProfile profile;
  final String? email;
  final UserProfileRepository repository;
  final ValueChanged<UserProfile> onSaved;
  final Future<void> Function() onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileSection? _section;
  bool _signingOut = false;
  String? _error;

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Nu am putut face deconectarea. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  Widget _row(ProfileSection section, String summary) => Card(
    elevation: 0,
    child: ListTile(
      key: ValueKey(section),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      title: Text(section.label),
      subtitle: Text(summary),
      trailing: const Icon(Icons.chevron_right),
      onTap: _signingOut ? null : () => setState(() => _section = section),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_section != null) {
      return ProfileEditScreen(
        key: ValueKey(_section),
        profile: widget.profile,
        section: _section!,
        repository: widget.repository,
        active: widget.active,
        onCancel: () => setState(() => _section = null),
        onSaved: (profile) {
          if (!mounted) {
            return;
          }
          widget.onSaved(profile);
          setState(() => _section = null);
        },
      );
    }
    final profile = widget.profile;
    final email = widget.email ?? 'Email indisponibil';
    return Scaffold(
      appBar: AppBar(title: const Text('Profilul meu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 40),
                    const SizedBox(height: 12),
                    Text(email, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text('PROFIL NUTRIȚIONAL'),
            const SizedBox(height: 12),
            _row(
              ProfileSection.personal,
              '${sexLabels[profile.sex] ?? profile.sex} · ${profileDate(profile.dateOfBirth)}',
            ),
            _row(
              ProfileSection.measurements,
              '${profileNumber(profile.heightCm)} cm · ${profileNumber(profile.weightKg)} kg',
            ),
            _row(
              ProfileSection.activity,
              activityLabels[profile.activityLevel] ?? profile.activityLevel,
            ),
            _row(ProfileSection.goal, goalLabels[profile.goal] ?? profile.goal),
            const SizedBox(height: 32),
            const Text('CONT ȘI SECURITATE'),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Email'),
                subtitle: Text(email),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              key: const ValueKey('profileSignOut'),
              onPressed: _signingOut ? null : _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Deconectare'),
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 16),
            ListTile(
              enabled: false,
              title: Text(
                'Șterge contul',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('Disponibil în curând'),
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
