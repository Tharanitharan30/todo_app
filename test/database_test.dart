import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Tasks Database Operations', () {
    test('addTask and getTaskById', () async {
      final id = await db.addTask(
        TasksCompanion.insert(
          title: 'Test Task',
          description: const Value('Description'),
          priority: const Value('high'),
          category: const Value('work'),
        ),
      );

      final task = await db.getTaskById(id);
      expect(task, isNotNull);
      expect(task!.title, 'Test Task');
      expect(task.priority, 'high');
      expect(task.status, 'pending');
    });

    test('completeTask and uncompleteTask', () async {
      final id = await db.addTask(
        TasksCompanion.insert(title: 'Task to Complete'),
      );

      await db.completeTask(id);
      var task = await db.getTaskById(id);
      expect(task!.status, 'completed');
      expect(task.completedAt, isNotNull);

      await db.uncompleteTask(id);
      task = await db.getTaskById(id);
      expect(task!.status, 'pending');
      expect(task.completedAt, isNull);
    });

    test('deleteTask and orphan subtasks cleanup', () async {
      final taskId = await db.addTask(
        TasksCompanion.insert(title: 'Parent Task'),
      );

      await db.addSubtask(
        SubtasksCompanion.insert(taskId: taskId, title: 'Subtask 1'),
      );

      final subtasksBefore = await db.getSubtasksForTask(taskId);
      expect(subtasksBefore.length, 1);

      await db.deleteTask(taskId);
      final task = await db.getTaskById(taskId);
      expect(task, isNull);

      final subtasksAfter = await db.getSubtasksForTask(taskId);
      expect(subtasksAfter, isEmpty);
    });
  });

  group('Finance Database Operations', () {
    test('Add and retrieve expenses', () async {
      await db.addExpense(
        ExpensesCompanion.insert(
          amount: 500.0,
          category: 'Food',
          date: DateTime.now(),
          paymentMethod: const Value('UPI'),
          note: const Value('Lunch'),
        ),
      );

      final expenses = await db.getAllExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.amount, 500.0);
      expect(expenses.first.category, 'Food');
    });

    test('Add and retrieve income', () async {
      await db.addIncome(
        IncomeCompanion.insert(
          amount: 50000.0,
          source: 'Salary',
          date: DateTime.now(),
        ),
      );

      final incomeList = await db.getAllIncome();
      expect(incomeList.length, 1);
      expect(incomeList.first.amount, 50000.0);
    });

    test('Budgets, Savings, and Subscriptions', () async {
      await db.addBudget(
        BudgetsCompanion.insert(category: 'Food', amount: 5000.0),
      );
      final budgets = await db.getAllBudgets();
      expect(budgets.length, 1);

      await db.addSavingsGoal(
        SavingsGoalsCompanion.insert(name: 'Laptop', targetAmount: 80000.0),
      );
      final savings = await db.getAllSavingsGoals();
      expect(savings.length, 1);

      await db.addSubscription(
        SubscriptionsCompanion.insert(
          name: 'Netflix',
          amount: 649.0,
          nextBillingDate: DateTime.now().add(const Duration(days: 30)),
        ),
      );
      final subs = await db.getAllSubscriptions();
      expect(subs.length, 1);
    });
  });

  group('Settings Key-Value Storage', () {
    test('setSetting and getSetting', () async {
      await db.setSetting('currency', 'USD');
      final val = await db.getSetting('currency');
      expect(val, 'USD');
    });
  });
}
