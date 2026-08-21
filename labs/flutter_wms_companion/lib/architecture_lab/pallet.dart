/// พาเลทหนึ่งใบในโซนหนึ่ง
///
/// คลาสนี้ไม่ import อะไรเลย ไม่รู้จัก http ไม่รู้จัก Flutter — ตั้งใจให้เป็น
/// อย่างนั้น เพราะมันคือคำศัพท์ของงานคลัง ไม่ใช่ของหน้าจอหรือของ network (9.2)
class Pallet {
  const Pallet({
    required this.code,
    required this.productCode,
    required this.quantity,
    required this.onHold,
  });

  final String code;
  final String productCode;
  final int quantity;

  /// ถูกล็อกไว้แล้ว หยิบต่อไม่ได้จนกว่าจะปลด
  final bool onHold;

  Pallet copyWith({bool? onHold}) => Pallet(
    code: code,
    productCode: productCode,
    quantity: quantity,
    onHold: onHold ?? this.onHold,
  );

  @override
  String toString() => 'Pallet($code, $productCode x$quantity, hold=$onHold)';
}
