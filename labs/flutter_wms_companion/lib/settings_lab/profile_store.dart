import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'health_probe.dart';
import 'profile_snapshot.dart';
import 'server_profile.dart';

/// ผลของการตรวจล่าสุด ใช้แสดงเป็นจุดสีบนหัวจอ
enum ServerStatus { unknown, checking, connected, disconnected }

/// ที่เก็บการตั้งค่าแบบง่าย ๆ ที่สลับตัวจริงตัวปลอมได้
///
/// แบบเดียวกับ SessionStorage ใน 8.5 — ประกาศเป็น interface เพื่อให้เทสต์
/// ไม่ต้องแตะดิสก์จริง
abstract interface class SettingsStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class InMemorySettingsStorage implements SettingsStorage {
  InMemorySettingsStorage({Map<String, String>? seed})
    : _values = {...?seed};

  final Map<String, String> _values;

  /// จำลองเครื่องที่เขียนลงดิสก์ไม่ได้ เช่นพื้นที่เต็มหรือสิทธิ์ไม่พอ
  bool failOnWrite = false;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    if (failOnWrite) throw Exception('เขียนลงเครื่องไม่ได้');
    _values[key] = value;
  }
}

/// แหล่งความจริงเดียวของ "มีเซิร์ฟเวอร์อะไรบ้าง ใช้ตัวไหนอยู่ ตอบไหม"
class ProfileStore extends ChangeNotifier {
  ProfileStore(this.storage, {String Function()? createId})
    : _createId =
          createId ?? (() => 'p${DateTime.now().microsecondsSinceEpoch}');

  static const String storageKey = 'server_profiles_v1';

  final SettingsStorage storage;
  final String Function() _createId;

  final List<ServerProfile> _profiles = [];
  String? _activeId;
  ServerStatus _status = ServerStatus.unknown;
  ProbeResult? _lastResult;
  bool _loaded = false;

  List<ServerProfile> get profiles => List.unmodifiable(_profiles);
  bool get isLoaded => _loaded;
  ServerStatus get status => _status;
  ProbeResult? get lastResult => _lastResult;

  ServerProfile? get active {
    for (final profile in _profiles) {
      if (profile.id == _activeId) return profile;
    }
    return null;
  }

  /// null จนกว่า [load] จะทำงานเสร็จ — คนเรียกจึงแยกออกระหว่าง
  /// "ยังไม่รู้" กับ "รู้แล้วว่าไม่มี"
  String? get activeBaseUrl => active?.baseUrl;

  bool isActive(ServerProfile profile) => profile.id == _activeId;

  /// อ่านค่าที่บันทึกไว้ ถ้าไม่มีเลยให้สร้างตัวเริ่มต้นให้หนึ่งตัว
  ///
  /// การสร้างให้ตั้งแต่แรกสำคัญ เพราะแอปที่เปิดมาแล้วไม่มีที่อยู่เลย
  /// จะยิงคำขอไม่ได้ และผู้ใช้จะเห็นแค่ข้อความว่าเชื่อมต่อไม่ได้
  /// โดยไม่รู้ว่าต้องไปตั้งค่าที่ไหน
  Future<void> load() async {
    String? raw;
    try {
      raw = await storage.read(storageKey);
    } catch (_) {
      // อ่านไม่ได้ ถือว่ายังไม่เคยตั้งค่า ดีกว่าเปิดแอปไม่ได้ (8.5)
      raw = null;
    }

    final snapshot = decodeProfiles(raw);
    _profiles
      ..clear()
      ..addAll(snapshot.profiles);
    _activeId = snapshot.activeId;

    if (_profiles.isEmpty) {
      final seed = seedProfile(id: _createId());
      _profiles.add(seed);
      _activeId = seed.id;
      await _persist();
    }

    _loaded = true;
    notifyListeners();
  }

  /// เพิ่ม profile ใหม่ โดย**ไม่**เปลี่ยนตัวที่ใช้งานอยู่
  ///
  /// บันทึกกับสลับเป็นคนละการกระทำโดยตั้งใจ — คนที่จดที่อยู่เครื่องทดสอบไว้
  /// ตอนบ่าย ไม่ได้อยากให้ PDA เปลี่ยนไปยิงเครื่องทดสอบทันที (10.6)
  Future<ServerProfile> saveAsNew(ServerProfile draft) async {
    final saved = draft.copyWith(id: _createId());
    _profiles.add(saved);
    await _persist();
    notifyListeners();
    return saved;
  }

  /// ทับตัวเดิมที่ id ตรงกัน ถ้าไม่เจอให้ถือว่าเป็นตัวใหม่
  Future<ServerProfile> saveEdits(ServerProfile draft) async {
    final index = _profiles.indexWhere((p) => p.id == draft.id);
    if (index < 0) return saveAsNew(draft);

    _profiles[index] = draft;
    await _persist();
    notifyListeners();
    return draft;
  }

  /// ชี้ทุกคำขอหลังจากนี้ไปที่ [id]
  ///
  /// ไม่มีการสร้าง ApiClient ใหม่ เพราะมันอ่าน baseUrl ใหม่ทุกครั้งที่ยิง
  /// token ที่ติดอยู่จึงไม่หาย — แต่ถ้า token นั้นออกโดยเซิร์ฟเวอร์เก่า
  /// มันจะใช้กับเซิร์ฟเวอร์ใหม่ไม่ได้ ซึ่ง 8.11 จัดการไว้แล้ว
  Future<void> activate(String id) async {
    if (_profiles.every((p) => p.id != id)) return;
    _activeId = id;
    // สถานะเดิมเป็นของเซิร์ฟเวอร์ตัวเก่า ใช้ต่อไม่ได้
    _status = ServerStatus.unknown;
    _lastResult = null;
    await _persist();
    notifyListeners();
  }

  /// ลบ profile
  ///
  /// ปฏิเสธการลบตัวสุดท้าย เพราะถ้าไม่เหลือเลย จะไม่มีที่อยู่ให้ยิง
  /// และไม่มีทางพิมพ์ตัวใหม่เข้าไปได้
  Future<bool> remove(String id, {String? nextActiveId}) async {
    if (_profiles.length <= 1) return false;
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index < 0) return false;

    _profiles.removeAt(index);
    if (_activeId == id) {
      final replacement = nextActiveId ?? _profiles.first.id;
      _activeId = _profiles.any((p) => p.id == replacement)
          ? replacement
          : _profiles.first.id;
      _status = ServerStatus.unknown;
      _lastResult = null;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  /// ตรวจว่าตัวที่ใช้งานอยู่ตอบไหม
  ///
  /// เรียกตอนเปิดจอ ตอนกลับมาจากพื้นหลัง และหลังสลับ profile
  /// **ไม่มีตัวจับเวลาที่วิ่งตลอด** เพราะเครื่องที่ถือทั้งวันไม่ควรเปลืองแบต
  /// และคลื่นวิทยุไปกับจุดสีที่ไม่มีใครมอง (10.8)
  Future<ServerStatus> refreshStatus({http.Client? client}) async {
    final url = activeBaseUrl;
    if (url == null) {
      _status = ServerStatus.disconnected;
      notifyListeners();
      return _status;
    }

    _status = ServerStatus.checking;
    notifyListeners();

    final result = await probeServer(baseUrl: url, client: client);
    _lastResult = result;
    _status = result.ok ? ServerStatus.connected : ServerStatus.disconnected;
    notifyListeners();
    return _status;
  }

  Future<void> _persist() async {
    try {
      await storage.write(storageKey, encodeProfiles(_profiles, _activeId));
    } catch (_) {
      // เขียนไม่ได้ก็ยังใช้งานรอบนี้ได้ ผู้ใช้ไม่ควรถูกบล็อกเพราะดิสก์เต็ม
      // แลกกับว่าปิดแอปแล้วค่าหาย ซึ่งดีกว่าใช้งานไม่ได้เลย (8.5)
    }
  }
}
