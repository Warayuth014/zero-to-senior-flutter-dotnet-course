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
        if (widget.store.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.store.error case final error?
            when widget.store.tasks.isEmpty) {
          return _ErrorView(message: error, onRetry: widget.store.load);
        }
        if (widget.store.tasks.isEmpty) {
          return const Center(child: Text('ไม่มีงานค้าง'));
        }
        return Column(
          children: [
            if (widget.store.refreshing) const LinearProgressIndicator(),
            if (widget.store.error case final error?)
              MaterialBanner(
                content: Text(error),
                actions: [
                  TextButton(
                    onPressed: widget.store.load,
                    child: const Text('โหลดใหม่'),
                  ),
                ],
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.store.load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.store.tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = widget.store.tasks[index];
                    return _TaskCard(
                      key: ValueKey(task.id),
                      task: task,
                      busy: widget.store.isBusy(task.id),
                      onComplete: () => _confirmAndComplete(task),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _confirmAndComplete(WmsTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันปิด ${task.id}?'),
        content: Text('${task.from} → ${task.to}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.store.complete(task);
    if (!mounted) return;
    final message = widget.store.actionMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.busy,
    required this.onComplete,
  });

  final WmsTask task;
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'งาน ${task.id} จาก ${task.from} ไป ${task.to}',
    child: Card(
      child: ListTile(
        title: Text(task.id),
        subtitle: Text('${task.from} → ${task.to} · ${task.status.name}'),
        trailing: SizedBox(
          width: 104,
          child: FilledButton(
            onPressed: busy ? null : onComplete,
            child: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('เสร็จงาน'),
          ),
        ),
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
