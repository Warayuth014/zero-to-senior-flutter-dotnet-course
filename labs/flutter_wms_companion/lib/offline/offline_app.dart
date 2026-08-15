import 'package:flutter/material.dart';

import '../features/tasks/task_store.dart';
import '../features/tasks/wms_task.dart';
import 'offline_database.dart';
import 'offline_task_repository.dart';

class OfflineWmsApp extends StatefulWidget {
  const OfflineWmsApp({
    super.key,
    required this.database,
    required this.repository,
    required this.store,
  });

  final OfflineDatabase database;
  final OfflineTaskRepository repository;
  final TaskStore store;

  @override
  State<OfflineWmsApp> createState() => _OfflineWmsAppState();
}

class _OfflineWmsAppState extends State<OfflineWmsApp> {
  @override
  void dispose() {
    widget.store.dispose();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Offline-first WMS Lab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155eef)),
      useMaterial3: true,
    ),
    home: OfflineTaskScreen(
      store: widget.store,
      repository: widget.repository,
      database: widget.database,
    ),
  );
}

class OfflineTaskScreen extends StatefulWidget {
  const OfflineTaskScreen({
    super.key,
    required this.store,
    required this.repository,
    required this.database,
  });

  final TaskStore store;
  final OfflineTaskRepository repository;
  final OfflineDatabase database;

  @override
  State<OfflineTaskScreen> createState() => _OfflineTaskScreenState();
}

class _OfflineTaskScreenState extends State<OfflineTaskScreen> {
  bool _syncing = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Offline-first WMS'),
      actions: [
        IconButton(
          tooltip: 'ซิงก์ outbox',
          onPressed: _syncing ? null : _sync,
          icon: _syncing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        if (widget.store.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _OutboxStatus(database: widget.database, message: _syncMessage),
            if (widget.store.error case final error?)
              MaterialBanner(
                content: Text('กำลังใช้ข้อมูล cache · $error'),
                actions: [
                  TextButton(
                    onPressed: widget.store.load,
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.store.load,
                child: widget.store.tasks.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 180),
                          Center(child: Text('ไม่มีงานที่ต้องแสดง')),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.store.tasks.length,
                        itemBuilder: (context, index) {
                          final task = widget.store.tasks[index];
                          return Card(
                            child: ListTile(
                              title: Text(task.id),
                              subtitle: Text('${task.from} → ${task.to}'),
                              trailing: FilledButton(
                                onPressed: widget.store.isBusy(task.id)
                                    ? null
                                    : () => _complete(task),
                                child: const Text('เสร็จงาน'),
                              ),
                            ),
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

  Future<void> _complete(WmsTask task) async {
    await widget.store.complete(task);
    if (!mounted) return;
    setState(() => _syncMessage = '${task.id} อยู่ใน outbox รอซิงก์');
  }

  Future<void> _sync() async {
    setState(() {
      _syncing = true;
      _syncMessage = null;
    });
    final count = await widget.repository.syncPending();
    if (!mounted) return;
    await widget.store.load();
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _syncMessage = count == 0
          ? 'ยังไม่มีคำสั่งที่ซิงก์สำเร็จ'
          : 'ซิงก์สำเร็จ $count คำสั่ง';
    });
  }
}

class _OutboxStatus extends StatelessWidget {
  const _OutboxStatus({required this.database, required this.message});

  final OfflineDatabase database;
  final String? message;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<PendingCommand>>(
    stream: database.select(database.pendingCommands).watch(),
    builder: (context, snapshot) {
      final count = snapshot.data?.length ?? 0;
      return ListTile(
        leading: Icon(count == 0 ? Icons.cloud_done : Icons.cloud_upload),
        title: Text('Outbox รอซิงก์ $count คำสั่ง'),
        subtitle: message == null ? null : Text(message!),
      );
    },
  );
}
