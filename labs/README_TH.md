# Companion Labs

## 1. .NET API ตัวอย่าง

```powershell
dotnet run --project .\dotnet\WmsMobileApi --urls http://0.0.0.0:5080
```

มี endpoint สำหรับ health, โหลด task และ complete task คำสั่ง complete บังคับ `Idempotency-Key`, คืน `correlationId` และตอบซ้ำอย่างปลอดภัย โค้ดนี้ตั้งใจบางเพื่อให้เห็น API contract เท่านั้น ส่วน Controller/Service/EF Core/JWT เชิงลึกให้อ่านจากคอร์ส .NET เดิม

## 2. Flutter App

Android emulator ใช้ค่าเริ่มต้น `http://10.0.2.2:5080`:

```powershell
flutter run --project-directory .\flutter_wms_companion
```

Windows/Web หรือเครื่องจริงกำหนด URL เอง:

```powershell
flutter run --project-directory .\flutter_wms_companion --dart-define=WMS_API_BASE_URL=http://localhost:5080
```

## สิ่งที่ Lab แสดง

`TaskScreen → TaskStore → TaskRepository → ApiClient → .NET endpoint`

มี initial loading/refresh/action state แยกกัน, per-task duplicate guard, timeout reconciliation, strict JSON validation, dependency injection ผ่าน `JsonApi` และ unit/widget tests

## ตรวจ checkpoint

```powershell
flutter analyze --no-pub --project-directory .\flutter_wms_companion
flutter test --no-pub --project-directory .\flutter_wms_companion
dotnet build .\dotnet\WmsMobileApi\WmsMobileApi.csproj --no-restore
```

เปิด API ก่อนแล้วเปิด Flutter จากนั้นลองกดปิด task เดิมซ้ำผ่าน HTTP client ด้วย `Idempotency-Key` เดิม ผลต้องสำเร็จและมี `replayed: true` โดยไม่เกิด side effect รอบสอง

## State Management Comparison (Part 27)

เปิด entrypoint เปรียบเทียบ Provider, Riverpod และ Cubit ซึ่งใช้ `TaskRepository` และ presentational list ชุดเดียวกัน:

```powershell
flutter run --project-directory .\flutter_wms_companion -t lib/state_patterns_main.dart --dart-define=WMS_API_BASE_URL=http://localhost:5080
```

รุ่นที่ lab resolve และทดสอบแล้วคือ `provider 6.1.5+1`, `flutter_riverpod 3.3.2` และ `flutter_bloc 9.1.1` ให้ศึกษา ownership/rebuild/test seam จากโค้ดก่อนตัดสินใจเลือก package ไม่ควรติดตั้งทั้งสามใน production app โดยไม่มีเหตุผล

## Routing & Deep Links (Part 28)

เปิด entrypoint `go_router 17.5.0` ซึ่งมี login redirect, intended URL, nested branch navigation และ full-screen scanner:

```powershell
flutter run --project-directory .\flutter_wms_companion -t lib/routing_main.dart --dart-define=WMS_API_BASE_URL=http://localhost:5080
```

เริ่มแบบ login แล้วลอง deep link ใน Flutter Web เช่น `/tasks/TASK-001?source=email` หรือกำหนด `--dart-define=ROUTING_AUTHENTICATED=true` เพื่อข้ามหน้า login ใน lab เท่านั้น การเปิด URL ตรงบน web production ต้องตั้งค่า server rewrite ไป `index.html` และ mobile ต้องตั้ง Android App Links/iOS Universal Links เพิ่ม

## Drift/SQLite Offline-first (Part 29)

เปิด entrypoint ที่ใช้ local database เป็น source of truth และเก็บคำสั่งปิด task ใน transactional outbox ก่อน sync ไป .NET API:

```powershell
flutter run --project-directory .\flutter_wms_companion -t lib/offline_main.dart --dart-define=WMS_API_BASE_URL=http://localhost:5080
```

ลองโหลด task ขณะ API ทำงาน จากนั้นหยุด API แล้วปิด task รายการจะถูกซ่อนและ badge จะแสดง command รอ sync เมื่อเปิด API อีกครั้งให้กดปุ่ม sync; repository จะ replay `commandId` เดิมเพื่อใช้ idempotency contract ฝั่ง server

เมื่อแก้ table หรือ annotation ให้สร้าง type-safe code ใหม่และรัน tests:

```powershell
Set-Location .\flutter_wms_companion
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
```

Lab ใช้ `drift 2.34.3`, `drift_flutter 0.3.1` และ SQLite ผ่าน dependency ที่ resolve ใน `pubspec.lock` สำหรับ Flutter Web ต้องติดตั้งไฟล์ SQLite WASM/worker ตามเอกสาร Drift และทดสอบ runtime จริงเพิ่มเติม ไม่ควรถือว่า web build ผ่านแล้ว asset พร้อมเสมอ

## Freezed & JSON Code Generation (Part 30)

`WmsTask` ตัวจริงถูก refactorให้ใช้ Freezed และ json_serializable โดยยัง normalize/validate API contract เดิม ส่วน `TaskSyncState` แสดง sealed union และ exhaustive Dart patterns:

```powershell
Set-Location .\flutter_wms_companion
dart run build_runner build
dart format lib test
flutter analyze --no-pub
flutter test --no-pub
```

Lab resolve `freezed 3.2.5`, `freezed_annotation 3.1.0`, `json_serializable 6.14.1` และ `json_annotation 4.12.0` Generated `.freezed.dart`/`.g.dart` ถูก commitเพื่อให้ศึกษาและตรวจ diffได้ แต่ห้ามแก้โดยตรง ให้แก้ annotated sourceแล้ว generateใหม่
