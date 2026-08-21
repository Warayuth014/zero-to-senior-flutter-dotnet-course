import 'dart:async';

import 'package:flutter/foundation.dart';

import 'hub_events.dart';
import 'live_task.dart';
import 'realtime_client.dart';

/// แหล่งข้อมูลของงาน ซึ่งอาจมาจาก HTTP หรือมาจากเหตุการณ์ก็ได้
abstract interface class LiveTaskRepository {
  Future<List<LiveTask>> fetchOpen();
}

/// รวมสองแหล่งข้อมูลให้เป็นความจริงชุดเดียว
///
/// เหตุการณ์บอกว่า "มีอะไรเปลี่ยน" ส่วน HTTP บอกว่า "ตอนนี้เป็นอย่างไร"
/// ทั้งสองอย่างจำเป็น และบทที่ยากคือทำให้ทั้งสองอย่างไม่ขัดกัน (12.10)
class LiveTaskStore extends ChangeNotifier {
  LiveTaskStore({
    required this.repository,
    required this.client,
    this.pollInterval = const Duration(seconds: 15),
  });

  final LiveTaskRepository repository;
  final SharedRealtimeClient client;

  /// ความถี่ของการถามซ้ำ เมื่อเรียลไทม์ใช้ไม่ได้
  ///
  /// ไม่ได้ใช้ตอนที่เรียลไทม์ทำงานปกติ — การมีทั้งสองอย่างพร้อมกันคือ
  /// การจ่ายค่าเครือข่ายสองต่อเพื่อข้อมูลชุดเดียว (12.11)
  final Duration pollInterval;

  StreamSubscription<HubEvent>? _eventSub;
  StreamSubscription<RealtimeStatus>? _statusSub;
  Timer? _pollTimer;

  final Map<String, LiveTask> _tasks = {};
  bool _loading = false;
  String? _error;
  RealtimeStatus _status = RealtimeStatus.disconnected;

  /// นับไว้เพื่อให้เทสต์ตรวจได้ว่าเหตุการณ์เสียถูกทิ้งจริง ไม่ได้ถูกใช้
  int malformedEventCount = 0;

  List<LiveTask> get tasks => List.unmodifiable(_tasks.values);
  bool get loading => _loading;
  String? get error => _error;
  RealtimeStatus get status => _status;

  /// กำลังถามซ้ำเป็นระยะอยู่ไหม — ใช้แสดงให้ผู้ใช้รู้ว่าข้อมูลอาจช้า
  bool get isPolling => _pollTimer != null;

  /// เริ่มทำงาน — ต่อเรียลไทม์ ฟังเหตุการณ์ และโหลดครั้งแรก
  Future<void> start() async {
    // ฟังก่อนต่อ ไม่ใช่ต่อก่อนฟัง — เหตุการณ์ที่มาถึงระหว่างที่ยังไม่ได้
    // ลงทะเบียนฟัง จะหายไปเงียบ ๆ (12.7)
    _eventSub = client.events.listen(_onEvent);
    _statusSub = client.status.listen(_onStatus);

    await client.acquire();
    await load();
  }

  /// โหลดสถานะปัจจุบันทั้งชุดผ่าน HTTP
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await repository.fetchOpen();
      // เขียนทับทั้งชุด เพราะนี่คือความจริงล่าสุดจากเซิร์ฟเวอร์
      _tasks
        ..clear()
        ..addEntries(result.map((task) => MapEntry(task.id, task)));
    } catch (exception) {
      _error = exception.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _onStatus(RealtimeStatus value) {
    final previous = _status;
    _status = value;

    switch (value) {
      case RealtimeStatus.connected:
        _stopPolling();
        // ต่อกลับมาได้หลังจากหลุดไป แปลว่าระหว่างนั้นมีเหตุการณ์ที่เรา
        // ไม่ได้รับ — ไม่มีทางรู้ว่ากี่อัน จึงต้องโหลดใหม่ทั้งชุด (12.4)
        if (previous == RealtimeStatus.reconnecting ||
            previous == RealtimeStatus.disconnected) {
          unawaited(load());
        }
      case RealtimeStatus.reconnecting:
      case RealtimeStatus.disconnected:
        // ระหว่างที่เรียลไทม์ใช้ไม่ได้ ให้ถามซ้ำเป็นระยะแทน
        _startPolling();
      case RealtimeStatus.connecting:
        break;
    }

    notifyListeners();
  }

  void _onEvent(HubEvent event) {
    switch (event) {
      case TaskDispatched(:final taskId, :final assignee, :final version):
        _applyIfNewer(
          taskId,
          version,
          (task) => task.copyWith(
            status: LiveTaskStatus.dispatched,
            assignee: assignee,
            version: version,
          ),
          orElse: () => LiveTask(
            id: taskId,
            status: LiveTaskStatus.dispatched,
            assignee: assignee,
            version: version,
          ),
        );

      case TaskCompleted(:final taskId, :final version):
        _applyIfNewer(
          taskId,
          version,
          (task) => task.copyWith(status: LiveTaskStatus.done, version: version),
          // งานที่เสร็จแล้วและเราไม่เคยรู้จัก ไม่ต้องเพิ่มเข้ามา —
          // ลิสต์นี้แสดงงานค้าง การเพิ่มงานที่เสร็จแล้วเข้าไปไม่มีประโยชน์
          orElse: null,
        );

      case StationCounterUpdated():
        // จอนี้ไม่สนใจ แต่จออื่นที่ฟัง stream เดียวกันสนใจ
        break;

      case UnknownHubEvent():
        // เซิร์ฟเวอร์รุ่นใหม่กว่าแอป ไม่ใช่ปัญหา
        break;

      case MalformedHubEvent():
        // นับไว้ให้ทีมเห็น แต่ไม่ทำให้อะไรพัง (12.5)
        malformedEventCount++;
    }

    notifyListeners();
  }

  /// ใช้เหตุการณ์เฉพาะเมื่อมันใหม่กว่าสิ่งที่รู้อยู่
  ///
  /// เหตุการณ์ที่ส่งผ่านเครือข่ายมาถึงไม่เรียงลำดับได้ และหลังจาก
  /// [load] เพิ่งเขียนข้อมูลใหม่ลงไป เหตุการณ์เก่าที่ค้างอยู่ในสายอาจ
  /// มาถึงทีหลัง — ถ้าใช้โดยไม่ตรวจ งานที่เสร็จแล้วจะกลับมาค้างอีก
  void _applyIfNewer(
    String taskId,
    int version,
    LiveTask Function(LiveTask existing) update, {
    required LiveTask Function()? orElse,
  }) {
    final existing = _tasks[taskId];
    if (existing == null) {
      if (orElse != null) _tasks[taskId] = orElse();
      return;
    }
    if (version <= existing.version) return; // เก่ากว่าหรือซ้ำ ทิ้ง
    _tasks[taskId] = update(existing);
  }

  void _startPolling() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(load()));
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// หยุดทุกอย่างที่ยังทำงานอยู่
  ///
  /// สามอย่างที่ต้องเก็บให้ครบ — สองการฟัง หนึ่งตัวจับเวลา และการปล่อย
  /// การเชื่อมต่อที่ใช้ร่วมกัน ลืมอย่างใดอย่างหนึ่งแปลว่ารั่ว (12.8)
  @override
  void dispose() {
    _eventSub?.cancel();
    _statusSub?.cancel();
    _stopPolling();
    unawaited(client.release());
    super.dispose();
  }
}
