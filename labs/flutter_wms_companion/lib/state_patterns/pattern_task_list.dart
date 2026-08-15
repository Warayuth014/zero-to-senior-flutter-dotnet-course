import 'package:flutter/material.dart';

import '../features/tasks/wms_task.dart';

class PatternTaskList extends StatelessWidget {
  const PatternTaskList({
    super.key,
    required this.tasks,
    required this.refreshing,
    required this.error,
    required this.isBusy,
    required this.onRefresh,
    required this.onComplete,
  });

  final List<WmsTask> tasks;
  final bool refreshing;
  final String? error;
  final bool Function(String taskId) isBusy;
  final Future<void> Function() onRefresh;
  final Future<void> Function(WmsTask task) onComplete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (refreshing) const LinearProgressIndicator(),
      if (error case final message?)
        MaterialBanner(
          content: Text(message),
          actions: [
            TextButton(onPressed: onRefresh, child: const Text('โหลดใหม่')),
          ],
        ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: tasks.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('ไม่มีงานค้าง')),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final busy = isBusy(task.id);
                    return Card(
                      key: ValueKey(task.id),
                      child: ListTile(
                        title: Text(task.id),
                        subtitle: Text('${task.from} → ${task.to}'),
                        trailing: FilledButton(
                          onPressed: busy ? null : () => onComplete(task),
                          child: busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('เสร็จงาน'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ],
  );
}
