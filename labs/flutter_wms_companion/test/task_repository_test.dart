import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/core/json_api.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';

class RecordingJsonApi implements JsonApi {
  Map<String, dynamic> getResponse = const {};
  Map<String, dynamic> postResponse = const {};
  String? postedPath;
  Map<String, String>? postedHeaders;

  @override
  Future<Map<String, dynamic>> getJson(String path) async => getResponse;

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) async {
    postedPath = path;
    postedHeaders = headers;
    return postResponse;
  }
}

void main() {
  test('complete ส่ง idempotency key และ parse correlation', () async {
    final api = RecordingJsonApi()
      ..postResponse = const {
        'id': 'TASK-001',
        'alreadyCompleted': false,
        'correlationId': 'corr-42',
      };
    final repository = RemoteTaskRepository(api);

    final result = await repository.complete(
      'TASK-001',
      commandId: 'command-42',
    );

    expect(api.postedPath, '/api/WMS/mobile_tasks/TASK-001/complete');
    expect(api.postedHeaders?['Idempotency-Key'], 'command-42');
    expect(result.correlationId, 'corr-42');
  });

  test('fetch reject item ที่ไม่ใช่ object', () async {
    final api = RecordingJsonApi()
      ..getResponse = const {
        'items': ['broken'],
      };
    final repository = RemoteTaskRepository(api);

    expect(repository.fetchOpen(), throwsA(isA<Exception>()));
  });
}
