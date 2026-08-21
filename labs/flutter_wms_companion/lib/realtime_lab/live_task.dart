/// งานหนึ่งชิ้นที่สถานะเปลี่ยนได้จากทั้งสองทาง — จากที่เราโหลดมา
/// และจากเหตุการณ์ที่เซิร์ฟเวอร์ส่งมาบอก
library;

enum LiveTaskStatus { waiting, dispatched, done }

class LiveTask {
  const LiveTask({
    required this.id,
    required this.status,
    required this.version,
    this.assignee = '',
  });

  final String id;
  final LiveTaskStatus status;

  /// เลขรุ่นที่เซิร์ฟเวอร์เพิ่มขึ้นทุกครั้งที่งานนี้เปลี่ยน
  ///
  /// เป็นตัวตัดสินว่าข้อมูลไหนใหม่กว่า — จะมาจากเหตุการณ์หรือจากการ
  /// โหลดผ่าน HTTP ก็ตัดสินด้วยตัวเลขนี้เหมือนกัน (12.10)
  final int version;

  final String assignee;

  LiveTask copyWith({
    LiveTaskStatus? status,
    int? version,
    String? assignee,
  }) => LiveTask(
    id: id,
    status: status ?? this.status,
    version: version ?? this.version,
    assignee: assignee ?? this.assignee,
  );

  @override
  String toString() => 'LiveTask($id, ${status.name}, v$version)';
}
