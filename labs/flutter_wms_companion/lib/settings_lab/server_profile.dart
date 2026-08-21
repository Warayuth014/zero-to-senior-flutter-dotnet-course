/// ที่อยู่เซิร์ฟเวอร์หนึ่งชุดที่ผู้ใช้บันทึกไว้
///
/// ผู้ปฏิบัติงานเก็บไว้หลายชุด (เครื่องที่ออฟฟิศ, เครื่องทดสอบ, โน้ตบุ๊กตัวเอง)
/// แล้วสลับจากในแอป แทนที่จะต้อง build ใหม่ทุกครั้งที่เปลี่ยนเครื่อง (10.4)
library;

enum ServerProtocol {
  http,
  https;

  static ServerProtocol parse(String? raw) =>
      raw?.toLowerCase() == 'https' ? ServerProtocol.https : ServerProtocol.http;
}

/// ป้ายกำกับที่ผู้ใช้เลือกเอง ไม่มีผลต่อการทำงาน
///
/// มีไว้ให้แยกออกว่าอันไหนคืออันไหนในรายการ และใช้ตั้งค่าเริ่มต้นของพอร์ต
/// ตอนสร้างใหม่เท่านั้น
enum ServerEnvironment {
  production,
  development,
  custom;

  static ServerEnvironment parse(String? raw) => switch (raw) {
    'production' => ServerEnvironment.production,
    'custom' => ServerEnvironment.custom,
    _ => ServerEnvironment.development,
  };
}

/// แปลงสิ่งที่ผู้ใช้พิมพ์ให้เป็นเส้นทางที่ต่อท้าย URL ได้อย่างปลอดภัย
///
/// คืน `''` หรือ `/something` ที่ไม่มีทับซ้อนและไม่มีทับปิดท้าย
/// รับได้ทั้ง `wms`, `/wms`, `wms/`, `//wms//` แล้วให้ผลเดียวกันคือ `/wms`
///
/// นี่คือส่วนเสริมสำหรับเซิร์ฟเวอร์ที่อยู่หลัง reverse proxy
/// **ไม่ใช่** `/api` ของแอป — แอปเรียกสามรากคือ `/api/WMS`, `/api/data`
/// และ `/api/Authenticate` ส่วนนั้นจึงเปิดให้ผู้ใช้แก้ไม่ได้ (10.3)
String normalizeBasePath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final collapsed = trimmed
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .join('/');
  return collapsed.isEmpty ? '' : '/$collapsed';
}

class ServerProfile {
  const ServerProfile({
    required this.id,
    required this.name,
    required this.environment,
    required this.protocol,
    required this.host,
    required this.port,
    required this.basePath,
  });

  final String id;
  final String name;
  final ServerEnvironment environment;
  final ServerProtocol protocol;
  final String host;
  final int port;

  /// เก็บตามที่ผู้ใช้พิมพ์ ใช้งานผ่าน [baseUrl] หรือ [normalizeBasePath]
  ///
  /// เก็บดิบไว้เพราะเวลาผู้ใช้กลับมาแก้ จะได้เห็นสิ่งที่ตัวเองพิมพ์
  /// ไม่ใช่สิ่งที่แอปแปลงให้
  final String basePath;

  /// สิ่งที่เอาไปต่อหน้าทุกคำขอ เช่น `http://192.168.1.194:6191`
  String get baseUrl =>
      '${protocol.name}://$host:$port${normalizeBasePath(basePath)}';

  ServerProfile copyWith({
    String? id,
    String? name,
    ServerEnvironment? environment,
    ServerProtocol? protocol,
    String? host,
    int? port,
    String? basePath,
  }) => ServerProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    environment: environment ?? this.environment,
    protocol: protocol ?? this.protocol,
    host: host ?? this.host,
    port: port ?? this.port,
    basePath: basePath ?? this.basePath,
  );

  Map<String, dynamic> toJson({bool isActive = false}) => {
    'id': id,
    'name': name,
    'environment': environment.name,
    'protocol': protocol.name,
    'host': host,
    'port': port,
    'basePath': basePath,
    'isActive': isActive,
  };

  /// คืน null สำหรับแถวที่เชื่อไม่ได้ แทนที่จะโยน
  ///
  /// ต่างจากกฎใน Part 6 โดยตั้งใจ — ข้อมูลนี้เราเขียนเองลงเครื่องนี้
  /// ไม่ใช่สัญญากับเซิร์ฟเวอร์ และแถวเสียหนึ่งแถวต้องไม่ทำให้ผู้ใช้
  /// เสีย profile อื่นที่เหลือทั้งหมด (10.5)
  static ServerProfile? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id']?.toString();
    final host = raw['host']?.toString();
    final port = int.tryParse(raw['port']?.toString() ?? '');
    if (id == null || id.isEmpty || host == null || host.isEmpty) return null;
    if (port == null || port < 1 || port > 65535) return null;

    final name = raw['name']?.toString().trim();
    return ServerProfile(
      id: id,
      // ไม่มีชื่อก็ใช้ host แทน ดีกว่าปล่อยให้เป็นบรรทัดว่างในรายการ
      name: name == null || name.isEmpty ? host : name,
      environment: ServerEnvironment.parse(raw['environment']?.toString()),
      protocol: ServerProtocol.parse(raw['protocol']?.toString()),
      host: host,
      port: port,
      basePath: raw['basePath']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'ServerProfile($name, $baseUrl)';
}

/// ที่อยู่เริ่มต้น อยู่ที่เดียวในระบบ
///
/// ทั้ง profile ตัวแรกที่สร้างตอนเปิดแอปครั้งแรก และค่าสำรองก่อนโหลดเสร็จ
/// อ่านจากสองค่านี้ ย้ายเครื่อง dev จึงแก้บรรทัดเดียว
const String defaultServerHost = 'localhost';
const int defaultServerPort = 6191;

/// profile ที่สร้างให้ตอนเปิดแอปครั้งแรก
ServerProfile seedProfile({String id = 'seed'}) => ServerProfile(
  id: id,
  name: 'Default',
  environment: ServerEnvironment.development,
  protocol: ServerProtocol.http,
  host: defaultServerHost,
  port: defaultServerPort,
  basePath: '',
);
