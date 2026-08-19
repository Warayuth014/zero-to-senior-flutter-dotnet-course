import 'dart:async';

import 'package:flutter/foundation.dart';

import 'pick_repository.dart';

/// สถานะการโหลด — ใช้ enum แทน bool หลายตัว เพื่อไม่ให้เกิดค่าที่ขัดกันเอง (D1.10)
enum LoadState { idle, loading, ready, empty, failed }

/// ตัวเก็บสถานะของหน้าหยิบสินค้า
///
/// ไม่รู้จัก widget ไม่ import material จึงทดสอบได้โดยไม่ต้องประกอบหน้าจอ
class PickStore extends ChangeNotifier {
  PickStore({required this.repository, String Function()? createCommandId})
    : _createCommandId =
          createCommandId ??
          (() => DateTime.now().microsecondsSinceEpoch.toString());

  final PickRepository repository;
  final String Function() _createCommandId;

  List<PickLine> _lines = const [];
  LoadState _state = LoadState.idle;
  String? _errorMessage;
  Timer? _pollTimer;

  /// หมายเลขรุ่นของคำขอ ใช้ทิ้งผลลัพธ์เก่าที่มาช้า (3.13)
  int _generation = 0;

  /// บรรทัดที่กำลังส่งคำสั่งอยู่ — เก็บเป็น id ไม่ใช่ตำแหน่ง (1.8)
  final Set<String> _busyLineIds = <String>{};

  /// รหัสคำสั่งของแต่ละบรรทัด เก็บไว้เพื่อให้การลองใหม่ใช้รหัสเดิม (3.8)
  final Map<String, String> _pendingCommandIds = <String, String>{};

  List<PickLine> get lines => List.unmodifiable(_lines);

  LoadState get state => _state;

  String? get errorMessage => _errorMessage;

  bool isBusy(String lineId) => _busyLineIds.contains(lineId);

  /// ค่าที่คำนวณจากค่าอื่นได้ ไม่เก็บซ้ำ (D1.7)
  int get remainingCount => _lines.where((line) => !line.done).length;

  bool get allDone => _lines.isNotEmpty && remainingCount == 0;

  Future<void> load() async {
    final generation = ++_generation;
    _state = LoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.fetchLines();
      if (generation != _generation) return; // มีคำขอใหม่กว่าแล้ว ทิ้งผลนี้

      _lines = result;
      _state = result.isEmpty ? LoadState.empty : LoadState.ready;
    } on PickException catch (error) {
      if (generation != _generation) return;
      _state = LoadState.failed;
      _errorMessage = error.message;
    } finally {
      if (generation == _generation) notifyListeners();
    }
  }

  /// ปิดงานหนึ่งบรรทัด โดยแสดงผลทันทีแล้วค่อยยืนยันกับ server
  Future<void> markDone(String lineId) async {
    if (_busyLineIds.contains(lineId)) return; // กันสั่งซ้อน (3.8)

    final index = _lines.indexWhere((line) => line.id == lineId);
    if (index == -1) return;

    final before = _lines[index];
    if (before.done) return;

    // ใช้รหัสเดิมเมื่อลองใหม่ เพื่อไม่ให้ server บันทึกซ้ำ (3.8)
    final commandId = _pendingCommandIds.putIfAbsent(lineId, _createCommandId);

    _busyLineIds.add(lineId);
    _errorMessage = null;
    _setLine(index, before.copyWith(done: true)); // แสดงผลทันที
    notifyListeners();

    try {
      await repository.markDone(lineId, commandId: commandId);
      _pendingCommandIds.remove(lineId); // สำเร็จแล้ว รหัสนี้ใช้หมดหน้าที่
    } on PickException catch (error) {
      if (error.outcomeUnknown) {
        // ไม่รู้ผล — ห้ามย้อนกลับเอง ต้องถาม server ว่าตอนนี้เป็นอย่างไร
        _errorMessage = '${error.message} กำลังตรวจสอบสถานะล่าสุด';
        notifyListeners();
        await load();
        return;
      }
      // รู้แน่ว่าล้มเหลว จึงย้อนกลับได้อย่างปลอดภัย
      _rollback(lineId, before);
      _pendingCommandIds.remove(lineId);
      _errorMessage = error.message;
    } finally {
      _busyLineIds.remove(lineId);
      notifyListeners();
    }
  }

  void _setLine(int index, PickLine line) {
    // สร้าง list ก้อนใหม่ ไม่แก้ก้อนเดิม (D1.5)
    final next = [..._lines];
    next[index] = line;
    _lines = next;
  }

  void _rollback(String lineId, PickLine before) {
    final index = _lines.indexWhere((line) => line.id == lineId);
    if (index != -1) _setLine(index, before);
  }

  /// เริ่มดึงข้อมูลซ้ำเป็นรอบ ๆ
  void startPolling(Duration interval) {
    stopPolling(); // หยุดตัวเก่าก่อนเสมอ ไม่งั้นสะสม (1.6)
    _pollTimer = Timer.periodic(interval, (_) {
      if (_busyLineIds.isEmpty) load(); // ไม่ดึงทับระหว่างกำลังสั่งงาน
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    _generation++; // ทำให้ผลที่ยังค้างอยู่ถูกทิ้งทั้งหมด
    super.dispose();
  }
}
