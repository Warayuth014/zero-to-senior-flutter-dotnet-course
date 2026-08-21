/// ตรวจว่าโปรเจกต์พร้อมปล่อยจริงไหม
///
/// ปัญหาของ checklist ที่เขียนเป็นเอกสารคือไม่มีใครอ่านตอนรีบ ไฟล์นี้
/// เปลี่ยน checklist ให้เป็นเทสต์ที่ CI รันได้ — ข้อไหนตกก็เห็นก่อน build
/// ไม่ใช่หลังจากที่ APK ถึงมือผู้ใช้แล้ว (15.12)
library;

/// ความรุนแรงของสิ่งที่ตรวจพบ
enum Severity {
  /// ปล่อยไปแล้วแอปใช้งานไม่ได้
  blocker,

  /// ใช้งานได้ แต่มีความเสี่ยงหรือผิดแนวปฏิบัติ
  warning,
}

/// สิ่งที่ตรวจพบหนึ่งข้อ
class ReleaseFinding {
  const ReleaseFinding(this.severity, this.code, this.message, this.fix);

  final Severity severity;

  /// รหัสสั้นสำหรับอ้างอิงในเทสต์ ไม่ต้องเทียบข้อความยาว
  final String code;

  final String message;

  /// วิธีแก้ที่ทำตามได้เลย
  final String fix;

  bool get isBlocker => severity == Severity.blocker;

  @override
  String toString() => '[${severity.name}] $code: $message';
}

/// ตรวจ AndroidManifest.xml ของ build ที่จะปล่อย
///
/// รับข้อความของไฟล์ ไม่ใช่ที่อยู่ไฟล์ — ทำให้เทสต์ไม่ต้องมีไฟล์จริง
/// และเรียกจากสคริปต์ที่อ่านไฟล์เองก็ได้ (14.3)
List<ReleaseFinding> checkAndroidManifest(String manifest) {
  final findings = <ReleaseFinding>[];

  // Flutter ใส่สิทธิ์นี้ให้เฉพาะใน debug และ profile manifest — ถ้า main
  // ไม่มี แอปที่ build เป็น release จะต่อเน็ตไม่ได้เลย และอาการที่เห็นคือ
  // "โหลดไม่สำเร็จ" ทุกจอ โดยที่ทดสอบตอนพัฒนาแล้วปกติทุกอย่าง
  if (!manifest.contains('android.permission.INTERNET')) {
    findings.add(const ReleaseFinding(
      Severity.blocker,
      'missing-internet-permission',
      'main manifest ไม่มีสิทธิ์ INTERNET',
      'เพิ่ม <uses-permission android:name="android.permission.INTERNET"/> '
          'ใน android/app/src/main/AndroidManifest.xml',
    ));
  }

  // ตั้งแต่ Android 9 การเรียก http:// ถูกบล็อกโดยปริยาย — เซิร์ฟเวอร์ WMS
  // ในคลังส่วนใหญ่เป็น http จึงต้องอนุญาตอย่างใดอย่างหนึ่ง
  final allowsCleartext = manifest.contains('usesCleartextTraffic="true"');
  final hasNetworkConfig = manifest.contains('networkSecurityConfig');
  if (!allowsCleartext && !hasNetworkConfig) {
    findings.add(const ReleaseFinding(
      Severity.blocker,
      'cleartext-blocked',
      'ไม่ได้อนุญาต http และไม่มี network security config',
      'ถ้าเซิร์ฟเวอร์เป็น https ไม่ต้องทำอะไร — ถ้าเป็น http ให้เพิ่ม '
          'networkSecurityConfig ที่จำกัดเฉพาะโดเมนของคลัง (15.4)',
    ));
  }

  // อนุญาตทั้งหมดใช้ได้ แต่กว้างเกินจำเป็น
  if (allowsCleartext && !hasNetworkConfig) {
    findings.add(const ReleaseFinding(
      Severity.warning,
      'cleartext-too-broad',
      'usesCleartextTraffic="true" อนุญาต http ไปทุกที่อยู่',
      'ใช้ networkSecurityConfig จำกัดเฉพาะโดเมนที่จำเป็น',
    ));
  }

  if (manifest.contains('android:label="')) {
    final label = RegExp(r'android:label="([^"]*)"').firstMatch(manifest)?[1];
    if (label == null || label.trim().isEmpty) {
      findings.add(const ReleaseFinding(
        Severity.warning,
        'empty-label',
        'ชื่อแอปว่าง',
        'ตั้ง android:label ให้ผู้ใช้แยกออกจากแอปอื่นบนเครื่อง (11.12)',
      ));
    }
  }

  // ข้อความที่หลุดเข้ามาในไฟล์ XML — มักเกิดจากการพิมพ์พลาดตอนแก้ไฟล์
  // แล้วไม่มีอะไรฟ้อง เพราะ XML ยอมให้มีข้อความในอิลิเมนต์ได้
  final strayText = RegExp(r'>\s*([A-Za-z])\s*<\s*\w').firstMatch(manifest);
  if (strayText != null) {
    findings.add(ReleaseFinding(
      Severity.warning,
      'stray-text',
      'มีข้อความ "${strayText[1]}" หลุดอยู่ระหว่างแท็ก',
      'ลบออก — น่าจะพิมพ์พลาดตอนแก้ไฟล์',
    ));
  }

  return findings;
}

/// ตรวจ build.gradle ของ Android
List<ReleaseFinding> checkAndroidGradle(String gradle) {
  final findings = <ReleaseFinding>[];

  // Flutter สร้างโปรเจกต์มาด้วย com.example.* ซึ่งเป็นชื่อจองไว้สำหรับ
  // ตัวอย่าง — Play Store ปฏิเสธ และเครื่องที่เคยติดตั้งแอปตัวอย่างอื่น
  // ที่ใช้ชื่อเดียวกันจะทับกัน
  if (gradle.contains('applicationId = "com.example.')) {
    findings.add(const ReleaseFinding(
      Severity.blocker,
      'default-application-id',
      'applicationId ยังเป็น com.example.*',
      'เปลี่ยนเป็นชื่อโดเมนขององค์กร เช่น com.acetec.wms.pda (15.7)',
    ));
  }

  // เซ็นด้วยกุญแจ debug แปลว่าใครก็สร้างแอปที่อัปเดตทับได้ เพราะกุญแจ
  // debug เป็นกุญแจสาธารณะที่ทุกเครื่องที่ติดตั้ง Android SDK มีเหมือนกัน
  if (gradle.contains('signingConfigs.getByName("debug")')) {
    findings.add(const ReleaseFinding(
      Severity.blocker,
      'debug-signing',
      'build ที่จะปล่อยเซ็นด้วยกุญแจ debug',
      'สร้าง keystore ของตัวเองแล้วอ้างผ่าน key.properties ที่ไม่เข้า git (15.8)',
    ));
  }

  return findings;
}

/// ตรวจ pubspec.yaml
List<ReleaseFinding> checkPubspec(String pubspec) {
  final findings = <ReleaseFinding>[];

  final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
      .firstMatch(pubspec)?[1];

  if (version == null) {
    findings.add(const ReleaseFinding(
      Severity.blocker,
      'missing-version',
      'ไม่มีบรรทัด version ใน pubspec.yaml',
      'เพิ่ม version: 1.0.0+1',
    ));
  } else if (!version.contains('+')) {
    findings.add(ReleaseFinding(
      Severity.blocker,
      'missing-build-number',
      'version "$version" ไม่มีเลข build ต่อท้าย',
      'เขียนเป็น 1.0.0+1 — เลขหลัง + คือสิ่งที่ Android ใช้ตัดสินว่ารุ่นไหนใหม่กว่า (15.2)',
    ));
  }

  // แพ็กเกจที่ใช้เฉพาะตอนพัฒนา ไม่ควรติดไปกับแอปจริง
  const devOnly = ['flutter_launcher_icons', 'build_runner', 'flutter_lints'];
  final dependencies = _sectionOf(pubspec, 'dependencies');
  for (final package in devOnly) {
    if (dependencies.contains('$package:')) {
      findings.add(ReleaseFinding(
        Severity.warning,
        'dev-package-in-dependencies',
        '$package อยู่ใน dependencies ทั้งที่ใช้เฉพาะตอนพัฒนา',
        'ย้ายไป dev_dependencies (11.12)',
      ));
    }
  }

  return findings;
}

/// ตัดเอาเฉพาะส่วนของ dependencies ออกมา ไม่ให้ปนกับ dev_dependencies
String _sectionOf(String pubspec, String name) {
  final start = pubspec.indexOf('\n$name:');
  if (start < 0) return '';
  final rest = pubspec.substring(start + 1);
  // จบเมื่อเจอบรรทัดที่ไม่ได้ย่อหน้า ซึ่งแปลว่าเป็นหัวข้อถัดไป
  final end = RegExp(r'\n(?=\S)').firstMatch(rest.substring(name.length + 1));
  return end == null
      ? rest
      : rest.substring(0, name.length + 1 + end.start);
}

/// รวมผลทั้งหมด
class ReleaseReport {
  const ReleaseReport(this.findings);

  final List<ReleaseFinding> findings;

  List<ReleaseFinding> get blockers =>
      findings.where((f) => f.isBlocker).toList();

  List<ReleaseFinding> get warnings =>
      findings.where((f) => !f.isBlocker).toList();

  /// ปล่อยได้ไหม — คำถามเดียวที่ CI ต้องการคำตอบ
  bool get canRelease => blockers.isEmpty;

  bool has(String code) => findings.any((f) => f.code == code);

  @override
  String toString() => findings.isEmpty
      ? 'พร้อมปล่อย'
      : findings.map((f) => '${f.severity.name}  ${f.code}\n  ${f.fix}').join('\n');
}

/// ตรวจทั้งโปรเจกต์
ReleaseReport checkRelease({
  required String androidManifest,
  required String androidGradle,
  required String pubspec,
}) => ReleaseReport([
  ...checkAndroidManifest(androidManifest),
  ...checkAndroidGradle(androidGradle),
  ...checkPubspec(pubspec),
]);
