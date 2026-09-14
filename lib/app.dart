import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class PersonalCommandCenterApp extends StatelessWidget {
  const PersonalCommandCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Personal Command Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}