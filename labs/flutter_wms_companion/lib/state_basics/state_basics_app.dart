import 'package:flutter/material.dart';

import 'pick_repository.dart';
import 'pick_store.dart';

/// Lab ของ Part 4 — หน้าหยิบสินค้าที่แยกสถานะออกจากหน้าจอ
///
/// หน้าจอไม่ถือข้อมูลเลย มันอ่านจาก store แล้ววาด
/// ทุกการเปลี่ยนแปลงเกิดผ่านคำสั่งของ store เท่านั้น
class StateBasicsApp extends StatelessWidget {
  const StateBasicsApp({super.key, required this.store});

  final PickStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'State Basics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: PickScreen(store: store),
    );
  }
}

class PickScreen extends StatefulWidget {
  const PickScreen({super.key, required this.store});

  final PickStore store;

  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  @override
  void initState() {
    super.initState();
    // เริ่มโหลดที่นี่ ไม่ใช่ใน build (1.9)
    widget.store.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หยิบสินค้า'),
        actions: [
          // ส่วนนี้ฟัง store เพื่อแสดงจำนวนคงเหลือ
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, child) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  'เหลือ ${widget.store.remainingCount}',
                  key: const Key('remaining-count'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, child) => switch (widget.store.state) {
          LoadState.idle || LoadState.loading => const Center(
            key: Key('loading-view'),
            child: CircularProgressIndicator(),
          ),
          LoadState.empty => const Center(
            key: Key('empty-view'),
            child: Text('ยังไม่มีงานในกะนี้'),
          ),
          LoadState.failed => _FailedView(
            key: const Key('failed-view'),
            message: widget.store.errorMessage ?? 'โหลดไม่สำเร็จ',
            onRetry: widget.store.load,
          ),
          LoadState.ready => _LineListView(store: widget.store),
        },
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('retry-button'),
            onPressed: onRetry,
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }
}

class _LineListView extends StatelessWidget {
  const _LineListView({required this.store});

  final PickStore store;

  @override
  Widget build(BuildContext context) {
    final lines = store.lines;

    return Column(
      children: [
        if (store.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              store.errorMessage!,
              key: const Key('inline-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              return PickLineTile(
                key: ValueKey<String>(line.id),
                line: line,
                busy: store.isBusy(line.id),
                onDone: () => store.markDone(line.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// แถวหนึ่งบรรทัด — ไม่ถือสถานะเอง รับทุกอย่างมาจากแม่ (1.12)
class PickLineTile extends StatelessWidget {
  const PickLineTile({
    super.key,
    required this.line,
    required this.busy,
    required this.onDone,
  });

  final PickLine line;
  final bool busy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        line.done ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
      title: Text(line.palletCode),
      subtitle: Text('${line.id} · ${line.quantity} ชิ้น'),
      trailing: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton(
              key: ValueKey<String>('done-${line.id}'),
              // ปิดปุ่มเมื่อทำเสร็จแล้วหรือกำลังส่งคำสั่ง
              onPressed: line.done ? null : onDone,
              child: const Text('เสร็จ'),
            ),
    );
  }
}
