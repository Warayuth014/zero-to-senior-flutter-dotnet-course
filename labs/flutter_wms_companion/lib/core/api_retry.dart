import 'dart:async';
import 'dart:math';

import 'api_client.dart';
import 'api_failure.dart';

/// นโยบายการลองใหม่
///
/// รับ [sleep] และ [random] เข้ามาเพื่อให้เทสต์เดินเวลาเองได้
/// และได้ผลเหมือนเดิมทุกครั้ง (4.11)
class RetryPolicy {
  RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 400),
    this.maxDelay = const Duration(seconds: 8),
    Future<void> Function(Duration)? sleep,
    Random? random,
  }) : _sleep = sleep ?? Future<void>.delayed,
       _random = random ?? Random();

  /// รวมครั้งแรกด้วย — 3 แปลว่ายิงจริงได้มากที่สุด 3 ครั้ง
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  final Future<void> Function(Duration) _sleep;
  final Random _random;

  /// เรียก [action] แล้วลองใหม่เฉพาะเมื่อล้มเหลวแบบที่ลองใหม่แล้วมีความหมาย
  ///
  /// [isIdempotent] ต้องเป็น true เท่านั้นจึงจะลองใหม่ — คำสั่งที่ยังไม่รู้ผล
  /// ห้ามยิงซ้ำโดยอัตโนมัติ ถ้าไม่มีรหัสคำสั่งกำกับ (4.14)
  Future<T> run<T>(
    Future<T> Function() action, {
    required bool isIdempotent,
  }) async {
    var attempt = 1;
    while (true) {
      try {
        return await action();
      } on ApiException catch (error) {
        final canRetry =
            isIdempotent && error.kind.isRetryable && attempt < maxAttempts;
        if (!canRetry) rethrow;
        await _sleep(delayForAttempt(attempt));
        attempt++;
      }
    }
  }

  /// ยืดเป็นทวีคูณ มีเพดาน และสุ่มเล็กน้อย
  ///
  /// jitter จำเป็นเพราะ PDA ทั้งคลังมักหลุดพร้อมกัน ถ้าไม่สุ่มก็จะ
  /// กลับมายิงพร้อมกันจนเซิร์ฟเวอร์ล้มซ้ำ
  Duration delayForAttempt(int attempt) {
    final growth = baseDelay.inMilliseconds * (1 << (attempt - 1));
    final capped = min(growth, maxDelay.inMilliseconds);
    final jitter = _random.nextInt(capped ~/ 4 + 1);
    return Duration(milliseconds: capped + jitter);
  }
}
