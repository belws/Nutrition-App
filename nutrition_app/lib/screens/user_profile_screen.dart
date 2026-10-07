import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';

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
  final _form = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  DateTime? _birthDate;
  String? _sex;
  String? _activity;
  String? _goal;
  String? _error;
  bool _saving = false;
  bool _signingOut = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validateNumber(String? value) {
    final number = _number(value ?? '');
    return number == null || !number.isFinite || number <= 0
        ? 'Introdu o valoare validă mai mare decât 0.'
        : null;
  }

  Future<void> _save() async {
    if (_saving || _signingOut || !_form.currentState!.validate()) return;
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
          heightCm: _number(_height.text)!,
          weightKg: _number(_weight.text)!,
          activityLevel: _activity!,
          goal: _goal!,
        ),
      );
      if (!mounted) return;
      widget.onSaved(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Nu am putut salva profilul. Încearcă din nou.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    if (_saving || _signingOut) return;
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

  Widget _choice(
    String key,
    String label,
    Map<String, String> choices,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey(key),
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: choices.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(
                entry.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Alege o opțiune.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _signingOut;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil nutrițional'),
        actions: [
          IconButton(
            onPressed: busy ? null : _signOut,
            tooltip: 'Deconectare',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AbsorbPointer(
                absorbing: busy,
                child: Column(
                  children: [
                    _choice('sex', 'Sex', const {
                      'male': 'Masculin',
                      'female': 'Feminin',
                    }, (value) => _sex = value),
                    FormField<DateTime>(
                      validator: (_) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        if (_birthDate == null) return 'Alege data nașterii.';
                        return _birthDate!.isAfter(today)
                            ? 'Data nu poate fi în viitor.'
                            : null;
                      },
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            key: const ValueKey('birthDate'),
                            onPressed: () async {
                              final now = DateTime.now();
                              final today = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: _birthDate ?? today,
                                firstDate: DateTime(1),
                                lastDate: today,
                                initialEntryMode:
                                    DatePickerEntryMode.calendarOnly,
                                helpText: 'Data nașterii',
                                cancelText: 'Anulează',
                                confirmText: 'Selectează',
                              );
                              if (!mounted || selected == null) return;
                              setState(
                                () => _birthDate = DateTime(
                                  selected.year,
                                  selected.month,
                                  selected.day,
                                ),
                              );
                              field.didChange(_birthDate);
                            },
                            child: Text(
                              _birthDate == null
                                  ? 'Alege data nașterii'
                                  : '${_birthDate!.day.toString().padLeft(2, '0')}.'
                                        '${_birthDate!.month.toString().padLeft(2, '0')}.'
                                        '${_birthDate!.year.toString().padLeft(4, '0')}',
                            ),
                          ),
                          if (field.hasError)
                            Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextFormField(
                      key: const ValueKey('height'),
                      controller: _height,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Înălțime (cm)',
                      ),
                      validator: _validateNumber,
                    ),
                    TextFormField(
                      key: const ValueKey('weight'),
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Greutate (kg)',
                      ),
                      validator: _validateNumber,
                    ),
                    _choice('activity', 'Nivel de activitate', const {
                      'sedentary': 'Sedentar — puțină mișcare',
                      'lightly_active': 'Ușor activ — activitate ușoară',
                      'moderately_active':
                          'Moderat activ — activitate regulată',
                      'very_active':
                          'Foarte activ — activitate intensă frecventă',
                      'extra_active':
                          'Extrem de activ — efort fizic intens zilnic',
                    }, (value) => _activity = value),
                    _choice('goal', 'Obiectiv', const {
                      'lose': 'Scădere în greutate',
                      'maintain': 'Menținere',
                      'gain': 'Creștere în greutate',
                    }, (value) => _goal = value),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('saveProfile'),
                onPressed: busy ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvează profilul'),
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
    );
  }
}
