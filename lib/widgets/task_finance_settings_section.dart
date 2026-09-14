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
