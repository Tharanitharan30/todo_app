import 'package:drift/drift.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get title => text()();

  TextColumn get description => text().withDefault(const Constant(''))();

  DateTimeColumn get dueDate => dateTime().nullable()();

  DateTimeColumn get dueTime => dateTime().nullable()();

  TextColumn get priority => text().withDefault(const Constant('medium'))();

  TextColumn get category => text().withDefault(const Constant('personal'))();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  TextColumn get recurrenceRule => text().nullable()();

  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get completedAt => dateTime().nullable()();

  TextColumn get tags => text().withDefault(const Constant(''))();

  DateTimeColumn get reminderAt => dateTime().nullable()();

  TextColumn get notes => text().withDefault(const Constant(''))();
}

class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get taskId => integer()();

  TextColumn get title => text()();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amount => real()();

  TextColumn get category => text()();

  DateTimeColumn get date => dateTime()();

  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();

  TextColumn get note => text().withDefault(const Constant(''))();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Income extends Table {
  IntColumn get id => integer().autoIncrement()();

  RealColumn get amount => real()();

  TextColumn get source => text()();

  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().withDefault(const Constant(''))();

  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  RealColumn get targetAmount => real()();

  RealColumn get currentAmount => real().withDefault(const Constant(0))();

  DateTimeColumn get targetDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  RealColumn get amount => real()();

  TextColumn get billingCycle =>
      text().withDefault(const Constant('monthly'))();

  DateTimeColumn get nextBillingDate => dateTime()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();

  IntColumn get referenceId => integer().nullable()();

  TextColumn get title => text()();

  TextColumn get body => text()();

  DateTimeColumn get scheduledAt => dateTime()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  BoolColumn get read => boolean().withDefault(const Constant(false))();

  TextColumn get payload => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Settings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get category => text()();

  RealColumn get amount => real()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
