import 'package:altoke_app/app/app.dart';
import 'package:altoke_app/l10n/l10n.dart';
import 'package:altoke_app/tasks/tasks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SliverTasksAppBar extends ConsumerWidget {
  const SliverTasksAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SliverResponsiveAppBar(
      title: Text(
        l10n.tasksTasksListAppBarTitle,
        key: const Key('<tasks::sliver-tasks-app-bar::title>'),
      ),
      actions: const [
        MarkAllTasksAsCompletedButton(),
        DeleteCompletedTasksButton(),
      ],
    );
  }
}

class MarkAllTasksAsCompletedButton extends ConsumerWidget {
  const MarkAllTasksAsCompletedButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen<TasksMutationState>(
      tasksMutatorPod,
      (previousState, newState) {
        if (previousState is! TasksMarkingAllAsCompleted) return;
        final message = switch (newState) {
          TasksMutationIdle() =>
            l10n.tasksAllTasksMarkedAsCompletedSnackbarMessage,
          TasksMutationFailure() =>
            l10n.tasksFailedToMarkAllTasksAsCompletedSnackbarMessage,
          _ => null,
        };
        if (message == null) return;
        final snackBar = SnackBar(
          content: Text(message),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      },
    );
    return IconButton(
      tooltip: l10n.tasksMarkAllTasksAsCompletedButtonTooltip,
      icon: const Icon(Icons.done_all),
      onPressed: () {
        ref.read(tasksMutatorPod.notifier).markAllAsCompleted();
      },
    );
  }
}

class DeleteCompletedTasksButton extends ConsumerWidget {
  const DeleteCompletedTasksButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen<TasksMutationState>(
      tasksMutatorPod,
      (previousState, newState) {
        if (previousState is! TasksDeletingAllCompleted) return;
        final message = switch (newState) {
          TasksMutationIdle() =>
            l10n.tasksAllCompletedTasksDeletedSnackbarMessage,
          TasksMutationFailure() =>
            l10n.tasksFailedToDeleteAllCompletedTasksSnackbarMessage,
          _ => null,
        };
        if (message == null) return;
        final snackBar = SnackBar(
          content: Text(message),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      },
    );
    return IconButton(
      tooltip: l10n.tasksDeleteAllCompletedTasksButtonTooltip,
      icon: const Icon(Icons.remove_done),
      onPressed: () {
        ref.read(tasksMutatorPod.notifier).deleteAllCompletedTasks();
      },
    );
  }
}
