import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import 'neumorphic_card.dart';

class TaskFinanceSettingsSection extends ConsumerWidget {
  const TaskFinanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // TASKS SECTION
        NeumorphicCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tasks Defaults',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownRow(
                context,
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
                context,
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
                context,
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
        const SizedBox(height: 16),
        // FINANCE SECTION
        NeumorphicCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Finance Defaults',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdownRow(
                context,
                label: 'Default Currency',
                value: settings.currency,
                items: const ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)'],
                onChanged: (val) {
                  if (val != null) {
                    final code = val.split(' ').first;
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(settings.copyWith(currency: code));
                  }
                },
              ),
              const Divider(height: 24),
              _buildDropdownRow(
                context,
                label: 'Daily Focus Goal (Hours)',
                value: '${settings.dailyFocusGoalHours.toInt()}h',
                items: const ['1h', '2h', '3h', '4h', '5h', '6h', '8h'],
                onChanged: (val) {
                  if (val != null) {
                    final hrs = double.parse(val.replaceAll('h', ''));
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(
                          settings.copyWith(dailyFocusGoalHours: hrs),
                        );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          underline: const SizedBox.shrink(),
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
          onChanged: onChanged,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
