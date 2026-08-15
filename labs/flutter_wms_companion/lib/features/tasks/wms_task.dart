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

  factory WmsTask.fromJson(Map<String, dynamic> json) => WmsTask(
    id: json['id']?.toString() ?? '',
    from: json['from']?.toString() ?? '-',
    to: json['to']?.toString() ?? '-',
    status: TaskStatus.values.firstWhere(
      (value) => value.name == json['status']?.toString().toLowerCase(),
      orElse: () => TaskStatus.waiting,
    ),
  );
}
