import 'profile_draft.dart';
import 'server_profile.dart';

/// ข้อความผิดพลาดรายช่อง เพื่อให้แสดงใต้ช่องที่ผิดได้ตรงตัว
///
/// ไม่ใช่ `List<String>` เพราะข้อความรวมกองเดียวบังคับให้ผู้ใช้เดาว่า
/// ข้อความไหนหมายถึงช่องไหน (10.7)
class ProfileValidation {
  const ProfileValidation({this.name, this.host, this.port, this.basePath});

  final String? name;
  final String? host;
  final String? port;
  final String? basePath;

  bool get isValid =>
      name == null && host == null && port == null && basePath == null;
}

/// ตรวจข้อความดิบในฟอร์ม
///
/// รับ [ProfileDraft] ไม่ใช่ [ServerProfile] เพราะต้องตรวจได้ตั้งแต่ตอนที่
/// พอร์ตยังแปลงเป็นตัวเลขไม่ได้
ProfileValidation validateDraft(ProfileDraft draft) {
  return ProfileValidation(
    name: _validateName(draft.name),
    host: _validateHost(draft.host),
    port: _validatePort(draft.port),
    basePath: _validateBasePath(draft.basePath),
  );
}

String? _validateName(String raw) =>
    raw.trim().isEmpty ? 'ตั้งชื่อ profile ก่อน' : null;

/// ทุกข้อความบอกว่า "ค่านั้นควรไปอยู่ที่ไหน" ไม่ใช่แค่ "ผิด"
///
/// ผู้ใช้ที่พิมพ์ http://192.168.1.5:6191 ลงช่อง host ไม่ได้โง่ — เขาแค่
/// คัดลอกที่อยู่ทั้งอันมาจากเบราว์เซอร์ ซึ่งเป็นสิ่งที่สมเหตุสมผลที่สุด
String? _validateHost(String raw) {
  final host = raw.trim();
  if (host.isEmpty) return 'ใส่ IP หรือชื่อเครื่อง';
  if (host.contains('://') || host.toLowerCase().startsWith('http')) {
    return 'ใส่เฉพาะที่อยู่ ไม่ต้องมี http:// (เลือกที่ช่อง Protocol)';
  }
  if (host.contains('/')) return 'เส้นทางให้ใส่ที่ช่อง Base Path';
  if (host.contains(':')) return 'พอร์ตให้ใส่ที่ช่อง Port';
  if (host.contains(' ')) return 'ห้ามมีช่องว่าง';
  return null;
}

String? _validatePort(String raw) {
  final port = int.tryParse(raw.trim());
  if (port == null) return 'พอร์ตต้องเป็นตัวเลข';
  if (port < 1 || port > 65535) return 'พอร์ตต้องอยู่ระหว่าง 1-65535';
  return null;
}

/// กับดักที่แพงที่สุดในฟอร์มนี้
///
/// ช่องนี้หน้าตาเหมือนที่ที่ควรใส่ `/api` แต่แอปเติม `/api/WMS` ให้เองอยู่แล้ว
/// ใส่ลงไปจะได้ `/api/api/WMS/...` แล้วทุกเส้นทาง 404 โดยที่หน้าจอบอกแค่ว่า
/// "โหลดไม่สำเร็จ" — ผู้ใช้ไม่มีทางเดาถูกเลย จึงต้องดักตั้งแต่ตรงนี้ (10.3)
String? _validateBasePath(String raw) {
  if (raw.trim().contains('://')) return 'Base Path คือเส้นทาง ไม่ใช่ URL';
  if (normalizeBasePath(raw).toLowerCase().startsWith('/api')) {
    return 'ปล่อยว่างไว้ — แอปเติม /api ให้เองอยู่แล้ว '
        'ถ้าใส่ตรงนี้จะกลายเป็น /api/.../api/... แล้วยิงไม่เข้าสักเส้น';
  }
  return null;
}
