/// รุ่นของแอปที่ประกอบจาก pubspec
///
/// สองเลขนี้ทำหน้าที่ต่างกันโดยสิ้นเชิง และการสับสนระหว่างสองอย่างนี้
/// ทำให้ผู้ใช้ติดตั้งทับไม่ได้ หรือได้รุ่นเก่ากว่าที่มีอยู่ (15.2)
class AppVersion {
  const AppVersion({
    required this.name,
    required this.build,
  });

  /// เลขที่ผู้ใช้เห็น เช่น "3.1.0" — สื่อว่ามีอะไรเปลี่ยนมากแค่ไหน
  final String name;

  /// เลขที่ระบบใช้ตัดสินว่ารุ่นไหนใหม่กว่า ต้องเพิ่มขึ้นเสมอ
  ///
  /// Android เรียกว่า versionCode และ **ปฏิเสธการติดตั้งทับด้วยเลขที่
  /// เท่ากันหรือน้อยกว่า** ไม่ว่าชื่อรุ่นจะเป็นอะไร
  final int build;

  /// อ่านจากบรรทัด version ใน pubspec.yaml
  ///
  /// คืน null เมื่อรูปแบบไม่ถูก แทนที่จะโยน เพราะคนเรียกคือสคริปต์ตรวจ
  /// ที่ต้องรายงานทุกปัญหาพร้อมกัน ไม่ใช่หยุดที่ปัญหาแรก
  static AppVersion? parse(String raw) {
    final parts = raw.trim().split('+');
    if (parts.length != 2) return null;

    final build = int.tryParse(parts[1]);
    if (build == null || build < 1) return null;

    // ชื่อรุ่นต้องเป็นตัวเลขคั่นจุดสามส่วน
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(parts[0])) return null;

    return AppVersion(name: parts[0], build: build);
  }

  /// รุ่นนี้ติดตั้งทับ [installed] ได้ไหม
  bool canUpgradeFrom(AppVersion installed) => build > installed.build;

  /// เลขรุ่นถัดไปสำหรับการ build ครั้งต่อไป
  AppVersion nextBuild() => AppVersion(name: name, build: build + 1);

  /// ขึ้นรุ่นย่อย เช่นแก้บั๊ก — เลข build ยังต้องเพิ่มด้วย
  AppVersion nextPatch() {
    final numbers = name.split('.').map(int.parse).toList();
    return AppVersion(
      name: '${numbers[0]}.${numbers[1]}.${numbers[2] + 1}',
      build: build + 1,
    );
  }

  String get pubspecLine => '$name+$build';

  @override
  String toString() => pubspecLine;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && other.name == name && other.build == build;

  @override
  int get hashCode => Object.hash(name, build);
}
