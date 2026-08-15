// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wms_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WmsTask _$WmsTaskFromJson(Map<String, dynamic> json) => _WmsTask(
  id: json['id'] as String,
  from: json['from'] as String,
  to: json['to'] as String,
  status: $enumDecode(_$TaskStatusEnumMap, json['status']),
);

Map<String, dynamic> _$WmsTaskToJson(_WmsTask instance) => <String, dynamic>{
  'id': instance.id,
  'from': instance.from,
  'to': instance.to,
  'status': _$TaskStatusEnumMap[instance.status]!,
};

const _$TaskStatusEnumMap = {
  TaskStatus.waiting: 'waiting',
  TaskStatus.working: 'working',
  TaskStatus.completed: 'completed',
};
