enum TaskStatus { waiting, working, completed }

class WmsTask {
  const WmsTask({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
  });

  final String id;
  final String from;
  final String to;
  final TaskStatus status;

  factory WmsTask.fromJson(Map<String, dynamic> json) {
    String requiredText(String key) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isEmpty) throw FormatException('task.$key ต้องมีค่า');
      return value;
    }

    final rawStatus = requiredText('status').toLowerCase();
    final status = TaskStatus.values.where((value) => value.name == rawStatus);
    if (status.isEmpty) {
      throw FormatException('ไม่รู้จัก task.status: $rawStatus');
    }

    return WmsTask(
      id: requiredText('id'),
      from: requiredText('from'),
      to: requiredText('to'),
      status: status.single,
    );
  }
}
