param(
  [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$blueprintPath = Join-Path $ProjectRoot 'course-blueprint.json'
$manifestPath = Join-Path $ProjectRoot 'course-manifest.json'
$lessonsRoot = Join-Path $ProjectRoot 'lessons'
$contentRoot = Join-Path $ProjectRoot 'content'
$blueprint = Get-Content -LiteralPath $blueprintPath -Raw -Encoding UTF8 | ConvertFrom-Json
$coveragePath = Join-Path $ProjectRoot 'coverage-manifest.json'
$coverage = if (Test-Path -LiteralPath $coveragePath) {
  [object[]](Get-Content -LiteralPath $coveragePath -Raw -Encoding UTF8 | ConvertFrom-Json)
} else { @() }

$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Path $lessonsRoot -Force | Out-Null

function HtmlEncode([object]$value) {
  [System.Net.WebUtility]::HtmlEncode([string]$value)
}

function LessonId([int]$partNumber, [int]$topicNumber) {
  if ($partNumber -lt 0) { return 'm01-{0:D2}' -f $topicNumber }
  return '{0:D2}-{1:D2}' -f $partNumber, $topicNumber
}

function PartFolder([object]$part) {
  if ([int]$part.number -lt 0) { return 'part-m01-{0}' -f $part.slug }
  return 'part-{0:D2}-{1}' -f [int]$part.number, $part.slug
}

function KindLabel([string]$kind) {
  switch ($kind) {
    'dart' { 'Dart Core' }
    'flutter' { 'Flutter UI' }
    'state' { 'State & Lifecycle' }
    'api' { 'Flutter + .NET' }
    'auth' { 'Auth Integration' }
    'architecture' { 'Architecture' }
    'realtime' { 'Realtime' }
    'files' { 'Files & Platform' }
    'testing' { 'Testing' }
    'production' { 'Production' }
    'codebase' { 'Real Codebase' }
    'project' { 'Project Lab' }
    default { 'Foundation' }
  }
}

function CodeSample([string]$kind, [string]$topic) {
  switch ($kind) {
    'dart' {
@'
Future&lt;T&gt; guard&lt;T&gt;(Future&lt;T&gt; Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(error, stackTrace);
  }
}
'@
    }
    'api' {
@'
final response = await client.post(
  Uri.parse('$baseUrl/api/WMS/mobile_action'),
  headers: {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  },
  body: jsonEncode({'barcode': barcode.trim()}),
).timeout(const Duration(seconds: 15));
'@
    }
    'auth' {
@'
final json = await api.post('/api/Authenticate/login', {
  'username': username,
  'password': password,
}, absolute: true);
api.authToken = json['token'] as String?;
'@
    }
    'state' {
@'
class ScanStore extends ChangeNotifier {
  bool loading = false;

  Future&lt;void&gt; submit(String code) async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      await repository.submit(code.trim());
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
'@
    }
    'architecture' {
@'
abstract interface class TaskRepository {
  Future&lt;List&lt;WmsTask&gt;&gt; fetchOpen();
}

class TaskViewModel extends ChangeNotifier {
  TaskViewModel(this.repository);
  final TaskRepository repository;
}
'@
    }
    'realtime' {
@'
@override
void initState() {
  super.initState();
  signalR.addTaskChangedListener(_onTaskChanged);
}

@override
void dispose() {
  signalR.removeTaskChangedListener(_onTaskChanged);
  super.dispose();
}
'@
    }
    'testing' {
@'
testWidgets('ยืนยันงานได้หลังสแกนครบ', (tester) async {
  await tester.pumpWidget(buildSubject(fakeRepository));
  await tester.enterText(find.byType(TextField), 'PALLET-001');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  expect(find.text('ยืนยัน'), findsOneWidget);
});
'@
    }
    'codebase' {
@'
# เริ่มจากชื่อ action แล้วไล่ลงทีละชั้น
rg -n "ชื่อเมธอด|ชื่อ endpoint|ชื่อ model" lib docs

# เส้นทางที่ต้องตอบให้ได้
Screen → State/Store → Repository/ApiService → JSON → .NET endpoint
'@
    }
    default {
@'
class WarehouseCard extends StatelessWidget {
  const WarehouseCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: child,
  ));
}
'@
    }
  }
}

function TopicExplanation([string]$topic, [string]$kind) {
  switch -Regex ($topic) {
    'final, const และ late' { return '<p><code>final</code> กำหนดค่าได้ครั้งเดียวตอน runtime, <code>const</code> ต้องเป็นค่าคงที่ตอน compile time และ <code>late</code> เลื่อน initialization แต่ยังรับประกันชนิด non-nullable ความต่างนี้กระทบทั้ง model, controller และ const widget โดยตรง</p>' }
    'null|Nullable' { return '<p>Dart เป็น sound null safe: ชนิด <code>T</code> ห้ามเป็น null ส่วน <code>T?</code> ยอมให้ไม่มีค่าได้ ใช้ <code>?</code>, <code>?.</code>, <code>??</code> และ promotion เพื่อบังคับให้จัดการ absence ก่อนใช้งาน แทนการกระจาย <code>!</code> ไปทั่วโค้ด</p>' }
    'Future|async|await' { return '<p><code>Future&lt;T&gt;</code> แทนผลลัพธ์ที่จะมาในอนาคต <code>await</code> พักเฉพาะ async function ไม่ได้ block UI thread จุดสำคัญคือ error จะเดินทางผ่าน Future และ widget อาจถูก dispose ระหว่างรอ</p>' }
    'Stream|event-driven' { return '<p>Stream ส่งค่าได้หลายครั้ง ต่างจาก Future ที่จบครั้งเดียว ทุก subscription มี lifecycle: subscribe, handle data/error/done และ cancel เหมาะกับ realtime event แต่ถ้าไม่ยกเลิกจะเกิด callback ซ้ำและ memory leak</p>' }
    'Isolate' { return '<p>UI isolate ต้องว่างพอ render frame งาน CPU หนักจึงควรแยก isolate ส่วน HTTP ไม่ต้องแยกเพราะเป็น asynchronous I/O อยู่แล้ว ต้นทุนของ isolate คือการส่งข้อความและข้อมูลต้องส่งข้าม boundary ได้</p>' }
    'JSON|fromJson|toJson|dynamic|runtime cast' { return '<p>JSON เป็นข้อมูลไร้ type จาก network boundary ให้ decode เป็น <code>Map&lt;String, dynamic&gt;</code> ชั่วคราว แล้ว validate/แปลงเป็น model ที่มีชนิดทันที เพื่อไม่ให้ runtime cast error ไหลไปถึง widget</p>' }
    'Widget tree|Element tree|RenderObject' { return '<p>Widget คือ immutable configuration, Element เก็บตำแหน่งและ identity ใน tree, RenderObject ทำ layout/paint เมื่อ build คืน widget ใหม่ Flutter จะ reconcile กับ Element เดิม จึงไม่ได้สร้างหน้าจอ native ใหม่ทั้งหมดทุกครั้ง</p>' }
    'StatelessWidget' { return '<p>StatelessWidget ไม่มี State object ของตัวเอง แต่ rebuild ได้เมื่อ parent หรือ inherited dependency เปลี่ยน เหมาะกับ UI ที่คำนวณจาก constructor input และ context โดยไม่ถือ mutable lifecycle state</p>' }
    'StatefulWidget|State object' { return '<p>StatefulWidget ยัง immutable; mutable data อยู่ใน State object ที่ Flutter ผูกกับตำแหน่งใน tree การแยกสอง object นี้ทำให้ configuration เปลี่ยนได้โดยรักษา state เดิมเมื่อ identity ยังตรงกัน</p>' }
    'initState|dispose|lifecycle' { return '<p>สร้าง controller/listener/subscription ใน lifecycle ที่เหมาะสมและคืนทรัพยากรใน <code>dispose</code> งานที่ขึ้นกับ inherited widget ใช้ <code>didChangeDependencies</code>; อย่าทำ side effect ซ้ำทุก <code>build</code></p>' }
    'BuildContext' { return '<p>BuildContext คือ handle ของตำแหน่ง Element ไม่ใช่ global application context การหา Theme, Navigator หรือ MediaQuery จะค้นขึ้น tree จากตำแหน่งนั้น และ context อาจใช้ไม่ได้หลัง await หาก widget ถูกถอดออกแล้ว</p>' }
    '^Key|identity' { return '<p>Key ช่วย Flutter จับคู่ว่า widget ใหม่คือ entity เดิมตัวใด โดยเฉพาะ list ที่ reorder/insert ถ้าไม่มี key state อาจติดกับตำแหน่งแทนข้อมูล ส่วน GlobalKey มีต้นทุนสูงและควรใช้เฉพาะเมื่อต้องเข้าถึง State/Form จริง ๆ</p>' }
    'Constraints|Row, Column|Expanded|Flexible|RenderFlex|LayoutBuilder|MediaQuery|SafeArea|ListView|GridView|Sliver' { return '<p>Layout ของ Flutter เริ่มจาก parent ส่ง constraints ลงไป child เลือก size ภายในกรอบ แล้ว parent จัดตำแหน่ง ปัญหา overflow จึงแก้ด้วยการหา constraint ที่ไม่จำกัดหรือ child ที่ขอพื้นที่เกิน ไม่ใช่สุ่มใส่ height</p>' }
    'TextField|TextEditingController|FocusNode|Form|validator|Keyboard|Scanner|barcode|Debounce|duplicate scan|Quantity input' { return '<p>Scanner warehouse ส่วนมากส่งอักขระเหมือน keyboard แล้วปิดด้วย Enter หน้าจอต้องคุม focus, normalize ค่า, ป้องกัน duplicate/submit ซ้ำ และคืน feedback เร็ว Controller กับ FocusNode เป็น resource ที่ต้อง dispose</p>' }
    'setState' { return '<p><code>setState</code> ไม่ได้เปลี่ยนค่าให้เรา มันประกาศว่า local State เปลี่ยนและ subtree นี้ต้อง build ใหม่ เหมาะกับ state ในหน้าจอเดียว แต่เมื่อหลายหน้าต้องแชร์หรือทดสอบ logic แยก ควรย้าย owner ออกไป</p>' }
    'ValueNotifier|ValueListenableBuilder' { return '<p>ValueNotifier เหมาะกับค่าเดียวที่เปลี่ยนไม่ซับซ้อน Builder จะ rebuild เฉพาะ subtree ที่ฟัง แต่การ mutate object/list เดิมโดยไม่ assign value ใหม่อาจไม่ notify</p>' }
    'ChangeNotifier|notifyListeners|Store|ViewModel' { return '<p>ChangeNotifier รวม state และ commands ไว้ใน object ที่ทดสอบแยกจาก widget ได้ ทุก mutation ต้องรักษา invariant แล้วเรียก notifyListeners อย่างมีขอบเขต ไม่ควรให้ public field ถูกแก้จากทุกที่โดยไร้กติกา</p>' }
    'Loading/Error/Empty/Success|try/finally' { return '<p>Remote screen ไม่ได้มีแค่ข้อมูลหรือไม่มีข้อมูล แต่มีอย่างน้อย initial/loading/success-empty/success-data/error การตั้ง loading กลับใน <code>finally</code> ป้องกันปุ่มค้างเมื่อ request throw</p>' }
    'Stale response|generation token|race' { return '<p>Request เก่าที่ตอบช้ากว่า request ใหม่อาจทับ state ล่าสุด ใช้ generation token, cancellation หรือเปรียบเทียบ query ปัจจุบันก่อน commit result และตรวจ mounted เมื่อ state owner คือ widget</p>' }
    'Timer|polling|listener|Subscribe|unsubscribe' { return '<p>Timer และ listener เป็น side effect ที่มีอายุยาวกว่า method call ต้องกำหนด owner ให้ชัด เริ่มหนึ่งครั้ง หยุดใน dispose และป้องกัน request รอบใหม่ซ้อนรอบเดิม</p>' }
    'Navigator|MaterialPageRoute|pushReplacement|PopScope|Bottom navigation|Dialog|bottom sheet|SnackBar|toast' { return '<p>Navigation คือ state transition ระหว่าง route ไม่ใช่แค่เปิดหน้า ต้องตัดสินใจว่ากลับแล้วเก็บหรือทิ้ง transient workflow, dependency ส่งเข้า route อย่างไร และ action ใดต้องรอ result จาก dialog/sheet</p>' }
    'DTO|domain model|UI model|Grid envelope|PascalCase|camelCase|DateTime|timezone|Enum/status' { return '<p>API DTO สะท้อน contract ภายนอก ส่วน domain/UI model สะท้อนสิ่งที่แอปต้องใช้ การแยกชั้นช่วยกัก casing, nullable, status code และ date format ที่ไม่นิ่งไว้ที่ boundary แทนการกระจายเงื่อนไขใน widget</p>' }
    'URL|URI|base URL|localhost|emulator|API prefix|ConnectionProfile|Normalize' { return '<p><code>localhost</code> หมายถึงเครื่องที่โปรแกรมกำลังรัน: บน Android emulator ใช้ <code>10.0.2.2</code> เพื่อย้อนหา host การแยก origin/base path/API prefix ป้องกัน URL ซ้ำ <code>/api/.../api/...</code> และรองรับหลาย environment</p>' }
    'HTTP|Header|content-type|authorization|Timeout|SocketException|Status code|ProblemDetails|ApiResult|ApiException|Pagination|query string|Health endpoint|probe' { return '<p>HTTP client ที่ใช้งานจริงต้องกำหนด URL, method, headers, body, timeout และ decoding contract ชัดเจน แยก network failure ออกจาก non-2xx และ malformed payload เพื่อให้ UI แสดง action ที่แก้ปัญหาได้</p>' }
    'Login|JWT|Bearer|session|401|Logout|Role|secure storage' { return '<p>Login แลก credential กับ token จากนั้น client แนบ <code>Authorization: Bearer ...</code> ทุก request Session ต้องมีจุดเริ่ม/หมดอายุ/logout ชัดเจน และ token production ควรอยู่ secure storage ไม่ใช่ log หรือ plain preference</p>' }
    'Separation|data layer|Repository|dependency injection|Single source|Unidirectional|feature-first|God Store|Giant screen|Refactor' { return '<p>แยก View, state/command และ data access เพื่อให้แต่ละชั้นมี input/output ชัด UI ส่ง event ลง ข้อมูลใหม่ไหลกลับขึ้นจาก single source of truth การ inject interface ทำให้เปลี่ยน remote implementation เป็น fake ใน test ได้</p>' }
    'SignalR|Hub|reconnect|realtime|Polling' { return '<p>HTTP เหมาะกับ command/query ณ เวลาใดเวลาหนึ่ง ส่วน SignalR push event เมื่อ server state เปลี่ยน Client ยังต้องจัดการ reconnect, duplicate event, ordering และ refresh authoritative state เมื่อไม่แน่ใจ</p>' }
    'ImagePicker|Multipart|upload|thumbnail|Asset|launcher icon' { return '<p>ไฟล์ไม่ได้อยู่ใน JSON body ปกติ Multipart แยก field กับ binary part ต้องตรวจ permission, type, size, timeout และ URL ที่ backend คืนมา พร้อมระวังความต่างของ <code>dart:io File</code> บน web</p>' }
    'test|Test|WidgetTester|Fake|DevTools|performance|rebuild' { return '<p>แยก logic ออกจาก widget เพื่อใช้ unit test กับ fake repository แล้วใช้ widget test พิสูจน์ rendering/navigation เฉพาะจุด DevTools ช่วยยืนยัน rebuild/layout/memory แทนการคาดเดา</p>' }
    default { return "<p><strong>$(HtmlEncode $topic)</strong> ให้อ่านโดยแยก 4 อย่าง: input ที่เข้ามา, state ที่ถืออยู่, side effect ที่ออกไป และ output ที่ UI แสดง จากนั้นหา owner และ lifecycle ของแต่ละอย่างให้เจอ</p>" }
  }
}

function Pitfalls([string]$kind) {
  switch ($kind) {
    'dart' { 'อย่าใช้ dynamic เพื่อปิด error ของ type system; ระบุ boundary ที่ข้อมูลยังไม่แน่นอนแล้วแปลงเป็นชนิดจริงให้เร็วที่สุด' }
    'api' { 'อย่าสมมติว่า HTTP 200 แปลว่า payload ถูกต้อง และอย่าต่อ URL ด้วย string โดยไม่กำหนดกติกา base path ให้ชัด' }
    'auth' { 'อย่าเก็บรหัสผ่าน และอย่า log token; เมื่อเปลี่ยน server หรือได้ 401 ต้องตัดสินใจเรื่อง session อย่างชัดเจน' }
    'state' { 'อย่าเรียก setState/notifyListeners หลัง dispose และอย่าให้ response เก่าทับ state ของ request ใหม่' }
    'realtime' { 'listener ที่เพิ่มแล้วไม่ถอดจะยิงซ้ำทุกครั้งที่กลับเข้าหน้า และ connection singleton ต้องแยก lifecycle ออกจาก screen' }
    'testing' { 'test ที่พึ่ง network จริงจะช้าและไม่แน่นอน; inject dependency แล้วใช้ fake ที่ควบคุมผลลัพธ์ได้' }
    'codebase' { 'อย่าอ่านไฟล์ใหญ่จากบรรทัดแรกถึงท้ายโดยไม่มีคำถาม; เริ่มจาก user action แล้ว trace เฉพาะ state และ dependency ที่เกี่ยวข้อง' }
    default { 'อย่าแก้ UI จากอาการอย่างเดียว ให้แยกก่อนว่าเป็น constraints, state, lifecycle หรือ data contract' }
  }
}

$allLessons = New-Object System.Collections.Generic.List[object]
foreach ($part in $blueprint.parts) {
  $folderName = PartFolder $part
  $folder = Join-Path $lessonsRoot $folderName
  New-Item -ItemType Directory -Path $folder -Force | Out-Null
  $topicNumber = 0
  foreach ($topic in $part.topics) {
    $topicNumber++
    $id = LessonId ([int]$part.number) $topicNumber
    $path = "lessons/$folderName/$id.html"
    $contentPath = "content/$folderName/$id.html"
    $allLessons.Add([pscustomobject]@{
      id = $id
      part = [int]$part.number
      number = $topicNumber
      title = [string]$topic
      partTitle = "Part $($part.number): $($part.title)"
      kind = [string]$part.kind
      path = $path
      contentPath = $contentPath
      authored = Test-Path -LiteralPath (Join-Path $ProjectRoot ($contentPath -replace '/', '\'))
    })
  }
}

foreach ($lesson in $allLessons) {
  $part = $blueprint.parts | Where-Object { [int]$_.number -eq [int]$lesson.part } | Select-Object -First 1
  $refs = @($coverage | Where-Object lessonId -eq $lesson.id)
  $referenceHtml = if ($refs.Count) {
    '<ul>' + (($refs | ForEach-Object { '<li><code>{0}:{1}</code></li>' -f (HtmlEncode $_.project), (HtmlEncode $_.path) }) -join '') + '</ul>'
  } else {
    '<p>บทพื้นฐานนี้เตรียมแนวคิดสำหรับอ่านทั้ง <code>wmsapp</code> และ <code>wms_absolute_mobile</code> โดยบท Codebase Deep Dive จะระบุไฟล์จริงแบบรายไฟล์</p>'
  }
  $bridge = if ($lesson.kind -in @('api','auth','realtime','files','codebase','project')) {
    '<div class="note"><strong>รอยต่อ .NET:</strong> บทนี้อธิบาย request/response และ endpoint ที่ Flutter ต้องรู้ ส่วน Controller → Service → EF Core/SQL ให้อ่านต่อในคอร์ส <code>zero-to-senior-dotnet8-course</code></div>'
  } else {
    '<div class="note"><strong>มุม Flutter:</strong> จับหลักให้ได้ก่อน แล้วค่อยเทียบการใช้งานสองแบบในโปรเจกต์จริง</div>'
  }
  $authoredPath = Join-Path $ProjectRoot ($lesson.contentPath -replace '/', '\')
  $lessonBody = if (Test-Path -LiteralPath $authoredPath) {
    Get-Content -LiteralPath $authoredPath -Raw -Encoding UTF8
  } else {
@"
<div class="note">$(HtmlEncode $part.description)</div>
<section><h2>1. เป้าหมายของบทนี้</h2><ul><li>อธิบาย <strong>$(HtmlEncode $lesson.title)</strong> ด้วยภาษาของตัวเองได้</li><li>ชี้ได้ว่าแนวคิดนี้อยู่ตรงไหนใน flow Flutter → .NET</li><li>ทดลองและตรวจผลได้ ไม่ใช่จำโค้ดอย่างเดียว</li></ul></section>
<section><h2>2. Mental model</h2>$(TopicExplanation $lesson.title $lesson.kind)<p>หัวข้อนี้อยู่ในกลุ่ม <strong>$(HtmlEncode $part.title)</strong> เมื่อเปิดโค้ดจริงให้ถามว่าใครเป็นเจ้าของข้อมูล ใครเปลี่ยนข้อมูล และ widget ใดต้อง rebuild หลังการเปลี่ยนนั้น</p>$bridge</section>
<section><h2>3. หาในโปรเจกต์จริง</h2>$referenceHtml</section>
<section><h2>4. วิธีไล่ทีละขั้น</h2><ol><li>เริ่มจาก event ของผู้ใช้ เช่น tap, submit หรือ scan</li><li>ตาม method ที่เปลี่ยน state หรือเรียก dependency</li><li>ถ้ามี I/O ให้เปิด request DTO, endpoint และ response model คู่กัน</li><li>กลับมาดูว่า state ใหม่ทำให้ widget ส่วนใด rebuild</li><li>เขียน test หรือ checklist เพื่อพิสูจน์ happy path และ error path</li></ol></section>
<section><h2>5. ตัวอย่างโค้ด</h2><pre class="code-vs"><code>$(CodeSample $lesson.kind $lesson.title)</code></pre></section>
<section><h2>6. จุดที่พบบ่อยในงานจริง</h2><div class="warn">$(HtmlEncode (Pitfalls $lesson.kind))</div></section>
<section><h2>7. Mini Exercise</h2><ol><li>ค้นหา <code>$(HtmlEncode $lesson.title)</code> หรือ symbol ที่เกี่ยวข้องในสอง reference apps</li><li>วาด flow สั้น ๆ จาก UI ไป data source แล้วกลับมา UI</li><li>เพิ่ม error case หนึ่งกรณีและอธิบายว่าผู้ใช้ควรเห็นอะไร</li></ol></section>
<section><h2>8. Checklist</h2><ul><li>บอก owner ของ state ได้</li><li>แยก synchronous code กับ asynchronous side effect ได้</li><li>รู้ว่า dispose/cancel ตรงไหน</li><li>อธิบาย contract กับ .NET โดยไม่ต้องเดาจาก UI</li></ul></section>
<section><h2>9. สรุปจำเร็ว</h2><div class="success"><strong>$(HtmlEncode $lesson.title)</strong> ต้องตอบได้ทั้ง “มันคืออะไร”, “อยู่ตรงไหนในโค้ด”, “พังแบบไหน” และ “ทดสอบอย่างไร”</div></section>
"@
  }
  $html = @"
<!doctype html>
<html lang="th">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(HtmlEncode $lesson.title)</title><link rel="stylesheet" href="../../assets/course.css"></head>
<body><div class="lesson">
<header class="hero"><span class="badge">$(HtmlEncode $lesson.id) · $(HtmlEncode (KindLabel $lesson.kind))</span><h1>$(HtmlEncode $lesson.title)</h1><p>$(HtmlEncode $lesson.partTitle)</p></header>
$lessonBody
</div><script src="../../assets/course.js"></script></body></html>
"@
  $absolutePath = Join-Path $ProjectRoot ($lesson.path -replace '/', '\')
  [System.IO.File]::WriteAllText($absolutePath, $html, $utf8)
}

$partsManifest = foreach ($part in $blueprint.parts) {
  [pscustomobject]@{
    number = [int]$part.number
    title = [string]$part.title
    slug = [string]$part.slug
    description = [string]$part.description
    topics = @($allLessons | Where-Object part -eq ([int]$part.number))
  }
}
$manifest = [pscustomobject]@{
  courseTitle = $blueprint.courseTitle
  subtitle = $blueprint.subtitle
  generatedAt = (Get-Date).ToString('yyyy-MM-dd')
  lessonCount = $allLessons.Count
  authoredCount = @($allLessons | Where-Object authored).Count
  parts = @($partsManifest)
}
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8), $utf8)

$details = foreach ($part in $partsManifest) {
  $rows = foreach ($lesson in $part.topics) {
    '<a class="row" href="{0}" target="frame" data-id="{1}" data-title="{2}" data-part="Part {3}: {4}"><input class="ck" type="checkbox" data-id="{1}"><span class="rtitle">{3}.{5} {2}</span><span>›</span></a>' -f (HtmlEncode $lesson.path), (HtmlEncode $lesson.id), (HtmlEncode $lesson.title), $part.number, (HtmlEncode $part.title), $lesson.number
  }
  '<details class="part"><summary>Part {0}: {1} <small>{2} lessons</small></summary><div class="list">{3}</div></details>' -f $part.number, (HtmlEncode $part.title), $part.topics.Count, ($rows -join '')
}

$indexHtml = @"
<!doctype html><html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>$(HtmlEncode $blueprint.courseTitle)</title><link rel="stylesheet" href="assets/course.css"></head><body>
<div class="shell"><div id="sidebarHotspot" class="sidebar-hotspot" aria-hidden="true"></div><aside class="side">
<div class="brand"><span class="badge">Course Index</span><h1>$(HtmlEncode $blueprint.courseTitle)</h1><p>$(HtmlEncode $blueprint.subtitle)</p></div>
<input id="search" class="search" type="search" placeholder="ค้นหาชื่อบทหรือเนื้อหา เช่น ChangeNotifier, JWT, SignalR">
<div class="stats"><div class="stat"><b id="done">0</b><span>Done</span></div><div class="stat"><b id="total">0</b><span>Lessons</span></div><div class="stat"><b id="pct">0%</b><span>Progress</span></div></div>
<button id="reset" class="btn" type="button">Reset Progress</button>
<div class="filter-tabs" aria-label="Lesson filters"><button class="active" type="button" data-filter="all">All</button><button type="button" data-filter="todo">Not Started</button><button type="button" data-filter="done">Done</button><button type="button" data-filter="current">Current Part</button></div>
$($details -join "`n")
</aside><main class="main"><div class="top"><button id="sidebarToggle" class="btn sidebar-toggle" type="button" aria-expanded="true">ซ่อนเมนู</button><a id="homeLink" class="btn" href="home.html" target="frame">Home</a><div id="cur" class="title">Home</div><button id="themeToggle" class="btn theme-toggle" type="button">☀️</button><a id="open" class="btn" href="home.html" target="_blank" rel="noopener">Open New Tab</a></div><iframe id="frame" name="frame" src="home.html" title="Course lesson viewer"></iframe></main></div>
<script src="assets/search-index.js"></script><script src="assets/course.js"></script></body></html>
"@
[System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'index.html'), $indexHtml, $utf8)

$homeHtml = @"
<!doctype html><html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>$(HtmlEncode $blueprint.courseTitle)</title><link rel="stylesheet" href="assets/course.css"></head><body>
<div class="home-page"><header class="home-hero"><span class="home-kicker">Flutter · Dart · .NET Integration · Real WMS</span><h1>$(HtmlEncode $blueprint.courseTitle)</h1><p class="home-lead">$(HtmlEncode $blueprint.subtitle)</p><div class="home-actions"><a class="btn primary" href="$($allLessons[0].path)" target="_top">เริ่มบทแรก →</a></div></header>
<section class="home-section"><div class="home-section-title"><h2>เรียนแล้วทำอะไรได้</h2></div><div class="home-grid">
<div class="home-card home-card-accent"><span class="card-label">Flutter Core</span><h3>อ่าน Widget และ State ออก</h3><p>Dart, lifecycle, layout, scanner, navigation และ async workflow</p></div>
<div class="home-card"><span class="card-label">Integration</span><h3>ต่อ .NET API ได้จริง</h3><p>HTTP/JSON/JWT/SignalR/upload พร้อม error และ connection handling</p></div>
<div class="home-card"><span class="card-label">Real Code</span><h3>อ่าน WMS สองระบบ</h3><p>ทุกไฟล์ Dart ถูกผูกกับ coverage manifest และบท Deep Dive</p></div>
<div class="home-card"><span class="card-label">Practice</span><h3>ลงมือสร้าง Mobile WMS</h3><p>Lab ต่อเนื่องและ Final Project ที่ประกอบทุกส่วนเข้าด้วยกัน</p></div>
</div></section><p class="foot">Baseline: Flutter 3.41.7 · Dart 3.11.5 · เนื้อหาไทย</p></div><script src="assets/course.js"></script></body></html>
"@
[System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'home.html'), $homeHtml, $utf8)

Write-Output "Generated $($allLessons.Count) lessons across $($partsManifest.Count) parts"
