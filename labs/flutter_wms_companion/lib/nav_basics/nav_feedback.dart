import 'package:flutter/material.dart';

import 'nav_models.dart';

/// ถามยืนยันก่อนทิ้งสิ่งที่แก้ไว้
///
/// คืน true เมื่อผู้ใช้ยืนยันว่าจะทิ้งเท่านั้น
/// ทุกทางออกอื่น (กดแก้ต่อ, แตะนอกกล่อง, กดปุ่มย้อนกลับ) คืน false
Future<bool> showDiscardDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('discard-dialog'),
      title: const Text('ทิ้งสิ่งที่แก้ไว้?'),
      content: const Text('จำนวนและหมายเหตุที่แก้ไว้จะหายไปทั้งหมด'),
      actions: [
        TextButton(
          key: const Key('discard-keep'),
          // ใช้ dialogContext ไม่ใช่ context ของหน้าจอ — คนละ route กัน
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('แก้ต่อ'),
        ),
        FilledButton(
          key: const Key('discard-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('ทิ้งไป'),
        ),
      ],
    ),
  );
  // แตะนอกกล่องหรือกดย้อนกลับได้ null ซึ่งต้องแปลว่า "ไม่ทิ้ง"
  return confirmed ?? false;
}

/// ให้ผู้ใช้เลือกรหัสพาเลทจากรายการที่มี
///
/// คืน null เมื่อปิดแผ่นโดยไม่เลือก
Future<String?> showPalletPicker(
  BuildContext context, {
  required List<String> codes,
}) => showModalBottomSheet<String>(
  context: context,
  builder: (sheetContext) => SafeArea(
    child: ListView(
      key: const Key('pallet-picker'),
      shrinkWrap: true,
      children: [
        const ListTile(title: Text('เลือกพาเลทปลายทาง')),
        const Divider(height: 1),
        for (final code in codes)
          ListTile(
            key: ValueKey<String>('pallet-$code'),
            title: Text(code),
            onTap: () => Navigator.of(sheetContext).pop(code),
          ),
      ],
    ),
  ),
);

/// แสดงข้อความสั้น ๆ ที่ไม่ขวางการทำงาน
///
/// รับ ScaffoldMessengerState ไม่ใช่ BuildContext เพื่อให้เรียกได้หลัง await
/// โดยไม่ต้องพึ่งว่า context ยังใช้ได้อยู่ (4.9)
void showResultBanner(
  ScaffoldMessengerState messenger,
  String message, {
  bool isError = false,
}) {
  messenger
    // ปิดอันเก่าก่อน ไม่ให้ต่อคิวจนผู้ใช้ต้องรอดูทีละอัน
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        key: const Key('result-banner'),
        content: Text(message),
        duration: Duration(seconds: isError ? 6 : 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// เปิดแผ่นตั้งค่า
Future<void> showSettingsSheet(
  BuildContext context, {
  required AppSession session,
  required VoidCallback onSignOut,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) =>
      SettingsSheet(session: session, onSignOut: onSignOut),
);

/// แผ่นตั้งค่าที่มีการแก้ไขค้างอยู่ได้ จึงต้องกันการปิดโดยไม่ตั้งใจ
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  final AppSession session;

  /// แผ่นนี้ไม่รู้จักเส้นทางของแอป จึงบอกได้แค่ว่า "ผู้ใช้ขอออกจากระบบ"
  /// แล้วให้เจ้าของหน้าจอเป็นคนตัดสินว่าต้องล้าง stack อย่างไร
  final VoidCallback onSignOut;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late bool _scanSound;

  @override
  void initState() {
    super.initState();
    // อ่านค่าตั้งต้นครั้งเดียว จากนั้นแผ่นนี้ถือค่าที่ยังไม่บันทึกของตัวเอง
    _scanSound = widget.session.scanSound;
  }

  bool get _isDirty => _scanSound != widget.session.scanSound;

  void _save() {
    widget.session.setScanSound(enabled: _scanSound);
    Navigator.of(context).pop();
  }

  Future<void> _signOut() async {
    // ออกจากระบบทิ้งค่าที่ยังไม่บันทึกอยู่แล้ว จึงถามก่อนถ้ามีของค้าง
    if (_isDirty && !await showDiscardDialog(context)) return;
    if (!mounted) return;
    Navigator.of(context).pop(); // ปิดแผ่นก่อน
    widget.onSignOut(); // แล้วให้เจ้าของหน้าจอจัดการเส้นทาง
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isDirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop) return;
      final discard = await showDiscardDialog(context);
      if (!discard || !context.mounted) return;
      Navigator.of(context).pop();
    },
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ตั้งค่า', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('scan-sound-switch'),
              title: const Text('เสียงเตือนเมื่อสแกนสำเร็จ'),
              value: _scanSound,
              onChanged: (value) => setState(() => _scanSound = value),
            ),
            const Divider(),
            FilledButton(
              key: const Key('settings-save'),
              onPressed: _isDirty ? _save : null,
              child: const Text('บันทึก'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('sign-out-button'),
              onPressed: _signOut,
              child: const Text('ออกจากระบบ'),
            ),
          ],
        ),
      ),
    ),
  );
}
