import 'package:flutter/material.dart';

import 'nav_feedback.dart';
import 'nav_models.dart';

const List<String> kPalletCodes = ['PAL-0101', 'PAL-0102', 'PAL-0103'];

/// หน้ารายละเอียดงาน — แก้จำนวน พาเลท และหมายเหตุ แล้วส่งผลกลับ
///
/// หน้านี้ถือ "ร่าง" ของตัวเอง และไม่แก้ข้อมูลของหน้ารายการโดยตรง
/// ทางเดียวที่ผลจะกลับไปถึงหน้ารายการคือผ่านค่าที่ pop ออกไป
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final NavTask task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final TextEditingController _noteController;
  late String _palletCode;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.task.note);
    _palletCode = widget.task.palletCode;
    _quantity = widget.task.quantity;
    // ต้องฟังเอง เพราะปุ่มบันทึกเปิด/ปิดตามว่ามีการแก้ไขหรือยัง
    _noteController.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _noteController
      ..removeListener(_onNoteChanged) // คู่ตรงข้าม (4.12)
      ..dispose();
    super.dispose();
  }

  void _onNoteChanged() => setState(() {});

  /// มีอะไรที่แก้ไว้แล้วยังไม่ได้ส่งกลับหรือไม่
  bool get _isDirty =>
      _quantity != widget.task.quantity ||
      _palletCode != widget.task.palletCode ||
      _noteController.text != widget.task.note;

  NavTask get _draft => widget.task.copyWith(
    palletCode: _palletCode,
    quantity: _quantity,
    note: _noteController.text,
  );

  Future<void> _pickPallet() async {
    final code = await showPalletPicker(context, codes: kPalletCodes);
    if (code == null) return; // ปิดแผ่นโดยไม่เลือก
    setState(() => _palletCode = code);
  }

  void _save() => Navigator.of(context).pop(TaskSaved(_draft));

  void _pause() => Navigator.of(context).pop(TaskPaused(_draft));

  @override
  Widget build(BuildContext context) => PopScope(
    // ปล่อยให้ปิดได้เองเมื่อไม่มีอะไรค้าง
    canPop: !_isDirty,
    onPopInvokedWithResult: (didPop, result) async {
      // ปิดไปแล้ว ห้ามสั่งปิดซ้ำ
      if (didPop) return;
      final discard = await showDiscardDialog(context);
      if (!discard || !context.mounted) return;
      Navigator.of(context).pop(const TaskCancelled());
    },
    child: Scaffold(
      appBar: AppBar(title: Text('งาน ${widget.task.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            key: const Key('pallet-field'),
            title: const Text('พาเลทปลายทาง'),
            subtitle: Text(_palletCode),
            trailing: const Icon(Icons.expand_more),
            onTap: _pickPallet,
          ),
          const Divider(),
          ListTile(
            title: const Text('จำนวน'),
            subtitle: Text('$_quantity ชิ้น', key: const Key('quantity-value')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('quantity-minus'),
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 0
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                IconButton(
                  key: const Key('quantity-plus'),
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const Divider(),
          TextField(
            key: const Key('note-field'),
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'หมายเหตุ'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('save-button'),
            onPressed: _isDirty ? _save : null,
            child: const Text('บันทึก'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('pause-button'),
            onPressed: _pause,
            child: const Text('พักไว้ก่อน'),
          ),
        ],
      ),
    ),
  );
}
