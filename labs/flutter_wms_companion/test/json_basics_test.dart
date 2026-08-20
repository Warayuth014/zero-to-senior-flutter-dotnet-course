import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/json_basics/inbound_dto.dart';
import 'package:flutter_wms_companion/json_basics/json_read.dart';
import 'package:flutter_wms_companion/json_basics/task_domain.dart';
import 'package:flutter_wms_companion/json_basics/task_dto.dart';

/// อ่านไฟล์ตัวอย่างที่เก็บหน้าตาของข้อมูลจริงไว้
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

/// สร้าง JSON ของงานหนึ่งชิ้น แล้วแก้เฉพาะคีย์ที่อยากทดสอบ
Map<String, dynamic> taskJson([Map<String, Object?> overrides = const {}]) => {
  'id': 'T-001',
  'palletCode': 'PAL-0101',
  'quantity': 12,
  'status': 'PENDING',
  'createdAt': '2026-08-15T03:00:00Z',
  ...overrides,
};

void main() {
  group('อ่านค่าที่จำเป็น', () {
    test('ไม่มีคีย์ ต้องบอกว่าคีย์ไหนหาย', () {
      final json = taskJson()..remove('id');

      expect(
        () => TaskDto.fromJson(json),
        throwsA(
          isA<ContractException>()
              .having((e) => e.path, 'path', 'id')
              .having((e) => e.message, 'message', contains('ไม่มีคีย์นี้')),
        ),
      );
    });

    test('คีย์มีอยู่แต่ค่าเป็น null ต้องบอกคนละอย่างกับคีย์หาย', () {
      expect(
        () => TaskDto.fromJson(taskJson({'id': null})),
        throwsA(
          isA<ContractException>().having(
            (e) => e.message,
            'message',
            contains('ต้องไม่เป็น null'),
          ),
        ),
      );
    });

    test('ข้อความว่างไม่นับว่ามีค่า', () {
      expect(
        () => TaskDto.fromJson(taskJson({'palletCode': '   '})),
        throwsA(isA<ContractException>()),
      );
    });

    test('หมายเหตุที่ไม่มี ค่า null และข้อความว่าง ให้ผลเหมือนกัน', () {
      expect(TaskDto.fromJson(taskJson()).note, isNull);
      expect(TaskDto.fromJson(taskJson({'note': null})).note, isNull);
      expect(TaskDto.fromJson(taskJson({'note': '  '})).note, isNull);
    });
  });

  group('ตัวเลข', () {
    test('รับทั้ง 12, 12.0 และ "12" เพราะ JSON ไม่แยกชนิด', () {
      for (final raw in <Object>[12, 12.0, '12']) {
        expect(TaskDto.fromJson(taskJson({'quantity': raw})).quantity, 12);
      }
    });

    test('ปฏิเสธเศษ ไม่ปัดให้เงียบ ๆ', () {
      expect(
        () => TaskDto.fromJson(taskJson({'quantity': 1.9})),
        throwsA(
          isA<ContractException>().having(
            (e) => e.message,
            'message',
            contains('จำนวนเต็ม'),
          ),
        ),
      );
    });

    test('ข้อความที่ไม่ใช่ตัวเลข ต้องพังพร้อมบอกค่าที่ได้', () {
      expect(
        () => TaskDto.fromJson(taskJson({'quantity': 'สิบสอง'})),
        throwsA(
          isA<ContractException>().having(
            (e) => e.message,
            'message',
            contains('สิบสอง'),
          ),
        ),
      );
    });
  });

  group('เวลา', () {
    test('แปลง offset เป็น UTC ให้เสมอ', () {
      final dto = TaskDto.fromJson(
        taskJson({'createdAt': '2026-08-15T10:00:00+07:00'}),
      );

      expect(dto.createdAt.isUtc, isTrue);
      expect(dto.createdAt, DateTime.utc(2026, 8, 15, 3));
    });

    test('เวลาที่ไม่บอกเขตเวลา ต้องถูกปฏิเสธ', () {
      expect(
        () => TaskDto.fromJson(taskJson({'createdAt': '2026-08-15T10:00:00'})),
        throwsA(
          isA<ContractException>().having(
            (e) => e.message,
            'message',
            contains('เขตเวลา'),
          ),
        ),
      );
    });
  });

  group('สถานะ', () {
    test('แปลงค่าที่รู้จัก และรับชื่อเล่นของระบบเก่า', () {
      expect(parseTaskStatus('PENDING'), TaskStatus.pending);
      expect(parseTaskStatus('working'), TaskStatus.working);
      expect(parseTaskStatus('DONE'), TaskStatus.done);
      expect(parseTaskStatus('COMPLETED'), TaskStatus.done);
    });

    test('ค่าที่ไม่รู้จักต้องไม่ทำให้พัง แต่ต้องทำงานต่อไม่ได้', () {
      final status = parseTaskStatus('PAUSED');

      expect(status, TaskStatus.unknown);
      expect(status.canWorkOn, isFalse);
    });
  });

  group('ซองที่ห่อรายการมา', () {
    test('อ่านไฟล์ตัวอย่างได้ครบ และ totalCount ไม่ใช่จำนวนในหน้านี้', () {
      final page = TaskPageDto.fromJson(fixture('tasks_page.json'));

      expect(page.items, hasLength(3));
      expect(page.totalCount, 137);
      expect(page.hasMore, isTrue);
    });

    test('รับ PascalCase จากระบบเก่าได้ด้วย', () {
      final page = TaskPageDto.fromJson(fixture('tasks_page_pascal.json'));

      expect(page.items.single.id, 'T-101');
      expect(page.items.single.quantity, 5);
      expect(page.hasMore, isFalse);
    });

    test('รายการว่างคือความสำเร็จ ไม่ใช่ความผิดพลาด', () {
      final page = TaskPageDto.fromJson({'items': [], 'totalCount': 0});

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('แถวที่พังต้องบอกว่าเป็นแถวที่เท่าไหร่', () {
      final json = {
        'items': [taskJson(), taskJson({'id': 'T-002'})..remove('quantity')],
        'totalCount': 2,
      };

      expect(
        () => TaskPageDto.fromJson(json),
        throwsA(
          isA<ContractException>().having(
            (e) => e.path,
            'path',
            'items[1].quantity',
          ),
        ),
      );
    });

    test('items ที่ไม่ใช่ array ต้องพังที่ items ไม่ใช่ที่อื่น', () {
      expect(
        () => TaskPageDto.fromJson({'items': {'0': {}}, 'totalCount': 1}),
        throwsA(isA<ContractException>().having((e) => e.path, 'path', 'items')),
      );
    });

    test('totalCount น้อยกว่าจำนวนที่ส่งมา คือข้อมูลขัดแย้งกันเอง', () {
      expect(
        () => TaskPageDto.fromJson({
          'items': [taskJson()],
          'totalCount': 0,
        }),
        throwsA(isA<ContractException>()),
      );
    });
  });

  group('JSON ที่ซ้อนกัน', () {
    test('อ่านใบรับเข้าพร้อมบรรทัดสินค้าได้ครบ', () {
      final order = InboundOrderDto.fromJson(fixture('inbound_order.json'));

      expect(order.orderNo, 'IN-2026-0812');
      expect(order.details, hasLength(3));
      expect(order.details[1].lotNumber, isNull);
      expect(order.totalExpectedQuantity, 130);
      expect(order.expectedAt, DateTime.utc(2026, 8, 16, 1));
    });

    test('บรรทัดที่พังต้องบอกตำแหน่งลึกถึงชั้นใน', () {
      final json = fixture('inbound_order.json');
      (json['details'] as List)[2] = {'productCode': 'SKU-1003'};

      expect(
        () => InboundOrderDto.fromJson(json),
        throwsA(
          isA<ContractException>().having(
            (e) => e.path,
            'path',
            'details[2].expectedQuantity',
          ),
        ),
      );
    });

    test('ใบที่ไม่มีบรรทัดสินค้าเลย คือข้อมูลที่ใช้ไม่ได้', () {
      final json = fixture('inbound_order.json')..['details'] = [];

      expect(() => InboundOrderDto.fromJson(json), throwsA(isA<ContractException>()));
    });

    test('เวลาที่คาดว่าของจะมาถึง ไม่มีก็ได้', () {
      final json = fixture('inbound_order.json')..remove('expectedAt');

      expect(InboundOrderDto.fromJson(json).expectedAt, isNull);
    });
  });

  group('แปลงเป็นชนิดของธุรกิจ', () {
    test('แปลงครบทุก field และ status กลายเป็น enum', () {
      final task = toTask(TaskDto.fromJson(taskJson({'status': 'COMPLETED'})));

      expect(task.id, 'T-001');
      expect(task.status, TaskStatus.done);
      expect(task.createdAt.isUtc, isTrue);
    });

    test('จำนวนติดลบจากเซิร์ฟเวอร์ ต้องปฏิเสธ ไม่ใช่ปรับเป็นศูนย์', () {
      final dto = TaskDto.fromJson(taskJson({'quantity': -5}));

      expect(
        () => toTask(dto),
        throwsA(
          isA<ContractException>().having(
            (e) => e.message,
            'message',
            contains('มากกว่าศูนย์'),
          ),
        ),
      );
    });
  });

  group('วัตถุที่แก้ไม่ได้', () {
    test('copyWith เปลี่ยนเฉพาะที่ส่งมา', () {
      final task = toTask(TaskDto.fromJson(taskJson({'note': 'วางชั้นล่าง'})));
      final updated = task.copyWith(status: TaskStatus.done);

      expect(updated.status, TaskStatus.done);
      expect(updated.quantity, task.quantity);
      expect(updated.note, 'วางชั้นล่าง');
    });

    test('copyWith ตั้งค่าเป็น null ไม่ได้ จึงต้องมีเมธอดล้างแยก', () {
      final task = toTask(TaskDto.fromJson(taskJson({'note': 'วางชั้นล่าง'})));

      expect(task.copyWith().note, 'วางชั้นล่าง');
      expect(task.clearNote().note, isNull);
    });

    test('เท่ากันเมื่อค่าเท่ากัน ไม่ใช่เมื่อเป็นวัตถุตัวเดียวกัน', () {
      final a = toTask(TaskDto.fromJson(taskJson()));
      final b = toTask(TaskDto.fromJson(taskJson()));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(identical(a, b), isFalse);
    });
  });

  group('คำสั่งที่ส่งขึ้นไป', () {
    test('ส่งคีย์ครบตามที่ตกลง รวมถึงคีย์ที่ค่าเป็น null', () {
      const request = CompleteTaskRequest(
        taskId: 'T-001',
        quantity: 12,
        commandId: 'cmd-1',
      );

      expect(request.toJson(), {
        'taskId': 'T-001',
        'quantity': 12,
        'commandId': 'cmd-1',
        'note': null,
      });
    });
  });
}
