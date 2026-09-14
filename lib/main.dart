import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'routes.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService().init(
      onPayloadTap: (payload) {
        if (payload != null && payload.isNotEmpty) {
          if (payload == 'briefing' || payload == 'summary') {
            appRouter.go('/briefing');
          } else if (payload.startsWith('task:')) {
            appRouter.go('/tasks');
          } else if (payload.startsWith('budget:') ||
              payload.startsWith('subscription:')) {
            appRouter.go('/finance');
          }
        }
      },
    );
  } catch (e) {
    debugPrint('Notification initialization warning: $e');
  }

  runApp(const ProviderScope(child: PersonalCommandCenterApp()));
}
