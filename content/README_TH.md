# แหล่งเนื้อหาคอร์สที่เขียนจริง

ไฟล์ใน `content/<part-folder>/<lesson-id>.html` เป็น source of truth ของบทที่เขียนและตรวจแล้ว ส่วนไฟล์ใน `lessons/` เป็นผลลัพธ์ที่สร้างจาก `scripts/build-course.ps1`

- แก้เนื้อหาที่ `content/` เท่านั้น ไม่แก้ HTML ใน `lessons/` โดยตรง
- ถ้ายังไม่มี content override ระบบจะสร้างหน้า scaffold เพื่อให้สารบัญและลิงก์ไม่ขาด
- หลังแก้ให้รัน build-course, build-search-index และ verify-course ตามลำดับ
- ค่า `authored` ใน `course-manifest.json` ใช้แยกบทจริงออกจาก scaffold
