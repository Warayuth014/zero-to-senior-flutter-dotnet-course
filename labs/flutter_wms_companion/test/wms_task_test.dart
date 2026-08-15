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
