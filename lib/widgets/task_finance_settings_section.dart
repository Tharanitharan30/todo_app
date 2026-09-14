import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class TaskFinanceSettingsSection extends ConsumerWidget {
  const TaskFinanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // TASKS SECTION
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasks Defaults',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Default Priority',
                  value: settings.defaultTaskPriority,
                  items: const ['low', 'medium', 'high', 'urgent'],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(defaultTaskPriority: val),
                          );
                    }
                  },
                ),
                const Divider(height: 24),
                _buildDropdownRow(
                  label: 'Default Category',
                  value: settings.defaultTaskCategory,
                  items: const [
                    'personal',
                    'work',
                    'shopping',
                    'health',
                    'education',
                    'finance',
                    'general',
                    'other',
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(defaultTaskCategory: val),
                          );
                    }
                  },
                ),
                const Divider(height: 24),
                _buildDropdownRow(
                  label: 'Week Starts On',
                  value: settings.weekStartsOn,
                  items: const ['Monday', 'Sunday'],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(settings.copyWith(weekStartsOn: val));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // FINANCE SECTION
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finance Defaults',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Currency',
                  value: settings.currency,
                  items: const ['INR', 'USD', 'EUR', 'GBP', 'JPY'],
                  displayMap: const {
                    'INR': 'INR (₹)',
                    'USD': 'USD (\$)',
                    'EUR': 'EUR (€)',
                    'GBP': 'GBP (£)',
                    'JPY': 'JPY (¥)',
                  },
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(settings.copyWith(currency: val));
                    }
                  },
                ),
                const Divider(height: 24),
                _buildDropdownRow(
                  label: 'Default Payment Method',
                  value: settings.defaultPaymentMethod,
                  items: const [
                    'UPI',
                    'Cash',
                    'Debit Card',
                    'Credit Card',
                    'Bank Transfer',
                    'Other',
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(defaultPaymentMethod: val),
                          );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // FOCUS SECTION
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Defaults',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Focus Duration',
                  value: '${settings.focusDurationMinutes}',
                  items: const ['15', '25', '30', '45', '60'],
                  displayMap: const {
                    '15': '15 min',
                    '25': '25 min',
                    '30': '30 min',
                    '45': '45 min',
                    '60': '60 min',
                  },
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(
                              focusDurationMinutes: int.parse(val),
                            ),
                          );
                    }
                  },
                ),
                const Divider(height: 24),
                _buildDropdownRow(
                  label: 'Short Break',
                  value: '${settings.shortBreakMinutes}',
                  items: const ['3', '5', '10', '15'],
                  displayMap: const {
                    '3': '3 min',
                    '5': '5 min',
                    '10': '10 min',
                    '15': '15 min',
                  },
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(
                              shortBreakMinutes: int.parse(val),
                            ),
                          );
                    }
                  },
                ),
                const Divider(height: 24),
                _buildDropdownRow(
                  label: 'Long Break',
                  value: '${settings.longBreakMinutes}',
                  items: const ['10', '15', '20', '30'],
                  displayMap: const {
                    '10': '10 min',
                    '15': '15 min',
                    '20': '20 min',
                    '30': '30 min',
                  },
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(longBreakMinutes: int.parse(val)),
                          );
                    }
                  },
                ),
                const Divider(height: 24),
                _buildDropdownRow(
                  label: 'Daily Focus Goal',
                  value: '${settings.dailyFocusGoalHours}',
                  items: const [
                    '1.0',
                    '2.0',
                    '3.0',
                    '4.0',
                    '5.0',
                    '6.0',
                    '8.0',
                  ],
                  displayMap: const {
                    '1.0': '1 hour',
                    '2.0': '2 hours',
                    '3.0': '3 hours',
                    '4.0': '4 hours',
                    '5.0': '5 hours',
                    '6.0': '6 hours',
                    '8.0': '8 hours',
                  },
                  onChanged: (val) {
                    if (val != null) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateSettings(
                            settings.copyWith(
                              dailyFocusGoalHours: double.parse(val),
                            ),
                          );
                    }
                  },
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-start Breaks'),
                  subtitle: const Text(
                    'Automatically begin rest timer when focus finishes',
                  ),
                  value: settings.autoStartBreaks,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(
                          settings.copyWith(autoStartBreaks: val),
                        );
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-start Focus'),
                  subtitle: const Text(
                    'Automatically begin next focus timer when break finishes',
                  ),
                  value: settings.autoStartFocus,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(settings.copyWith(autoStartFocus: val));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    Map<String, String>? displayMap,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        DropdownButton<String>(
          value: effectiveValue,
          underline: const SizedBox(),
          items: items.map((item) {
            final displayText =
                displayMap?[item] ??
                '${item[0].toUpperCase()}${item.substring(1)}';
            return DropdownMenuItem(
              value: item,
              child: Text(displayText, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
