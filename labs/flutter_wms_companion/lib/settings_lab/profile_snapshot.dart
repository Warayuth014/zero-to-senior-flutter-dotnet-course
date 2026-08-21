import 'dart:convert';

import 'server_profile.dart';

/// ทุกอย่างถูกเก็บใต้กุญแจเดียว
///
/// เก็บรวมเพราะกฎ "มี profile ที่ใช้งานอยู่หนึ่งตัวเสมอ" ต้องเขียนและอ่าน
/// พร้อมกัน ถ้าแยกเป็นสองกุญแจ (รายการ กับ id ที่ใช้อยู่) แล้วเขียนสำเร็จ
/// แค่ตัวเดียว จะได้สถานะที่ไม่มีทางเกิดจากการใช้งานปกติ (10.5)
typedef ProfileSnapshot = ({List<ServerProfile> profiles, String? activeId});

/// เลขรุ่นของโครงข้อมูล มีตั้งแต่วันแรก ไม่ใช่ตอนที่ต้องเปลี่ยน (8.5)
const int profileSchemaVersion = 1;

String encodeProfiles(List<ServerProfile> profiles, String? activeId) =>
    jsonEncode({
      'version': profileSchemaVersion,
      'profiles': [
        for (final profile in profiles)
          profile.toJson(isActive: profile.id == activeId),
      ],
    });

/// อ่านกลับมา โดยทิ้งแถวที่เสีย
///
/// `activeId` มาจากธง `isActive` ที่เก็บไว้ ถ้าไม่มีแถวไหนถูกทำเครื่องหมาย
/// ให้ใช้แถวแรก — กฎ "มีตัวที่ใช้งานอยู่หนึ่งตัวเสมอ" จึงเป็นจริงเสมอ
/// แม้ไฟล์จะถูกแก้ด้วยมือมาก่อน
ProfileSnapshot decodeProfiles(String? raw) {
  const empty = (profiles: <ServerProfile>[], activeId: null);
  if (raw == null || raw.trim().isEmpty) return empty;

  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    // ไฟล์เสียทั้งไฟล์ ถือว่าไม่เคยมี แล้วให้ผู้ใช้เริ่มใหม่
    // ดีกว่าเปิดแอปไม่ได้เลย
    return empty;
  }
  if (decoded is! Map) return empty;

  final rows = decoded['profiles'];
  if (rows is! List) return empty;

  final profiles = <ServerProfile>[];
  String? activeId;
  for (final row in rows) {
    final profile = ServerProfile.fromJson(row);
    if (profile == null) continue;
    profiles.add(profile);
    if (activeId == null && row is Map && row['isActive'] == true) {
      activeId = profile.id;
    }
  }

  if (profiles.isEmpty) return empty;
  return (profiles: profiles, activeId: activeId ?? profiles.first.id);
}
