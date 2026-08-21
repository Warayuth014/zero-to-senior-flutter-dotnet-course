import 'package:flutter/material.dart';

import 'rebuild_counter.dart';

/// รายการพาเลทที่สร้างลูกทุกตัวพร้อมกัน
///
/// `Column` ใน `SingleChildScrollView` สร้าง widget ครบทุกตัวตั้งแต่แรก
/// แม้จะเห็นแค่ห้าตัวบนจอ — 500 แถวคือ 500 widget ที่ถูกสร้างและวาด (14.16)
class EagerPalletList extends StatelessWidget {
  const EagerPalletList({
    super.key,
    required this.codes,
    required this.counter,
  });

  final List<String> codes;
  final RebuildCounter counter;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      children: [
        for (final code in codes)
          CountedBuilder(
            counter: counter,
            label: 'row',
            builder: (_) => SizedBox(height: 56, child: Text(code)),
          ),
      ],
    ),
  );
}

/// รายการเดียวกันที่สร้างเฉพาะแถวที่กำลังจะเห็น
///
/// `ListView.builder` เรียก `itemBuilder` เมื่อแถวนั้นใกล้เข้ามาในจอ
/// จำนวน widget ที่มีอยู่จริงจึงขึ้นกับขนาดจอ ไม่ใช่ขนาดข้อมูล
class LazyPalletList extends StatelessWidget {
  const LazyPalletList({
    super.key,
    required this.codes,
    required this.counter,
  });

  final List<String> codes;
  final RebuildCounter counter;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: codes.length,
    // บอกความสูงล่วงหน้าทำให้ Flutter คำนวณตำแหน่งได้โดยไม่ต้องวัดทุกแถว
    // และแถบเลื่อนแสดงสัดส่วนที่ถูกต้องตั้งแต่แรก
    itemExtent: 56,
    itemBuilder: (context, index) => CountedBuilder(
      counter: counter,
      label: 'row',
      builder: (_) => Text(codes[index]),
    ),
  );
}
