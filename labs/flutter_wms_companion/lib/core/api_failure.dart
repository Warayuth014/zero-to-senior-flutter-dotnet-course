/// ชนิดของความล้มเหลวที่คุยกับเซิร์ฟเวอร์
///
/// แยกชนิดไว้เพราะแต่ละชนิดผู้ใช้ต้องทำคนละอย่าง — ถ้ายุบเป็น
/// "เกิดข้อผิดพลาด" อย่างเดียว ผู้ใช้จะกดลองใหม่กับทุกอย่าง
/// และส่วนใหญ่จะได้ผลเดิม
library;

enum ApiFailureKind {
  /// ต่อเซิร์ฟเวอร์ไม่ได้เลย — เน็ตหลุด หรือที่อยู่ผิด
  network,

  /// ส่งไปแล้วแต่ไม่ได้คำตอบภายในเวลา
  timeout,

  /// ยังไม่ได้เข้าสู่ระบบ หรือ token หมดอายุ
  unauthorized,

  /// เข้าสู่ระบบแล้ว แต่ไม่มีสิทธิ์ทำสิ่งนี้
  forbidden,

  /// ไม่พบสิ่งที่ขอ
  notFound,

  /// คนอื่นทำไปก่อนแล้ว หรือสถานะไม่ตรงกับที่คาด
  conflict,

  /// ข้อมูลที่ส่งไปไม่ผ่านการตรวจของเซิร์ฟเวอร์
  validation,

  /// เซิร์ฟเวอร์มีปัญหาภายใน
  server,

  /// ตอบกลับมาแล้ว แต่รูปแบบไม่ตรงกับที่ตกลงไว้
  contract,
}

extension ApiFailureKindRules on ApiFailureKind {
  /// ลองใหม่ด้วยคำขอเดิมแล้วมีโอกาสได้ผลต่างไหม
  ///
  /// เขียนเป็นรายชื่อที่อนุญาต ไม่ใช่รายชื่อที่ห้าม — ชนิดใหม่ที่เพิ่มมา
  /// จะได้ไม่กลายเป็น "ลองใหม่ได้" โดยอัตโนมัติ
  bool get isRetryable => switch (this) {
    ApiFailureKind.network || ApiFailureKind.timeout || ApiFailureKind.server =>
      true,
    ApiFailureKind.unauthorized ||
    ApiFailureKind.forbidden ||
    ApiFailureKind.notFound ||
    ApiFailureKind.conflict ||
    ApiFailureKind.validation ||
    ApiFailureKind.contract => false,
  };

  /// รู้ผลแน่หรือไม่ว่าเซิร์ฟเวอร์ทำไปแล้วหรือยัง
  ///
  /// timeout กับ network ที่ขาดกลางทางคือกรณีที่ไม่รู้ผล ซึ่งห้ามเดา (4.13)
  bool get outcomeIsKnown => switch (this) {
    ApiFailureKind.network || ApiFailureKind.timeout => false,
    _ => true,
  };
}

/// รายละเอียดความผิดพลาดตามรูปแบบมาตรฐานที่ ASP.NET ส่งมา
///
/// ทั้ง ProblemDetails และ ValidationProblemDetails ใช้โครงเดียวกัน
/// ต่างกันแค่ว่ามี errors หรือไม่
class ProblemDetails {
  const ProblemDetails({
    this.title,
    this.detail,
    this.status,
    this.traceId,
    this.errors = const {},
  });

  /// อ่านจาก JSON ถ้าหน้าตาตรงกับ ProblemDetails
  ///
  /// คืน null เมื่อไม่ใช่ — ไม่โยน เพราะบาง endpoint ตอบรูปแบบอื่น
  /// และนั่นไม่ใช่ความผิดพลาดที่ต้องหยุดทุกอย่าง
  static ProblemDetails? tryParse(Map<String, dynamic>? json) {
    if (json == null) return null;
    final hasAnyField =
        json.containsKey('title') ||
        json.containsKey('detail') ||
        json.containsKey('errors');
    if (!hasAnyField) return null;

    return ProblemDetails(
      title: _readText(json['title']),
      detail: _readText(json['detail']),
      status: json['status'] is int ? json['status'] as int : null,
      traceId: _readText(json['traceId']),
      errors: _readErrors(json['errors']),
    );
  }

  final String? title;
  final String? detail;
  final int? status;

  /// รหัสที่ใช้ตามหาคำขอนี้ใน log ฝั่งเซิร์ฟเวอร์
  final String? traceId;

  /// ข้อผิดพลาดรายช่อง เช่น {'quantity': ['ต้องมากกว่าศูนย์']}
  final Map<String, List<String>> errors;

  bool get hasFieldErrors => errors.isNotEmpty;

  /// ข้อความที่เอาไปแสดงให้ผู้ใช้ได้เลย
  ///
  /// เรียงจากเจาะจงที่สุดไปกว้างที่สุด — detail บอกเรื่องของคำขอนี้
  /// ส่วน title มักเป็นชื่อประเภทข้อผิดพลาดกว้าง ๆ
  String? get userMessage {
    if (hasFieldErrors) {
      return errors.values.expand((messages) => messages).join('\n');
    }
    return detail ?? title;
  }

  static String? _readText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, List<String>> _readErrors(Object? value) {
    if (value is! Map) return const {};
    final result = <String, List<String>>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final raw = entry.value;
      if (raw is List) {
        // `?` ข้างหน้าแปลว่า "ใส่เฉพาะตัวที่ไม่เป็น null" — ตัดข้อความว่างทิ้งไปเอง
        final messages = [for (final message in raw) ?_readText(message)];
        if (messages.isNotEmpty) result[key] = messages;
      } else if (_readText(raw) case final text?) {
        result[key] = [text];
      }
    }
    return result;
  }
}

/// แปลงรหัสตอบกลับเป็นชนิดความล้มเหลว
///
/// รวมไว้ที่เดียวเพราะกฎนี้ต้องเหมือนกันทุก endpoint
ApiFailureKind failureKindForStatus(int statusCode) => switch (statusCode) {
  401 => ApiFailureKind.unauthorized,
  403 => ApiFailureKind.forbidden,
  404 => ApiFailureKind.notFound,
  409 => ApiFailureKind.conflict,
  400 || 422 => ApiFailureKind.validation,
  >= 500 => ApiFailureKind.server,
  _ => ApiFailureKind.contract,
};
