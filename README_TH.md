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

- Part 0 — Start Here: รื้อใหม่สำหรับผู้ไม่เคยเขียน Flutter ครบ 12/12 บท ตั้งแต่ติดตั้งจนถึง Mini Project Warehouse Counter ที่รันและทดสอบได้
- Dart Foundation: มีเนื้อหา 20/20 บท และเริ่มรื้อเส้นทางใหม่จากศูนย์แล้ว โดยบทแรกเริ่มที่ `main`, `print`, ตัวแปร และ lab Dart จริง
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
- Part 17: เขียนเนื้อหาเฉพาะบทครบ 14/14 บท ครอบคลุม receiving PO/part/serial/pallet, pending recovery, unload sessions และ load-to-basket trace
- Part 18: เขียนเนื้อหาเฉพาะบทครบ 16/16 บท ครอบคลุม putaway stations/prework/SignalR และ picking ตั้งแต่ order, source/destination pallets จนส่งเข้า packing
- Part 19: เขียนเนื้อหาเฉพาะบทครบ 15/15 บท ครอบคลุม packing state machine/auto-finalize, sorting REST+SignalR, check-in preview/commit/dispatch และ supervisor image upload
- Part 20: เขียนเนื้อหาเฉพาะบทครบ 15/15 บท ครอบคลุม bootstrap, API client/auth session, language/theme, connection profiles/probe/settings และ WarehouseShell lifecycle ของ wms_absolute_mobile
- Part 21: เขียนเนื้อหาเฉพาะบทครบ 15/15 บท ครอบคลุม WarehouseStore/repository, receiving state machine, inventory mapping/search และ cycle count contract/modes/tests ของ wms_absolute_mobile
- Part 22: เขียนเนื้อหาเฉพาะบทครบ 17/17 บท ครอบคลุม task models/API, manual scans, AGV/Forklift dispatch, withdraw, C1/C2 picking, C3 Store In, history, polling races และ tests ของ wms_absolute_mobile
- Part 23: เขียนเนื้อหาเฉพาะบทครบ 14/14 บท เปรียบเทียบ architecture สองโปรเจกต์ ครอบคลุม state/API/DI/model trade-offs, giant screen/God Store, race/security, test-first migration, review checklist และ ADR
- Part 24: เขียนเนื้อหาเฉพาะบทครบ 18/18 บท เป็น Final Project แบบ production-style ตั้งแต่ scope/architecture, shell/config/auth, receiving/inventory/cycle count/task, SignalR/upload ไปจน tests, Android release และ production readiness
- Part 25: เขียนเนื้อหาเฉพาะบทครบ 13/13 บท เป็น onboarding/code-reading playbook ครอบคลุม trace, contract/state/lifecycle/network debugging, เพิ่ม endpoint/workflow, security/performance review, coverage, glossary และแบบประเมินพร้อมทำงานจริง
- Part 26: เขียนเนื้อหาเฉพาะบทครบ 14/14 บท พร้อม implementation จริงของ task vertical slice ครอบคลุม test seam, strict contract, idempotency, per-task busy, timeout reconciliation, PDA UX และ integration runbook
- Part 27: เขียนเนื้อหาเฉพาะบทครบ 15/15 บท พร้อม lab เปรียบเทียบ Provider, Riverpod และ BLoC/Cubit จาก TaskRepository เดียวกัน ครอบคลุม ownership, async state, rebuild, testing, package evaluation และ migration
- Part 28: เขียนเนื้อหาเฉพาะบทครบ 16/16 บท พร้อม go_router lab ครอบคลุม URL contract, path/query, nested StatefulShellRoute, root scanner, auth redirect, intended deep link, browser history, platform setup และ routing tests
- Part 29: เขียนเนื้อหาเฉพาะบทครบ 16/16 บท พร้อม Drift/SQLite offline-first lab ครอบคลุม local source of truth, reactive query, transactional outbox, optimistic UI, idempotent sync/retry, conflict, migration, security และ in-memory database tests
- Part 30: เขียนเนื้อหาเฉพาะบทครบ 16/16 บท พร้อม refactor WmsTask ด้วย Freezed/json_serializable และ sealed TaskSyncState ครอบคลุม immutability, equality, copyWith, JSON/enum/converter, unions, build_runner, DTO-domain boundary และ compatibility tests

คอร์สมีเนื้อหาเฉพาะบท 468/468 บทและไม่มี scaffold เหลือ แต่กำลังปรับลำดับและวิธีอธิบายทั้งคอร์สให้เป็นมิตรกับผู้เริ่มต้นมากขึ้น สถานะ “มีเนื้อหา” จึงไม่ถูกใช้แทนคำว่า “รื้อเพื่อมือใหม่เสร็จแล้ว”

ทุกบทที่ generate ใหม่มีสารบัญภายในบทและหัวข้อที่กดข้ามไปอ่านได้ เพื่อให้บทที่ยาวอ่านเป็นช่วงได้เหมือนคอร์ส .NET

ชื่อ Part และชื่อบทในเมนูใช้รูปแบบสั้นแบบคอร์ส .NET โดย verifier จำกัดความยาวไม่เกิน 32 ตัวอักษร รายละเอียดเต็มยังอยู่ในเนื้อหาและ full-text search

ไฟล์ต้นฉบับของบทที่เขียนจริงอยู่ใน `content/` ส่วน `lessons/` เป็นไฟล์ที่ generator สร้าง ห้ามแก้ `lessons/` โดยตรงเพราะจะถูกเขียนทับ

## สร้างไฟล์ใหม่หลังแก้ Blueprint

```powershell
.\scripts\build-coverage.ps1
.\scripts\build-course.ps1
.\scripts\build-search-index.ps1
.\scripts\verify-course.ps1
```

โฟลเดอร์ `lessons/`, `index.html`, `course-manifest.json`, `coverage-manifest.json` และ `assets/search-index.js` เป็นผลลัพธ์จากสคริปต์ ค่า `authored` ใน manifest แยกบทที่เขียนจริงจาก scaffold
