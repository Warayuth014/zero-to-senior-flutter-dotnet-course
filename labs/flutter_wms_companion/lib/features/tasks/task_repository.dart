import '../../core/api_client.dart';
import '../../core/json_api.dart';
import 'wms_task.dart';

class TaskCompletion {
  const TaskCompletion({
    required this.id,
    required this.alreadyCompleted,
    required this.correlationId,
  });

  final String id;
  final bool alreadyCompleted;
  final String correlationId;
}

abstract interface class TaskRepository {
  Future<List<WmsTask>> fetchOpen();
  Future<TaskCompletion> complete(String id, {required String commandId});
}

class RemoteTaskRepository implements TaskRepository {
  const RemoteTaskRepository(this.api);

  final JsonApi api;

  @override
  Future<List<WmsTask>> fetchOpen() async {
    final json = await api.getJson('/api/WMS/mobile_tasks');
    final items = json['items'];
    if (items is! List) {
      throw const ApiException('รูปแบบรายการ task ไม่ถูกต้อง');
    }
    try {
      return items
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('task item ต้องเป็น object');
            }
            return WmsTask.fromJson(item);
          })
          .toList(growable: false);
    } on FormatException catch (error) {
      throw ApiException('รูปแบบ task จาก server ไม่ถูกต้อง: ${error.message}');
    }
  }

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async {
    final json = await api.postJson(
      '/api/WMS/mobile_tasks/$id/complete',
      const {},
      headers: {'Idempotency-Key': commandId},
    );
    final responseId = json['id']?.toString();
    final alreadyCompleted = json['alreadyCompleted'];
    final correlationId = json['correlationId']?.toString();
    if (responseId == null ||
        responseId != id ||
        alreadyCompleted is! bool ||
        correlationId == null ||
        correlationId.isEmpty) {
      throw const ApiException('รูปแบบผล complete task ไม่ถูกต้อง');
    }
    return TaskCompletion(
      id: responseId,
      alreadyCompleted: alreadyCompleted,
      correlationId: correlationId,
    );
  }
}
