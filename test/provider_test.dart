import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/database/database.dart';
import 'package:todo_app/providers/database_provider.dart';
import 'package:todo_app/providers/search_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('SearchProvider Tests', () {
    test('Initial search state is empty', () {
      final state = container.read(searchProvider);
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.categoryFilter, SearchCategory.all);
    });

    test('Search returns matching tasks from SQLite', () async {
      await db.addTask(
        TasksCompanion.insert(
          title: 'Project Documentation',
          category: const Value('Work'),
        ),
      );

      final notifier = container.read(searchProvider.notifier);
      await notifier.search('Project');

      final state = container.read(searchProvider);
      expect(state.results.length, 1);
      expect(state.results.first.title, 'Project Documentation');
    });

    test('Search category filter isolates results', () async {
      await db.addTask(TasksCompanion.insert(title: 'Food Shopping Task'));
      await db.addExpense(
        ExpensesCompanion.insert(
          amount: 250.0,
          category: 'Food',
          date: DateTime.now(),
          note: const Value('Food Dinner'),
        ),
      );

      final notifier = container.read(searchProvider.notifier);
      notifier.setCategoryFilter(SearchCategory.expenses);
      await notifier.search('Food');

      final state = container.read(searchProvider);
      expect(state.results.length, 1);
      expect(state.results.first.category, SearchCategory.expenses);
    });
  });
}
