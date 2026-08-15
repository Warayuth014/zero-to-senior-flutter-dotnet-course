# Zero to Senior Flutter + .NET

คอร์ส Flutter/Dart ภาษาไทยสำหรับอ่านและพัฒนา Mobile WMS ที่เชื่อมกับ .NET API ได้จริง

## เป้าหมาย

- เรียน Flutter ตั้งแต่พื้นฐานจนอ่านโปรเจกต์ `wmsapp` และ `wms_absolute_mobile` ได้อย่างน้อย 90%
- เข้าใจรอยต่อ Flutter → HTTP/JSON/JWT/SignalR → .NET API
- ไม่สอน business logic ฝั่ง .NET ซ้ำทั้งหมด แต่ยก endpoint/DTO ที่จำเป็นและโยงไปคอร์ส `zero-to-senior-dotnet8-course`
- มี coverage manifest ผูกไฟล์ Dart จริงทุกไฟล์เข้ากับบทเรียน

## Baseline

- Flutter 3.41.7 stable (SDK ในเครื่องวันที่เริ่มสร้างคอร์ส)
- Dart 3.11.5
- Reference apps:
  - `C:\Users\User\Documents\GitHub\wms-app\wmsapp`
  - `C:\Users\User\Desktop\wms_absolute_mobile`

## เปิดคอร์ส

เปิด `index.html` ด้วย browser แล้วเลือกบทเรียนจากเมนูด้านซ้าย Progress และ localStorage ใช้ namespace `zts_flutter_dotnet_` แยกจากคอร์สอื่น

## สถานะเนื้อหา

- Part -1: เขียนเนื้อหาเฉพาะบทครบ 20/20 บท พร้อมตัวอย่างจากสอง codebase แบบฝึกหัด และแนวคำตอบ
- Part 0: เขียนเนื้อหาเฉพาะบทครบ 12/12 บท พร้อม environment checks และ lab เปิดสองโปรเจกต์จริง
- Part 1: เขียนเนื้อหาเฉพาะบทครบ 15/15 บท ตั้งแต่ widget mental model จนถึง lab วิเคราะห์ Dashboard จากโปรเจกต์จริง
- Part 2: เขียนเนื้อหาเฉพาะบทครบ 15/15 บท ครอบคลุม constraints, responsive layout, scrolling, PDA ergonomics และ lab Warehouse Home
- Part 3: เขียนเนื้อหาเฉพาะบทครบ 14/14 บท ครอบคลุม form, focus, keyboard-wedge scanner, duplicate guard และ scan state machine
- Part 4: เขียนเนื้อหาเฉพาะบทครบ 16/16 บท ครอบคลุม state ownership, async race, polling, idempotency, FSM และ store testing
- Part 5: เขียนเนื้อหาเฉพาะบทครบ 12/12 บท ครอบคลุม navigation stack, modal, PopScope, application shell และ session cleanup
- Part 6: เขียนเนื้อหาเฉพาะบทครบ 14/14 บท ครอบคลุม DTO, JSON parsing, null/time/status/pagination และ contract tests
- Part 7: เขียนเนื้อหาเฉพาะบทครบ 18/18 บท ครอบคลุม HTTP client, URL/device networking, ProblemDetails, grid, retry/idempotency และ integration lab
- Part 8: เขียนเนื้อหาเฉพาะบทครบ 12/12 บท ครอบคลุม login, JWT session, secure persistence, 401/logout, permission และ server-bound session
- Part 9: เขียนเนื้อหาเฉพาะบทครบ 16/16 บท ครอบคลุม layers, data source/repository/store, DI, SSOT, error translation และ incremental refactoring
- Part 10: เขียนเนื้อหาเฉพาะบทครบ 13/13 บท ครอบคลุม typed settings, environment/profile, URL normalization, health probe และ safe server switching
- Part 11: เขียนเนื้อหาเฉพาะบทครบ 14/14 บท ครอบคลุม themes, design tokens, Thai font/localization, assets/icons และ platform-safe PDA shell
- Part 12: เขียนเนื้อหาเฉพาะบทครบ 12/12 บท ครอบคลุม SignalR, typed events/listeners, reconnect/reconciliation และ lifecycle-safe fallback polling
- Part 13: เขียนเนื้อหาเฉพาะบทครบ 10/10 บท ครอบคลุม image picking, cross-platform files, multipart upload, validation/progress และ secure .NET endpoint
- Part 14: เขียนเนื้อหาเฉพาะบทครบ 17/17 บท ครอบคลุม unit/contract/store/widget/flow tests, fake time, scanner layout, debugging และ performance profiling
- Part 15: เขียนเนื้อหาเฉพาะบทครบ 12/12 บท ครอบคลุม release artifacts/signing, platform permissions, HTTPS/certificates, secrets, diagnostics และ resilience checklist
- Part 16: เขียนเนื้อหาเฉพาะบทครบ 12/12 บท เป็นแผนที่ wmsapp จาก composition, session/routes, config/API extensions/models ไปจนถึง shared UI และ platform files
- Part 17–25: มีโครงหน้าและสารบัญเพื่อวางแผน coverage แต่ยังนับเป็น scaffold ไม่ใช่เนื้อหาที่เขียนเสร็จ

ไฟล์ต้นฉบับของบทที่เขียนจริงอยู่ใน `content/` ส่วน `lessons/` เป็นไฟล์ที่ generator สร้าง ห้ามแก้ `lessons/` โดยตรงเพราะจะถูกเขียนทับ

## สร้างไฟล์ใหม่หลังแก้ Blueprint

```powershell
.\scripts\build-coverage.ps1
.\scripts\build-course.ps1
.\scripts\build-search-index.ps1
.\scripts\verify-course.ps1
```

โฟลเดอร์ `lessons/`, `index.html`, `course-manifest.json`, `coverage-manifest.json` และ `assets/search-index.js` เป็นผลลัพธ์จากสคริปต์ ค่า `authored` ใน manifest แยกบทที่เขียนจริงจาก scaffold
