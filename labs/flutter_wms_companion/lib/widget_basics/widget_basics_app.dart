import 'package:flutter/material.dart';

/// Lab ของ Part 1: แดชบอร์ดคลังสินค้าแบบย่อส่วน
///
/// ใช้เฉพาะสิ่งที่ Flutter มีให้ในตัว ไม่มี package เสริม ไม่มีเครือข่าย
/// เป้าหมายคือให้เห็น widget tree, การแตก widget, callback จากลูกไปแม่
/// และการ rebuild เฉพาะส่วนด้วย ValueListenableBuilder
void main() {
  runApp(const WidgetBasicsApp());
}

/// งานหนึ่งใบบนแดชบอร์ด — ข้อมูลล้วน ไม่มี widget ปนอยู่
class DashboardTask {
  const DashboardTask({
    required this.id,
    required this.title,
    required this.quantity,
  });

  final String id;
  final String title;
  final int quantity;
}

class WidgetBasicsApp extends StatelessWidget {
  const WidgetBasicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widget Basics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _allTasks = <DashboardTask>[
    DashboardTask(id: 'T-01', title: 'จัดเก็บ PAL-1001', quantity: 12),
    DashboardTask(id: 'T-02', title: 'หยิบออก PAL-1002', quantity: 4),
    DashboardTask(id: 'T-03', title: 'ตรวจนับ โซน A', quantity: 30),
  ];

  /// state ที่เป็นของหน้าจอนี้: งานที่ทำเสร็จแล้วมีใบไหนบ้าง
  final Set<String> _doneIds = <String>{};

  /// ValueNotifier แจ้งเฉพาะคนที่ฟังมัน ไม่ได้ rebuild ทั้งหน้าจอ
  final ValueNotifier<int> _tapCount = ValueNotifier<int>(0);

  int get _remaining => _allTasks.length - _doneIds.length;

  void _toggleDone(String id) {
    setState(() {
      if (!_doneIds.remove(id)) _doneIds.add(id);
    });
    _tapCount.value++;
  }

  @override
  void dispose() {
    _tapCount.dispose(); // ใครสร้าง คนนั้นต้องคืน
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดคลัง'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    key: const Key('stat-total'),
                    label: 'งานทั้งหมด',
                    value: '${_allTasks.length}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    key: const Key('stat-remaining'),
                    label: 'ยังไม่เสร็จ',
                    value: '$_remaining',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ส่วนนี้เท่านั้นที่ rebuild เมื่อ _tapCount เปลี่ยน
            ValueListenableBuilder<int>(
              valueListenable: _tapCount,
              builder: (context, count, child) {
                return Text(
                  'กดไปแล้ว $count ครั้ง',
                  key: const Key('tap-count'),
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _allTasks.length,
                itemBuilder: (context, index) {
                  final task = _allTasks[index];
                  return TaskTile(
                    // ValueKey ผูก widget กับ "ข้อมูลใบไหน" ไม่ใช่ "ตำแหน่งที่เท่าไร"
                    key: ValueKey<String>(task.id),
                    task: task,
                    done: _doneIds.contains(task.id),
                    // ลูกไม่รู้ว่ากดแล้วจะเกิดอะไร มันแค่บอกว่า "ถูกกดนะ"
                    onToggle: () => _toggleDone(task.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// widget ที่ไม่มี state ของตัวเอง วาดจาก argument ที่ได้รับอย่างเดียว
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// แถวงานหนึ่งใบ — รับข้อมูลและ callback เข้ามา ไม่ถือ state เอง
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.done,
    required this.onToggle,
  });

  final DashboardTask task;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
      title: Text(
        task.title,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text('${task.id} · ${task.quantity} ชิ้น'),
      onTap: onToggle,
    );
  }
}
