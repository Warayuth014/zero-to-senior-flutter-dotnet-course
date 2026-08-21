import 'dart:async';

import 'package:flutter/foundation.dart';

import 'image_validation.dart';
import 'picked_image.dart';
import 'upload_client.dart';

/// สถานะของการอัปโหลดหนึ่งครั้ง
enum UploadStage { idle, picking, ready, uploading, done, failed }

/// เจ้าของทั้งกระบวนการ — เลือกรูป ตรวจ แสดงตัวอย่าง อัปโหลด
class UploadStore extends ChangeNotifier {
  UploadStore({
    required this.picker,
    required this.client,
    this.policy = const ImagePolicy(),
    String Function()? createCommandId,
  }) : _createCommandId =
           createCommandId ??
           (() => 'upload-${DateTime.now().microsecondsSinceEpoch}');

  final ImagePickerPort picker;
  final UploadClient client;
  final ImagePolicy policy;
  final String Function() _createCommandId;

  UploadStage _stage = UploadStage.idle;
  PickedImage? _image;
  String? _message;
  String? _warning;
  String? _uploadedUrl;
  int _sent = 0;
  int _total = 0;

  Completer<void>? _cancel;

  /// รหัสคำสั่งของรอบนี้ สร้างครั้งเดียวตอนเลือกรูป
  ///
  /// **ไม่สร้างใหม่ตอนลองใหม่** — การส่งซ้ำไฟล์เดิมต้องใช้รหัสเดิม
  /// ไม่งั้นเซิร์ฟเวอร์จะเก็บรูปสองใบ (7.13)
  String? _commandId;

  UploadStage get stage => _stage;
  PickedImage? get image => _image;
  String? get message => _message;
  String? get warning => _warning;
  String? get uploadedUrl => _uploadedUrl;

  /// 0.0 ถึง 1.0 — null เมื่อยังไม่รู้ขนาดรวม
  double? get progress => _total == 0 ? null : _sent / _total;

  bool get canUpload => _stage == UploadStage.ready || _stage == UploadStage.failed;

  /// ขอรูปจากผู้ใช้แล้วตรวจ
  Future<void> pick(PickSource source) async {
    _stage = UploadStage.picking;
    _message = null;
    _warning = null;
    notifyListeners();

    final PickedImage? picked;
    try {
      picked = await picker.pick(source);
    } on PermissionDeniedException {
      _stage = UploadStage.idle;
      // ข้อความบอกทางแก้ ไม่ใช่แค่บอกว่าถูกปฏิเสธ — ลองใหม่ในแอปไม่ช่วย
      // ต้องไปเปิดสิทธิ์ในหน้าตั้งค่าของเครื่อง
      _message = source == PickSource.camera
          ? 'แอปยังไม่ได้รับอนุญาตให้ใช้กล้อง เปิดสิทธิ์ในหน้าตั้งค่าของเครื่องก่อน'
          : 'แอปยังไม่ได้รับอนุญาตให้เข้าถึงรูป เปิดสิทธิ์ในหน้าตั้งค่าของเครื่องก่อน';
      notifyListeners();
      return;
    }

    if (picked == null) {
      // ผู้ใช้กดยกเลิก ไม่ใช่ความผิดพลาด จึงไม่แสดงข้อความอะไร
      _stage = _image == null ? UploadStage.idle : UploadStage.ready;
      notifyListeners();
      return;
    }

    switch (checkImage(picked, policy: policy)) {
      case ImageRejected(:final message):
        _stage = UploadStage.idle;
        _image = null;
        _message = message;
      case ImageWarning(:final message):
        _stage = UploadStage.ready;
        _image = picked;
        _commandId = _createCommandId();
        _warning = message;
      case ImageAccepted():
        _stage = UploadStage.ready;
        _image = picked;
        _commandId = _createCommandId();
    }

    notifyListeners();
  }

  /// ส่งรูปที่เลือกไว้
  Future<void> upload({
    required String path,
    Map<String, String> fields = const {},
  }) async {
    final image = _image;
    final commandId = _commandId;
    if (image == null || commandId == null || _stage == UploadStage.uploading) {
      return;
    }

    _stage = UploadStage.uploading;
    _message = null;
    _sent = 0;
    _total = image.sizeBytes;
    _cancel = Completer<void>();
    notifyListeners();

    final outcome = await client.uploadImage(
      path: path,
      image: image,
      commandId: commandId,
      fields: fields,
      onProgress: _onProgress,
      cancel: _cancel!.future,
    );

    switch (outcome) {
      case UploadSucceeded(:final url):
        _stage = UploadStage.done;
        _uploadedUrl = url;
      case UploadRejected(:final message):
        // ผู้ใช้แก้ได้ แต่ต้องเลือกรูปใหม่ ไม่ใช่กดส่งซ้ำ
        _stage = UploadStage.idle;
        _image = null;
        _message = message;
      case UploadFailed(:final message, :final outcomeUnknown):
        _stage = UploadStage.failed;
        _message = outcomeUnknown
            ? '$message — ตรวจว่ารูปขึ้นแล้วหรือยังก่อนส่งซ้ำ'
            : message;
      case UploadCancelled():
        _stage = UploadStage.ready;
        _message = null;
    }

    _cancel = null;
    notifyListeners();
  }

  /// ยกเลิกระหว่างอัปโหลด
  void cancel() {
    if (_stage != UploadStage.uploading) return;
    _cancel?.complete();
  }

  /// เริ่มใหม่ทั้งหมด
  void reset() {
    _stage = UploadStage.idle;
    _image = null;
    _message = null;
    _warning = null;
    _uploadedUrl = null;
    _commandId = null;
    _sent = 0;
    _total = 0;
    notifyListeners();
  }

  void _onProgress(int sent, int total) {
    _sent = sent;
    _total = total;
    notifyListeners();
  }

  @override
  void dispose() {
    // ยกเลิกการอัปโหลดที่ค้างอยู่ ไม่ให้ callback มาถึง store ที่ถูกทิ้งแล้ว
    if (_cancel case final completer? when !completer.isCompleted) {
      completer.complete();
    }
    super.dispose();
  }
}
