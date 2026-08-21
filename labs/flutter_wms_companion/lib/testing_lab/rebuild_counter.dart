import 'package:flutter/material.dart';

/// นับจำนวนครั้งที่ widget ถูกวาดใหม่ แยกตามป้ายชื่อ
///
/// ประสิทธิภาพเป็นเรื่องที่เถียงกันได้ไม่จบถ้าไม่มีตัวเลข — ตัวนับนี้ทำให้
/// คำว่า "เร็วขึ้น" กลายเป็นสิ่งที่เทสต์ยืนยันได้ แทนที่จะเป็นความรู้สึก (14.15)
class RebuildCounter {
  RebuildCounter();

  final Map<String, int> _counts = {};

  /// จำนวนครั้งที่ป้ายนี้ถูกวาด
  int countOf(String label) => _counts[label] ?? 0;

  /// ทุกป้ายที่เคยถูกวาด
  Map<String, int> get snapshot => Map.unmodifiable(_counts);

  int get total => _counts.values.fold(0, (sum, value) => sum + value);

  void record(String label) => _counts[label] = countOf(label) + 1;

  void reset() => _counts.clear();

  @override
  String toString() =>
      _counts.entries.map((e) => '${e.key}=${e.value}').join(', ');
}

/// ห่อ widget ไว้เพื่อให้รู้ว่ามันถูกวาดกี่ครั้ง
///
/// ตัว builder ถูกเรียกทุกครั้งที่ Flutter ตัดสินใจวาดส่วนนี้ใหม่ — ซึ่งเป็น
/// สิ่งที่เราอยากวัด ไม่ใช่จำนวนครั้งที่ setState ถูกเรียก
class CountedBuilder extends StatelessWidget {
  const CountedBuilder({
    super.key,
    required this.counter,
    required this.label,
    required this.builder,
  });

  final RebuildCounter counter;
  final String label;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    counter.record(label);
    return builder(context);
  }
}
