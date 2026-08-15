import 'package:freezed_annotation/freezed_annotation.dart';

part 'wms_task.freezed.dart';
part 'wms_task.g.dart';

enum TaskStatus { waiting, working, completed }

@freezed
abstract class WmsTask with _$WmsTask {
  const factory WmsTask({
    required String id,
    required String from,
    required String to,
    required TaskStatus status,
  }) = _WmsTask;

  factory WmsTask.fromJson(Map<String, dynamic> json) =>
      _$WmsTaskFromJson(_normalizeTaskJson(json));
}

Map<String, dynamic> _normalizeTaskJson(Map<String, dynamic> json) {
  String requiredText(String key) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw FormatException('task.$key ต้องมีค่า');
    return value;
  }

  final rawStatus = requiredText('status').toLowerCase();
  if (!TaskStatus.values.any((value) => value.name == rawStatus)) {
    throw FormatException('ไม่รู้จัก task.status: $rawStatus');
  }

  return {
    'id': requiredText('id'),
    'from': requiredText('from'),
    'to': requiredText('to'),
    'status': rawStatus,
  };
}
