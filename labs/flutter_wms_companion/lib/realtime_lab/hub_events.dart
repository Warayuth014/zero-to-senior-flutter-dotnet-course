/// เหตุการณ์ที่เซิร์ฟเวอร์ส่งมาบอกโดยที่ผู้ใช้ไม่ได้กดอะไร
///
/// SignalR ส่งมาเป็น `List<Object?>` ที่ไม่มีชนิด ไฟล์นี้คือขอบที่แปลง
/// ของไร้ชนิดนั้นให้เป็นชนิดที่คอมไพเลอร์ตรวจได้ ก่อนที่ส่วนอื่นจะเห็น (12.5)
library;

/// ฐานของเหตุการณ์ทั้งหมด
///
/// `sealed` ทำให้ `switch` ที่จัดการไม่ครบทุกชนิด คอมไพล์ไม่ผ่าน —
/// วันที่เพิ่มเหตุการณ์ใหม่ คอมไพเลอร์จะชี้ให้เห็นทุกที่ที่ต้องแก้ (6.11)
sealed class HubEvent {
  const HubEvent();

  /// ชื่อที่เซิร์ฟเวอร์ใช้ส่งมา เก็บไว้เพื่อการบันทึกและวินิจฉัย
  String get name;
}

/// งานถูกจ่ายให้หุ่นยนต์หรือคนขับแล้ว
class TaskDispatched extends HubEvent {
  const TaskDispatched({
    required this.taskId,
    required this.assignee,
    required this.version,
  });

  final String taskId;
  final String assignee;

  /// เลขรุ่นของงานนี้ที่เซิร์ฟเวอร์นับให้
  ///
  /// จำเป็นเพราะเหตุการณ์ที่ส่งมาทางเครือข่าย **ไม่รับประกันลำดับ** —
  /// เหตุการณ์เก่าที่มาถึงช้ากว่าต้องไม่ทับของใหม่ (12.10)
  final int version;

  @override
  String get name => 'TaskDispatched';
}

/// งานเสร็จแล้ว
class TaskCompleted extends HubEvent {
  const TaskCompleted({required this.taskId, required this.version});

  final String taskId;
  final int version;

  @override
  String get name => 'TaskCompleted';
}

/// จำนวนของที่จุดปลายทางเปลี่ยน
class StationCounterUpdated extends HubEvent {
  const StationCounterUpdated({required this.stationId, required this.count});

  final String stationId;
  final int count;

  @override
  String get name => 'StationCounterUpdated';
}

/// เหตุการณ์ที่แอปรุ่นนี้ยังไม่รู้จัก
///
/// ไม่ใช่ความผิดพลาด — เซิร์ฟเวอร์รุ่นใหม่ส่งเหตุการณ์ที่แอปรุ่นเก่า
/// ยังไม่รองรับเป็นเรื่องปกติ และต้องไม่ทำให้อะไรพัง (12.5)
class UnknownHubEvent extends HubEvent {
  const UnknownHubEvent(this.name);

  @override
  final String name;
}

/// เหตุการณ์ที่รู้จักชื่อ แต่ข้อมูลข้างในไม่ตรงกับที่ตกลงไว้
///
/// ต่างจาก [UnknownHubEvent] ตรงที่อันนี้**เป็นปัญหา**ที่ทีมต้องรู้ แต่ก็ยัง
/// ไม่ใช่เหตุให้ตัดการเชื่อมต่อทิ้ง — เหตุการณ์เสียหนึ่งก้อนต้องไม่ทำให้
/// เหตุการณ์ที่เหลือทั้งวันหายไปด้วย (12.5)
class MalformedHubEvent extends HubEvent {
  const MalformedHubEvent(this.name, this.reason);

  @override
  final String name;

  /// อธิบายว่าอะไรไม่ตรง เพื่อส่งเข้าระบบบันทึกแล้วตามแก้ได้
  final String reason;
}

/// แปลงข้อมูลดิบจาก hub ให้เป็นเหตุการณ์ที่มีชนิด
///
/// **ไม่โยนไม่ว่ากรณีใด** — คนเรียกคือตัวรับเหตุการณ์ที่ทำงานอยู่เบื้องหลัง
/// ถ้าโยน การเชื่อมต่อจะหลุดและผู้ใช้จะไม่ได้รับเหตุการณ์อีกเลยทั้งกะ
/// โดยไม่มีใครรู้ว่าทำไม
HubEvent decodeHubEvent(String name, List<Object?>? args) {
  final payload = _firstMap(args);
  if (payload == null) {
    return MalformedHubEvent(name, 'ข้อมูลที่ส่งมาไม่ใช่ object');
  }

  try {
    return switch (name) {
      'TaskDispatched' => TaskDispatched(
        taskId: _requireText(payload, 'taskId'),
        assignee: _requireText(payload, 'assignee'),
        version: _requireInt(payload, 'version'),
      ),
      'TaskCompleted' => TaskCompleted(
        taskId: _requireText(payload, 'taskId'),
        version: _requireInt(payload, 'version'),
      ),
      'StationCounterUpdated' => StationCounterUpdated(
        stationId: _requireText(payload, 'stationId'),
        count: _requireInt(payload, 'count'),
      ),
      _ => UnknownHubEvent(name),
    };
  } on _FieldError catch (error) {
    return MalformedHubEvent(name, error.message);
  }
}

/// SignalR ส่ง argument มาเป็นลิสต์ เพราะฝั่ง .NET เรียก
/// `SendAsync("EventName", arg1, arg2)` ได้หลายตัว
///
/// สัญญาของระบบนี้คือส่ง object เดียว จึงอ่านเฉพาะตัวแรก
Map<String, dynamic>? _firstMap(List<Object?>? args) {
  if (args == null || args.isEmpty) return null;
  final first = args.first;
  if (first is Map<String, dynamic>) return first;
  // มาจาก JSON ที่ถอดรหัสแล้วอาจเป็น Map<dynamic, dynamic>
  if (first is Map) return Map<String, dynamic>.from(first);
  return null;
}

class _FieldError implements Exception {
  const _FieldError(this.message);
  final String message;
}

String _requireText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw _FieldError('$key ต้องเป็นข้อความที่ไม่ว่าง แต่ได้ ${value.runtimeType}');
  }
  return value.trim();
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  // JSON ไม่แยก int กับ double — 3 กับ 3.0 คือเลขเดียวกัน (6.7)
  if (value is int) return value;
  if (value is double && value == value.roundToDouble()) return value.toInt();
  throw _FieldError('$key ต้องเป็นจำนวนเต็ม แต่ได้ ${value.runtimeType}');
}
