# Companion Labs

## 1. .NET API ตัวอย่าง

```powershell
dotnet run --project .\dotnet\WmsMobileApi --urls http://0.0.0.0:5080
```

มี endpoint สำหรับ health, โหลด task และ complete task โค้ดนี้ตั้งใจบางเพื่อให้เห็น API contract เท่านั้น ส่วน Controller/Service/EF Core/JWT เชิงลึกให้อ่านจากคอร์ส .NET เดิม

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

มี loading/error/empty/success state, timeout/network error, JSON validation, dependency injection และ store unit test
