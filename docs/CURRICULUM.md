# Curriculum Design

## Learning contract

ผู้เรียนจบคอร์สควรทำงานต่อไปนี้ได้โดยไม่ต้องเดา:

1. เปิด Flutter project ใหม่แล้วหา entry point, app shell, feature, state owner และ data source ได้
2. Trace user action จาก widget ไปถึง .NET endpoint และ trace response กลับมาเป็น UI state ได้
3. แก้ contract mismatch, lifecycle bug, stale async response, duplicate scan และ network error ได้
4. เพิ่ม screen/API/model/repository/store/test ใหม่ตาม architecture ที่โปรเจกต์ใช้อยู่
5. อ่านไฟล์ Dart ทุกไฟล์ใน `wmsapp` และ `wms_absolute_mobile` ได้ โดยไฟล์เฉพาะทางจะมีบท Deep Dive และไฟล์ boilerplate จะมีบทอ้างอิง

## Scope boundary

คอร์สนี้สอน Flutter และรอยต่อกับ Backend อย่างละเอียด ได้แก่ HTTP, JSON, DTO, JWT, SignalR, multipart, health probe และ environment configuration ตัวอย่าง .NET API จะบางและใช้เพื่อพิสูจน์ contract เท่านั้น

เนื้อหา Controller, service layer, EF Core, SQL Server, Identity และ business logic ภายใน backend ให้อ่านต่อจาก `zero-to-senior-dotnet8-course`

## Progression

- Part -1–6: ภาษา, widget, layout, scanner, state และ model
- Part 7–15: .NET integration, auth, architecture, settings, realtime, files, tests และ production
- Part 16–22: อ่านสอง WMS codebase แบบ trace flow จริง
- Part 23: เปรียบเทียบและ refactor ด้วย senior trade-offs
- Part 24: ประกอบ final project
- Part 25: onboarding และ troubleshooting playbook

## Definition of done ต่อบท

บทหนึ่งถือว่าเรียนจบเมื่อผู้เรียนตอบได้ครบ:

- แนวคิดนี้คืออะไรและมีไว้แก้ปัญหาใด
- ใครเป็นเจ้าของ state และ side effect
- อยู่ในไฟล์ใดของ reference apps
- รอยต่อ request/response กับ .NET เป็นอย่างไร (ถ้ามี)
- happy path และ error path ต่างกันอย่างไร
- จะพิสูจน์ด้วย unit/widget/contract test แบบใด

## Coverage policy

`coverage-manifest.json` เป็น machine-readable mapping จาก source file ไป lesson ID ส่วน `scripts/verify-course.ps1` จะ fail เมื่อ:

- reference app มีไฟล์ Dart ใหม่ที่ยังไม่ถูก map
- lesson ID ซ้ำหรือไฟล์บทเรียนหาย
- index, manifest และ full-text index จำนวนไม่ตรงกัน
- coverage ชี้ไปบทที่ไม่มีอยู่
- localStorage namespace กลับไปชนคอร์สอื่น
- part ที่ประกาศใน `content/authored-parts.json` ยังมีบท scaffold
- content HTML ไม่มี lesson ID รองรับ หรือ authored count ใน manifest ไม่ตรง

## Authoring status

| Part | สถานะ | บทจริง |
|---|---|---:|
| -1 Dart Foundation | Authored + verified | 20/20 |
| 0 Setup, Tools & Project Anatomy | Authored + verified | 12/12 |
| 1 Flutter Widget Mental Model | Authored + verified | 15/15 |
| 2–25 | Scaffold/roadmap | 0/344 |

คำว่า “391 lessons” ใน manifest หมายถึงจำนวนเส้นทางบททั้งหมด ไม่ได้หมายความว่าเขียนเนื้อหาเชิงลึกครบแล้ว ให้ใช้ `authoredCount` เป็นตัวเลขความคืบหน้าด้านเนื้อหา
