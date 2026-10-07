import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const sexLabels = {'male': 'Masculin', 'female': 'Feminin'};
const activityLabels = {
  'sedentary': 'Sedentar',
  'lightly_active': 'Ușor activ',
  'moderately_active': 'Moderat activ',
  'very_active': 'Foarte activ',
  'extra_active': 'Extrem de activ',
};
const activityDescriptions = {
  'sedentary': 'Puțină mișcare în viața de zi cu zi',
  'lightly_active': 'Activitate ușoară în mod regulat',
  'moderately_active': 'Activitate fizică regulată',
  'very_active': 'Activitate intensă și frecventă',
  'extra_active': 'Efort fizic intens aproape zilnic',
};
const goalLabels = {
  'lose': 'Scădere în greutate',
  'maintain': 'Menținere',
  'gain': 'Creștere în greutate',
};

String profileNumber(double value) =>
    value.toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',');
String profileDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.'
    '${value.year.toString().padLeft(4, '0')}';

class ProfileChoices extends StatelessWidget {
  const ProfileChoices({
    super.key,
    required this.labels,
    required this.value,
    required this.onChanged,
    this.descriptions = const {},
  });
  final Map<String, String> labels;
  final Map<String, String> descriptions;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final entry in labels.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              selected: entry.key == value,
              child: Material(
                color: entry.key == value
                    ? colors.primaryContainer
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  key: ValueKey(entry.key),
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (descriptions[entry.key] != null) ...[
                                const SizedBox(height: 4),
                                Text(descriptions[entry.key]!),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          entry.key == value
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: entry.key == value
                              ? colors.primary
                              : colors.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileDateSelector extends StatelessWidget {
  const ProfileDateSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('Data nașterii'),
      const SizedBox(height: 8),
      TextButton.icon(
        key: const ValueKey('birthDate'),
        style: TextButton.styleFrom(minimumSize: const Size(0, 64)),
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          value == null ? 'Alege data nașterii' : profileDate(value!),
        ),
        onPressed: () async {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final selected = await showDatePicker(
            context: context,
            initialDate: value == null || value!.isAfter(today) ? today : value,
            firstDate: DateTime(1),
            lastDate: today,
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            helpText: 'Data nașterii',
            cancelText: 'Anulează',
            confirmText: 'Selectează',
          );
          if (!context.mounted || selected == null) {
            return;
          }
          onChanged(DateTime(selected.year, selected.month, selected.day));
        },
      ),
    ],
  );
}

class ProfileMeasurementWheel extends StatefulWidget {
  const ProfileMeasurementWheel({
    super.key,
    required this.height,
    required this.value,
    required this.onChanged,
  });
  final bool height;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<ProfileMeasurementWheel> createState() =>
      _ProfileMeasurementWheelState();
}

class _ProfileMeasurementWheelState extends State<ProfileMeasurementWheel> {
  late final List<double> _values;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _values = List.generate(
      widget.height ? 101 : 321,
      (index) => widget.height ? (120 + index).toDouble() : 40 + index * 0.5,
    );
    // An exact legacy value is a real selectable entry, never a rounded default.
    if (!_values.contains(widget.value)) {
      _values.add(widget.value);
      _values.sort();
    }
    _controller = FixedExtentScrollController(
      initialItem: _values.indexOf(widget.value),
      keepScrollOffset: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 180,
        height: 260,
        child: CupertinoPicker.builder(
          key: ValueKey(widget.height ? 'height' : 'weight'),
          scrollController: _controller,
          itemExtent: 56,
          magnification: 1.15,
          useMagnifier: true,
          childCount: _values.length,
          onSelectedItemChanged: (index) => widget.onChanged(_values[index]),
          itemBuilder: (context, index) => Center(
            child: Text(
              profileNumber(_values[index]),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Text(
        widget.height ? 'cm' : 'kg',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    ],
  );
}
