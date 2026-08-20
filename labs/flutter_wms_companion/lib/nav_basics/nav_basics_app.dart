import 'package:flutter/material.dart';

import 'nav_feedback.dart';
import 'nav_models.dart';
import 'task_detail_screen.dart';

/// แอปตัวอย่างของ Part 5 — ใช้ Navigator แบบ stack ล้วน ยังไม่มี router
class NavBasicsApp extends StatelessWidget {
  const NavBasicsApp({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nav Basics',
    theme: ThemeData(useMaterial3: true),
    home: LoginScreen(session: session),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.session});

  final AppSession session;

  void _signIn(BuildContext context) {
    session.signIn('somchai');
    // pushReplacement แทนหน้าเข้าสู่ระบบด้วยหน้าหลัก
    // ถ้าใช้ push เฉย ๆ ปุ่มย้อนกลับจะพากลับเข้าหน้าเข้าสู่ระบบเดิม
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => HomeShell(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
    body: Center(
      child: FilledButton(
        key: const Key('sign-in-button'),
        onPressed: () => _signIn(context),
        child: const Text('เข้าสู่ระบบ'),
      ),
    ),
  );
}

/// โครงหลักของแอปหลังล็อกอิน — แถบล่างสามปุ่ม
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.session});

  final AppSession session;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const List<String> _titles = ['งานวันนี้', 'ประวัติ', 'ของฉัน'];

  int _tabIndex = 0;

  /// ออกจากระบบ — ล้าง stack ทั้งหมดแล้ววางหน้าเข้าสู่ระบบเป็นหน้าเดียวที่เหลือ
  ///
  /// pushReplacement อย่างเดียวไม่พอ เพราะมันแทนแค่ route บนสุด
  /// ถ้าผู้ใช้อยู่ลึกกว่านั้น หน้าเก่าจะยังค้างอยู่ใต้หน้าเข้าสู่ระบบ
  /// แล้วปุ่มย้อนกลับจะพากลับเข้าไปในข้อมูลของ session ที่ออกไปแล้ว
  void _signOut() {
    widget.session.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginScreen(session: widget.session),
      ),
      (route) => false, // ไม่เก็บ route ไหนไว้เลย
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_titles[_tabIndex]),
      actions: [
        IconButton(
          key: const Key('settings-button'),
          icon: const Icon(Icons.settings),
          onPressed: () => showSettingsSheet(
            context,
            session: widget.session,
            onSignOut: _signOut,
          ),
        ),
      ],
    ),
    // IndexedStack เก็บทุกแท็บไว้ในต้นไม้ สลับกลับมาแล้วยังอยู่ที่เดิม
    body: IndexedStack(
      index: _tabIndex,
      children: [
        const TaskListTab(),
        const HistoryTab(),
        ProfileTab(session: widget.session),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      key: const Key('bottom-nav'),
      selectedIndex: _tabIndex,
      onDestinationSelected: (index) => setState(() => _tabIndex = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.list_alt), label: 'งานวันนี้'),
        NavigationDestination(icon: Icon(Icons.history), label: 'ประวัติ'),
        NavigationDestination(icon: Icon(Icons.person), label: 'ของฉัน'),
      ],
    ),
  );
}

class TaskListTab extends StatefulWidget {
  const TaskListTab({super.key});

  @override
  State<TaskListTab> createState() => _TaskListTabState();
}

class _TaskListTabState extends State<TaskListTab> {
  List<NavTask> _tasks = const [
    NavTask(id: 'T-001', palletCode: 'PAL-0101', quantity: 12),
    NavTask(id: 'T-002', palletCode: 'PAL-0102', quantity: 8),
    NavTask(id: 'T-003', palletCode: 'PAL-0103', quantity: 20),
  ];

  /// รหัสงานที่ผู้ใช้กดพักไว้ ยังไม่ถือว่าเสร็จ
  final Set<String> _pausedIds = <String>{};

  Future<void> _openTask(NavTask task) async {
    // หยิบไว้ก่อน await เพราะหลังจากนี้หน้าจออาจถูกปิดไปแล้ว (4.9)
    final messenger = ScaffoldMessenger.of(context);

    final outcome = await Navigator.of(context).push<TaskOutcome>(
      MaterialPageRoute<TaskOutcome>(
        builder: (_) => TaskDetailScreen(task: task),
      ),
    );
    if (!mounted) return;

    switch (outcome) {
      case TaskSaved(task: final saved):
        setState(() {
          _tasks = [
            for (final item in _tasks) item.id == saved.id ? saved : item,
          ];
          _pausedIds.remove(saved.id);
        });
        showResultBanner(messenger, 'บันทึก ${saved.id} แล้ว');
      case TaskPaused(draft: final draft):
        setState(() {
          _tasks = [
            for (final item in _tasks) item.id == draft.id ? draft : item,
          ];
          _pausedIds.add(draft.id);
        });
        showResultBanner(messenger, 'พัก ${draft.id} ไว้ก่อน');
      case TaskCancelled():
        showResultBanner(messenger, 'ยกเลิกการแก้ไข ${task.id}');
      // ผู้ใช้กดปุ่มย้อนกลับโดยไม่ได้แก้อะไร — ไม่ต้องทำอะไรและไม่ต้องแจ้ง
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: const Key('task-list'),
    itemCount: _tasks.length,
    itemBuilder: (context, index) {
      final task = _tasks[index];
      return ListTile(
        key: ValueKey<String>(task.id),
        title: Text('${task.id} · ${task.palletCode}'),
        subtitle: Text('${task.quantity} ชิ้น'),
        trailing: _pausedIds.contains(task.id)
            ? const Icon(Icons.pause_circle_outline)
            : const Icon(Icons.chevron_right),
        onTap: () => _openTask(task),
      );
    },
  );
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    key: Key('history-tab'),
    child: Text('ประวัติย้อนหลังดูได้จากเว็บ'),
  );
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('profile-tab'),
    child: Text('ผู้ใช้: ${session.username}'),
  );
}
