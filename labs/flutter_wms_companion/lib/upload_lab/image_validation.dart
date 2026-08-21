import 'dart:typed_data';

import 'picked_image.dart';

/// ผลของการตรวจรูปก่อนอัปโหลด
sealed class ImageCheck {
  const ImageCheck();
}

/// ผ่าน ส่งได้เลย
class ImageAccepted extends ImageCheck {
  const ImageAccepted();
}

/// ส่งไม่ได้ พร้อมเหตุผลที่บอกผู้ใช้ได้ว่าต้องทำอะไรต่อ
class ImageRejected extends ImageCheck {
  const ImageRejected(this.message);
  final String message;
}

/// ส่งได้ แต่มีเรื่องที่ควรรู้ก่อน
///
/// แยกจาก [ImageRejected] เพราะการห้ามกับการเตือนพาผู้ใช้ไปคนละทาง —
/// รูปที่เบลอนิดหน่อยยังใช้เป็นหลักฐานได้ ถ้าเขายืนยันว่านั่นคือของจริง
/// หลักเดียวกับ 10.7 ว่าห้ามเฉพาะสิ่งที่ผิดแน่นอน
class ImageWarning extends ImageCheck {
  const ImageWarning(this.message);
  final String message;
}

/// ข้อกำหนดของรูปที่รับได้ ต้องตรงกับที่ฝั่งเซิร์ฟเวอร์ตั้งไว้
///
/// ถ้าสองฝั่งไม่ตรงกัน ผู้ใช้จะเจอรูปที่ผ่านฝั่งแอปแต่ถูกปฏิเสธตอนอัปโหลด
/// ซึ่งเสียเวลาและเสียเน็ตไปเปล่า ๆ (13.9)
class ImagePolicy {
  const ImagePolicy({
    this.maxBytes = 5 * 1024 * 1024,
    this.minBytes = 5 * 1024,
    this.allowedMimeTypes = const {'image/jpeg', 'image/png', 'image/webp'},
    this.minWidth = 480,
    this.minHeight = 480,
  });

  final int maxBytes;

  /// รูปที่เล็กผิดปกติ มักเป็นไฟล์เสียหรือรูปที่ถ่ายพลาด
  final int minBytes;

  final Set<String> allowedMimeTypes;
  final int minWidth;
  final int minHeight;

  double get maxMb => maxBytes / (1024 * 1024);
}

/// ตรวจก่อนส่ง
///
/// การตรวจฝั่งแอปคือความสะดวก ไม่ใช่ความปลอดภัย — เซิร์ฟเวอร์ต้องตรวจซ้ำ
/// เสมอ เพราะใครก็ยิงเข้า endpoint ตรง ๆ ได้โดยไม่ผ่านแอปนี้ (13.9)
ImageCheck checkImage(PickedImage image, {ImagePolicy policy = const ImagePolicy()}) {
  if (!policy.allowedMimeTypes.contains(image.mimeType)) {
    return ImageRejected(
      'รองรับเฉพาะไฟล์ ${policy.allowedMimeTypes.map(_shortName).join(', ')} '
      'แต่ไฟล์นี้เป็น ${_shortName(image.mimeType)}',
    );
  }

  if (image.sizeBytes > policy.maxBytes) {
    return ImageRejected(
      'ไฟล์ใหญ่ ${image.sizeMb.toStringAsFixed(1)} MB '
      'เกินที่รับได้ ${policy.maxMb.toStringAsFixed(0)} MB — ลองถ่ายใหม่ที่ความละเอียดต่ำลง',
    );
  }

  if (image.sizeBytes < policy.minBytes) {
    return const ImageRejected('ไฟล์เล็กผิดปกติ อาจเสียหาย ลองถ่ายใหม่');
  }

  // เนื้อไฟล์ต้องตรงกับชนิดที่อ้าง — ชื่อไฟล์กับ mimeType โกหกได้ทั้งคู่
  if (!_looksLike(image.bytes, image.mimeType)) {
    return const ImageRejected('เนื้อไฟล์ไม่ตรงกับชนิดที่ระบุ');
  }

  final width = image.width;
  final height = image.height;
  if (width != null && height != null) {
    if (width < policy.minWidth || height < policy.minHeight) {
      return ImageWarning(
        'รูปมีขนาด $width×$height ซึ่งเล็กกว่าที่แนะนำ '
        '(${policy.minWidth}×${policy.minHeight}) อาจอ่านฉลากไม่ออก',
      );
    }
  }

  return const ImageAccepted();
}

/// ตรวจว่าไบต์ต้นไฟล์ตรงกับชนิดที่อ้างไหม
///
/// ทุกรูปแบบไฟล์มีลายเซ็นที่ต้นไฟล์ เรียกว่า magic number ตรวจสองสามไบต์
/// แรกก็พอที่จะจับไฟล์ที่เปลี่ยนนามสกุลมาหลอกได้แล้ว
bool _looksLike(Uint8List bytes, String mimeType) {
  if (bytes.length < 12) return false;

  return switch (mimeType) {
    // JPEG ขึ้นต้นด้วย FF D8 FF เสมอ
    'image/jpeg' => bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF,
    // PNG ขึ้นต้นด้วย 89 P N G
    'image/png' =>
      bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47,
    // WebP คือ RIFF....WEBP
    'image/webp' =>
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50,
    _ => false,
  };
}

String _shortName(String mimeType) => switch (mimeType) {
  'image/jpeg' => 'JPG',
  'image/png' => 'PNG',
  'image/webp' => 'WebP',
  'image/heic' => 'HEIC',
  _ => mimeType,
};

/// ทำชื่อไฟล์ให้ปลอดภัยก่อนส่งไปเซิร์ฟเวอร์
///
/// เก็บเฉพาะตัวอักษร ตัวเลข ขีด และจุด ที่เหลือแทนด้วยขีดล่าง — กัน
/// ทั้ง `../` ที่พาไปเขียนนอกโฟลเดอร์ และอักขระที่ระบบไฟล์บางตัวไม่รับ
///
/// เป็นการช่วยฝั่งเซิร์ฟเวอร์ ไม่ใช่การป้องกัน — เซิร์ฟเวอร์ยังต้องทำเองด้วย
String safeFileName(String raw, {required String extension}) {
  final base = raw.split(RegExp(r'[/\\]')).last;          // ตัดเส้นทางทิ้ง
  final withoutExt = base.contains('.')
      ? base.substring(0, base.lastIndexOf('.'))
      : base;
  final cleaned = withoutExt.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  final trimmed = cleaned.isEmpty ? 'image' : cleaned;
  // จำกัดความยาว เพราะบางระบบไฟล์รับได้ไม่เกิน 255 ไบต์
  final limited = trimmed.length > 60 ? trimmed.substring(0, 60) : trimmed;
  return '$limited.$extension';
}
