import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/database/database.dart';
import 'package:todo_app/providers/database_provider.dart';
import 'package:todo_app/widgets/quick_actions.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('QuickActions renders action chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: Scaffold(body: QuickActions())),
      ),
    );

    expect(find.text('+ Task'), findsOneWidget);
    expect(find.text('+ Expense'), findsOneWidget);
    expect(find.text('+ Income'), findsOneWidget);
    expect(find.text('Start Focus'), findsOneWidget);
    expect(find.text('Open Calendar'), findsOneWidget);
  });
}
