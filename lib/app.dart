import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'routes.dart';
import 'theme.dart';

class PersonalCommandCenterApp extends ConsumerWidget {
  const PersonalCommandCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'Personal Command Center',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.getLight(settings.accentColor),
      darkTheme: AppTheme.getDark(settings.accentColor),
      routerConfig: appRouter,
    );
  }
}
