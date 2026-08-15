import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';

void main() {
  test('parse task contract ที่ครบถ้วน', () {
    final task = WmsTask.fromJson(const {
      'id': 'TASK-001',
      'from': 'A-01',
      'to': 'PACK-01',
      'status': 'WORKING',
    });

    expect(task.id, 'TASK-001');
    expect(task.status, TaskStatus.working);
    expect(task.toJson(), {
      'id': 'TASK-001',
      'from': 'A-01',
      'to': 'PACK-01',
      'status': 'working',
    });
  });

  test('generated equality และ copyWith ไม่แก้ object เดิม', () {
    const original = WmsTask(
      id: 'TASK-001',
      from: 'A-01',
      to: 'PACK-01',
      status: TaskStatus.waiting,
    );
    final working = original.copyWith(status: TaskStatus.working);

    expect(
      original,
      const WmsTask(
        id: 'TASK-001',
        from: 'A-01',
        to: 'PACK-01',
        status: TaskStatus.waiting,
      ),
    );
    expect(working.status, TaskStatus.working);
    expect(original.status, TaskStatus.waiting);
  });

  test('reject task ที่ id ว่างแทนการสร้าง model เสีย', () {
    expect(
      () => WmsTask.fromJson(const {
        'id': '',
        'from': 'A-01',
        'to': 'PACK-01',
        'status': 'waiting',
      }),
      throwsFormatException,
    );
  });

  test('reject status ใหม่ที่ client ยังไม่รองรับ', () {
    expect(
      () => WmsTask.fromJson(const {
        'id': 'TASK-001',
        'from': 'A-01',
        'to': 'PACK-01',
        'status': 'cancelled',
      }),
      throwsFormatException,
    );
  });
}
