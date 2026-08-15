import 'package:flutter/foundation.dart';

import 'task_repository.dart';
import 'wms_task.dart';

class TaskStore extends ChangeNotifier {
  TaskStore(this.repository);

  final TaskRepository repository;
  List<WmsTask> tasks = const [];
  bool loading = false;
  String? error;
  int _requestGeneration = 0;

  Future<void> load() async {
    final generation = ++_requestGeneration;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.fetchOpen();
      if (generation != _requestGeneration) return;
      tasks = result;
    } catch (exception) {
      if (generation != _requestGeneration) return;
      error = exception.toString();
    } finally {
      if (generation == _requestGeneration) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> complete(WmsTask task) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repository.complete(task.id);
      tasks = tasks.where((item) => item.id != task.id).toList();
    } catch (exception) {
      error = exception.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
