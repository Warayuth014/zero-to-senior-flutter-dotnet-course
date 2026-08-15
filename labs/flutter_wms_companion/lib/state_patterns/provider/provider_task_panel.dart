import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/tasks/task_repository.dart';
import '../../features/tasks/task_store.dart';
import '../pattern_task_list.dart';

class ProviderTaskPanel extends StatelessWidget {
  const ProviderTaskPanel({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => TaskStore(repository)..load(),
    child: const _ProviderTaskBody(),
  );
}

class _ProviderTaskBody extends StatelessWidget {
  const _ProviderTaskBody();

  @override
  Widget build(BuildContext context) {
    final taskCount = context.select<TaskStore, int>(
      (store) => store.tasks.length,
    );
    return Column(
      children: [
        ListTile(
          title: const Text('Provider + ChangeNotifier'),
          trailing: Text('$taskCount tasks'),
        ),
        Expanded(
          child: Consumer<TaskStore>(
            builder: (context, store, _) {
              if (store.initialLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return PatternTaskList(
                tasks: store.tasks,
                refreshing: store.refreshing,
                error: store.error,
                isBusy: store.isBusy,
                onRefresh: store.load,
                onComplete: store.complete,
              );
            },
          ),
        ),
      ],
    );
  }
}
