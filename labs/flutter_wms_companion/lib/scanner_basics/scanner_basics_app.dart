import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scan_session.dart';

/// Lab ของ Part 3 — หน้าจอรับสินค้าเข้าที่ขับด้วยเครื่องสแกน
///
/// เครื่องสแกนของ PDA ทำงานเหมือนแป้นพิมพ์: มันพิมพ์รหัสลงช่องที่โฟกัสอยู่
/// แล้วกด Enter ให้ หน้าจอนี้จึงต้องรักษาโฟกัสไว้ที่ช่องรับตลอดเวลา
void main() {
  runApp(const ScannerBasicsApp());
}

class ScannerBasicsApp extends StatelessWidget {
  const ScannerBasicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scanner Basics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ReceiveScreen(),
    );
  }
}

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key, this.onSubmit});

  /// ส่งเข้ามาจากภายนอกได้ เพื่อให้เทสต์ควบคุมผลลัพธ์และเวลาได้
  /// หน้าจอไม่รู้จัก API เอง (1.12)
  final Future<bool> Function(List<String> codes)? onSubmit;

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  // ของที่เราสร้าง เราต้องคืน (1.6)
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _barcodeFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  final _session = ScanSession(operatorName: 'สมชาย');

  ScanOutcome? _lastOutcome;
  bool _submitting = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  /// เรียกทั้งจากปุ่มยืนยันและจากการกด Enter ของเครื่องสแกน
  void _handleScan() {
    final outcome = _session.accept(_barcodeController.text);

    if (outcome.shouldClearInput) {
      _barcodeController.clear();
    }

    _giveFeedback(outcome);

    setState(() => _lastOutcome = outcome);

    // คืนโฟกัสทันที เพื่อให้ยิงตัวถัดไปได้โดยไม่ต้องแตะจอ
    _barcodeFocus.requestFocus();
  }

  /// สัญญาณตอบรับหลายช่องทาง — พนักงานกำลังมองของในมือ ไม่ได้มองจอ (2.13)
  void _giveFeedback(ScanOutcome outcome) {
    if (outcome.isFailure) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _submit() async {
    if (_submitting || _session.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await _confirmSubmit();
    if (!mounted || confirmed != true) return; // โลกอาจเปลี่ยนไประหว่างรอ (1.6)

    setState(() => _submitting = true);
    _session.beginSubmit();
    try {
      final send = widget.onSubmit;
      final ok = send == null ? true : await send(_session.accepted);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'บันทึกสำเร็จ' : 'บันทึกไม่สำเร็จ')),
      );
    } finally {
      _session.endSubmit();
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool?> _confirmSubmit() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการบันทึก'),
        content: Text('บันทึก ${_session.count} รายการใช่หรือไม่'),
        actions: [
          TextButton(
            key: const Key('confirm-cancel'),
            // ใช้ context ของกล่อง ไม่ใช่ของหน้าจอ (1.7)
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            key: const Key('confirm-ok'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _lastOutcome;

    return Scaffold(
      appBar: AppBar(title: const Text('รับสินค้าเข้า')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('barcode-field'),
                  controller: _barcodeController,
                  focusNode: _barcodeFocus,
                  autofocus: true,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'บาร์โค้ดพาเลท',
                    hintText: 'PAL-1001',
                    border: OutlineInputBorder(),
                  ),
                  // เครื่องสแกนกด Enter ให้ จึงเข้าทางนี้เป็นหลัก
                  onFieldSubmitted: (_) => _handleScan(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('quantity-field'),
                  controller: _quantityController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนต่อพาเลท',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => validateQuantity(value),
                ),
                const SizedBox(height: 12),
                if (outcome != null)
                  ScanFeedbackBanner(
                    key: const Key('feedback-banner'),
                    outcome: outcome,
                  ),
                const SizedBox(height: 12),
                Text(
                  'รับแล้ว ${_session.count} รายการ',
                  key: const Key('accepted-count'),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _session.count,
                    itemBuilder: (context, index) {
                      final code = _session.accepted[index];
                      return ListTile(
                        key: ValueKey<String>(code),
                        title: Text(code),
                        trailing: IconButton(
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _session.remove(code)),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'เอาออก',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 54, // ปุ่มหลัก ใหญ่กว่าขั้นต่ำ 48 (2.13)
            child: FilledButton(
              key: const Key('submit-button'),
              // ปิดปุ่มระหว่างบันทึก และเมื่อยังไม่มีรายการ (1.12)
              onPressed: _submitting || _session.isEmpty ? null : _submit,
              child: Text(_submitting ? 'กำลังบันทึก...' : 'บันทึกทั้งหมด'),
            ),
          ),
        ),
      ),
    );
  }
}

/// แถบบอกผลการสแกนล่าสุด — สี ไอคอน และข้อความ ครบสามช่องทาง (2.12)
class ScanFeedbackBanner extends StatelessWidget {
  const ScanFeedbackBanner({super.key, required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = outcome.isFailure;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: failed ? scheme.errorContainer : scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(failed ? Icons.error_outline : Icons.check_circle_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(outcome.message)),
        ],
      ),
    );
  }
}
