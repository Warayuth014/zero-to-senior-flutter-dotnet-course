import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/release_lab/app_version.dart';
import 'package:flutter_wms_companion/release_lab/crash_report.dart';
import 'package:flutter_wms_companion/release_lab/release_checks.dart';

/// manifest ที่ผ่านทุกข้อ ใช้เป็นฐานแล้วแก้ทีละจุดในแต่ละเทสต์
const goodManifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:label="ABS PDA V3"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config">
        <activity android:name=".MainActivity" android:exported="true"/>
    </application>
</manifest>
''';

const goodGradle = '''
android {
    namespace = "com.acetec.wms.pda"
    defaultConfig {
        applicationId = "com.acetec.wms.pda"
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
''';

const goodPubspec = '''
name: wms_pda
version: 3.1.0+42

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
''';

void main() {
  group('ตรวจ AndroidManifest', () {
    test('manifest ที่ถูกต้อง ไม่มีข้อทักท้วง', () {
      expect(checkAndroidManifest(goodManifest), isEmpty);
    });

    test('ไม่มีสิทธิ์ INTERNET ต้องเป็นตัวขวางการปล่อย', () {
      // Flutter ใส่สิทธิ์นี้ให้เฉพาะใน debug/profile manifest — build ที่
      // ปล่อยจริงจะต่อเน็ตไม่ได้เลย และทดสอบตอนพัฒนาจะไม่มีทางเจอ
      final manifest = goodManifest.replaceAll(
        '<uses-permission android:name="android.permission.INTERNET"/>',
        '',
      );

      final findings = checkAndroidManifest(manifest);
      final blocker = findings.firstWhere((f) => f.isBlocker);
      expect(blocker.code, 'missing-internet-permission');
      expect(blocker.fix, contains('uses-permission'));
    });

    test('ไม่มีทั้ง cleartext และ network config ต้องขวางการปล่อย', () {
      final manifest = goodManifest.replaceAll(
        'android:networkSecurityConfig="@xml/network_security_config"',
        '',
      );

      final findings = checkAndroidManifest(manifest);
      expect(findings.any((f) => f.code == 'cleartext-blocked'), isTrue);
    });

    test('อนุญาต http ทั้งหมด ผ่านได้แต่ต้องเตือน', () {
      final manifest = goodManifest.replaceAll(
        'android:networkSecurityConfig="@xml/network_security_config"',
        'android:usesCleartextTraffic="true"',
      );

      final findings = checkAndroidManifest(manifest);
      expect(findings.any((f) => f.isBlocker), isFalse);
      expect(findings.single.code, 'cleartext-too-broad');
    });

    test('ข้อความที่หลุดเข้ามาระหว่างแท็ก ต้องถูกจับ', () {
      // XML ยอมให้มีข้อความในอิลิเมนต์ จึงไม่มีอะไรฟ้องตอน build
      final manifest = goodManifest.replaceAll(
        'android:networkSecurityConfig="@xml/network_security_config">',
        'android:networkSecurityConfig="@xml/network_security_config">f',
      );

      final findings = checkAndroidManifest(manifest);
      final stray = findings.firstWhere((f) => f.code == 'stray-text');
      expect(stray.message, contains('f'));
      expect(stray.isBlocker, isFalse);
    });

    test('ชื่อแอปว่าง ต้องเตือน', () {
      final manifest = goodManifest.replaceAll(
        'android:label="ABS PDA V3"',
        'android:label=""',
      );

      expect(
        checkAndroidManifest(manifest).any((f) => f.code == 'empty-label'),
        isTrue,
      );
    });
  });

  group('ตรวจ build.gradle', () {
    test('gradle ที่ถูกต้อง ไม่มีข้อทักท้วง', () {
      expect(checkAndroidGradle(goodGradle), isEmpty);
    });

    test('applicationId ที่ยังเป็น com.example ต้องขวางการปล่อย', () {
      final gradle = goodGradle.replaceAll(
        'com.acetec.wms.pda"',
        'com.example.wms_pda"',
      );

      final findings = checkAndroidGradle(gradle);
      final blocker = findings.firstWhere((f) => f.isBlocker);
      expect(blocker.code, 'default-application-id');
    });

    test('เซ็นด้วยกุญแจ debug ต้องขวางการปล่อย', () {
      final gradle = goodGradle.replaceAll(
        'signingConfigs.getByName("release")',
        'signingConfigs.getByName("debug")',
      );

      final findings = checkAndroidGradle(gradle);
      expect(findings.single.code, 'debug-signing');
      expect(findings.single.isBlocker, isTrue);
    });
  });

  group('ตรวจ pubspec', () {
    test('pubspec ที่ถูกต้อง ไม่มีข้อทักท้วง', () {
      expect(checkPubspec(goodPubspec), isEmpty);
    });

    test('version ที่ไม่มีเลข build ต้องขวางการปล่อย', () {
      final pubspec = goodPubspec.replaceAll('3.1.0+42', '3.1.0');

      final findings = checkPubspec(pubspec);
      expect(findings.single.code, 'missing-build-number');
      expect(findings.single.fix, contains('+'));
    });

    test('แพ็กเกจที่ใช้เฉพาะตอนพัฒนา อยู่ใน dependencies ต้องเตือน', () {
      final pubspec = goodPubspec.replaceAll(
        '  http: ^1.2.2',
        '  http: ^1.2.2\n  build_runner: ^2.15.1',
      );

      final findings = checkPubspec(pubspec);
      expect(
        findings.any((f) => f.code == 'dev-package-in-dependencies'),
        isTrue,
      );
    });

    test('flutter_lints ที่อยู่ใน dev_dependencies ต้องไม่ถูกเตือน', () {
      // ต้องแยกให้ออกว่าอยู่ส่วนไหน ไม่ใช่ค้นทั้งไฟล์
      expect(checkPubspec(goodPubspec), isEmpty);
    });
  });

  group('รายงานรวม', () {
    test('โปรเจกต์ที่พร้อม ปล่อยได้', () {
      final report = checkRelease(
        androidManifest: goodManifest,
        androidGradle: goodGradle,
        pubspec: goodPubspec,
      );

      expect(report.canRelease, isTrue);
      expect(report.toString(), 'พร้อมปล่อย');
    });

    test('โปรเจกต์ที่เพิ่งสร้างจากแม่แบบ ปล่อยไม่ได้', () {
      // นี่คือสถานะของโปรเจกต์ Flutter ที่ยังไม่ได้ตั้งค่าอะไรเลย
      final report = checkRelease(
        androidManifest: '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="wmsapp"/>
</manifest>
''',
        androidGradle: '''
defaultConfig { applicationId = "com.example.wmsapp" }
buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }
''',
        pubspec: 'name: wmsapp\nversion: 1.0.0+1\n',
      );

      expect(report.canRelease, isFalse);
      // สามข้อนี้คือสิ่งที่ทำให้ APK ที่ build ออกมาใช้งานจริงไม่ได้
      expect(report.has('missing-internet-permission'), isTrue);
      expect(report.has('cleartext-blocked'), isTrue);
      expect(report.has('default-application-id'), isTrue);
      expect(report.has('debug-signing'), isTrue);
    });

    test('รายงานแยกตัวขวางออกจากคำเตือน', () {
      final report = checkRelease(
        androidManifest: goodManifest.replaceAll(
          'android:networkSecurityConfig="@xml/network_security_config"',
          'android:usesCleartextTraffic="true"',
        ),
        androidGradle: goodGradle,
        pubspec: goodPubspec,
      );

      expect(report.blockers, isEmpty);
      expect(report.warnings, hasLength(1));
      expect(report.canRelease, isTrue, reason: 'คำเตือนไม่ขวางการปล่อย');
    });
  });

  group('AppVersion', () {
    test('อ่านรูปแบบที่ถูกต้อง', () {
      final version = AppVersion.parse('3.1.0+42');
      expect(version, isNotNull);
      expect(version!.name, '3.1.0');
      expect(version.build, 42);
    });

    test('รูปแบบที่ผิดคืน null ไม่ใช่โยน', () {
      for (final raw in ['3.1.0', '3.1+2', 'v3.1.0+2', '3.1.0+0', '3.1.0+abc']) {
        expect(AppVersion.parse(raw), isNull, reason: 'ผิดที่ "$raw"');
      }
    });

    test('เลข build ที่มากกว่าเท่านั้นที่ติดตั้งทับได้', () {
      final installed = AppVersion.parse('3.1.0+42')!;

      expect(AppVersion.parse('3.1.0+43')!.canUpgradeFrom(installed), isTrue);
      expect(AppVersion.parse('3.1.0+42')!.canUpgradeFrom(installed), isFalse);
      // ชื่อรุ่นใหม่กว่าแต่เลข build เท่าเดิม — Android ปฏิเสธ
      expect(AppVersion.parse('4.0.0+42')!.canUpgradeFrom(installed), isFalse);
    });

    test('ขึ้นรุ่นย่อยต้องเพิ่มเลข build ด้วย', () {
      final next = AppVersion.parse('3.1.0+42')!.nextPatch();
      expect(next.name, '3.1.1');
      expect(next.build, 43);
      expect(next.pubspecLine, '3.1.1+43');
    });
  });

  group('รายงานข้อผิดพลาด', () {
    test('token ใน query string ต้องถูกปิด', () {
      const text = 'GET /api/tasks?token=abc123def&zone=A1 failed';
      final result = redact(text);

      expect(result, isNot(contains('abc123def')));
      expect(result, contains('REDACTED'));
      expect(result, contains('zone=A1'), reason: 'ค่าที่ไม่อ่อนไหวต้องอยู่');
    });

    test('Bearer token ต้องถูกปิด', () {
      const text = 'headers: {Authorization: Bearer eyJhbGciOi.J9.abc}';
      expect(redact(text), isNot(contains('eyJhbGciOi')));
    });

    test('รหัสผ่านใน JSON ต้องถูกปิด', () {
      const text = '{"username":"somchai","password":"s3cret"}';
      final result = redact(text);

      expect(result, isNot(contains('s3cret')));
      expect(result, contains('somchai'), reason: 'ชื่อผู้ใช้ไม่ใช่ความลับ');
    });

    test('ข้อมูลประกอบที่มีคีย์อ่อนไหว ต้องถูกปิด', () {
      final context = redactContext({
        'screen': 'receiving',
        'token': 'abc123',
        'palletCode': 'PLT-001',
      });

      expect(context['token'], 'REDACTED');
      expect(context['screen'], 'receiving');
      expect(context['palletCode'], 'PLT-001');
    });

    test('รายงานที่สร้างแล้ว ต้องไม่มีความลับหลงเหลือ', () {
      final report = buildReport(
        error: Exception('401 on /api/tasks?token=abc123'),
        stack: StackTrace.fromString('at login(password: s3cret)'),
        appVersion: '3.1.0+42',
        at: DateTime.utc(2026, 8, 21, 10),
        screen: 'tasks',
        context: {'token': 'abc123'},
      );

      final json = report.toJson().toString();
      expect(json, isNot(contains('abc123')));
      expect(json, isNot(contains('s3cret')));
      // แต่ข้อมูลที่ใช้หาสาเหตุต้องยังอยู่ครบ
      expect(json, contains('401'));
      expect(json, contains('tasks'));
      expect(json, contains('3.1.0+42'));
    });

    test('เวลาในรายงานเป็น UTC เสมอ', () {
      final report = buildReport(
        error: Exception('x'),
        stack: StackTrace.empty,
        appVersion: '1.0.0+1',
        at: DateTime.utc(2026, 8, 21, 10),
      );

      expect(report.toJson()['at'], '2026-08-21T10:00:00.000Z');
    });
  });
}
