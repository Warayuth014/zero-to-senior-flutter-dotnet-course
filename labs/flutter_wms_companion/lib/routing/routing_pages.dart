import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/tasks/task_repository.dart';
import '../features/tasks/task_store.dart';
import '../features/tasks/wms_task.dart';
import 'routing_session.dart';

class RoutingLoginPage extends StatelessWidget {
  const RoutingLoginPage({super.key, required this.session, this.from});

  final RoutingSession session;
  final String? from;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Routing Lab Login')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            const Text('เส้นทางนี้ต้องเข้าสู่ระบบ'),
            if (from case final intended?) ...[
              const SizedBox(height: 8),
              Text('หลัง login จะไป: $intended'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: session.signIn,
              child: const Text('เข้าสู่ระบบแบบ Lab'),
            ),
          ],
        ),
      ),
    ),
  );
}

class RoutingShell extends StatelessWidget {
  const RoutingShell({
    super.key,
    required this.navigationShell,
    required this.session,
  });

  final StatefulNavigationShell navigationShell;
  final RoutingSession session;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('go_router Mobile WMS Lab'),
      actions: [
        IconButton(
          tooltip: 'ออกจากระบบ',
          onPressed: session.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.task_outlined), label: 'Tasks'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    ),
  );
}

class RoutingHomePage extends StatelessWidget {
  const RoutingHomePage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Warehouse Home', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text(
        'ทุกหน้าหลักมี URL ที่เปิดตรงได้ ส่วน dialog ยังคงเป็น pageless route',
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () =>
            context.goNamed('tasks', queryParameters: {'status': 'waiting'}),
        icon: const Icon(Icons.filter_alt_outlined),
        label: const Text('เปิดงาน waiting ด้วย query'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => context.goNamed(
          'taskDetail',
          pathParameters: {'taskId': 'TASK-001'},
          queryParameters: {'source': 'dashboard'},
        ),
        icon: const Icon(Icons.link),
        label: const Text('Deep link ตัวอย่าง TASK-001'),
      ),
    ],
  );
}

class RoutingTaskListPage extends StatefulWidget {
  const RoutingTaskListPage({
    super.key,
    required this.repository,
    this.statusFilter,
  });

  final TaskRepository repository;
  final String? statusFilter;

  @override
  State<RoutingTaskListPage> createState() => _RoutingTaskListPageState();
}

class _RoutingTaskListPageState extends State<RoutingTaskListPage> {
  late final TaskStore store;

  @override
  void initState() {
    super.initState();
    store = TaskStore(widget.repository)..load();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (store.initialLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      final tasks = _filtered(store.tasks, widget.statusFilter);
      return Column(
        children: [
          ListTile(
            title: const Text('งานขนย้าย'),
            subtitle: Text(
              widget.statusFilter == null
                  ? 'ทุกสถานะ'
                  : 'filter: ${widget.statusFilter}',
            ),
            trailing: IconButton(
              tooltip: 'โหลดใหม่',
              onPressed: store.load,
              icon: const Icon(Icons.refresh),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('ทั้งหมด'),
                selected: widget.statusFilter == null,
                onSelected: (_) => context.goNamed('tasks'),
              ),
              for (final status in TaskStatus.values.take(2))
                FilterChip(
                  label: Text(status.name),
                  selected: widget.statusFilter == status.name,
                  onSelected: (_) => context.goNamed(
                    'tasks',
                    queryParameters: {'status': status.name},
                  ),
                ),
            ],
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('ไม่มี task ตาม filter'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        child: ListTile(
                          title: Text(task.id),
                          subtitle: Text('${task.from} → ${task.to}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.goNamed(
                            'taskDetail',
                            pathParameters: {'taskId': task.id},
                            queryParameters: {'source': 'task-list'},
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );

  List<WmsTask> _filtered(List<WmsTask> tasks, String? status) => status == null
      ? tasks
      : tasks.where((task) => task.status.name == status).toList();
}

class RoutingTaskDetailPage extends StatelessWidget {
  const RoutingTaskDetailPage({super.key, required this.taskId, this.source});

  final String taskId;
  final String? source;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Task $taskId', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text('Path parameter: $taskId'),
      Text('Query source: ${source ?? '-'}'),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () async {
          final result = await context.pushNamed<String>(
            'taskScan',
            pathParameters: {'taskId': taskId},
          );
          if (result == null || !context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ผลจาก scanner: $result')));
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('เปิด scanner แบบ full screen'),
      ),
    ],
  );
}

class RoutingScannerPage extends StatelessWidget {
  const RoutingScannerPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Scanner · $taskId')),
    body: Center(
      child: FilledButton.icon(
        onPressed: () => context.pop('PALLET-DEMO-001'),
        icon: const Icon(Icons.qr_code_2),
        label: const Text('จำลองสแกนสำเร็จ'),
      ),
    ),
  );
}

class RoutingSettingsPage extends StatelessWidget {
  const RoutingSettingsPage({super.key, required this.session});

  final RoutingSession session;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      const Text('route: /settings'),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: session.signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Logout และทดสอบ redirect'),
      ),
    ],
  );
}

class RoutingNotFoundPage extends StatelessWidget {
  const RoutingNotFoundPage({super.key, required this.uri, this.error});

  final Uri uri;
  final Object? error;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ไม่พบเส้นทาง')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(uri.toString()),
            if (error != null) Text(error.toString()),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.goNamed('home'),
              child: const Text('กลับ Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
