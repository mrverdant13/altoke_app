import 'dart:async';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:tasks/tasks.dart';
import 'package:tasks_sembast_storage/src/tasks_sembast_storage.dart';
import 'package:tasks_storage/tasks_storage.dart';
import 'package:test/test.dart';

void main() {
  test(
    '''

GIVEN a constructor for a tasks storage
├─ THAT uses a Sembast database
WHEN the constructor is called
THEN an instance of the storage is returned
''',
    () async {
      final storage = TasksSembastStorage(
        database: await newDatabaseFactoryMemory().openDatabase(''),
      );
      expect(storage, isNotNull);
      expect(storage, isA<TasksStorage>());
    },
  );

  group(
    '''

GIVEN a tasks storage
├─ THAT uses a Sembast database''',
    () {
      late Database database;
      late TasksSembastStorage storage;

      setUp(() async {
        final databaseFactoryMemory = newDatabaseFactoryMemory();
        database = await databaseFactoryMemory.openDatabase('/a/path');
        storage = TasksSembastStorage(database: database);
      });

      tearDown(() async {
        await database.close();
      });

      test(
        '''

│  ├─ THAT does not have task records
AND the valid data for a new task
WHEN the task is created
THEN a task record is registered
''',
        () async {
          const newTask = NewTask(
            title: 'title',
            description: 'description',
          );
          final existingTasksCount = await storage.store.count(database);
          expect(existingTasksCount, isZero);
          await storage.create(newTask: newTask);
          final resultingMatchingTasksCount = await storage.store.count(
            database,
            filter: Filter.and([
              Filter.equals(
                SembastTask.titleFieldJsonKey,
                newTask.title,
              ),
              Filter.equals(
                SembastTask.descriptionFieldJsonKey,
                newTask.description,
              ),
            ]),
          );
          expect(resultingMatchingTasksCount, existingTasksCount + 1);
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND the valid data for a new task
WHEN the task is created
THEN a task record is registered
''',
        () async {
          const existingTaskId = 13;
          const existingTask = NewTask(
            title: 'title',
            description: 'description',
          );
          await storage.store
              .record(existingTaskId)
              .add(database, existingTask.toSembastJson());
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, 1);
          const newTask = NewTask(
            title: 'title',
            description: 'description',
          );
          await storage.create(newTask: newTask);
          final resultingMatchingTasksCount = await storage.store.count(
            database,
            filter: Filter.and([
              Filter.equals(
                SembastTask.titleFieldJsonKey,
                newTask.title,
              ),
              Filter.equals(
                SembastTask.descriptionFieldJsonKey,
                newTask.description,
              ),
            ]),
          );
          expect(resultingMatchingTasksCount, initialTasksCount + 1);
        },
      );

      test(
        '''

AND the invalid data for a new task
WHEN the task is created
THEN an exception is thrown
AND no task record is registered
''',
        () async {
          const newTask = NewTask(
            title: '',
            description: 'description',
          );
          final existingTasksCount = await storage.store.count(database);
          expect(existingTasksCount, isZero);
          expect(
            () async => storage.create(newTask: newTask),
            throwsA(isA<CreateTaskFailureEmptyTitle>()),
          );
          final resultingTasksCount = await storage.store.count(database);
          expect(resultingTasksCount, isZero);
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND the ID of a registered task
WHEN the task is deleted
THEN the task record is dropped
AND the deleted task is returned
''',
        () async {
          const taskId = 3254;
          const newTask = NewTask(title: 'title', description: 'description');
          await storage.store
              .record(taskId)
              .add(database, newTask.toSembastJson());
          final filter = Filter.byKey(taskId);
          final initialMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(initialMatchingTasksCount, 1);
          final deletedTask = await storage.delete(taskId: taskId);
          expect(deletedTask, isNotNull);
          expect(deletedTask!.id, taskId);
          final resultingMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(resultingMatchingTasksCount, isZero);
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND the ID of an unregistered task
WHEN the task is deleted
THEN no task record is dropped
AND null is returned
''',
        () async {
          const taskId = 7923;
          const newTask = NewTask(title: 'title', description: 'description');
          await storage.store.add(database, newTask.toSembastJson());
          final initialTasks = await storage.store.find(database);
          expect(initialTasks, hasLength(1));
          final initialTaskSnapshot = initialTasks.single;
          expect(initialTaskSnapshot.key, isNot(taskId));
          final deletedTask = await storage.delete(taskId: taskId);
          expect(deletedTask, isNull);
          final resultingTasks = await storage.store.find(database);
          expect(resultingTasks, hasLength(1));
          final resultingTaskSnapshot = resultingTasks.single;
          expect(resultingTaskSnapshot.toTask(), initialTaskSnapshot.toTask());
        },
      );

      test(
        '''

│  ├─ THAT has several task records
AND a reference task
├─ THAT includes a non-null title matcher
├─ AND includes a non-null status matcher
├─ AND includes a non-null description matcher
WHEN a delete operation is performed with the reference task
THEN the task records matching the reference task are dropped
AND the task records not matching the reference task are kept
''',
        () async {
          final tasks = [
            Task(
              id: 0,
              title: 'title 0',
              description: 'description 0',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 1 matching-pattern',
              description: 'description 1',
              isCompleted: true,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 2',
              description: 'description 2 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 3 matching-pattern',
              description: 'description 3 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 4',
              description: 'description 4',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 5 matching-pattern',
              description: 'description 5',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
            Task(
              id: 6,
              title: 'title 6',
              description: 'description 6 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 6),
            ),
            Task(
              id: 7,
              title: 'title 7 matching-pattern',
              description: 'description 7 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 7),
            ),
            Task(
              id: 8,
              title: 'title 8',
              description: 'description 8',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 8),
            ),
            Task(
              id: 9,
              title: 'title 9 matching-pattern',
              description: 'description 9',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 9),
            ),
            Task(
              id: 10,
              title: 'title 10',
              description: 'description 10 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 10),
            ),
            Task(
              id: 11,
              title: 'title 11 matching-pattern',
              description: 'description 11 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 11),
            ),
            Task(
              id: 12,
              title: 'title 12',
              description: 'description 12',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 12),
            ),
            Task(
              id: 13,
              title: 'title 13 matching-pattern',
              description: 'description 13',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 13),
            ),
            Task(
              id: 14,
              title: 'title 14',
              description: 'description 14 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 14),
            ),
            Task(
              id: 15,
              title: 'title 15 matching-pattern',
              description: 'description 15 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 15),
            ),
          ];
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          final referenceTask = PartialTask(
            title: () => 'matching-pattern',
            description: () => 'matching-pattern',
            isCompleted: () => false,
          );
          await storage.deleteAll(referenceTask: referenceTask);
          final resultingTaskSnapshots = await storage.store.find(database);

          bool shouldBeKept(Task task) {
            final Task(:title, :description, :isCompleted) = task;
            final noMatchInTitle = !title.contains('matching-pattern');
            if (noMatchInTitle) return true;
            if (description == null) return true;
            final noMatchInDescription =
                !description.contains('matching-pattern');
            if (noMatchInDescription) return true;
            final noMatchInStatus = isCompleted != false;
            return noMatchInStatus;
          }

          final expectedResultingTasks = [
            for (final task in tasks)
              if (shouldBeKept(task)) task,
          ];
          expect(
            resultingTaskSnapshots,
            hasLength(expectedResultingTasks.length),
          );
          final resultingTasks = [
            for (final taskSnapshot in resultingTaskSnapshots)
              taskSnapshot.toTask(),
          ];
          expect(resultingTasks, unorderedEquals(expectedResultingTasks));
        },
      );

      test(
        '''

│  ├─ THAT has several task records
AND a reference task
├─ THAT includes a null title matcher
├─ AND includes a non-null status matcher
├─ AND includes a non-null description matcher
WHEN a delete operation is performed with the reference task
THEN the task records matching the reference task are dropped
AND the task records not matching the reference task are kept
''',
        () async {
          final tasks = [
            Task(
              id: 0,
              title: 'title 0',
              description: 'description 0',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 1 matching-pattern',
              description: 'description 1',
              isCompleted: true,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 2',
              description: 'description 2 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 3 matching-pattern',
              description: 'description 3 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 4',
              description: 'description 4',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 5 matching-pattern',
              description: 'description 5',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
            Task(
              id: 6,
              title: 'title 6',
              description: 'description 6 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 6),
            ),
            Task(
              id: 7,
              title: 'title 7 matching-pattern',
              description: 'description 7 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 7),
            ),
            Task(
              id: 8,
              title: 'title 8',
              description: 'description 8',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 8),
            ),
            Task(
              id: 9,
              title: 'title 9 matching-pattern',
              description: 'description 9',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 9),
            ),
            Task(
              id: 10,
              title: 'title 10',
              description: 'description 10 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 10),
            ),
            Task(
              id: 11,
              title: 'title 11 matching-pattern',
              description: 'description 11 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 11),
            ),
            Task(
              id: 12,
              title: 'title 12',
              description: 'description 12',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 12),
            ),
            Task(
              id: 13,
              title: 'title 13 matching-pattern',
              description: 'description 13',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 13),
            ),
            Task(
              id: 14,
              title: 'title 14',
              description: 'description 14 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 14),
            ),
            Task(
              id: 15,
              title: 'title 15 matching-pattern',
              description: 'description 15 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 15),
            ),
          ];
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          final referenceTask = PartialTask(
            description: () => 'matching-pattern',
            isCompleted: () => false,
          );
          await storage.deleteAll(referenceTask: referenceTask);
          final resultingTaskSnapshots = await storage.store.find(database);

          bool shouldBeKept(Task task) {
            final Task(:description, :isCompleted) = task;
            if (description == null) return true;
            final noMatchInDescription =
                !description.contains('matching-pattern');
            if (noMatchInDescription) return true;
            final noMatchInStatus = isCompleted != false;
            return noMatchInStatus;
          }

          final expectedResultingTasks = [
            for (final task in tasks)
              if (shouldBeKept(task)) task,
          ];
          expect(
            resultingTaskSnapshots,
            hasLength(expectedResultingTasks.length),
          );
          final resultingTasks = [
            for (final taskSnapshot in resultingTaskSnapshots)
              taskSnapshot.toTask(),
          ];
          expect(resultingTasks, unorderedEquals(expectedResultingTasks));
        },
      );

      test(
        '''

│  ├─ THAT has several task records
AND a reference task
├─ THAT includes a non-null title matcher
├─ AND includes a null status matcher
├─ AND includes a non-null description matcher
WHEN a delete operation is performed with the reference task
THEN the task records matching the reference task are dropped
AND the task records not matching the reference task are kept
''',
        () async {
          final tasks = [
            Task(
              id: 0,
              title: 'title 0',
              description: 'description 0',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 1 matching-pattern',
              description: 'description 1',
              isCompleted: true,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 2',
              description: 'description 2 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 3 matching-pattern',
              description: 'description 3 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 4',
              description: 'description 4',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 5 matching-pattern',
              description: 'description 5',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
            Task(
              id: 6,
              title: 'title 6',
              description: 'description 6 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 6),
            ),
            Task(
              id: 7,
              title: 'title 7 matching-pattern',
              description: 'description 7 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 7),
            ),
            Task(
              id: 8,
              title: 'title 8',
              description: 'description 8',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 8),
            ),
            Task(
              id: 9,
              title: 'title 9 matching-pattern',
              description: 'description 9',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 9),
            ),
            Task(
              id: 10,
              title: 'title 10',
              description: 'description 10 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 10),
            ),
            Task(
              id: 11,
              title: 'title 11 matching-pattern',
              description: 'description 11 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 11),
            ),
            Task(
              id: 12,
              title: 'title 12',
              description: 'description 12',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 12),
            ),
            Task(
              id: 13,
              title: 'title 13 matching-pattern',
              description: 'description 13',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 13),
            ),
            Task(
              id: 14,
              title: 'title 14',
              description: 'description 14 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 14),
            ),
            Task(
              id: 15,
              title: 'title 15 matching-pattern',
              description: 'description 15 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 15),
            ),
          ];
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          final referenceTask = PartialTask(
            title: () => 'matching-pattern',
            description: () => 'matching-pattern',
          );
          await storage.deleteAll(referenceTask: referenceTask);
          final resultingTaskSnapshots = await storage.store.find(database);

          bool shouldBeKept(Task task) {
            final Task(:title, :description) = task;
            final noMatchInTitle = !title.contains('matching-pattern');
            if (noMatchInTitle) return true;
            if (description == null) return true;
            final noMatchInDescription =
                !description.contains('matching-pattern');
            return noMatchInDescription;
          }

          final expectedResultingTasks = [
            for (final task in tasks)
              if (shouldBeKept(task)) task,
          ];
          expect(
            resultingTaskSnapshots,
            hasLength(expectedResultingTasks.length),
          );
          final resultingTasks = [
            for (final taskSnapshot in resultingTaskSnapshots)
              taskSnapshot.toTask(),
          ];
          expect(resultingTasks, unorderedEquals(expectedResultingTasks));
        },
      );

      test(
        '''

│  ├─ THAT has several task records
AND a reference task
├─ THAT includes a non-null title matcher
├─ AND includes a non-null status matcher
├─ AND includes a null description matcher
WHEN a delete operation is performed with the reference task
THEN the task records matching the reference task are dropped
AND the task records not matching the reference task are kept
''',
        () async {
          final tasks = [
            Task(
              id: 0,
              title: 'title 0',
              description: 'description 0',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 1 matching-pattern',
              description: 'description 1',
              isCompleted: true,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 2',
              description: 'description 2 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 3 matching-pattern',
              description: 'description 3 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 4',
              description: 'description 4',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 5 matching-pattern',
              description: 'description 5',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
            Task(
              id: 6,
              title: 'title 6',
              description: 'description 6 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 6),
            ),
            Task(
              id: 7,
              title: 'title 7 matching-pattern',
              description: 'description 7 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 7),
            ),
            Task(
              id: 8,
              title: 'title 8',
              description: 'description 8',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 8),
            ),
            Task(
              id: 9,
              title: 'title 9 matching-pattern',
              description: 'description 9',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 9),
            ),
            Task(
              id: 10,
              title: 'title 10',
              description: 'description 10 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 10),
            ),
            Task(
              id: 11,
              title: 'title 11 matching-pattern',
              description: 'description 11 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 11),
            ),
            Task(
              id: 12,
              title: 'title 12',
              description: 'description 12',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 12),
            ),
            Task(
              id: 13,
              title: 'title 13 matching-pattern',
              description: 'description 13',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 13),
            ),
            Task(
              id: 14,
              title: 'title 14',
              description: 'description 14 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 14),
            ),
            Task(
              id: 15,
              title: 'title 15 matching-pattern',
              description: 'description 15 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 15),
            ),
          ];
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          final referenceTask = PartialTask(
            title: () => 'matching-pattern',
            isCompleted: () => false,
          );
          await storage.deleteAll(referenceTask: referenceTask);
          final resultingTaskSnapshots = await storage.store.find(database);

          bool shouldBeKept(Task task) {
            final Task(:title, :isCompleted) = task;
            final noMatchInTitle = !title.contains('matching-pattern');
            if (noMatchInTitle) return true;
            final noMatchInStatus = isCompleted != false;
            return noMatchInStatus;
          }

          final expectedResultingTasks = [
            for (final task in tasks)
              if (shouldBeKept(task)) task,
          ];
          expect(
            resultingTaskSnapshots,
            hasLength(expectedResultingTasks.length),
          );
          final resultingTasks = [
            for (final taskSnapshot in resultingTaskSnapshots)
              taskSnapshot.toTask(),
          ];
          expect(resultingTasks, unorderedEquals(expectedResultingTasks));
        },
      );

      test(
        '''

│  ├─ THAT has several task records
AND a reference task
├─ THAT includes a non-null title matcher
├─ AND includes a non-null status matcher
├─ AND includes a non-null empty description matcher
WHEN a delete operation is performed with the reference task
THEN the task records matching the reference task are dropped
AND the task records not matching the reference task are kept
''',
        () async {
          final tasks = [
            Task(
              id: 0,
              title: 'title 0',
              description: 'description 0',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 1 matching-pattern',
              description: 'description 1',
              isCompleted: true,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 2',
              description: 'description 2 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 3 matching-pattern',
              description: 'description 3 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 4',
              description: 'description 4',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 5 matching-pattern',
              description: 'description 5',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
            Task(
              id: 6,
              title: 'title 6',
              description: 'description 6 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 6),
            ),
            Task(
              id: 7,
              title: 'title 7 matching-pattern',
              description: 'description 7 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 7),
            ),
            Task(
              id: 8,
              title: 'title 8',
              description: 'description 8',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 8),
            ),
            Task(
              id: 9,
              title: 'title 9 matching-pattern',
              description: 'description 9',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 9),
            ),
            Task(
              id: 10,
              title: 'title 10',
              description: 'description 10 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 10),
            ),
            Task(
              id: 11,
              title: 'title 11 matching-pattern',
              description: 'description 11 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 11),
            ),
            Task(
              id: 12,
              title: 'title 12',
              description: 'description 12',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 12),
            ),
            Task(
              id: 13,
              title: 'title 13 matching-pattern',
              description: 'description 13',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 13),
            ),
            Task(
              id: 14,
              title: 'title 14',
              description: 'description 14 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 14),
            ),
            Task(
              id: 15,
              title: 'title 15 matching-pattern',
              description: 'description 15 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 15),
            ),
          ];
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          final referenceTask = PartialTask(
            title: () => 'matching-pattern',
            isCompleted: () => false,
            description: () => '',
          );
          await storage.deleteAll(referenceTask: referenceTask);
          final resultingTaskSnapshots = await storage.store.find(database);

          bool shouldBeKept(Task task) {
            final Task(:title, :isCompleted) = task;
            final noMatchInTitle = !title.contains('matching-pattern');
            if (noMatchInTitle) return true;
            final noMatchInStatus = isCompleted != false;
            return noMatchInStatus;
          }

          final expectedResultingTasks = [
            for (final task in tasks)
              if (shouldBeKept(task)) task,
          ];
          expect(
            resultingTaskSnapshots,
            hasLength(expectedResultingTasks.length),
          );
          final resultingTasks = [
            for (final taskSnapshot in resultingTaskSnapshots)
              taskSnapshot.toTask(),
          ];
          expect(resultingTasks, unorderedEquals(expectedResultingTasks));
        },
      );

      test(
        '''

│  ├─ THAT has several task records
AND a reference task
├─ THAT includes an empty description matcher
WHEN a delete operation is performed with the reference task
THEN the task records matching the reference task are dropped
AND the task records not matching the reference task are kept
''',
        () async {
          final tasks = [
            Task(
              id: 0,
              title: 'title 0',
              description: 'description 0',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 1 matching-pattern',
              description: 'description 1',
              isCompleted: true,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 2',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 3 matching-pattern',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 4',
              description: 'description 4',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 5 matching-pattern',
              description: 'description 5',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
            Task(
              id: 6,
              title: 'title 6',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: false,
              createdAt: DateTime(2020, 1, 6),
            ),
            Task(
              id: 7,
              title: 'title 7 matching-pattern',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: false,
              createdAt: DateTime(2020, 1, 7),
            ),
            Task(
              id: 8,
              title: 'title 8',
              description: 'description 8',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 8),
            ),
            Task(
              id: 9,
              title: 'title 9 matching-pattern',
              description: 'description 9',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 9),
            ),
            Task(
              id: 10,
              title: 'title 10',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: true,
              createdAt: DateTime(2020, 1, 10),
            ),
            Task(
              id: 11,
              title: 'title 11 matching-pattern',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: true,
              createdAt: DateTime(2020, 1, 11),
            ),
            Task(
              id: 12,
              title: 'title 12',
              description: 'description 12',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 12),
            ),
            Task(
              id: 13,
              title: 'title 13 matching-pattern',
              description: 'description 13',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 13),
            ),
            Task(
              id: 14,
              title: 'title 14',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: false,
              createdAt: DateTime(2020, 1, 14),
            ),
            Task(
              id: 15,
              title: 'title 15 matching-pattern',
              // ignore: avoid_redundant_argument_values
              description: null,
              isCompleted: false,
              createdAt: DateTime(2020, 1, 15),
            ),
          ];
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          final referenceTask = PartialTask(
            title: () => 'matching-pattern',
            description: () => null,
            isCompleted: () => false,
          );
          await storage.deleteAll(referenceTask: referenceTask);
          final resultingTaskSnapshots = await storage.store.find(database);

          bool shouldBeKept(Task task) {
            final Task(:title, :description, :isCompleted) = task;
            final noMatchInTitle = !title.contains('matching-pattern');
            if (noMatchInTitle) return true;
            final noMatchInDescription =
                description != null && description.isNotEmpty;
            if (noMatchInDescription) return true;
            final noMatchInStatus = isCompleted != false;
            return noMatchInStatus;
          }

          final expectedResultingTasks = [
            for (final task in tasks)
              if (shouldBeKept(task)) task,
          ];
          expect(
            resultingTaskSnapshots,
            hasLength(expectedResultingTasks.length),
          );
          final resultingTasks = [
            for (final taskSnapshot in resultingTaskSnapshots)
              taskSnapshot.toTask(),
          ];
          expect(resultingTasks, unorderedEquals(expectedResultingTasks));
        },
      );

      test(
        '''

│  ├─ THAT has several task records
WHEN a delete operation is performed with no reference task
THEN all task records are dropped
''',
        () async {
          final tasks = List.generate(
            30,
            (index) => Task(
              id: index,
              title: 'title $index',
              description: 'description $index',
              isCompleted: index % 7 == 0,
              createdAt: DateTime.now(),
            ),
          );
          await storage.store.records([
            for (final task in tasks) task.id,
          ]).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final initialTasksCount = await storage.store.count(database);
          expect(initialTasksCount, tasks.length);
          await storage.deleteAll();
          final resultingTaskSnapshotsCount =
              await storage.store.count(database);
          expect(resultingTaskSnapshotsCount, isZero);
        },
      );

      test(
        '''

AND a task
WHEN the task is inserted
THEN a task record is registered
''',
        () async {
          final task = Task(
            id: 10,
            title: 'title',
            description: 'description',
            isCompleted: false,
            createdAt: DateTime.now(),
          );
          final existingTasksCount = await storage.store.count(database);
          expect(existingTasksCount, isZero);
          await storage.insert(task: task);
          final resultingTaskSnapshots = await storage.store.find(database);
          expect(resultingTaskSnapshots, hasLength(1));
          final resultingTaskSnapshot = resultingTaskSnapshots.single;
          expect(resultingTaskSnapshot.toTask(), task);
        },
      );

      test(
        '''

│  ├─ THAT has several task records
WHEN all tasks are marked as completed
THEN all task records are updated
''',
        () async {
          final tasks = List.generate(
            30,
            (index) => Task(
              id: index,
              title: 'title $index',
              description: 'description $index',
              isCompleted: index % 7 == 0,
              createdAt: DateTime.now(),
            ),
          );
          await storage.store.records(
            [for (final task in tasks) task.id],
          ).add(
            database,
            [for (final task in tasks) task.toSembastJson()],
          );
          final filter = Filter.equals(
            SembastTask.statusFieldJsonKey,
            false,
          );
          final initialIncompleteTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(initialIncompleteTasksCount, isPositive);
          await storage.markAllAsCompleted();
          final resultingIncompleteTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(resultingIncompleteTasksCount, isZero);
        },
      );

      test(
        '''

AND the ID of a registered task
AND the valid partial task data
WHEN the task is updated
THEN a task record is updated
''',
        () async {
          final task = Task(
            id: 53,
            title: 'title',
            description: 'description',
            isCompleted: false,
            createdAt: DateTime.now(),
          );
          await storage.store
              .record(task.id)
              .add(database, task.toSembastJson());
          final existingTasksCount = await storage.store.count(database);
          expect(existingTasksCount, 1);
          const newTitle = 'new title';
          const newDescription = 'new description';
          const newStatus = true;
          final filter = Filter.and([
            Filter.byKey(task.id),
            Filter.equals(
              SembastTask.titleFieldJsonKey,
              newTitle,
            ),
            Filter.equals(
              SembastTask.descriptionFieldJsonKey,
              newDescription,
            ),
            Filter.equals(
              SembastTask.statusFieldJsonKey,
              newStatus,
            ),
          ]);
          final existingMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(existingMatchingTasksCount, isZero);
          await storage.update(
            taskId: task.id,
            partialTask: PartialTask(
              title: () => newTitle,
              description: () => newDescription,
              isCompleted: () => newStatus,
            ),
          );
          final resultingMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(resultingMatchingTasksCount, existingMatchingTasksCount + 1);
        },
      );

      test(
        '''

AND the invalid data for a new task
WHEN the task is created
THEN an exception is thrown
AND no task record is registered
''',
        () async {
          const newTask = NewTask(
            title: '',
            description: 'description',
          );
          final existingTasksCount = await storage.store.count(database);
          expect(existingTasksCount, isZero);
          expect(
            () async => storage.create(newTask: newTask),
            throwsA(isA<CreateTaskFailureEmptyTitle>()),
          );
          final resultingTasksCount = await storage.store.count(database);
          expect(resultingTasksCount, isZero);
        },
      );

      test(
        '''

AND the ID of a registered task
AND the invalid partial task data
WHEN the task is updated
THEN an exception is thrown
AND no task record is updated
''',
        () async {
          final task = Task(
            id: 573,
            title: 'title',
            description: 'description',
            isCompleted: false,
            createdAt: DateTime.now(),
          );
          await storage.store
              .record(task.id)
              .add(database, task.toSembastJson());
          final existingTasksCount = await storage.store.count(database);
          expect(existingTasksCount, 1);
          const newTitle = '';
          const newDescription = 'new description';
          const newStatus = true;
          final filter = Filter.and([
            Filter.byKey(task.id),
            Filter.equals(
              SembastTask.titleFieldJsonKey,
              newTitle,
            ),
            Filter.equals(
              SembastTask.descriptionFieldJsonKey,
              newDescription,
            ),
            Filter.equals(
              SembastTask.statusFieldJsonKey,
              newStatus,
            ),
          ]);
          final existingMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(existingMatchingTasksCount, isZero);
          expect(
            () async => storage.update(
              taskId: task.id,
              partialTask: PartialTask(
                title: () => newTitle,
                description: () => newDescription,
                isCompleted: () => newStatus,
              ),
            ),
            throwsA(isA<UpdateTaskFailureEmptyTitle>()),
          );
          final resultingMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(resultingMatchingTasksCount, isZero);
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND the ID of a registered task
WHEN the task is requested
THEN the task is returned
''',
        () async {
          const taskId = 3745;
          final task = Task(
            id: taskId,
            title: 'title',
            description: 'description',
            isCompleted: false,
            createdAt: DateTime.now(),
          );
          await storage.store
              .record(taskId)
              .add(database, task.toSembastJson());
          final filter = Filter.byKey(taskId);
          final initialMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(initialMatchingTasksCount, 1);
          final retrievedTask = await storage.getById(taskId);
          expect(retrievedTask, isNotNull);
          expect(retrievedTask, task);
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND the ID of an unregistered task
WHEN the task is requested
THEN null is returned
''',
        () async {
          const taskId = 3952;
          final filter = Filter.byKey(taskId);
          final initialMatchingTasksCount = await storage.store.count(
            database,
            filter: filter,
          );
          expect(initialMatchingTasksCount, isZero);
          final retrievedTask = await storage.getById(taskId);
          expect(retrievedTask, isNull);
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND pagination parameters
WHEN a tasks page is watched
├─ THAT are not filtered by their status
├─ AND are not filtered by their content
THEN the paginated tasks that match the conditions are continuously emitted as they change
''',
        () async {
          final stream = storage.watchPaginated(
            offset: 2,
            limit: 2,
            statusFilter: TasksStatusFilter.all,
          );

          // Stage 00
          final tasksForStage00 = <Task>[
            Task(
              id: 0,
              title: 'title 00',
              description: 'description 00',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 01',
              isCompleted: false,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 02',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
          ];
          final sortedTasksForStage00 = [...tasksForStage00]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage00 =
              sortedTasksForStage00.skip(2).take(2).toList();

          // Stage 01
          final newTaskInStage01 = Task(
            id: 3,
            title: 'title 03',
            isCompleted: true,
            createdAt: DateTime(2020, 1, 3),
          );
          final tasksForStage01 = <Task>[
            ...tasksForStage00,
            newTaskInStage01,
          ];
          final sortedTasksForStage01 = [...tasksForStage01]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage01 =
              sortedTasksForStage01.skip(2).take(2).toList();

          // Stage 02
          final tasksForStage02 = <Task>[
            for (final task in tasksForStage01)
              if (!task.isCompleted) task,
          ];
          final sortedTasksForStage02 = [...tasksForStage02]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage02 =
              sortedTasksForStage02.skip(2).take(2).toList();

          // Stage 03
          // final tasksForStage03 = <Task>[
          //   for (final task in tasksForStage02)
          //     if (task.description == null)
          //       task.copyWith(description: 'updated description')
          //     else
          //       task,
          // ];
          // final sortedTasksForStage03 = [...tasksForStage03]
          //   ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          // final expectedTasksForStage03 =
          //     sortedTasksForStage03.skip(2).take(2).toList();

          unawaited(
            expectLater(
              stream,
              emitsInOrder(
                [
                  List<Task>.empty(), // initially empty,
                  orderedEquals(expectedTasksForStage00),
                  orderedEquals(expectedTasksForStage01),
                  orderedEquals(expectedTasksForStage02),

                  // Not emitted since the tasks have not been updated
                  // orderedEquals(expectedTasksForStage03),
                ],
              ),
            ),
          );

          // Stage 00
          await storage.store.records([
            for (final task in tasksForStage00) task.id,
          ]).add(
            database,
            [for (final task in tasksForStage00) task.toSembastJson()],
          );

          // Stage 01
          await storage.store
              .record(newTaskInStage01.id)
              .add(database, newTaskInStage01.toSembastJson());

          // Stage 02
          await storage.store.delete(
            database,
            finder: Finder(
              filter: Filter.equals(
                SembastTask.statusFieldJsonKey,
                true,
              ),
            ),
          );

          // Stage 03
          await storage.store.update(
            database,
            {SembastTask.descriptionFieldJsonKey: 'updated description'},
            finder: Finder(
              filter: Filter.isNull(SembastTask.descriptionFieldJsonKey),
            ),
          );
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND pagination parameters
WHEN a tasks page is watched
├─ THAT are filtered by their status (completed)
├─ AND are filtered by their content
THEN the paginated tasks that match the conditions are continuously emitted as they change
''',
        () async {
          final stream = storage.watchPaginated(
            offset: 2,
            limit: 2,
            statusFilter: TasksStatusFilter.completed,
            searchTerm: 'matching-pattern',
          );

          bool matches(Task task) =>
              task.isCompleted &&
              (task.title.contains('matching-pattern') ||
                  (task.description?.contains('matching-pattern') ?? false));

          // Stage 00
          final tasksForStage00 = <Task>[
            Task(
              id: 0,
              title: 'title 00',
              description: 'description 00 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 01',
              isCompleted: false,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 02',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 03',
              description: 'description 03 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 04',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 05',
              description: 'description 05 matching-pattern',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
          ];
          // final sortedTasksForStage00 = [...tasksForStage00]
          //   ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          // final expectedTasksForStage00 =
          //     sortedTasksForStage00.where(matches).skip(2).take(2).toList();

          // Stage 01
          final newTaskInStage01 = Task(
            id: 6,
            title: 'title 06 matching-pattern',
            isCompleted: true,
            createdAt: DateTime(2020, 1, 6),
          );
          final tasksForStage01 = <Task>[
            ...tasksForStage00,
            newTaskInStage01,
          ];
          final sortedTasksForStage01 = [...tasksForStage01]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage01 =
              sortedTasksForStage01.where(matches).skip(2).take(2).toList();

          // Stage 02
          final tasksForStage02 = <Task>[
            for (final task in tasksForStage01)
              if (!task.title.contains('00')) task,
          ];
          final sortedTasksForStage02 = [...tasksForStage02]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage02 =
              sortedTasksForStage02.where(matches).skip(2).take(2).toList();

          // Stage 03
          // final tasksForStage03 = <Task>[
          //   for (final task in tasksForStage02)
          //     if (task.description == null)
          //       task.copyWith(description: 'updated description')
          //     else
          //       task,
          // ];
          // final sortedTasksForStage03 = [...tasksForStage03]
          //   ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          // final expectedTasksForStage03 = sortedTasksForStage03
          //     .where(matches)
          //     .skip(2)
          //     .take(2)
          //     .toList();

          unawaited(
            expectLater(
              stream,
              emitsInOrder(
                [
                  List<Task>.empty(), // initially empty,

                  // Not emitted since the tasks have not been updated
                  // orderedEquals(expectedTasksForStage00),

                  orderedEquals(expectedTasksForStage01),
                  orderedEquals(expectedTasksForStage02),

                  // Not emitted since the tasks have not been updated
                  // orderedEquals(expectedTasksForStage03),
                ],
              ),
            ),
          );

          // Stage 00
          await storage.store.records([
            for (final task in tasksForStage00) task.id,
          ]).add(
            database,
            [for (final task in tasksForStage00) task.toSembastJson()],
          );

          // Stage 01
          await storage.store
              .record(newTaskInStage01.id)
              .add(database, newTaskInStage01.toSembastJson());

          // Stage 02
          await storage.store.delete(
            database,
            finder: Finder(
              filter: Filter.matches(
                SembastTask.titleFieldJsonKey,
                '00',
              ),
            ),
          );

          // Stage 03
          await storage.store.update(
            database,
            {SembastTask.descriptionFieldJsonKey: 'updated description'},
            finder: Finder(
              filter: Filter.isNull(SembastTask.descriptionFieldJsonKey),
            ),
          );
        },
      );

      test(
        '''

│  ├─ THAT has task records
AND pagination parameters
WHEN a tasks page is watched
├─ THAT are filtered by their status (uncompleted)
├─ AND are not filtered by their content
THEN the paginated tasks that match the conditions are continuously emitted as they change
''',
        () async {
          final stream = storage.watchPaginated(
            offset: 2,
            limit: 2,
            statusFilter: TasksStatusFilter.uncompleted,
          );

          bool matches(Task task) => !task.isCompleted;

          // Stage 00
          final tasksForStage00 = <Task>[
            Task(
              id: 0,
              title: 'title 00',
              description: 'description 00',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 0),
            ),
            Task(
              id: 1,
              title: 'title 01',
              isCompleted: false,
              // ignore: avoid_redundant_argument_values
              createdAt: DateTime(2020, 1, 1),
            ),
            Task(
              id: 2,
              title: 'title 02',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 2),
            ),
            Task(
              id: 3,
              title: 'title 03',
              description: 'description 03',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            ),
            Task(
              id: 4,
              title: 'title 04',
              description: 'description 04',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 4),
            ),
            Task(
              id: 5,
              title: 'title 05',
              isCompleted: false,
              createdAt: DateTime(2020, 1, 5),
            ),
          ];
          final sortedTasksForStage00 = [...tasksForStage00]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage00 =
              sortedTasksForStage00.where(matches).skip(2).take(2).toList();

          // Stage 01
          final newTaskInStage01 = Task(
            id: 6,
            title: 'title 06',
            isCompleted: true,
            createdAt: DateTime(2020, 1, 6),
          );
          final tasksForStage01 = <Task>[
            ...tasksForStage00,
            newTaskInStage01,
          ];
          // final sortedTasksForStage01 = [...tasksForStage01]
          //   ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          // final expectedTasksForStage01 = sortedTasksForStage01
          //     .where(matches)
          //     .skip(2)
          //     .take(2)
          //     .toList();

          // Stage 02
          final tasksForStage02 = <Task>[
            for (final task in tasksForStage01)
              if (!task.title.contains('00')) task,
          ];
          // final sortedTasksForStage02 = [...tasksForStage02]
          //   ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          // final expectedTasksForStage02 = sortedTasksForStage02
          //     .where(matches)
          //     .skip(2)
          //     .take(2)
          //     .toList();

          // Stage 03
          final tasksForStage03 = <Task>[
            for (final task in tasksForStage02)
              if (task.description == null)
                task.copyWith(description: 'updated description')
              else
                task,
          ];
          final sortedTasksForStage03 = [...tasksForStage03]
            ..sort((tA, tB) => tB.createdAt.compareTo(tA.createdAt));
          final expectedTasksForStage03 =
              sortedTasksForStage03.where(matches).skip(2).take(2).toList();

          unawaited(
            expectLater(
              stream,
              emitsInOrder(
                [
                  List<Task>.empty(), // initially empty,
                  orderedEquals(expectedTasksForStage00),

                  // Not emitted since the tasks have not been updated
                  // orderedEquals(expectedTasksForStage01),

                  // Not emitted since the tasks have not been updated
                  // orderedEquals(expectedTasksForStage02),

                  orderedEquals(expectedTasksForStage03),
                ],
              ),
            ),
          );

          // Stage 00
          await storage.store.records([
            for (final task in tasksForStage00) task.id,
          ]).add(
            database,
            [for (final task in tasksForStage00) task.toSembastJson()],
          );

          // Stage 01
          await storage.store
              .record(newTaskInStage01.id)
              .add(database, newTaskInStage01.toSembastJson());

          // Stage 02
          await storage.store.delete(
            database,
            finder: Finder(
              filter: Filter.matches(
                SembastTask.titleFieldJsonKey,
                '00',
              ),
            ),
          );

          // Stage 03
          await storage.store.update(
            database,
            {SembastTask.descriptionFieldJsonKey: 'updated description'},
            finder: Finder(
              filter: Filter.isNull(SembastTask.descriptionFieldJsonKey),
            ),
          );
        },
      );

      test(
        '''

│  ├─ THAT has task records
WHEN the tasks count is watched
├─ THAT are not filtered by their status
├─ AND are not filtered by their content
THEN the quantity of persisted tasks that match the conditions is continuously emitted as it changes
''',
        () async {
          final stream = storage.watchCount(
            statusFilter: TasksStatusFilter.all,
          );

          unawaited(
            expectLater(
              stream,
              emitsInOrder(
                [
                  0, // initially empty,
                  2,
                  3,
                  1,

                  // Not emitted since the tasks count has not changed
                  // 1,
                ],
              ),
            ),
          );

          // Stage 00
          {
            final initialTasks = [
              Task(
                id: 0,
                title: 'title 00',
                description: 'description 00',
                isCompleted: true,
                createdAt: DateTime(2020, 1, 0),
              ),
              Task(
                id: 1,
                title: 'title 01',
                isCompleted: false,
                // ignore: avoid_redundant_argument_values
                createdAt: DateTime(2020, 1, 1),
              ),
            ];
            await storage.store.records([
              for (final task in initialTasks) task.id,
            ]).add(
              database,
              [for (final task in initialTasks) task.toSembastJson()],
            );
          }

          // Stage 01
          {
            final newTask = Task(
              id: 3,
              title: 'title 03',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            );
            await storage.store
                .record(newTask.id)
                .add(database, newTask.toSembastJson());
          }

          // Stage 02
          await storage.store.delete(
            database,
            finder: Finder(
              filter: Filter.equals(
                SembastTask.statusFieldJsonKey,
                true,
              ),
            ),
          );

          // Stage 03
          await storage.store.update(
            database,
            {SembastTask.descriptionFieldJsonKey: 'updated description'},
            finder: Finder(
              filter: Filter.isNull(SembastTask.descriptionFieldJsonKey),
            ),
          );
        },
      );

      test(
        '''

│  ├─ THAT has task records
WHEN the tasks count is watched
├─ THAT are filtered by their status (completed)
├─ AND are filtered by their content
THEN the quantity of persisted tasks that match the conditions is continuously emitted as it changes
''',
        () async {
          final stream = storage.watchCount(
            statusFilter: TasksStatusFilter.completed,
            searchTerm: 'matching-pattern',
          );

          unawaited(
            expectLater(
              stream,
              emitsInOrder(
                [
                  0, // initially empty,
                  1,
                  2,
                  0,
                ],
              ),
            ),
          );

          // Stage 00
          {
            final initialTasks = [
              Task(
                id: 0,
                title: 'title 00',
                description: 'description 00 matching-pattern',
                isCompleted: true,
                createdAt: DateTime(2020, 1, 0),
              ),
              Task(
                id: 1,
                title: 'title 01',
                isCompleted: false,
                // ignore: avoid_redundant_argument_values
                createdAt: DateTime(2020, 1, 1),
              ),
            ];
            await storage.store.records([
              for (final task in initialTasks) task.id,
            ]).add(
              database,
              [for (final task in initialTasks) task.toSembastJson()],
            );
          }

          // Stage 01
          {
            final newTask = Task(
              id: 3,
              title: 'title 03 matching-pattern',
              isCompleted: true,
              createdAt: DateTime(2020, 1, 3),
            );
            await storage.store
                .record(newTask.id)
                .add(database, newTask.toSembastJson());
          }

          // Stage 02
          await storage.store.delete(
            database,
            finder: Finder(
              filter: Filter.equals(
                SembastTask.statusFieldJsonKey,
                true,
              ),
            ),
          );

          // Stage 03
          await storage.store.update(
            database,
            {SembastTask.descriptionFieldJsonKey: 'updated description'},
            finder: Finder(
              filter: Filter.isNull(SembastTask.descriptionFieldJsonKey),
            ),
          );
        },
      );
    },
  );

  test(
    '''

GIVEN a Sembast database
WHEN a raw migration is performed
THEN the action is properly executed
''',
    () async {
      final databaseFactoryMemory = newDatabaseFactoryMemory();
      final database = await databaseFactoryMemory.openDatabase('/some/path');
      final result = await database.performRawMigration<String>(
        rawMigration: ({required tasksStore}) async {
          final initialCount = await tasksStore.count(database);
          expect(initialCount, isZero);
          await tasksStore.record(0).put(database, {'key': 'value'});
          final resultingCount = await tasksStore.count(database);
          expect(resultingCount, 1);
          final record = await tasksStore.find(database);
          expect(record, hasLength(1));
          final snapshot = record.single;
          expect(snapshot.key, 0);
          expect(snapshot.value, {'key': 'value'});
          return 'result';
        },
      );
      expect(result, 'result');
    },
  );
}
