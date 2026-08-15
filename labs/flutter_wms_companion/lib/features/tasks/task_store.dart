import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'task_repository.dart';
import 'wms_task.dart';

class TaskStore extends ChangeNotifier {
  TaskStore(this.repository, {String Function(String taskId)? createCommandId})
    : _createCommandId =
          createCommandId ??
          ((taskId) => '$taskId-${DateTime.now().microsecondsSinceEpoch}');

  final TaskRepository repository;
  final String Function(String taskId) _createCommandId;
  List<WmsTask> _tasks = const [];
  bool _loading = false;
  String? _error;
  String? _actionMessage;
  final Set<String> _busyTaskIds = {};
  int _requestGeneration = 0;

  List<WmsTask> get tasks => List.unmodifiable(_tasks);
  bool get initialLoading => _loading && _tasks.isEmpty;
  bool get refreshing => _loading && _tasks.isNotEmpty;
  String? get error => _error;
  String? get actionMessage => _actionMessage;
  bool isBusy(String taskId) => _busyTaskIds.contains(taskId);

  Future<void> load({bool preserveError = false}) async {
    final generation = ++_requestGeneration;
    _loading = true;
    if (!preserveError) _error = null;
    notifyListeners();
    try {
      final result = await repository.fetchOpen();
      if (generation != _requestGeneration) return;
      _tasks = result;
    } catch (exception) {
      if (generation != _requestGeneration) return;
      _error = exception.toString();
    } finally {
      if (generation == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> complete(WmsTask task) async {
    if (_busyTaskIds.contains(task.id)) return;
    _busyTaskIds.add(task.id);
    _error = null;
    _actionMessage = null;
    notifyListeners();
    try {
      final result = await repository.complete(
        task.id,
        commandId: _createCommandId(task.id),
      );
      _tasks = _tasks.where((item) => item.id != task.id).toList();
      _actionMessage = result.alreadyCompleted
          ? '${task.id} ถูกปิดไปแล้ว (ตรวจซ้ำสำเร็จ)'
          : 'ปิด ${task.id} สำเร็จ · ${result.correlationId}';
    } on ApiException catch (exception) {
      if (exception.outcomeUnknown) {
        _error = '${exception.message} กำลังตรวจสอบสถานะล่าสุด';
        notifyListeners();
        await load(preserveError: true);
        final stillOpen = _tasks.any((item) => item.id == task.id);
        if (!stillOpen) {
          _error = null;
          _actionMessage = '${task.id} ไม่อยู่ในงานค้างแล้ว หลังตรวจสอบซ้ำ';
        } else {
          final reconcileDetail = _error;
          _error =
              'ยังยืนยันผลของ ${task.id} ไม่ได้ กรุณาตรวจสอบก่อนสั่งซ้ำ'
              '${reconcileDetail == null ? '' : ' · $reconcileDetail'}';
        }
      } else {
        _error = exception.message;
      }
    } catch (exception) {
      _error = exception.toString();
    } finally {
      _busyTaskIds.remove(task.id);
      notifyListeners();
    }
  }
}
