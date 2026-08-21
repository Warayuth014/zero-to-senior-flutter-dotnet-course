import 'dart:async';

import 'hub_events.dart';

/// สถานะของการเชื่อมต่อแบบเรียลไทม์
///
/// สี่สถานะ ไม่ใช่สอง — `reconnecting` ต่างจาก `disconnected` ตรงที่
/// ตัวไลบรารีกำลังพยายามต่อใหม่ให้อยู่ ผู้ใช้จึงไม่ต้องทำอะไร ส่วน
/// `disconnected` แปลว่าเลิกพยายามแล้ว (12.4)
enum RealtimeStatus { disconnected, connecting, connected, reconnecting }

/// สัญญาว่าตัวเชื่อมต่อเรียลไทม์ต้องทำอะไรได้บ้าง
///
/// ประกาศเป็น interface เพื่อให้เทสต์ใส่ตัวปลอมที่สั่งให้ส่งเหตุการณ์
/// เมื่อไหร่ก็ได้ — ทดสอบเรื่อง "เหตุการณ์มาถึงตอนที่หลุดพอดี" กับ
/// SignalR ตัวจริงแทบเป็นไปไม่ได้ (9.5)
abstract interface class RealtimeClient {
  Stream<HubEvent> get events;
  Stream<RealtimeStatus> get status;

  /// สถานะล่าสุด สำหรับคนที่เพิ่งมาฟังและยังไม่ได้รับค่าจาก stream
  RealtimeStatus get currentStatus;

  Future<void> connect();
  Future<void> disconnect();
}

/// ตัวเชื่อมต่อที่ใช้ร่วมกันทั้งแอป โดยนับจำนวนผู้ใช้งาน
///
/// จอสามจอที่ต้องการเหตุการณ์ชุดเดียวกัน ควรใช้การเชื่อมต่อเดียว —
/// การเปิดสามการเชื่อมต่อกิน socket, กินแบต และทำให้เซิร์ฟเวอร์ส่ง
/// เหตุการณ์เดียวกันสามรอบ (12.9)
class SharedRealtimeClient {
  SharedRealtimeClient(this._inner);

  final RealtimeClient _inner;
  int _users = 0;

  /// จำนวนผู้ใช้งานตอนนี้ เปิดให้เทสต์ตรวจได้ว่าปล่อยครบไหม
  int get userCount => _users;

  Stream<HubEvent> get events => _inner.events;
  Stream<RealtimeStatus> get status => _inner.status;
  RealtimeStatus get currentStatus => _inner.currentStatus;

  /// ขอใช้การเชื่อมต่อ — ต่อจริงเฉพาะคนแรก
  Future<void> acquire() async {
    _users++;
    if (_users == 1) await _inner.connect();
  }

  /// เลิกใช้ — ตัดจริงเฉพาะเมื่อไม่เหลือใครแล้ว
  ///
  /// ไม่ให้ค่าติดลบ เพราะการเรียก release เกินหนึ่งครั้งเป็นบั๊กที่พบบ่อย
  /// และถ้าปล่อยให้ติดลบ การ acquire ครั้งถัดไปจะไม่ต่อจริง แล้วจอจะ
  /// เงียบไปทั้งจอโดยไม่มีข้อผิดพลาดใด ๆ
  Future<void> release() async {
    if (_users == 0) return;
    _users--;
    if (_users == 0) await _inner.disconnect();
  }
}

/// ตัวเชื่อมต่อในหน่วยความจำ ใช้ในเทสต์และตอนสาธิต
///
/// ตัวจริงจะห่อ `HubConnection` ของ `signalr_netcore` แล้วแปลง callback
/// ของมันมาเป็น stream สองเส้นนี้ ส่วนที่เหลือของแอปไม่ต้องรู้ว่าข้างใน
/// เป็นอะไร — สลับไปใช้ WebSocket ธรรมดาหรือ MQTT ก็แก้แค่ไฟล์เดียว
class InMemoryRealtimeClient implements RealtimeClient {
  final _events = StreamController<HubEvent>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();

  RealtimeStatus _current = RealtimeStatus.disconnected;
  int connectCalls = 0;
  int disconnectCalls = 0;

  /// ตั้งเป็น true เพื่อจำลองเซิร์ฟเวอร์ที่ต่อไม่ได้
  bool failOnConnect = false;

  @override
  Stream<HubEvent> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get status => _status.stream;

  @override
  RealtimeStatus get currentStatus => _current;

  @override
  Future<void> connect() async {
    connectCalls++;
    _emitStatus(RealtimeStatus.connecting);
    if (failOnConnect) {
      _emitStatus(RealtimeStatus.disconnected);
      return;
    }
    _emitStatus(RealtimeStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    _emitStatus(RealtimeStatus.disconnected);
  }

  /// จำลองสายหลุดโดยที่ไลบรารีกำลังพยายามต่อใหม่
  void simulateDrop() => _emitStatus(RealtimeStatus.reconnecting);

  /// จำลองว่าต่อกลับได้แล้ว
  void simulateReconnected() => _emitStatus(RealtimeStatus.connected);

  /// ส่งเหตุการณ์ดิบเหมือนที่ hub ส่งมา
  void emitRaw(String name, List<Object?>? args) =>
      _events.add(decodeHubEvent(name, args));

  /// ส่งเหตุการณ์ที่แปลงแล้ว สำหรับเทสต์ที่ไม่สนใจการแปลง
  void emit(HubEvent event) => _events.add(event);

  void _emitStatus(RealtimeStatus value) {
    _current = value;
    _status.add(value);
  }

  Future<void> dispose() async {
    await _events.close();
    await _status.close();
  }
}
