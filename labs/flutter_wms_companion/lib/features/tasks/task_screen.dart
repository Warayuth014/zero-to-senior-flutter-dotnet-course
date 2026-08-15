import 'package:flutter/material.dart';

import 'task_store.dart';
import 'wms_task.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key, required this.store});

  final TaskStore store;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('งานขนย้าย'),
      actions: [
        IconButton(
          tooltip: 'โหลดใหม่',
          onPressed: widget.store.load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        if (widget.store.loading && widget.store.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.store.error case final error?) {
          return _ErrorView(message: error, onRetry: widget.store.load);
        }
        if (widget.store.tasks.isEmpty) {
          return const Center(child: Text('ไม่มีงานค้าง'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: widget.store.tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = widget.store.tasks[index];
            return _TaskCard(
              task: task,
              busy: widget.store.loading,
              onComplete: () => widget.store.complete(task),
            );
          },
        );
      },
    ),
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.busy,
    required this.onComplete,
  });

  final WmsTask task;
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(task.id),
      subtitle: Text('${task.from} → ${task.to}'),
      trailing: FilledButton(
        onPressed: busy ? null : onComplete,
        child: const Text('เสร็จงาน'),
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    ),
  );
}
