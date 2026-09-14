import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import 'database_provider.dart';

final appNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllNotifications();
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchUnreadNotificationsCount();
});
