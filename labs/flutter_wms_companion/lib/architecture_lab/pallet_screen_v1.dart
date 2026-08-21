import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// จอพาเลทแบบ "ทุกอย่างอยู่ในจอเดียว" — รุ่นก่อนแยกชั้น
///
/// โค้ดนี้ไม่ได้เขียนผิด มันทำงานได้จริงและอ่านจากบนลงล่างได้ในไฟล์เดียว
/// เขียนแบบนี้เร็วที่สุดถ้าจอนี้จะไม่โตอีก แต่มีสิ่งที่ทำไม่ได้อยู่สามอย่าง
/// ซึ่ง 9.14 จะพาดู และ test/architecture_test.dart จะพิสูจน์ให้เห็น
///
/// เทียบของจริง: wmsapp เขียนแนวนี้ทุกจอ (packing_screen.dart ~84KB)
class PalletScreenV1 extends StatefulWidget {
  const PalletScreenV1({super.key, required this.client, required this.zone});

  final http.Client client;
  final String zone;

  @override
  State<PalletScreenV1> createState() => _PalletScreenV1State();
}

class _PalletScreenV1State extends State<PalletScreenV1> {
  // สถานะของ UI ปนกับสถานะของข้อมูล อยู่ในกองเดียวกัน
  bool _loading = false;
  String? _error;
  bool _canRetry = false;
  List<Map<String, dynamic>> _pallets = const [];
  final Set<String> _busyCodes = {};

  static const String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await widget.client
          .get(
            Uri.parse(
              '$_baseUrl/api/WMS/mobile_pallets'
              '?zone=${Uri.encodeQueryComponent(widget.zone)}',
            ),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 400) {
        // แปลรหัสตอบกลับเป็นข้อความ ตรงนี้เอง ในจอนี้เอง
        // จอถัดไปที่ต้องแปลเหมือนกัน จะแปลด้วยคำที่ไม่เหมือนกัน
        setState(() {
          _error = response.statusCode >= 500
              ? 'เซิร์ฟเวอร์มีปัญหา แจ้งทีมระบบถ้ายังไม่หาย'
              : 'โหลดข้อมูลไม่สำเร็จ (${response.statusCode})';
          _canRetry = response.statusCode >= 500;
          _loading = false;
        });
        return;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (json['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);

      // ไม่มีการเช็คว่าคำขอนี้ยังใหม่อยู่ไหม — กด "โหลดใหม่" รัว ๆ แล้ว
      // คำตอบของคำขอเก่าที่กลับมาช้าจะทับคำตอบใหม่ได้ (4.10)
      if (!mounted) return;
      setState(() {
        _pallets = items;
        _loading = false;
      });
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสัญญาณแล้วลองใหม่';
        _canRetry = true;
        _loading = false;
      });
    } on http.ClientException {
      if (!mounted) return;
      setState(() {
        _error = 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสัญญาณแล้วลองใหม่';
        _canRetry = true;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'เซิร์ฟเวอร์ไม่ตอบภายในเวลาที่กำหนด';
        _canRetry = true;
        _loading = false;
      });
    }
  }

  Future<void> _hold(String code) async {
    if (_busyCodes.contains(code)) return;
    setState(() {
      _busyCodes.add(code);
      _error = null;
    });

    try {
      final response = await widget.client
          .post(
            Uri.parse('$_baseUrl/api/WMS/mobile_pallets/$code/hold'),
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': '$code-${DateTime.now().microsecondsSinceEpoch}',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 400) {
        if (!mounted) return;
        setState(() {
          _error = 'ล็อกพาเลทไม่สำเร็จ (${response.statusCode})';
          _canRetry = false;
          _busyCodes.remove(code);
        });
        return;
      }

      final updated = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _pallets = [
          for (final item in _pallets)
            if (item['code'] == updated['code']) updated else item,
        ];
        _busyCodes.remove(code);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'ล็อกพาเลทไม่สำเร็จ';
        _canRetry = true;
        _busyCodes.remove(code);
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('พาเลทในโซน ${widget.zone}'),
      actions: [
        IconButton(
          key: const Key('reload-button'),
          tooltip: 'โหลดใหม่',
          onPressed: _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Builder(
      builder: (context) {
        if (_loading && _pallets.isEmpty) {
          return const Center(
            key: Key('initial-loading'),
            child: CircularProgressIndicator(),
          );
        }
        if (_error != null && _pallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, key: const Key('error-text')),
                if (_canRetry)
                  FilledButton(
                    key: const Key('retry-button'),
                    onPressed: _load,
                    child: const Text('ลองใหม่'),
                  ),
              ],
            ),
          );
        }
        if (_pallets.isEmpty) {
          return const Center(
            key: Key('empty-text'),
            child: Text('ไม่มีพาเลทในโซนนี้'),
          );
        }
        return Column(
          children: [
            if (_error != null)
              Text(_error!, key: const Key('banner-error-text')),
            Expanded(
              child: ListView.builder(
                itemCount: _pallets.length,
                itemBuilder: (context, index) {
                  final pallet = _pallets[index];
                  final code = pallet['code'] as String;
                  final busy = _busyCodes.contains(code);
                  return ListTile(
                    key: Key('pallet-$code'),
                    title: Text(code),
                    subtitle: Text(
                      '${pallet['productCode']} x${pallet['quantity']}',
                    ),
                    trailing: (pallet['onHold'] as bool? ?? false)
                        ? const Text('ล็อกแล้ว')
                        : FilledButton(
                            key: Key('hold-$code'),
                            onPressed: busy ? null : () => _hold(code),
                            child: const Text('ล็อก'),
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
