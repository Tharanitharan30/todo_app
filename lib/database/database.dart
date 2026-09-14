import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Tasks,
    Subtasks,
    Expenses,
    Income,
    Budgets,
    SavingsGoals,
    Subscriptions,
    AppNotifications,
    Settings,
    FocusSessions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // =========================
  // TASKS
  // =========================

  Stream<List<Task>> watchAllTasks() {
    return select(tasks).watch();
  }

  Future<List<Task>> getAllTasks() {
    return select(tasks).get();
  }

  Future<Task?> getTaskById(int id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> addTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  Future<bool> updateTask(Task task) {
    return update(tasks).replace(task);
  }

  Future<int> deleteTask(int id) async {
    await (delete(subtasks)..where((s) => s.taskId.equals(id))).go();
    return (delete(tasks)..where((task) => task.id.equals(id))).go();
  }

  Future<void> completeTask(int id) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(
        status: const Value('completed'),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> uncompleteTask(int id) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      const TasksCompanion(status: Value('pending'), completedAt: Value(null)),
    );
  }

  Future<void> toggleTaskImportant(int id, bool isImportant) {
    return (update(tasks)..where((task) => task.id.equals(id))).write(
      TasksCompanion(isImportant: Value(isImportant)),
    );
  }

  Future<int> duplicateTask(int id) async {
    final original = await getTaskById(id);
    if (original == null) return -1;

    final newTaskId = await into(tasks).insert(
      TasksCompanion.insert(
        title: '${original.title} (Copy)',
        description: Value(original.description),
        dueDate: Value(original.dueDate),
        dueTime: Value(original.dueTime),
        priority: Value(original.priority),
        category: Value(original.category),
        status: const Value('pending'),
        isRecurring: Value(original.isRecurring),
        recurrenceRule: Value(original.recurrenceRule),
        isImportant: Value(original.isImportant),
        tags: Value(original.tags),
        reminderAt: Value(original.reminderAt),
        notes: Value(original.notes),
      ),
    );

    final originalSubtasks = await getSubtasksForTask(id);
    for (final sub in originalSubtasks) {
      await into(subtasks).insert(
        SubtasksCompanion.insert(
          taskId: newTaskId,
          title: sub.title,
          completed: Value(sub.completed),
        ),
      );
    }

    return newTaskId;
  }

  // =========================
  // SUBTASKS
  // =========================

  Stream<List<Subtask>> watchAllSubtasks() {
    return select(subtasks).watch();
  }

  Stream<List<Subtask>> watchSubtasksForTask(int taskId) {
    return (select(subtasks)..where((s) => s.taskId.equals(taskId))).watch();
  }

  Future<List<Subtask>> getSubtasksForTask(int taskId) {
    return (select(subtasks)..where((s) => s.taskId.equals(taskId))).get();
  }

  Future<int> addSubtask(SubtasksCompanion subtask) {
    return into(subtasks).insert(subtask);
  }

  Future<bool> updateSubtask(Subtask subtask) {
    return update(subtasks).replace(subtask);
  }

  Future<int> deleteSubtask(int id) {
    return (delete(subtasks)..where((s) => s.id.equals(id))).go();
  }

  Future<void> toggleSubtask(int id, bool completed) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(completed: Value(completed)),
    );
  }

  // =========================
  // EXPENSES
  // =========================

  Stream<List<Expense>> watchAllExpenses() {
    return select(expenses).watch();
  }

  Future<List<Expense>> getAllExpenses() {
    return select(expenses).get();
  }

  Future<int> addExpense(ExpensesCompanion expense) {
    return into(expenses).insert(expense);
  }

  Future<bool> updateExpense(Expense expense) {
    return update(expenses).replace(expense);
  }

  Future<int> deleteExpense(int id) {
    return (delete(expenses)..where((e) => e.id.equals(id))).go();
  }

  // =========================
  // INCOME
  // =========================

  Stream<List<IncomeData>> watchAllIncome() {
    return select(income).watch();
  }

  Future<List<IncomeData>> getAllIncome() {
    return select(income).get();
  }

  Future<int> addIncome(IncomeCompanion item) {
    return into(income).insert(item);
  }

  Future<bool> updateIncome(IncomeData item) {
    return update(income).replace(item);
  }

  Future<int> deleteIncome(int id) {
    return (delete(income)..where((i) => i.id.equals(id))).go();
  }

  // =========================
  // BUDGETS
  // =========================

  Stream<List<Budget>> watchAllBudgets() {
    return select(budgets).watch();
  }

  Future<List<Budget>> getAllBudgets() {
    return select(budgets).get();
  }

  Future<int> addBudget(BudgetsCompanion budget) {
    return into(budgets).insert(budget);
  }

  Future<bool> updateBudget(Budget budget) {
    return update(budgets).replace(budget);
  }

  Future<int> deleteBudget(int id) {
    return (delete(budgets)..where((b) => b.id.equals(id))).go();
  }

  // =========================
  // SAVINGS GOALS
  // =========================

  Stream<List<SavingsGoal>> watchAllSavingsGoals() {
    return select(savingsGoals).watch();
  }

  Future<List<SavingsGoal>> getAllSavingsGoals() {
    return select(savingsGoals).get();
  }

  Future<int> addSavingsGoal(SavingsGoalsCompanion goal) {
    return into(savingsGoals).insert(goal);
  }

  Future<bool> updateSavingsGoal(SavingsGoal goal) {
    return update(savingsGoals).replace(goal);
  }

  Future<int> deleteSavingsGoal(int id) {
    return (delete(savingsGoals)..where((g) => g.id.equals(id))).go();
  }

  Future<void> updateSavingsGoalAmount(int id, double newAmount) {
    return (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(
        currentAmount: Value(newAmount < 0 ? 0 : newAmount),
      ),
    );
  }

  // =========================
  // SUBSCRIPTIONS
  // =========================

  Stream<List<Subscription>> watchAllSubscriptions() {
    return select(subscriptions).watch();
  }

  Future<List<Subscription>> getAllSubscriptions() {
    return select(subscriptions).get();
  }

  Future<int> addSubscription(SubscriptionsCompanion subscription) {
    return into(subscriptions).insert(subscription);
  }

  Future<bool> updateSubscription(Subscription subscription) {
    return update(subscriptions).replace(subscription);
  }

  Future<int> deleteSubscription(int id) {
    return (delete(subscriptions)..where((s) => s.id.equals(id))).go();
  }

  Future<void> toggleSubscriptionActive(int id, bool active) {
    return (update(subscriptions)..where((s) => s.id.equals(id))).write(
      SubscriptionsCompanion(active: Value(active)),
    );
  }

  // =========================
  // NOTIFICATIONS
  // =========================

  Stream<List<AppNotification>> watchAllNotifications() {
    return (select(
      appNotifications,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Stream<int> watchUnreadNotificationsCount() {
    return (select(
      appNotifications,
    )..where((n) => n.read.equals(false))).watch().map((list) => list.length);
  }

  Future<List<AppNotification>> getAllNotifications() {
    return (select(
      appNotifications,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<int> addAppNotification(AppNotificationsCompanion item) {
    return into(appNotifications).insert(item);
  }

  Future<void> markNotificationAsRead(int id) {
    return (update(appNotifications)..where((n) => n.id.equals(id))).write(
      const AppNotificationsCompanion(read: Value(true)),
    );
  }

  Future<void> markAllNotificationsAsRead() {
    return (update(appNotifications)..where((n) => n.read.equals(false))).write(
      const AppNotificationsCompanion(read: Value(true)),
    );
  }

  Future<int> deleteAppNotification(int id) {
    return (delete(appNotifications)..where((n) => n.id.equals(id))).go();
  }

  Future<int> clearAllNotifications() {
    return delete(appNotifications).go();
  }

  // =========================
  // SETTINGS (KEY-VALUE)
  // =========================

  Future<String?> getSetting(String key) async {
    final entry = await (select(
      settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  Future<List<Setting>> getAllSettings() {
    return select(settings).get();
  }

  Future<void> setSetting(String key, String value) {
    return into(
      settings,
    ).insertOnConflictUpdate(Setting(key: key, value: value));
  }

  // =========================
  // FOCUS SESSIONS
  // =========================

  Stream<List<FocusSession>> watchAllFocusSessions() {
    return (select(
      focusSessions,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<List<FocusSession>> getAllFocusSessions() {
    return (select(
      focusSessions,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<List<FocusSession>> getFocusSessionsForTask(int taskId) {
    return (select(focusSessions)..where((s) => s.taskId.equals(taskId))).get();
  }

  Future<int> addFocusSession(FocusSessionsCompanion session) {
    return into(focusSessions).insert(session);
  }

  Future<bool> updateFocusSession(FocusSession session) {
    return update(focusSessions).replace(session);
  }

  Future<int> deleteFocusSession(int id) {
    return (delete(focusSessions)..where((s) => s.id.equals(id))).go();
  }

  Future<int> clearAllFocusSessions() {
    return delete(focusSessions).go();
  }

  // =========================
  // DATABASE VERSION & MIGRATIONS
  // =========================

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(tasks, tasks.tags);
          await m.addColumn(tasks, tasks.reminderAt);
          await m.addColumn(tasks, tasks.notes);
        }
        if (from < 3) {
          await m.createTable(budgets);
        }
        if (from < 4) {
          await m.addColumn(appNotifications, appNotifications.read);
          await m.addColumn(appNotifications, appNotifications.payload);
        }
        if (from < 5) {
          await m.createTable(focusSessions);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    final dbFile = File(
      path.join(dbFolder.path, 'personal_command_center.sqlite'),
    );

    return NativeDatabase.createInBackground(dbFile);
  });
}
