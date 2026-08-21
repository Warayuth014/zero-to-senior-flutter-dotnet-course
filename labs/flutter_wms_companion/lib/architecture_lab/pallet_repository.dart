import '../core/api_client.dart';
import '../core/api_failure.dart';
import '../core/json_api.dart';
import '../json_basics/json_read.dart';
import 'pallet.dart';
import 'pallet_failure.dart';

/// สัญญาว่า "จอพาเลทต้องการอะไรจากข้างนอก" — เขียนด้วยคำของงาน ไม่ใช่คำของ HTTP
///
/// จอกับ store พึ่งพา interface นี้ ไม่ได้พึ่งพา RemotePalletRepository ทำให้
/// สลับตัวจริงเป็นตัวปลอมในเทสต์ได้โดยไม่ต้องแตะโค้ดที่ถูกทดสอบ (9.5)
abstract interface class PalletRepository {
  Future<List<Pallet>> fetchInZone(String zone);
  Future<Pallet> hold(String code, {required String commandId});
}

/// ตัวจริงที่คุยกับ .NET
///
/// รับ [JsonApi] ไม่ใช่ ApiClient ตัวจริง เพื่อให้เทสต์ระดับ repository
/// ใส่ตัวปลอมได้โดยไม่ต้องยิงเน็ต (9.6)
class RemotePalletRepository implements PalletRepository {
  const RemotePalletRepository(this.api);

  final JsonApi api;

  @override
  Future<List<Pallet>> fetchInZone(String zone) async {
    final Map<String, dynamic> json;
    try {
      json = await api.getJson(
        '/api/WMS/mobile_pallets?zone=${Uri.encodeQueryComponent(zone)}',
      );
    } on ApiException catch (error) {
      throw _translate(error);
    }

    // อ่านคำตอบอยู่นอก try โดยตั้งใจ — คำตอบที่ผิดสัญญาไม่ใช่ความล้มเหลวที่
    // ผู้ใช้แก้ได้ ต้องปล่อยให้ ContractException โผล่ให้ทีมเห็น (8.2)
    final items = requireList(json, 'items');
    return [
      for (var index = 0; index < items.length; index++)
        _readPallet(items[index], 'items[$index]'),
    ];
  }

  @override
  Future<Pallet> hold(String code, {required String commandId}) async {
    final Map<String, dynamic> json;
    try {
      json = await api.postJson(
        '/api/WMS/mobile_pallets/$code/hold',
        const {},
        headers: {'Idempotency-Key': commandId},
      );
    } on ApiException catch (error) {
      throw _translate(error);
    }

    return _readPallet(json, 'pallet');
  }

  Pallet _readPallet(Object? value, String path) {
    final map = requireMap(value, path);
    return Pallet(
      code: requireString(map, 'code', path: path),
      productCode: requireString(map, 'productCode', path: path),
      quantity: requireInt(map, 'quantity', path: path),
      onHold: readBool(map, 'onHold', path: path, orElse: false),
    );
  }

  /// จุดเดียวในระบบที่แปลภาษาของ HTTP เป็นภาษาของงานคลัง
  ///
  /// ถ้าปล่อยให้จอแปลเอง ทุกจอจะแปลไม่เหมือนกัน และวันที่ต้องเปลี่ยนคำ
  /// ต้องไล่แก้ทุกจอ (9.13)
  PalletFailure _translate(ApiException error) => switch (error.kind) {
    ApiFailureKind.network => const PalletFailure(
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสัญญาณแล้วลองใหม่',
      canRetry: true,
    ),
    ApiFailureKind.timeout => const PalletFailure(
      'เซิร์ฟเวอร์ไม่ตอบภายในเวลาที่กำหนด',
      canRetry: true,
    ),
    ApiFailureKind.server => const PalletFailure(
      'เซิร์ฟเวอร์มีปัญหา แจ้งทีมระบบถ้ายังไม่หาย',
      canRetry: true,
    ),
    ApiFailureKind.notFound => const PalletFailure('ไม่พบข้อมูลที่ขอ'),
    // สามชนิดนี้เซิร์ฟเวอร์รู้เรื่องดีกว่าเรา จึงใช้ข้อความของมัน (7.11)
    ApiFailureKind.conflict ||
    ApiFailureKind.validation ||
    ApiFailureKind.forbidden => PalletFailure(error.userMessage),
    // 401 ไม่ควรมาถึงตรงนี้ SessionStore จัดการไปแล้ว (8.7) แต่กันไว้
    // ไม่ให้กลายเป็นข้อความว่างถ้าหลุดมา
    ApiFailureKind.unauthorized => const PalletFailure('เซสชันหมดอายุ'),
    ApiFailureKind.contract => PalletFailure(error.userMessage),
  };
}
