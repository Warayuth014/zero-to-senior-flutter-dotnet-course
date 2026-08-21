import 'server_profile.dart';

/// สิ่งที่ผู้ใช้กำลังพิมพ์อยู่ในฟอร์ม — ยังไม่ใช่ profile
///
/// แยกจาก [ServerProfile] เพราะระหว่างพิมพ์ ค่ายังเป็นข้อความที่แปลงไม่ได้
/// เช่น port ที่พิมพ์ไปครึ่งเดียวเป็น "61" หรือว่างเปล่า ถ้าใช้โมเดลจริง
/// เป็นตัวเก็บ จะต้องยอมให้ `port` เป็น `int?` ซึ่งทำให้ทุกที่ที่ใช้ profile
/// ต้องเช็ค null ทั้งที่ profile ที่บันทึกแล้วมีพอร์ตเสมอ (10.11)
class ProfileDraft {
  ProfileDraft({
    this.id,
    this.name = '',
    this.environment = ServerEnvironment.development,
    this.protocol = ServerProtocol.http,
    this.host = '',
    this.port = '',
    this.basePath = '',
  });

  /// สร้างร่างจาก profile ที่มีอยู่ เพื่อเปิดหน้าแก้ไข
  factory ProfileDraft.from(ServerProfile profile) => ProfileDraft(
    id: profile.id,
    name: profile.name,
    environment: profile.environment,
    protocol: profile.protocol,
    host: profile.host,
    port: profile.port.toString(),
    basePath: profile.basePath,
  );

  /// null แปลว่ากำลังสร้างใหม่ ไม่ใช่แก้ของเดิม
  final String? id;

  String name;
  ServerEnvironment environment;
  ServerProtocol protocol;
  String host;

  /// เป็น String ไม่ใช่ int เพราะระหว่างพิมพ์ยังไม่เป็นตัวเลข
  String port;
  String basePath;

  bool get isNew => id == null;

  /// ผู้ใช้แก้อะไรไปแล้วเทียบกับตัวที่บันทึกไว้หรือยัง
  ///
  /// ใช้ตัดสินว่าจะเตือนก่อนปิดฟอร์มไหม เทียบทีละช่องแทนที่จะเทียบ
  /// baseUrl เพราะการเปลี่ยนชื่อก็นับว่าแก้ ทั้งที่ baseUrl เท่าเดิม
  bool isDirtyFrom(ServerProfile? saved) {
    if (saved == null) {
      // ร่างใหม่ที่ยังไม่พิมพ์อะไรเลย ไม่ถือว่าแก้ — ปิดได้โดยไม่ต้องเตือน
      return name.trim().isNotEmpty ||
          host.trim().isNotEmpty ||
          port.trim().isNotEmpty ||
          basePath.trim().isNotEmpty;
    }
    return name.trim() != saved.name ||
        environment != saved.environment ||
        protocol != saved.protocol ||
        host.trim() != saved.host ||
        port.trim() != saved.port.toString() ||
        basePath.trim() != saved.basePath;
  }

  /// แปลงเป็น profile — เรียกได้ต่อเมื่อผ่านการตรวจแล้วเท่านั้น
  ///
  /// โยนถ้าพอร์ตแปลงไม่ได้ เพราะการมาถึงบรรทัดนี้ทั้งที่ยังไม่ผ่านการตรวจ
  /// เป็นบั๊กของเรา ไม่ใช่ความผิดของผู้ใช้ — ต้องดังให้ได้ยิน ไม่ใช่เงียบ
  ServerProfile toProfile({required String id}) {
    final parsedPort = int.tryParse(port.trim());
    if (parsedPort == null) {
      throw StateError('toProfile ถูกเรียกทั้งที่ยังไม่ผ่านการตรวจ: port="$port"');
    }
    return ServerProfile(
      id: id,
      name: name.trim(),
      environment: environment,
      protocol: protocol,
      host: host.trim(),
      port: parsedPort,
      basePath: basePath.trim(),
    );
  }
}
