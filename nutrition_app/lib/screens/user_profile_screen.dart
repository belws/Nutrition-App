import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../widgets/profile_controls.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.repository,
    required this.onSaved,
    required this.onSignOut,
  });

  final String userId;
  final UserProfileRepository repository;
  final ValueChanged<UserProfile> onSaved;
  final Future<void> Function() onSignOut;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _step = 0;
  double _height = 175;
  double _weight = 70;
  DateTime? _birthDate;
  String? _sex;
  String? _activity;
  String? _goal;
  String? _error;
  bool _saving = false;
  bool _signingOut = false;

  bool get _busy => _saving || _signingOut;

  bool get _canContinue {
    switch (_step) {
      case 0:
        final now = DateTime.now();
        return _sex != null &&
            _birthDate != null &&
            !_birthDate!.isAfter(DateTime(now.year, now.month, now.day));
      case 3:
        return _activity != null;
      case 4:
        return _goal != null;
      default:
        return true;
    }
  }

  Future<void> _save() async {
    if (_busy || _step != 4 || !_canContinue) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.saveProfile(
        UserProfile(
          userId: widget.userId,
          sex: _sex!,
          dateOfBirth: _birthDate!,
          heightCm: _height,
          weightKg: _weight,
          activityLevel: _activity!,
          goal: _goal!,
        ),
      );
      if (!mounted) {
        return;
      }
      widget.onSaved(saved);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Nu am putut salva profilul. Încearcă din nou.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_busy) {
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
        setState(() {
          _signingOut = false;
          _error = 'Nu am putut face deconectarea. Încearcă din nou.';
        });
      }
    }
  }

  Widget _progress() {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Pasul ${_step + 1} din 5',
      child: Row(
        children: [
          for (var index = 0; index < 5; index++) ...[
            if (index > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: index <= _step
                      ? colors.primary
                      : colors.outlineVariant,
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= _step ? colors.primary : colors.surface,
                border: Border.all(
                  color: index <= _step
                      ? colors.primary
                      : colors.outlineVariant,
                  width: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
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
      case 1:
        return ProfileMeasurementWheel(
          height: true,
          value: _height,
          onChanged: (value) => _height = value,
        );
      case 2:
        return ProfileMeasurementWheel(
          height: false,
          value: _weight,
          onChanged: (value) => _weight = value,
        );
      case 3:
        return ProfileChoices(
          labels: activityLabels,
          descriptions: activityDescriptions,
          value: _activity,
          onChanged: (value) => setState(() => _activity = value),
        );
      default:
        return ProfileChoices(
          labels: goalLabels,
          value: _goal,
          onChanged: (value) => setState(() => _goal = value),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Spune-ne câte ceva despre tine',
      'Care este înălțimea ta?',
      'Care este greutatea ta?',
      'Cât de activ ești?',
      'Care este obiectivul tău?',
    ];
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _busy ? null : _signOut,
            tooltip: 'Deconectare',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: _progress(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titles[_step],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 36),
                        AbsorbPointer(absorbing: _busy, child: _stepContent()),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        key: ValueKey(_step == 4 ? 'saveProfile' : 'continue'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                        onPressed: _busy || !_canContinue
                            ? null
                            : () {
                                if (_step == 4) {
                                  _save();
                                } else {
                                  setState(() {
                                    _step++;
                                    _error = null;
                                  });
                                }
                              },
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_step == 4 ? 'Finalizează' : 'Continuă'),
                      ),
                      if (_step > 0)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  setState(() {
                                    _step--;
                                    _error = null;
                                  });
                                },
                          child: const Text('Înapoi'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
