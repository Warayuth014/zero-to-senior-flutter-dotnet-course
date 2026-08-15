import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/tasks/task_repository.dart';
import '../pattern_task_list.dart';
import '../task_pattern_state.dart';
import 'task_cubit.dart';

class BlocTaskPanel extends StatelessWidget {
  const BlocTaskPanel({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TaskCubit(repository)..load(),
    child: BlocListener<TaskCubit, TaskPatternState>(
      listenWhen: (previous, current) =>
          previous.message != current.message && current.message != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.message!)));
      },
      child: const _BlocTaskBody(),
    ),
  );
}

class _BlocTaskBody extends StatelessWidget {
  const _BlocTaskBody();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        title: const Text('flutter_bloc + Cubit'),
        trailing: BlocSelector<TaskCubit, TaskPatternState, int>(
          selector: (state) => state.tasks.length,
          builder: (_, count) => Text('$count tasks'),
        ),
      ),
      Expanded(
        child: BlocBuilder<TaskCubit, TaskPatternState>(
          builder: (context, state) {
            if (state.refreshing && state.tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final cubit = context.read<TaskCubit>();
            return PatternTaskList(
              tasks: state.tasks,
              refreshing: state.refreshing,
              error: state.error,
              isBusy: state.isBusy,
              onRefresh: cubit.load,
              onComplete: cubit.complete,
            );
          },
        ),
      ),
    ],
  );
}
