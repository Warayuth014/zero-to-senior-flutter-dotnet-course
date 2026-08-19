import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/scanner_basics/scan_session.dart';

/// เทสต์ของตรรกะล้วน — ไม่ต้องประกอบหน้าจอเลย จึงรันเร็วมาก
void main() {
  group('normalizeBarcode', () {
    test('ตัดช่องว่างและแปลงเป็นตัวพิมพ์ใหญ่', () {
      expect(normalizeBarcode('  pal-1001  '), 'PAL-1001');
    });

    test('ค่าว่างยังคงเป็นค่าว่าง', () {
      expect(normalizeBarcode('   '), '');
    });
  });

  group('isValidPalletCode', () {
    test('ยอมรับรูปแบบที่ถูก', () {
      expect(isValidPalletCode('PAL-1001'), isTrue);
      expect(isValidPalletCode('PAL-100189'), isTrue);
    });

    test('ปฏิเสธรูปแบบที่ผิด', () {
      expect(isValidPalletCode('PAL-1'), isFalse); // ตัวเลขน้อยไป
      expect(isValidPalletCode('BOX-1001'), isFalse); // คนละคำนำหน้า
      expect(isValidPalletCode('pal-1001'), isFalse); // ต้อง normalize ก่อน
    });
  });

  group('validateQuantity', () {
    test('null แปลว่าผ่าน', () {
      expect(validateQuantity('12'), isNull);
    });

    test('ปฏิเสธค่าว่าง ตัวอักษร ศูนย์ ติดลบ และเกินเพดาน', () {
      expect(validateQuantity(''), 'กรุณากรอกจำนวน');
      expect(validateQuantity('มาก'), 'จำนวนต้องเป็นตัวเลข');
      expect(validateQuantity('0'), 'จำนวนต้องมากกว่า 0');
      expect(validateQuantity('-3'), 'จำนวนต้องมากกว่า 0');
      expect(validateQuantity('1000'), 'จำนวนต้องไม่เกิน 999');
    });

    test('เพดานปรับได้', () {
      expect(validateQuantity('50', max: 20), 'จำนวนต้องไม่เกิน 20');
    });
  });

  group('ScanSession', () {
    test('รับรหัสที่ถูกต้องและ normalize ให้', () {
      final session = ScanSession(operatorName: 'สมชาย');

      expect(session.accept(' pal-1001 '), ScanOutcome.accepted);
      expect(session.accepted, <String>['PAL-1001']);
      expect(session.count, 1);
    });

    test('ยิงซ้ำถูกปฏิเสธ แม้ตัวพิมพ์และช่องว่างต่างกัน', () {
      final session = ScanSession(operatorName: 'สมชาย');
      session.accept('PAL-1001');

      expect(session.accept('  pal-1001'), ScanOutcome.duplicate);
      expect(session.count, 1); // ไม่เพิ่มซ้ำ
    });

    test('ค่าว่างและรูปแบบผิด ให้ผลคนละแบบกัน', () {
      final session = ScanSession(operatorName: 'สมชาย');

      expect(session.accept('   '), ScanOutcome.empty);
      expect(session.accept('BOX-1'), ScanOutcome.badFormat);
      expect(session.count, 0);
    });

    test('ระหว่างบันทึก ไม่รับตัวใหม่', () {
      final session = ScanSession(operatorName: 'สมชาย');
      session.beginSubmit();

      expect(session.accept('PAL-1001'), ScanOutcome.busy);
      expect(session.count, 0);

      session.endSubmit();
      expect(session.accept('PAL-1001'), ScanOutcome.accepted);
    });

    test('เอารายการออกแล้ว ยิงใหม่ได้อีกครั้ง', () {
      final session = ScanSession(operatorName: 'สมชาย');
      session.accept('PAL-1001');

      expect(session.remove('pal-1001'), isTrue);
      expect(session.count, 0);
      expect(session.accept('PAL-1001'), ScanOutcome.accepted);
    });

    test('รายการที่คืนออกไปแก้ไม่ได้', () {
      final session = ScanSession(operatorName: 'สมชาย');
      session.accept('PAL-1001');

      expect(() => session.accepted.add('PAL-9999'), throwsUnsupportedError);
    });

    test('เฉพาะกรณีสำเร็จที่ควรล้างช่องกรอก', () {
      expect(ScanOutcome.accepted.shouldClearInput, isTrue);
      expect(ScanOutcome.duplicate.shouldClearInput, isFalse);
      expect(ScanOutcome.badFormat.shouldClearInput, isFalse);
    });
  });
}
