import 'dart:typed_data';

/// รูปที่ผู้ใช้เพิ่งเลือกหรือเพิ่งถ่าย ก่อนที่จะถูกอัปโหลด
///
/// เก็บเป็น**ไบต์** ไม่ใช่ที่อยู่ไฟล์ เพราะบนเว็บไม่มีระบบไฟล์ให้อ่าน
/// และ `dart:io` ใช้ไม่ได้เลย — โมเดลที่พูดถึงไบต์ทำงานได้ทุกแพลตฟอร์ม (13.2)
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.width,
    this.height,
  });

  final Uint8List bytes;

  /// ชื่อไฟล์ที่จะส่งไปกับ multipart
  ///
  /// อย่าเชื่อชื่อที่ได้จากอุปกรณ์โดยตรง — ผู้ใช้ตั้งชื่อไฟล์เป็นอะไรก็ได้
  /// รวมถึงชื่อที่มี `../` ซึ่งฝั่งเซิร์ฟเวอร์ที่เขียนไม่ระวังจะเขียนไฟล์
  /// ออกนอกโฟลเดอร์ที่ตั้งใจ (13.9)
  final String fileName;

  /// ชนิดของเนื้อหา เช่น `image/jpeg`
  final String mimeType;

  /// ขนาดจริงของรูปเป็นพิกเซล ถ้ารู้
  ///
  /// ใช้ตรวจว่าเล็กเกินจนอ่านฉลากไม่ออกไหม — ขนาดไฟล์อย่างเดียวบอกไม่ได้
  /// เพราะรูปเบลอ ๆ ที่ถูกบีบอัดหนักก็มีไฟล์เล็กเหมือนกัน
  final int? width;
  final int? height;

  int get sizeBytes => bytes.length;

  /// ขนาดเป็นเมกะไบต์ ใช้แสดงให้ผู้ใช้อ่าน
  double get sizeMb => sizeBytes / (1024 * 1024);

  /// นามสกุลที่คาดว่าตรงกับ [mimeType]
  ///
  /// ไม่ได้อ่านจากชื่อไฟล์ เพราะนามสกุลในชื่อไฟล์โกหกได้ ส่วน mimeType
  /// มาจากตัวเลือกรูปที่อ่านเนื้อไฟล์จริง
  String get extension => switch (mimeType) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/heic' => 'heic',
    _ => 'bin',
  };

  @override
  String toString() =>
      'PickedImage($fileName, $mimeType, ${sizeMb.toStringAsFixed(2)} MB)';
}

/// ที่มาของรูป
enum PickSource { camera, gallery }

/// สัญญาว่า "แอปขอรูปจากผู้ใช้ได้อย่างไร"
///
/// ประกาศเป็น interface เพื่อให้ตัวจริงห่อ `image_picker` ไว้ ส่วนเทสต์
/// ใส่ตัวปลอมที่คืนไบต์ที่กำหนดเองได้ — ทดสอบเรื่องการเลือกรูปกับปลั๊กอิน
/// ตัวจริงต้องมีเครื่องจริงและมีคนกดหน้าจอ (9.5)
abstract interface class ImagePickerPort {
  /// คืน null เมื่อผู้ใช้กดยกเลิก ซึ่งไม่ใช่ความผิดพลาด
  Future<PickedImage?> pick(PickSource source);
}

/// ตัวปลอมสำหรับเทสต์และตอนสาธิต
class FakeImagePicker implements ImagePickerPort {
  FakeImagePicker({this.result});

  /// ตั้งค่าให้คืนรูปนี้ — null แปลว่าผู้ใช้กดยกเลิก
  PickedImage? result;

  /// ตั้งเป็น true เพื่อจำลองว่าผู้ใช้ไม่ให้สิทธิ์เข้าถึงกล้อง
  bool denyPermission = false;

  PickSource? lastSource;
  int pickCalls = 0;

  @override
  Future<PickedImage?> pick(PickSource source) async {
    pickCalls++;
    lastSource = source;
    if (denyPermission) throw const PermissionDeniedException();
    return result;
  }
}

/// ผู้ใช้ปฏิเสธไม่ให้สิทธิ์
///
/// แยกเป็นชนิดของตัวเองเพราะต้องจัดการต่างจากความผิดพลาดอื่น — ลองใหม่
/// เฉย ๆ ไม่ช่วย ต้องพาผู้ใช้ไปหน้าตั้งค่าของเครื่อง (13.1)
class PermissionDeniedException implements Exception {
  const PermissionDeniedException();

  @override
  String toString() => 'ผู้ใช้ไม่อนุญาตให้เข้าถึง';
}
