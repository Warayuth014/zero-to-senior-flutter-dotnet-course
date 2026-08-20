import 'json_read.dart';

/// บรรทัดสินค้าหนึ่งบรรทัดในใบรับเข้า
class InboundDetailDto {
  const InboundDetailDto({
    required this.productCode,
    required this.expectedQuantity,
    this.lotNumber,
  });

  factory InboundDetailDto.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) => InboundDetailDto(
    productCode: requireString(json, 'productCode', path: path),
    expectedQuantity: requireInt(json, 'expectedQuantity', path: path),
    lotNumber: readString(json, 'lotNumber', path: path),
  );

  final String productCode;
  final int expectedQuantity;
  final String? lotNumber;
}

/// ใบรับเข้าหนึ่งใบ ซึ่งมีบรรทัดสินค้าอยู่ข้างใน
///
/// นี่คือจุดที่ JSON เริ่มซ้อนกัน — และเป็นจุดที่ข้อความผิดพลาดต้องบอกให้ได้ว่า
/// พังที่บรรทัดไหนของใบไหน ไม่ใช่แค่ "แปลงข้อมูลไม่สำเร็จ"
class InboundOrderDto {
  const InboundOrderDto({
    required this.orderNo,
    required this.supplierName,
    required this.details,
    this.expectedAt,
  });

  factory InboundOrderDto.fromJson(
    Map<String, dynamic> json, {
    String path = '',
  }) {
    final rawDetails = requireList(json, 'details', path: path);
    final details = <InboundDetailDto>[];
    for (var index = 0; index < rawDetails.length; index++) {
      final detailPath = path.isEmpty
          ? 'details[$index]'
          : '$path.details[$index]';
      details.add(
        InboundDetailDto.fromJson(
          requireMap(rawDetails[index], detailPath),
          path: detailPath,
        ),
      );
    }

    if (details.isEmpty) {
      throw ContractException(
        path.isEmpty ? 'details' : '$path.details',
        'ใบรับเข้าต้องมีอย่างน้อยหนึ่งบรรทัด',
      );
    }

    return InboundOrderDto(
      orderNo: requireString(json, 'orderNo', path: path),
      supplierName: requireString(json, 'supplierName', path: path),
      details: details,
      // เวลาที่คาดว่าของจะมาถึง อาจยังไม่รู้ จึงเป็น null ได้
      expectedAt: hasKey(json, 'expectedAt') && json['expectedAt'] != null
          ? requireUtcTime(json, 'expectedAt', path: path)
          : null,
    );
  }

  final String orderNo;
  final String supplierName;
  final List<InboundDetailDto> details;
  final DateTime? expectedAt;

  int get totalExpectedQuantity =>
      details.fold(0, (sum, detail) => sum + detail.expectedQuantity);
}
