import 'package:flutter/foundation.dart';

import 'pallet.dart';
import 'pallet_failure.dart';
import 'pallet_repository.dart';

/// เจ้าของสถานะของ "จอพาเลท" — แหล่งความจริงเดียวของหน้าจอนี้ (9.9)
///
/// ไม่ import material.dart โดยตั้งใจ ทำให้ทดสอบได้โดยไม่ต้องสร้าง widget เลย
/// และแปลว่ามันเปิด dialog หรือ push route เองไม่ได้ ซึ่งเป็นเรื่องดี (9.10)
class PalletStore extends ChangeNotifier {
  PalletStore(this.repository, {String Function(String code)? createCommandId})
    : _createCommandId =
          createCommandId ??
          ((code) => '$code-${DateTime.now().microsecondsSinceEpoch}');

  final PalletRepository repository;
  final String Function(String code) _createCommandId;

  String _zone = '';
  List<Pallet> _pallets = const [];
  bool _loading = false;
  PalletFailure? _failure;
  final Set<String> _busyCodes = {};

  /// เลขรุ่นของคำขอ ใช้ทิ้งคำตอบของคำขอเก่าที่กลับมาช้ากว่าคำขอใหม่ (4.10)
  int _generation = 0;

  String get zone => _zone;
  List<Pallet> get pallets => List.unmodifiable(_pallets);
  bool get initialLoading => _loading && _pallets.isEmpty;
  bool get refreshing => _loading && _pallets.isNotEmpty;
  PalletFailure? get failure => _failure;
  bool isBusy(String code) => _busyCodes.contains(code);

  Future<void> load(String zone) async {
    _zone = zone;
    final generation = ++_generation;
    _loading = true;
    _failure = null;
    notifyListeners();

    try {
      final result = await repository.fetchInZone(zone);
      if (generation != _generation) return;
      _pallets = result;
    } on PalletFailure catch (failure) {
      if (generation != _generation) return;
      // ไม่ต้องแปลอะไรอีกแล้ว repository แปลมาให้เรียบร้อย (9.13)
      _failure = failure;
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() => load(_zone);

  Future<void> hold(Pallet pallet) async {
    // กดซ้ำระหว่างรอ ต้องไม่ยิงซ้ำ — บน PDA ปุ่มโดนกดซ้ำเป็นเรื่องปกติ (4.9)
    if (_busyCodes.contains(pallet.code)) return;
    _busyCodes.add(pallet.code);
    _failure = null;
    notifyListeners();

    try {
      final updated = await repository.hold(
        pallet.code,
        commandId: _createCommandId(pallet.code),
      );
      _pallets = [
        for (final item in _pallets)
          if (item.code == updated.code) updated else item,
      ];
    } on PalletFailure catch (failure) {
      _failure = failure;
    } finally {
      _busyCodes.remove(pallet.code);
      notifyListeners();
    }
  }
}
