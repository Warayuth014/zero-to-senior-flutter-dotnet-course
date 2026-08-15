import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pattern_task_list.dart';
import 'riverpod_task_controller.dart';

class RiverpodTaskPanel extends ConsumerWidget {
  const RiverpodTaskPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(riverpodTaskProvider);
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(riverpodTaskProvider),
          child: Text('โหลดใหม่: $error'),
        ),
      ),
      data: (state) => Column(
        children: [
          ListTile(
            title: const Text('Riverpod AsyncNotifier'),
            trailing: Text('${state.tasks.length} tasks'),
          ),
          Expanded(
            child: PatternTaskList(
              tasks: state.tasks,
              refreshing: state.refreshing,
              error: state.error,
              isBusy: state.isBusy,
              onRefresh: ref.read(riverpodTaskProvider.notifier).refresh,
              onComplete: ref.read(riverpodTaskProvider.notifier).complete,
            ),
          ),
        ],
      ),
    );
  }
}
