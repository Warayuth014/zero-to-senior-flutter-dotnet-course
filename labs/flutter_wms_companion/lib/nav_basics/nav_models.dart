import 'package:flutter/foundation.dart';

/// งานหยิบสินค้าหนึ่งบรรทัด — เป็นวัตถุที่แก้ไม่ได้ ตามที่เรียนใน 4.13
class NavTask {
  const NavTask({
    required this.id,
    required this.palletCode,
    required this.quantity,
    this.note = '',
  });

  final String id;
  final String palletCode;
  final int quantity;
  final String note;

  NavTask copyWith({String? palletCode, int? quantity, String? note}) => NavTask(
    id: id,
    palletCode: palletCode ?? this.palletCode,
    quantity: quantity ?? this.quantity,
    note: note ?? this.note,
  );
}

/// ผลที่หน้ารายละเอียดส่งกลับให้หน้ารายการ
///
/// ใช้ sealed class แทนการคืน bool หรือ Map เพราะสามกรณีนี้
/// ต้องให้หน้ารายการทำคนละอย่าง — และ compiler จะบังคับให้จัดการครบ
sealed class TaskOutcome {
  const TaskOutcome();
}

/// บันทึกแล้ว ต้องอัปเดตรายการและแจ้งผู้ใช้
class TaskSaved extends TaskOutcome {
  const TaskSaved(this.task);
  final NavTask task;
}

/// พักไว้ก่อน เก็บร่างไว้แต่ยังไม่ถือว่าเสร็จ
class TaskPaused extends TaskOutcome {
  const TaskPaused(this.draft);
  final NavTask draft;
}

/// ทิ้งการแก้ไข กลับไปใช้ค่าเดิม
class TaskCancelled extends TaskOutcome {
  const TaskCancelled();
}

/// ข้อมูลของผู้ใช้ที่ล็อกอินอยู่ — อายุยาวกว่าทุกหน้าจอในแอป
class AppSession extends ChangeNotifier {
  String? _username;
  bool _scanSound = true;

  String? get username => _username;
  bool get authenticated => _username != null;
  bool get scanSound => _scanSound;

  void signIn(String username) {
    _username = username;
    notifyListeners();
  }

  void signOut() {
    _username = null;
    notifyListeners();
  }

  void setScanSound({required bool enabled}) {
    if (_scanSound == enabled) return;
    _scanSound = enabled;
    notifyListeners();
  }
}
