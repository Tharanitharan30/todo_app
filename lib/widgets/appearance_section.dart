import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import 'neumorphic_card.dart';
import 'neumorphic_container.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final theme = Theme.of(context);

    final colors = [
      {'name': 'default', 'label': 'Default', 'color': Colors.grey},
      {'name': 'blue', 'label': 'Blue', 'color': Colors.blue},
      {'name': 'green', 'label': 'Green', 'color': Colors.green},
      {'name': 'purple', 'label': 'Purple', 'color': Colors.deepPurple},
      {'name': 'orange', 'label': 'Orange', 'color': Colors.orange},
      {'name': 'red', 'label': 'Red', 'color': Colors.red},
    ];

    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Theme Mode',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildThemeChip(
                  context: context,
                  label: 'System',
                  icon: Icons.settings_suggest_outlined,
                  isSelected: settings.themeMode == ThemeMode.system,
                  onTap: () {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(
                          settings.copyWith(themeMode: ThemeMode.system),
                        );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeChip(
                  context: context,
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  isSelected: settings.themeMode == ThemeMode.light,
                  onTap: () {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(
                          settings.copyWith(themeMode: ThemeMode.light),
                        );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeChip(
                  context: context,
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  isSelected: settings.themeMode == ThemeMode.dark,
                  onTap: () {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateSettings(
                          settings.copyWith(themeMode: ThemeMode.dark),
                        );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Accent Color',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) {
              final name = c['name'] as String;
              final label = c['label'] as String;
              final color = c['color'] as Color;
              final isSelected = settings.accentColor == name;

              return GestureDetector(
                onTap: () {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateSettings(settings.copyWith(accentColor: name));
                },
                child: NeumorphicContainer(
                  style: isSelected
                      ? NeumorphicStyle.inset
                      : NeumorphicStyle.raised,
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  borderColor: isSelected ? color : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? color
                              : theme.colorScheme.onSurface,
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
    );
  }

  Widget _buildThemeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        style: isSelected ? NeumorphicStyle.inset : NeumorphicStyle.raised,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : null,
        borderColor: isSelected ? theme.colorScheme.primary : null,
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
