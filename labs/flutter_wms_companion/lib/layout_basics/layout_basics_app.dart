import 'package:flutter/material.dart';

/// Lab ของ Part 2: หน้าจอรับเข้าสินค้าแบบย่อส่วน ที่ต้องใช้ได้ทั้งจอ PDA แคบ
/// และแท็บเล็ตกว้าง
///
/// ทุกอย่างใช้ widget ที่ Flutter มีให้ในตัว ไม่มี package เสริม
/// เป้าหมายคือให้เห็นเรื่อง constraints, Row/Column, Expanded, Stack,
/// รายการแบบเลื่อนได้, MediaQuery, LayoutBuilder และการกันข้อความล้น
void main() {
  runApp(const LayoutBasicsApp());
}

/// ขนาดหน้าจอที่เราสนใจ — ตั้งชื่อไว้ที่เดียวแทนการกระจายตัวเลขทั่วไฟล์
class Breakpoints {
  const Breakpoints._();

  /// ต่ำกว่านี้ถือว่าเป็นจอ PDA แนวตั้ง
  static const double compact = 480;

  /// ปุ่มบน PDA ต้องกดได้ด้วยมือที่ใส่ถุงมือ
  static const double minTapTarget = 48;
}

class InboundLine {
  const InboundLine({
    required this.palletCode,
    required this.productName,
    required this.quantity,
    required this.location,
    this.urgent = false,
  });

  final String palletCode;
  final String productName;
  final int quantity;
  final String location;
  final bool urgent;
}

const demoLines = <InboundLine>[
  InboundLine(
    palletCode: 'PAL-1001',
    productName: 'กล่องกระดาษลูกฟูก ขนาดใหญ่พิเศษ สำหรับงานส่งออก',
    quantity: 12,
    location: 'A-01-02',
    urgent: true,
  ),
  InboundLine(
    palletCode: 'PAL-1002',
    productName: 'เทปกาว',
    quantity: 240,
    location: 'A-01-03',
  ),
  InboundLine(
    palletCode: 'PAL-1003',
    productName: 'ฟิล์มยืดพันพาเลท',
    quantity: 36,
    location: 'B-02-01',
  ),
  InboundLine(
    palletCode: 'PAL-1004',
    productName: 'สติกเกอร์บาร์โค้ด',
    quantity: 5000,
    location: 'B-02-04',
  ),
];

class LayoutBasicsApp extends StatelessWidget {
  const LayoutBasicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Layout Basics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const InboundScreen(),
    );
  }
}

class InboundScreen extends StatelessWidget {
  const InboundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รับเข้าสินค้า')),
      // SafeArea กันไม่ให้เนื้อหาไปอยู่ใต้รอยบากหรือแถบล่างของระบบ
      body: SafeArea(
        // LayoutBuilder บอกว่าพื้นที่ที่เราได้รับจริงกว้างเท่าไร
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < Breakpoints.compact;
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SummaryBar(
                    key: const Key('summary-bar'),
                    lineCount: demoLines.length,
                    totalQuantity: demoLines.fold<int>(
                      0,
                      (sum, line) => sum + line.quantity,
                    ),
                    stacked: isCompact,
                  ),
                  const SizedBox(height: 12),
                  // Expanded ให้รายการกินพื้นที่ที่เหลือทั้งหมด
                  // ถ้าไม่มี Expanded ListView จะไม่รู้ว่าตัวเองสูงเท่าไร
                  Expanded(
                    child: ListView.builder(
                      itemCount: demoLines.length,
                      itemBuilder: (context, index) {
                        final line = demoLines[index];
                        return InboundLineCard(
                          key: ValueKey<String>(line.palletCode),
                          line: line,
                          compact: isCompact,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// แถบสรุปด้านบน — เรียงเป็นแถวเมื่อจอกว้าง และซ้อนลงล่างเมื่อจอแคบ
class SummaryBar extends StatelessWidget {
  const SummaryBar({
    super.key,
    required this.lineCount,
    required this.totalQuantity,
    required this.stacked,
  });

  final int lineCount;
  final int totalQuantity;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      _SummaryCell(label: 'รายการ', value: '$lineCount'),
      _SummaryCell(label: 'จำนวนรวม', value: '$totalQuantity'),
    ];

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [cells[0], const SizedBox(height: 8), cells[1]],
      );
    }

    return Row(
      children: [
        Expanded(child: cells[0]),
        const SizedBox(width: 8),
        Expanded(child: cells[1]),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

/// การ์ดหนึ่งใบต่อหนึ่งรายการ
///
/// จุดสำคัญของ lab นี้อยู่ที่ Row ข้างใน: ชื่อสินค้ายาวไม่เท่ากัน
/// ถ้าไม่ห่อด้วย Expanded จะเกิด RenderFlex overflow ทันทีบนจอแคบ
class InboundLineCard extends StatelessWidget {
  const InboundLineCard({super.key, required this.line, required this.compact});

  final InboundLine line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Stack ใช้ซ้อนจุดแจ้งเตือนบนไอคอน
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 32),
                    if (line.urgent)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Expanded คือหัวใจ: บอกว่าข้อความกินพื้นที่ที่เหลือ
                // แล้ว maxLines + ellipsis จัดการส่วนที่ยาวเกิน
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.palletCode, style: theme.textTheme.titleMedium),
                      Text(
                        line.productName,
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${line.quantity}', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(line.location),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                // ปุ่มต้องสูงอย่างน้อย 48 เพื่อให้กดได้ด้วยมือที่ใส่ถุงมือ
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Breakpoints.minTapTarget,
                    minWidth: Breakpoints.minTapTarget * 2,
                  ),
                  child: FilledButton(
                    key: ValueKey<String>('confirm-${line.palletCode}'),
                    onPressed: () {},
                    child: const Text('ยืนยัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
