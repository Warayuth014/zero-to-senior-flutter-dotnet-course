// D1.18 — อีกหนึ่ง library ในโฟลเดอร์เดียวกัน

/// ช่องเก็บของในคลัง เช่น A-01-02
class StorageLocation {
  const StorageLocation(this.zone, this.rack, this.level);

  factory StorageLocation.parse(String raw) {
    final parts = raw.split('-');
    if (parts.length != 3) {
      throw FormatException('ช่องเก็บต้องอยู่ในรูป Z-RR-LL: $raw');
    }
    return StorageLocation(parts[0], parts[1], parts[2]);
  }

  final String zone;
  final String rack;
  final String level;

  @override
  String toString() => '$zone-$rack-$level';
}
