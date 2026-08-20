/// การบันทึกคำขอ HTTP ที่ปลอดภัยพอจะเก็บไว้ในเครื่องของคนอื่น
///
/// PDA ในคลังเปลี่ยนมือทุกกะ และไฟล์ log ถูกส่งให้ทีมดูเวลามีปัญหา
/// จึงต้องไม่มี token ชื่อลูกค้า หรือราคาอยู่ในนั้น
library;

/// คีย์ใน query string ที่ห้ามบันทึกค่าออกไป
const Set<String> _sensitiveQueryKeys = {
  'token',
  'access_token',
  'password',
  'pin',
  'apikey',
  'api_key',
};

/// ชื่อ header ที่ห้ามบันทึกค่าออกไป
const Set<String> _sensitiveHeaders = {
  'authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
};

/// ใช้ตัวอักษรล้วน ไม่ใช้เครื่องหมาย เพราะ Uri.replace จะ encode เครื่องหมาย
/// ให้เป็น %2A ทำให้ log อ่านยากและค้นหาไม่เจอ
const String _masked = 'REDACTED';

/// แทนค่าที่อ่อนไหวใน URL ด้วยเครื่องหมาย แต่เก็บโครงไว้ให้ครบ
///
/// เก็บชื่อคีย์ไว้เสมอ เพราะการรู้ว่า "มี token ส่งไปด้วย" มีประโยชน์
/// ตอนไล่หาสาเหตุ ส่วนตัวค่าไม่มีประโยชน์เลย
String redactUri(Uri uri) {
  if (uri.queryParameters.isEmpty) return uri.toString();
  final safe = <String, String>{
    for (final entry in uri.queryParameters.entries)
      entry.key: _sensitiveQueryKeys.contains(entry.key.toLowerCase())
          ? _masked
          : entry.value,
  };
  return uri.replace(queryParameters: safe).toString();
}

/// แทนค่า header ที่อ่อนไหว
Map<String, String> redactHeaders(Map<String, String> headers) => {
  for (final entry in headers.entries)
    entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase())
        ? _masked
        : entry.value,
};

/// สรุปคำขอหนึ่งครั้งให้พอไล่หาสาเหตุได้ โดยไม่มีเนื้อหาของ body
///
/// ไม่บันทึก body เลย เพราะ body ของงานคลังมีทั้งชื่อลูกค้า ที่อยู่ และราคา
/// สิ่งที่ต้องรู้จริง ๆ คือยิงไปที่ไหน ได้อะไรกลับมา และใช้เวลาเท่าไหร่
String describeExchange({
  required String method,
  required Uri uri,
  required int? statusCode,
  required Duration elapsed,
  String? traceId,
}) {
  final buffer = StringBuffer()
    ..write(method)
    ..write(' ')
    ..write(redactUri(uri))
    ..write(' → ')
    ..write(statusCode ?? 'ไม่ได้คำตอบ')
    ..write(' (')
    ..write(elapsed.inMilliseconds)
    ..write(' ms)');
  if (traceId != null) buffer.write(' trace=$traceId');
  return buffer.toString();
}
