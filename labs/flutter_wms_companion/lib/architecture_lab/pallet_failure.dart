/// ความล้มเหลวที่ "จอพาเลท" สนใจ
///
/// สังเกตว่าไม่มีคำว่า HTTP, ไม่มีเลข status และไม่มี SocketException —
/// สิ่งเหล่านั้นเป็นเรื่องของชั้นขนส่ง จอไม่ควรต้องรู้ (9.13)
class PalletFailure implements Exception {
  const PalletFailure(this.message, {this.canRetry = false});

  /// ข้อความที่เอาไปแสดงได้เลยโดยไม่ต้องแต่งต่อ
  final String message;

  /// กดลองใหม่แล้วมีโอกาสหายไหม — ใช้ตัดสินว่าจะโชว์ปุ่ม "ลองใหม่" หรือไม่
  final bool canRetry;

  @override
  String toString() => message;
}
