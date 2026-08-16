// ignore_for_file: avoid_print
// D1.9 Generics
// รัน: dart run tool/dart_foundation/d1_09_generics.dart

// T คือ "ช่องว่างของชนิด" ที่ผู้เรียกเป็นคนเติม
// เขียนครั้งเดียว ใช้ได้กับทุกชนิด และยังตรวจชนิดให้ตั้งแต่ยังไม่รัน
T? firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

// generic class: กล่องเก็บผลลัพธ์ที่ยังไม่รู้ว่าเก็บอะไร
class ApiResult<T> {
  const ApiResult.success(this.data) : error = null, isSuccess = true;

  const ApiResult.failure(this.error) : data = null, isSuccess = false;

  final T? data;
  final String? error;
  final bool isSuccess;

  // แปลงผลลัพธ์จากชนิดหนึ่งไปอีกชนิดโดยยังคงสถานะสำเร็จ/ล้มเหลว
  ApiResult<R> map<R>(R Function(T value) convert) {
    if (!isSuccess || data == null) {
      return ApiResult<R>.failure(error ?? 'ไม่มีข้อมูล');
    }
    return ApiResult<R>.success(convert(data as T));
  }

  @override
  String toString() => isSuccess ? 'สำเร็จ: $data' : 'ล้มเหลว: $error';
}

// constraint: จำกัดว่า T ต้องเป็นอะไรได้บ้าง จึงเรียก method ของชนิดนั้นได้
num sumAll<T extends num>(List<T> values) =>
    values.fold<num>(0, (total, value) => total + value);

class Pallet {
  const Pallet(this.code, this.quantity);
  final String code;
  final int quantity;
  @override
  String toString() => '$code($quantity)';
}

void main() {
  print('=== generic function ใช้ได้กับหลายชนิด แต่ยังรู้ชนิด ===');
  final codes = <String>['PAL-1001', 'PAL-1002'];
  final counts = <int>[10, 4, 7];
  final firstCode = firstOrNull(codes); // ได้ String?
  final firstCount = firstOrNull(counts); // ได้ int?
  print('firstCode  = $firstCode  (${firstCode.runtimeType})');
  print('firstCount = $firstCount  (${firstCount.runtimeType})');
  print('empty      = ${firstOrNull(<String>[])}');

  print('\n=== generic class ===');
  final ok = ApiResult<Pallet>.success(const Pallet('PAL-1001', 12));
  final bad = ApiResult<Pallet>.failure('เชื่อมต่อ server ไม่ได้');
  print(ok);
  print(bad);

  print('\n=== map: เปลี่ยนชนิดข้างในโดยไม่เสียสถานะ ===');
  print(ok.map((pallet) => pallet.quantity)); // ApiResult<int>
  print(bad.map((pallet) => pallet.quantity)); // ยังล้มเหลวเหมือนเดิม

  print('\n=== constraint: T ต้องเป็นตัวเลข จึงบวกกันได้ ===');
  print('sumAll(counts) = ${sumAll(counts)}');
  print('sumAll(double) = ${sumAll(<double>[1.5, 2.25])}');
  // sumAll(codes); // error ตั้งแต่ยังไม่รัน เพราะ String ไม่ใช่ num

  print('\n=== ชนิดของ collection ก็คือ generic ===');
  print('codes.runtimeType  = ${codes.runtimeType}');
  print('counts.runtimeType = ${counts.runtimeType}');
  final byCode = <String, Pallet>{'PAL-1001': const Pallet('PAL-1001', 12)};
  print('byCode.runtimeType = ${byCode.runtimeType}');
}
