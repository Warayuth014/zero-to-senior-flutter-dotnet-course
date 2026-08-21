/// รายงานข้อผิดพลาดที่ส่งออกจากเครื่องผู้ใช้
///
/// สิ่งที่ยากที่สุดของการเก็บรายงานไม่ใช่การเก็บ แต่คือ**การไม่เก็บสิ่งที่
/// ไม่ควรเก็บ** — รายงานที่มี token หรือรหัสผ่านติดไป คือช่องโหว่ที่
/// สร้างขึ้นเองด้วยความหวังดี (15.10)
library;

/// ข้อมูลของข้อผิดพลาดหนึ่งครั้ง
class CrashReport {
  const CrashReport({
    required this.error,
    required this.stack,
    required this.appVersion,
    required this.at,
    this.screen,
    this.context = const {},
  });

  final String error;
  final String stack;
  final String appVersion;
  final DateTime at;

  /// จอที่ผู้ใช้อยู่ตอนเกิด — ข้อมูลที่มีค่าที่สุดในการหาสาเหตุ
  final String? screen;

  /// ข้อมูลประกอบที่ทีมกำหนดเอง
  final Map<String, String> context;

  Map<String, dynamic> toJson() => {
    'error': error,
    'stack': stack,
    'appVersion': appVersion,
    'at': at.toUtc().toIso8601String(),
    if (screen != null) 'screen': screen,
    if (context.isNotEmpty) 'context': context,
  };
}

/// ค่าที่ต้องไม่หลุดออกไปกับรายงาน
///
/// รายชื่อนี้ต้องตรงกับที่ 7.17 ใช้กับ log — ถ้าสองที่ไม่ตรงกัน จะมีทาง
/// หนึ่งที่ปิดไว้และอีกทางที่เปิดอยู่
const Set<String> sensitiveKeys = {
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'password',
  'pwd',
  'secret',
  'apikey',
  'pin',
};

const String _masked = 'REDACTED';

/// ลบค่าที่อ่อนไหวออกจากข้อความก่อนส่ง
///
/// ทำสองอย่าง — ปิดค่าใน query string และปิดค่าใน JSON ที่อาจติดมาใน
/// ข้อความของข้อผิดพลาด
String redact(String text) {
  // Bearer ต้องมาก่อนเสมอ — ถ้าปล่อยให้ลูปข้างล่างเจอ `Authorization: Bearer`
  // ก่อน มันจะปิดคำว่า "Bearer" แล้วปล่อย token จริงไว้ ซึ่งเป็นการปิดที่
  // ดูเหมือนทำงานแต่ไม่ได้ปิดอะไรเลย
  var result = text.replaceAll(
    RegExp(r'Bearer\s+[A-Za-z0-9._\-]+', caseSensitive: false),
    'Bearer $_masked',
  );

  for (final key in sensitiveKeys) {
    // token=abc123 หรือ token: abc123 หรือ "token":"abc123"
    result = result.replaceAllMapped(
      RegExp('"?$key"?\\s*[=:]\\s*"?([^\\s,&}"]+)"?', caseSensitive: false),
      (match) {
        final value = match[1]!;
        // ปิดไปแล้วโดยกฎก่อนหน้า อย่าปิดซ้ำจนอ่านไม่รู้เรื่อง
        if (value == _masked || value == 'Bearer') return match[0]!;
        return match[0]!.replaceFirst(value, _masked);
      },
    );
  }

  return result;
}

/// ลบค่าที่อ่อนไหวออกจากข้อมูลประกอบ
Map<String, String> redactContext(Map<String, String> context) => {
  for (final entry in context.entries)
    entry.key: sensitiveKeys.contains(entry.key.toLowerCase())
        ? _masked
        : redact(entry.value),
};

/// สร้างรายงานที่ปลอดภัยพอที่จะส่งออกจากเครื่อง
CrashReport buildReport({
  required Object error,
  required StackTrace stack,
  required String appVersion,
  required DateTime at,
  String? screen,
  Map<String, String> context = const {},
}) => CrashReport(
  error: redact(error.toString()),
  stack: redact(stack.toString()),
  appVersion: appVersion,
  at: at,
  screen: screen,
  context: redactContext(context),
);

/// ที่ที่รายงานถูกส่งไป
///
/// ประกาศเป็น interface เพื่อให้ปิดได้ในเทสต์ และสลับผู้ให้บริการได้
/// โดยไม่ต้องแก้จุดที่เรียก
abstract interface class CrashSink {
  Future<void> send(CrashReport report);
}

/// เก็บไว้ในหน่วยความจำ ใช้ในเทสต์และตอนพัฒนา
class InMemoryCrashSink implements CrashSink {
  final List<CrashReport> reports = [];

  @override
  Future<void> send(CrashReport report) async => reports.add(report);
}
