import 'package:flutter/material.dart';

import 'rebuild_counter.dart';

/// สถานะของกระดานงาน — มีสองอย่างที่เปลี่ยนคนละจังหวะ
///
/// จำนวนที่นับได้เปลี่ยนทุกครั้งที่สแกน ส่วนชื่อผู้ใช้แทบไม่เปลี่ยนเลย
/// ทั้งคู่อยู่ใน notifier เดียวกัน ซึ่งเป็นสถานการณ์ปกติ
class BoardState extends ChangeNotifier {
  int _scanned = 0;
  String _operator = 'somchai';

  int get scanned => _scanned;
  String get operator => _operator;

  void scan() {
    _scanned++;
    notifyListeners();
  }

  void changeOperator(String name) {
    if (_operator == name) return;
    _operator = name;
    notifyListeners();
  }
}

/// รุ่นที่วาดใหม่ทั้งจอทุกครั้งที่มีอะไรเปลี่ยน
///
/// เขียนแบบนี้ไม่ผิดและทำงานถูกต้อง — เป็นแบบที่คนเขียนเป็นอันดับแรกเสมอ
/// และในจอเล็ก ๆ ก็ไม่มีปัญหา ปัญหาเริ่มเมื่อส่วนที่แพงอยู่ในนั้นด้วย (14.15)
class WideRebuildBoard extends StatelessWidget {
  const WideRebuildBoard({
    super.key,
    required this.state,
    required this.counter,
  });

  final BoardState state;
  final RebuildCounter counter;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => Column(
      children: [
        CountedBuilder(
          counter: counter,
          label: 'header',
          builder: (_) => Text('ผู้ปฏิบัติงาน: ${state.operator}'),
        ),
        CountedBuilder(
          counter: counter,
          label: 'counter',
          builder: (_) => Text('สแกนแล้ว ${state.scanned}'),
        ),
        CountedBuilder(
          counter: counter,
          // ส่วนที่แพง เช่นรายการยาวหรือแผนภูมิ
          label: 'expensive',
          builder: (_) => const _ExpensiveSection(),
        ),
      ],
    ),
  );
}

/// รุ่นที่วาดใหม่เฉพาะส่วนที่ค่าเปลี่ยนจริง
///
/// ต่างจากรุ่นบนที่จุดเดียว — ย้าย `ListenableBuilder` ลงไปครอบเฉพาะส่วนที่
/// ต้องใช้ค่านั้น แทนที่จะครอบทั้งจอ
class NarrowRebuildBoard extends StatelessWidget {
  const NarrowRebuildBoard({
    super.key,
    required this.state,
    required this.counter,
  });

  final BoardState state;
  final RebuildCounter counter;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListenableBuilder(
        listenable: state,
        builder: (context, _) => CountedBuilder(
          counter: counter,
          label: 'header',
          builder: (_) => Text('ผู้ปฏิบัติงาน: ${state.operator}'),
        ),
      ),
      ListenableBuilder(
        listenable: state,
        builder: (context, _) => CountedBuilder(
          counter: counter,
          label: 'counter',
          builder: (_) => Text('สแกนแล้ว ${state.scanned}'),
        ),
      ),
      // ไม่ได้อยู่ใต้ ListenableBuilder เลย จึงไม่ถูกวาดใหม่ไม่ว่าอะไรจะเปลี่ยน
      CountedBuilder(
        counter: counter,
        label: 'expensive',
        builder: (_) => const _ExpensiveSection(),
      ),
    ],
  );
}

class _ExpensiveSection extends StatelessWidget {
  const _ExpensiveSection();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 40, child: Text('ส่วนที่วาดแล้วแพง'));
}
