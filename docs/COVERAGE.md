# Real-code Coverage

คอร์สอ้างอิง source ปัจจุบันของสองแอป:

| Project | ลักษณะเด่น | บทหลัก |
|---|---|---|
| `wmsapp` | 110 Dart files, screen-centric state, API extension, multipart, SignalR | Part 16–19 |
| `wms_absolute_mobile` | 35 Dart files, ChangeNotifier store, repository, connection profile, tests | Part 20–22 |

รวม source/config/test ที่ติดตาม 166 ไฟล์ รายละเอียดรายไฟล์อยู่ใน `coverage-manifest.json`

## Coverage levels

- `deep`: ไฟล์ใน `lib/` ที่ต้องอ่านผ่านบท concept หรือ codebase flow
- `reference`: test/config/platform file ที่ต้องเข้าใจหน้าที่และใช้ตรวจงาน แต่ไม่จำเป็นต้องเดินทุกบรรทัด

ตัวเลขนี้เป็น structural coverage ไม่ใช่คำรับรองว่าอ่านชื่อไฟล์แล้วเข้าใจทันที เป้าหมาย 90%++ มาจากการเรียน foundation + integration ก่อน แล้วใช้ Part 16–22 trace business flows พร้อมเปิด source จริงคู่กัน
