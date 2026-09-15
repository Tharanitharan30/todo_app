import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../widgets/about_section.dart';
import '../widgets/appearance_section.dart';
import '../widgets/data_management_section.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/notification_settings_section.dart';
import '../widgets/task_finance_settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          if (isWide) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppearanceSection(),
                        const SizedBox(height: 16),
                        const TaskFinanceSettingsSection(),
                        const SizedBox(height: 16),
                        const AboutSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NotificationSettingsSection(),
                        const SizedBox(height: 16),
                        _buildPermissionCard(context),
                        const SizedBox(height: 16),
                        const DataManagementSection(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppearanceSection(),
                const SizedBox(height: 16),
                const NotificationSettingsSection(),
                const SizedBox(height: 12),
                _buildPermissionCard(context),
                const SizedBox(height: 16),
                const TaskFinanceSettingsSection(),
                const SizedBox(height: 16),
                const DataManagementSection(),
                const SizedBox(height: 16),
                const AboutSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      onTap: () async {
        await NotificationService().requestPermissions();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permission requested')),
          );
        }
      },
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request Notification Permission',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Ensure app has system permission to display daily briefing & alerts',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
