import '../../core/api_client.dart';
import 'wms_task.dart';

abstract interface class TaskRepository {
  Future<List<WmsTask>> fetchOpen();
  Future<void> complete(String id);
}

class RemoteTaskRepository implements TaskRepository {
  const RemoteTaskRepository(this.api);

  final ApiClient api;

  @override
  Future<List<WmsTask>> fetchOpen() async {
    final json = await api.getJson('/api/WMS/mobile_tasks');
    final items = json['items'];
    if (items is! List) {
      throw const ApiException('รูปแบบรายการ task ไม่ถูกต้อง');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(WmsTask.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> complete(String id) =>
      api.postJson('/api/WMS/mobile_tasks/$id/complete', const {});
}
