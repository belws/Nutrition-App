import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../widgets/profile_controls.dart';

enum ProfileSection {
  personal('Date personale'),
  measurements('Măsurători'),
  activity('Nivel de activitate'),
  goal('Obiectiv');

  const ProfileSection(this.label);
  final String label;
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.profile,
    required this.section,
    required this.repository,
    required this.onSaved,
    required this.onCancel,
    this.active = true,
  });
  final bool active;
  final UserProfile profile;
  final ProfileSection section;
  final UserProfileRepository repository;
  final ValueChanged<UserProfile> onSaved;
  final VoidCallback onCancel;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late String _sex;
  late DateTime _birthDate;
  late double _height;
  late double _weight;
  late String _activity;
  late String _goal;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _sex = profile.sex;
    _birthDate = profile.dateOfBirth;
    _height = profile.heightCm;
    _weight = profile.weightKg;
    _activity = profile.activityLevel;
    _goal = profile.goal;
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final now = DateTime.now();
    if (widget.section == ProfileSection.personal &&
        _birthDate.isAfter(DateTime(now.year, now.month, now.day))) {
      setState(() => _error = 'Data nașterii nu poate fi în viitor.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.saveProfile(
        UserProfile(
          userId: widget.profile.userId,
          sex: _sex,
          dateOfBirth: _birthDate,
          heightCm: _height,
          weightKg: _weight,
          activityLevel: _activity,
          goal: _goal,
          createdAt: widget.profile.createdAt,
          updatedAt: widget.profile.updatedAt,
        ),
      );
      if (!mounted) {
        return;
      }
      widget.onSaved(saved);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Nu am putut salva profilul. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _fields() {
    switch (widget.section) {
      case ProfileSection.personal:
        return Column(
          children: [
            ProfileChoices(
              labels: sexLabels,
              value: _sex,
              onChanged: (value) => setState(() => _sex = value),
            ),
            const SizedBox(height: 24),
            ProfileDateSelector(
              value: _birthDate,
              onChanged: (value) => setState(() => _birthDate = value),
            ),
          ],
        );
      case ProfileSection.measurements:
        return Column(
          children: [
            const Text('Înălțime'),
            ProfileMeasurementWheel(
              height: true,
              value: _height,
              onChanged: (value) => _height = value,
            ),
            const SizedBox(height: 24),
            const Text('Greutate'),
            ProfileMeasurementWheel(
              height: false,
              value: _weight,
              onChanged: (value) => _weight = value,
            ),
          ],
        );
      case ProfileSection.activity:
        return ProfileChoices(
          labels: activityLabels,
          descriptions: activityDescriptions,
          value: _activity,
          onChanged: (value) => setState(() => _activity = value),
        );
      case ProfileSection.goal:
        return ProfileChoices(
          labels: goalLabels,
          value: _goal,
          onChanged: (value) => setState(() => _goal = value),
        );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.active,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && widget.active && !_saving) {
        widget.onCancel();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.section.label),
        leading: IconButton(
          tooltip: 'Înapoi',
          icon: const Icon(Icons.arrow_back),
          onPressed: _saving ? null : widget.onCancel,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AbsorbPointer(absorbing: _saving, child: _fields()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    key: const ValueKey('saveEdits'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 56),
                    ),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvează'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
