import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);

    final colors = [
      {'name': 'default', 'label': 'Default', 'color': Colors.black},
      {'name': 'blue', 'label': 'Blue', 'color': Colors.blue},
      {'name': 'green', 'label': 'Green', 'color': Colors.green},
      {'name': 'purple', 'label': 'Purple', 'color': Colors.deepPurple},
      {'name': 'orange', 'label': 'Orange', 'color': Colors.orange},
      {'name': 'red', 'label': 'Red', 'color': Colors.red},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Theme',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_suggest_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (newSelection) {
                final newMode = newSelection.first;
                ref
                    .read(appSettingsProvider.notifier)
                    .updateSettings(settings.copyWith(themeMode: newMode));
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Accent Color',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((c) {
                final name = c['name'] as String;
                final color = c['color'] as Color;
                final isSelected = settings.accentColor == name;

                return InkWell(
                  onTap: () {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(settings.copyWith(accentColor: name));
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(color: color, width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color:
                                color == Colors.black &&
                                    theme.brightness == Brightness.dark
                                ? Colors.white
                                : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
