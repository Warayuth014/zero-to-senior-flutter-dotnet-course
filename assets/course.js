(function(){
const rows=[...document.querySelectorAll('.row')], checks=[...document.querySelectorAll('.ck')];
const frame=document.getElementById('frame'), title=document.getElementById('cur'), open=document.getElementById('open'), homeLink=document.getElementById('homeLink'), search=document.getElementById('search'), reset=document.getElementById('reset');
const done=document.getElementById('done'), total=document.getElementById('total'), pct=document.getElementById('pct');
const shell=document.querySelector('.shell'), sidebarToggle=document.getElementById('sidebarToggle');
const sidebar=document.querySelector('.side'), sidebarHotspot=document.getElementById('sidebarHotspot');
const filterControls=[...document.querySelectorAll('[data-filter]')];
const themeToggle=document.getElementById('themeToggle');
const storagePrefix='zts_flutter_dotnet_';
const key=id=>storagePrefix+'lesson_'+id;
const sidebarKey=storagePrefix+'sidebar_collapsed';
const sidebarWidthKey=storagePrefix+'sidebar_width';
const sidebarOpenPartKey=storagePrefix+'sidebar_open_part';
const currentLessonKey=storagePrefix+'current_lesson';
const courseIndexKey=storagePrefix+'course_index';
const recentLessonsKey=storagePrefix+'recent_lessons';
const themeKey=storagePrefix+'theme';
const lessonSearchIndex=window.COURSE_SEARCH_INDEX || {};
const rowSearchText=new Map(rows.map(row=>[
  row,
  (row.dataset.title+' '+row.dataset.part+' '+(lessonSearchIndex[row.dataset.id] || '')).toLocaleLowerCase()
]));

/* ---- ธีมสว่าง/มืด -------------------------------------------------------
   ทำงานทั้งในหน้า shell (index) และหน้าบทเรียนใน iframe — แต่ละหน้าตั้งธีมของ
   ตัวเองตอนโหลด ส่วนการกดสลับจะ sync ข้ามเฟรมให้ (ดู applyThemeToFrame) */
function savedTheme(){
  try {
    const value=localStorage.getItem(themeKey);
    return value === 'light' || value === 'dark' ? value : '';
  } catch { return ''; }
}
function preferredTheme(){
  return savedTheme()
    || (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
}
function applyTheme(mode,root=document.documentElement){
  if (root) root.setAttribute('data-theme',mode);
}
applyTheme(preferredTheme());

// Resolve the vendored highlight.js relative to this script, so it works from
// the index (root) and from lessons (nested) without a build step.
const courseScript=document.querySelector('script[src*="course.js"]');
const assetsBase=courseScript ? courseScript.src.replace(/course\.js(?:\?.*)?$/,'') : '';
function ensureHljs(cb){
  if (window.hljs) return cb();
  let s=document.querySelector('script[data-hljs]');
  if (s){ s.addEventListener('load',cb,{once:true}); s.addEventListener('error',cb,{once:true}); return; }
  s=document.createElement('script');
  s.dataset.hljs='1';
  s.src=assetsBase+'vendor/highlight.min.js';
  s.addEventListener('load',cb,{once:true});
  s.addEventListener('error',cb,{once:true});
  document.head.appendChild(s);
}

function escapeHtml(value){
  return value
    .replace(/&/g,'&amp;')
    .replace(/</g,'&lt;')
    .replace(/>/g,'&gt;');
}

function isLikelyCSharp(text){
  return /\b(using|namespace|public|private|protected|internal|class|record|interface|struct|enum|static|readonly|const|var|new|return|if|else|for|foreach|while|async|await|decimal|string|int|bool|DateTime|DateOnly|Guid|ControllerBase|IActionResult|ActionResult|Console)\b/.test(text);
}

function csharpTokenClass(token, prevChar, after, before){
  if (/^\/\//.test(token) || /^\/\*/.test(token)) return 'com';
  if (/^\[/.test(token)) return 'attr';
  if (/^\$?@?"/.test(token)) return 'str';
  if (/^\d/.test(token)) return 'num';
  if (/^(using|namespace|public|private|protected|internal|class|record|interface|struct|enum|static|readonly|const|var|new|return|if|else|for|foreach|while|switch|case|break|continue|async|await|try|catch|finally|throw|true|false|null|void|override|partial|this|base|get|set|init|params|out|ref|in|is|as|nameof|typeof|default|when|yield|from|where|select|join|equals|into|let|group|by|on|orderby)$/ .test(token)) return 'kw';
  if (/^(string|int|long|short|byte|decimal|double|float|bool|object|DateTime|DateOnly|TimeOnly|Guid|Task|ActionResult|IActionResult|List|Dictionary|IEnumerable|IReadOnlyList|ControllerBase|Console|Math|CancellationToken)$/ .test(token)) return 'type';
  // a PascalCase name right after "new" is a constructor/type, not a method
  if (/\bnew\s*$/.test(before) && /^[A-Z]/.test(token)) return 'cls';
  // identifier immediately followed by "(" => method call
  if (/^\s*\(/.test(after)) return 'meth';
  // member access ".Member" => property (light blue, like VS Code)
  if (prevChar === '.') return 'prop';
  // assignment / object-initializer target "Name = ..." (but not ==, =>) => property
  if (/^\s*=(?![=>])/.test(after)) return 'prop';
  // remaining PascalCase identifiers => types/classes (teal)
  if (/^[A-Z][A-Za-z0-9_]*$/.test(token)) return 'cls';
  return 'prop';
}

function highlightCSharp(text){
  // attribute regex: must not follow an identifier/")"/"]" (so array indexers like arr[i] are NOT styled as attributes),
  // and tolerates string args that contain "[" e.g. [Route("wms/[controller]")]
  const tokenPattern=/\/\/[^\n\r]*|\/\*[\s\S]*?\*\/|(?<![\w)\]])\[[A-Za-z_][\w.]*(?:\s*\([^)]*\))?\]|\$?@"(?:""|[^"])*"|\$?"(?:\\.|[^"\\])*"|\b\d+(?:\.\d+)?m?\b|\b[A-Za-z_][A-Za-z0-9_]*\b/g;
  let output='', lastIndex=0, match;

  while ((match=tokenPattern.exec(text)) !== null) {
    output += escapeHtml(text.slice(lastIndex, match.index));
    const token=match[0];
    const end=match.index+token.length;
    const prevChar=text.charAt(match.index-1);
    const after=text.slice(end, end+6);
    const before=text.slice(Math.max(0,match.index-6), match.index);
    output += `<span class="${csharpTokenClass(token, prevChar, after, before)}">${escapeHtml(token)}</span>`;
    lastIndex = end;
  }

  output += escapeHtml(text.slice(lastIndex));
  return output;
}

// Deterministic — no content "guessing" (that caused mis-highlighting).
// Priority: explicit author hint -> skip diagrams -> C# default for code blocks.
function detectLanguage(text, pre){
  const hint=(pre ? pre.className : '').match(/\blang-([a-z0-9]+)\b/);
  if (hint) return hint[1];           // e.g. class="code-vs lang-sql" / lang-json / lang-bash
  if (isDiagram(text)) return null;   // ASCII diagram / folder tree -> leave plain
  // This is a .NET course: every code-vs block is C# unless tagged otherwise above.
  if ((pre && pre.classList.contains('code-vs')) || isLikelyCSharp(text)) return 'csharp';
  return null;
}

// box-drawing chars => an ASCII diagram / folder tree, not real code: leave it plain
function isDiagram(text){
  return /[─-╿]/.test(text);
}

function highlightCodeBlocks(root=document){
  let needHljs=false;

  root.querySelectorAll('pre code').forEach(code=>{
    if (code.dataset.highlighted === '1') return;

    const text=code.textContent;
    code.dataset.copyText = text;
    const pre=code.closest('pre');
    const lang=detectLanguage(text, pre);

    if (!lang) { code.dataset.highlighted = '1'; return; }
    pre.classList.add('code-vs');

    if (!code.querySelector('span')) {
      if (lang === 'csharp') {
        // custom highlighter — colors types (teal), members/locals (light blue),
        // methods (yellow) to match VS Code's look as closely as a browser can
        code.innerHTML = highlightCSharp(text);
      } else if (window.hljs) {
        // explicitly tagged sql / json / bash -> highlight.js grammar
        try {
          code.innerHTML = window.hljs.highlight(text,{language:lang,ignoreIllegals:true}).value;
          code.classList.add('hljs');
        } catch {}
      } else {
        needHljs=true;          // load hljs, then re-process this block
        return;                 // (leave dataset.highlighted unset so the retry catches it)
      }
    }

    code.dataset.highlighted = '1';
  });

  addMiniExerciseLineNumbers(root);
  addCopyButtons(root);

  if (needHljs) ensureHljs(()=>highlightCodeBlocks(root));
}

function getCurrentLesson(){
  try {
    const raw=localStorage.getItem(currentLessonKey);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function rememberRecentLesson(lesson){
  if (!lesson || !lesson.id) return;

  try {
    const recent=JSON.parse(localStorage.getItem(recentLessonsKey) || '[]')
      .filter(item=>item.id !== lesson.id);
    recent.unshift(lesson);
    localStorage.setItem(recentLessonsKey,JSON.stringify(recent.slice(0,6)));
  } catch {}
}

function setCurrentLesson(row){
  if (!row) return;

  const lesson={
    id: row.dataset.id || '',
    title: row.dataset.title || '',
    part: row.dataset.part || '',
    href: row.getAttribute('href') || ''
  };

  localStorage.setItem(currentLessonKey,JSON.stringify(lesson));
  rememberRecentLesson(lesson);
}

function updateCurrentTrackCard(root=document){
  const card=root.querySelector('[data-current-track-card]');
  if (!card) return;

  const current=getCurrentLesson();
  if (!current || !current.id) return;

  const part=card.querySelector('[data-current-track-part]');
  const lesson=card.querySelector('[data-current-track-title]');
  const link=card.querySelector('[data-current-track-link]');

  card.href='index.html#'+encodeURIComponent(current.id);
  if (part && current.part) part.textContent=current.part;
  if (lesson && current.title) lesson.textContent=current.title;
  if (link) link.textContent='Continue current lesson';
}

function rowHrefForParent(row){
  const href=row.href || row.getAttribute?.('href') || '';
  return href ? 'index.html#'+encodeURIComponent(row.dataset.id || '') : 'index.html';
}

function updateLearningDashboard(root=document){
  const dashboard=root.querySelector('[data-dashboard]');
  if (!dashboard) return;

  const courseRows=getCourseRows();
  const totalLessons=courseRows.length;
  const doneCount=courseRows.filter(row=>localStorage.getItem(key(row.dataset.id)) === '1').length;
  const percent=totalLessons ? Math.round(doneCount*100/totalLessons) : 0;
  const current=getCurrentLesson();
  const currentIndex=current ? courseRows.findIndex(row=>row.dataset.id === current.id) : -1;
  const nextRow=courseRows.slice(Math.max(currentIndex+1,0)).find(row=>localStorage.getItem(key(row.dataset.id)) !== '1')
    || courseRows.find(row=>localStorage.getItem(key(row.dataset.id)) !== '1')
    || courseRows[currentIndex]
    || courseRows[0];

  const setText=(selector,value)=>{const el=root.querySelector(selector); if (el) el.textContent=value;};
  setText('[data-dashboard-done]',String(doneCount));
  setText('[data-dashboard-total]',String(totalLessons));
  setText('[data-dashboard-percent]',percent+'%');
  const bar=root.querySelector('[data-dashboard-bar]');
  if (bar) bar.style.width=percent+'%';

  const currentCard=root.querySelector('[data-current-track-card]');
  if (currentCard && current && current.id) {
    currentCard.href='index.html#'+encodeURIComponent(current.id);
    setText('[data-current-track-title]',current.title || 'Continue Learning');
    setText('[data-current-track-part]',current.part || '');
    setText('[data-current-track-link]','เรียนต่อ');
  }

  const nextCard=root.querySelector('[data-dashboard-next-card]');
  if (nextCard && nextRow) {
    nextCard.href='index.html#'+encodeURIComponent(nextRow.dataset.id);
    setText('[data-dashboard-next-title]',nextRow.dataset.title || 'บทถัดไป');
    setText('[data-dashboard-next-part]',nextRow.dataset.part || '');
  }

  const parts=root.querySelector('[data-dashboard-parts]');
  if (parts) {
    const groups=new Map();
    courseRows.forEach(row=>{
      const part=row.dataset.part || 'Other';
      if (!groups.has(part)) groups.set(part,[]);
      groups.get(part).push(row);
    });

    parts.innerHTML=[...groups.entries()].map(([part,items])=>{
      const completed=items.filter(row=>localStorage.getItem(key(row.dataset.id)) === '1').length;
      const partPercent=items.length ? Math.round(completed*100/items.length) : 0;
      const firstOpen=items.find(row=>localStorage.getItem(key(row.dataset.id)) !== '1') || items[0];
      return `<a class="part-progress-item" href="${rowHrefForParent(firstOpen)}" target="_parent">
        <strong>${escapeHtml(part)}</strong>
        <span>${completed}/${items.length} done</span>
        <em><i style="width:${partPercent}%"></i></em>
      </a>`;
    }).join('');
  }

  const recent=root.querySelector('[data-dashboard-recent]');
  if (recent) {
    let recentItems=[];
    try { recentItems=JSON.parse(localStorage.getItem(recentLessonsKey) || '[]'); } catch {}
    recent.innerHTML=(recentItems.length ? recentItems : (nextRow ? [{
      id: nextRow.dataset.id,
      title: nextRow.dataset.title,
      part: nextRow.dataset.part
    }] : [])).slice(0,4).map(item=>`<a href="index.html#${encodeURIComponent(item.id)}" target="_parent">
      <strong>${escapeHtml(item.title || 'Lesson')}</strong>
      <span>${escapeHtml(item.part || '')}</span>
    </a>`).join('');
  }
}

function getCourseRows(){
  // data-ref rows are reference/supplementary pages (e.g. flow walkthroughs), not counted lessons
  if (rows.length) return rows.filter(r=>!r.dataset.ref);

  try {
    if (parent && parent !== window) return [...parent.document.querySelectorAll('.row:not([data-ref])')];
  } catch {
    // Fall through to the cached course index for lessons opened in a new tab.
  }

  try {
    const cached=JSON.parse(localStorage.getItem(courseIndexKey) || '[]');
    return cached.map(item=>({
      dataset: {id:item.id || '', title:item.title || '', part:item.part || ''},
      href: item.href || '',
      getAttribute: name=>name === 'href' ? item.href || '' : null
    }));
  } catch {
    return [];
  }
}

function lessonIdFromPath(pathname=location.pathname){
  const file=(pathname.split('/').pop() || '').replace(/\.html$/,'');
  return file && file !== 'index' && file !== 'home' ? file : '';
}

function getActiveLessonId(ownerWindow=window){
  const hashId=decodeURIComponent((ownerWindow.location.hash || '').replace('#',''));
  return hashId || lessonIdFromPath(ownerWindow.location.pathname);
}

function setLessonDone(id,done){
  if (!id) return;
  done ? localStorage.setItem(key(id),'1') : localStorage.removeItem(key(id));
}

/* เฟส 3 — แถบความคืบหน้าการอ่าน + ปุ่มกลับขึ้นบน + สารบัญลอยข้างที่ไฮไลต์หัวข้อ
   ที่กำลังอ่าน · ฉีดเข้าหน้าบทเรียน (ทำงานทั้งใน iframe และเปิดแท็บใหม่) */
function enhanceLessonReading(root=document){
  const win=root.defaultView || window;
  const lesson=root.querySelector('.lesson');
  if (!lesson || root.getElementById('readingProgress')) return;

  const bar=root.createElement('div');
  bar.id='readingProgress';
  bar.className='reading-progress';
  bar.appendChild(root.createElement('i'));
  root.body.appendChild(bar);
  const fill=bar.firstElementChild;

  const toTop=root.createElement('button');
  toTop.type='button';
  toTop.className='back-to-top';
  toTop.textContent='↑';
  toTop.title='กลับขึ้นบนสุด';
  toTop.setAttribute('aria-label','กลับขึ้นบนสุด');
  toTop.addEventListener('click',()=>win.scrollTo({top:0,behavior:'smooth'}));
  root.body.appendChild(toTop);

  function onScroll(){
    const max=root.documentElement.scrollHeight - win.innerHeight;
    const ratio=max > 0 ? win.scrollY / max : 0;
    fill.style.width=Math.min(100,Math.max(0,ratio*100))+'%';
    toTop.classList.toggle('show',win.scrollY > 600);
  }
  win.addEventListener('scroll',onScroll,{passive:true});
  win.addEventListener('resize',onScroll);
  onScroll();

  // สารบัญลอยข้าง + ไฮไลต์หัวข้อปัจจุบัน
  const toc=[...lesson.children].find(child=>child.classList && child.classList.contains('toc'));
  const sections=[...lesson.querySelectorAll('section[id]')];
  if (!toc || !sections.length) return;

  lesson.classList.add('has-toc-rail');

  const links=new Map();
  toc.querySelectorAll('a[href^="#"]').forEach(link=>{
    links.set(decodeURIComponent(link.getAttribute('href').slice(1)),link);
  });
  if (!win.IntersectionObserver || !links.size) return;

  const visible=new Set();
  const observer=new win.IntersectionObserver(entries=>{
    entries.forEach(entry=>{
      entry.isIntersecting ? visible.add(entry.target.id) : visible.delete(entry.target.id);
    });
    // หัวข้อแรกที่มองเห็นตามลำดับเอกสาร = หัวข้อที่กำลังอ่าน
    const current=sections.find(section=>visible.has(section.id));
    links.forEach(link=>{
      link.classList.remove('active');
      if (link.parentElement) link.parentElement.classList.remove('active');
    });
    const active=current ? links.get(current.id) : null;
    if (active) {
      active.classList.add('active');
      if (active.parentElement) active.parentElement.classList.add('active');
    }
  },{rootMargin:'-80px 0px -70% 0px',threshold:0});
  sections.forEach(section=>observer.observe(section));
}

function injectLessonNav(root=document,currentId=getActiveLessonId()){
  const courseRows=getCourseRows();
  if (!courseRows.length || !currentId || root.getElementById('lessonNav')) return;

  const index=courseRows.findIndex(row=>row.dataset.id === currentId);
  if (index < 0) return;

  const row=courseRows[index];
  const previous=courseRows[index-1];
  const next=courseRows[index+1];
  const rowHref=row.href || row.getAttribute?.('href') || '';
  const partHref=rowHref ? rowHref.replace(/[^/\\]+\.html(?:.*)?$/,'index.html') : '#';
  const lesson=root.querySelector('.lesson');
  if (!lesson) return;

  const nav=root.createElement('nav');
  nav.id='lessonNav';
  nav.className='lesson-nav';
  nav.setAttribute('aria-label','Lesson navigation');
  nav.innerHTML=`
    <a class="lesson-nav-button ${previous ? '' : 'disabled'}" href="${previous ? previous.href : '#'}" data-nav-id="${previous ? previous.dataset.id : ''}" ${previous ? '' : 'aria-disabled="true" tabindex="-1"'}>Previous</a>
    <button class="lesson-nav-button done-next" type="button" data-nav-id="${row.dataset.id}" data-next-id="${next ? next.dataset.id : ''}">Mark Done${next ? ' & Next' : ''}</button>
    <a class="lesson-nav-button" href="${partHref}">Part Index</a>
    <a class="lesson-nav-button ${next ? '' : 'disabled'}" href="${next ? next.href : '#'}" data-nav-id="${next ? next.dataset.id : ''}" ${next ? '' : 'aria-disabled="true" tabindex="-1"'}>Next</a>
  `;

  nav.addEventListener('click',event=>{
    const targetWindow=root.defaultView || window;
    const button=event.target.closest('[data-nav-id]');
    if (!button) return;

    const navId=button.dataset.navId;
    const nextId=button.dataset.nextId;
    if (!navId) return;

    event.preventDefault();

    if (button.classList.contains('done-next')) {
      setLessonDone(navId,true);

      try {
        if (targetWindow.parent && targetWindow.parent !== targetWindow && targetWindow.parent.markLessonDone) {
          targetWindow.parent.markLessonDone(navId);
        }
      } catch {}

      if (nextId) {
        try {
          if (targetWindow.parent && targetWindow.parent !== targetWindow) {
            targetWindow.parent.location.hash=nextId;
            return;
          }
        } catch {}

        const nextRow=courseRows.find(item=>item.dataset.id === nextId);
        if (nextRow) targetWindow.location.href=nextRow.href;
      }

      button.textContent='Done';
      return;
    }

    try {
      if (targetWindow.parent && targetWindow.parent !== targetWindow) {
        targetWindow.parent.location.hash=navId;
        return;
      }
    } catch {}

    targetWindow.location.href=button.getAttribute('href');
  });

  lesson.appendChild(nav);
}

function stripExplicitLineNumbers(text){
  const normalized=text.replace(/\r\n/g,'\n');
  const lines=normalized.split('\n');
  const meaningful=lines.filter(line=>line.trim().length>0);
  const numbered=meaningful.filter(line=>/^\s*\d{2,4}(?:\s|$)/.test(line));

  if (meaningful.length > 0 && numbered.length / meaningful.length >= 0.6) {
    return lines.map(line=>line.replace(/^\s*\d{2,4}\s?/,'')).join('\n');
  }

  return normalized;
}

function copyToClipboard(text, ownerDocument){
  if (navigator.clipboard && navigator.clipboard.writeText) {
    return navigator.clipboard.writeText(text).catch(()=>fallbackCopy(text, ownerDocument));
  }

  return fallbackCopy(text, ownerDocument);
}

function fallbackCopy(text, ownerDocument){
  const textarea=ownerDocument.createElement('textarea');
  textarea.value=text;
  textarea.setAttribute('readonly','');
  textarea.style.position='fixed';
  textarea.style.left='-9999px';
  textarea.style.top='0';
  ownerDocument.body.appendChild(textarea);
  textarea.select();
  ownerDocument.execCommand('copy');
  textarea.remove();
  return Promise.resolve();
}

function addCopyButtons(root=document){
  root.querySelectorAll('pre.code-vs').forEach(pre=>{
    if (pre.dataset.copyReady === '1') return;

    const code=pre.querySelector('code');
    if (!code) return;

    const button=root.createElement('button');
    button.type='button';
    button.className='copy-code-button';
    button.textContent='Copy';
    button.setAttribute('aria-label','Copy code');

    button.addEventListener('click',async()=>{
      const text=stripExplicitLineNumbers(code.dataset.copyText || code.textContent);

      try {
        await copyToClipboard(text, root);
        button.textContent='Copied';
        button.classList.add('copied');
        setTimeout(()=>{
          button.textContent='Copy';
          button.classList.remove('copied');
        },1200);
      } catch {
        button.textContent='Failed';
        setTimeout(()=>{ button.textContent='Copy'; },1200);
      }
    });

    pre.classList.add('has-copy');
    pre.appendChild(button);
    pre.dataset.copyReady = '1';
  });
}

function addMiniExerciseLineNumbers(root=document){
  root.querySelectorAll('#mini-exercise pre.code-vs code').forEach(code=>{
    if (code.dataset.lineNumbered === '1') return;

    const pre=code.closest('pre');
    const rawText=code.textContent.replace(/\r\n/g,'\n');
    const firstMeaningfulLine=rawText.split('\n').find(line=>line.trim().length>0) || '';

    // Some newer lessons already include explicit line numbers in the snippet.
    if (/^\s*\d{2}\s/.test(firstMeaningfulLine)) {
      code.dataset.lineNumbered = '1';
      return;
    }

    const lines=code.innerHTML.replace(/\r\n/g,'\n').split('\n');
    const width=Math.max(2,String(lines.length).length);

    code.innerHTML=lines.map((line,index)=>{
      const number=String(index+1).padStart(width,'0');
      const content=line.length ? line : ' ';
      return `<span class="code-line" data-line="${number}"><span class="line-code">${content}</span></span>`;
    }).join('');

    if (pre) pre.classList.add('line-numbered');
    code.dataset.lineNumbered = '1';
  });
}

window.highlightCodeBlocks = highlightCodeBlocks;
highlightCodeBlocks(document);
updateCurrentTrackCard(document);
updateLearningDashboard(document);
injectLessonNav(document);
enhanceLessonReading(document);

// When this page runs inside the viewer's iframe, tell the parent shell which lesson is
// showing so it can sync the header title / active row — regardless of how we got here
// (Next/Prev/Mark-Done link, hash change, or a direct iframe navigation).
if (window.parent && window.parent !== window) {
  const lessonId=lessonIdFromPath(location.pathname);
  if (lessonId) {
    try { window.parent.postMessage({type:'zts-lesson',id:lessonId},'*'); } catch {}
  }
  // รับคำสั่งสลับธีมจาก shell (เผื่อ localStorage ข้ามเฟรมไม่ถึงกัน)
  window.addEventListener('message',event=>{
    const data=event.data;
    if (data && data.type === 'zts-theme' && (data.mode === 'light' || data.mode === 'dark')) {
      applyTheme(data.mode);
    }
  });
}

if(frame){
  frame.addEventListener('load',()=>{
    try {
      // the lesson page loads course.js itself and highlights its own code;
      // here we only refresh the parent-driven UI bits
      updateCurrentTrackCard(frame.contentDocument);
      updateLearningDashboard(frame.contentDocument);
      injectLessonNav(frame.contentDocument,lessonIdFromPath(frame.contentWindow.location.pathname));
      enhanceLessonReading(frame.contentDocument);
    } catch {
      // Lesson pages are local same-origin in normal use. Ignore if a browser blocks iframe access.
    }
  });
}

if(shell && sidebarToggle){
  function setSidebarCollapsed(collapsed){
    shell.classList.remove('sidebar-hover-open');
    shell.classList.toggle('sidebar-collapsed',collapsed);
    sidebarToggle.textContent = collapsed ? 'แสดงเมนู' : 'ซ่อนเมนู';
    sidebarToggle.setAttribute('aria-expanded',String(!collapsed));
    localStorage.setItem(sidebarKey,collapsed?'1':'0');
  }

  setSidebarCollapsed(localStorage.getItem(sidebarKey)==='1');
  sidebarToggle.addEventListener('click',()=>setSidebarCollapsed(!shell.classList.contains('sidebar-collapsed')));

  /* ลากขอบเมนูเพื่อปรับความกว้าง (จำค่าไว้) */
  const SIDEBAR_MIN=260, SIDEBAR_MAX=560;
  function setSidebarWidth(px){
    const width=Math.round(Math.min(SIDEBAR_MAX,Math.max(SIDEBAR_MIN,px)));
    shell.style.setProperty('--sidebar-w',width+'px');
    return width;
  }
  const storedWidth=parseInt(localStorage.getItem(sidebarWidthKey) || '',10);
  if (storedWidth) setSidebarWidth(storedWidth);

  const resizer=document.createElement('div');
  resizer.className='sidebar-resizer';
  resizer.setAttribute('role','separator');
  resizer.setAttribute('aria-orientation','vertical');
  resizer.setAttribute('aria-label','ปรับความกว้างเมนู');
  resizer.title='ลากเพื่อปรับความกว้าง (ดับเบิลคลิก = ค่าเริ่มต้น)';
  shell.appendChild(resizer);

  resizer.addEventListener('pointerdown',event=>{
    if (shell.classList.contains('sidebar-collapsed')) return;
    event.preventDefault();
    shell.classList.add('resizing');
    resizer.setPointerCapture(event.pointerId);

    const move=e=>setSidebarWidth(e.clientX - shell.getBoundingClientRect().left);
    const up=()=>{
      shell.classList.remove('resizing');
      resizer.removeEventListener('pointermove',move);
      resizer.removeEventListener('pointerup',up);
      resizer.removeEventListener('pointercancel',up);
      const current=parseInt(shell.style.getPropertyValue('--sidebar-w'),10);
      if (current) localStorage.setItem(sidebarWidthKey,String(current));
    };
    resizer.addEventListener('pointermove',move);
    resizer.addEventListener('pointerup',up);
    resizer.addEventListener('pointercancel',up);
  });

  resizer.addEventListener('dblclick',()=>{
    setSidebarWidth(360);
    localStorage.setItem(sidebarWidthKey,'360');
  });

  if(sidebar && sidebarHotspot){
    sidebarHotspot.addEventListener('mouseenter',()=>{
      if (shell.classList.contains('sidebar-collapsed')) {
        shell.classList.add('sidebar-hover-open');
        sidebarToggle.setAttribute('aria-expanded','true');
      }
    });

    sidebar.addEventListener('mouseleave',()=>{
      if (shell.classList.contains('sidebar-collapsed')) {
        shell.classList.remove('sidebar-hover-open');
        sidebarToggle.setAttribute('aria-expanded','false');
      }
    });
  }
}

if(rows.length && frame && title && open && search && reset && done && total && pct){
  let currentFilter='all';
  let syncingPartOpen=false;

  localStorage.setItem(courseIndexKey,JSON.stringify(rows.filter(row=>!row.dataset.ref).map(row=>({
    id: row.dataset.id || '',
    title: row.dataset.title || '',
    part: row.dataset.part || '',
    href: row.href
  }))));

  const resolvedHomeLink = homeLink || (() => {
    const link=document.createElement('a');
    link.id='homeLink';
    link.className='btn';
    link.href='home.html';
    link.target='frame';
    link.textContent='Home';
    title.parentNode.insertBefore(link,title);
    return link;
  })();

  function loadHome(){
    frame.src='home.html';
    title.textContent='Home';
    open.href='home.html';
    rows.forEach(row=>row.classList.remove('active','next'));
    updateSidebarState();
    applySidebarFilters();
    history.replaceState(null,'',location.pathname);
  }

  // breadcrumb: "Part 12 › 12.20 ..." (ย่อชื่อ Part ให้พอดีแถบบน)
  function setTitleFromRow(row){
    const part=(row.dataset.part || '').match(/^Part\s+[-\d.]+/);
    title.textContent='';
    if (part) {
      const partEl=document.createElement('span');
      partEl.className='crumb-part';
      partEl.textContent=part[0];
      const sep=document.createElement('span');
      sep.className='crumb-sep';
      sep.textContent='›';
      title.append(partEl,sep);
    }
    title.append(document.createTextNode(row.dataset.title || ''));
    title.title=[row.dataset.part,row.dataset.title].filter(Boolean).join(' › ');
  }

  function loadRow(row){
    frame.src=row.href;
    setTitleFromRow(row);
    open.href=row.href;
    setCurrentLesson(row);
    rows.forEach(item=>item.classList.toggle('active',item === row));
    updateSidebarState(row);
    applySidebarFilters();
    history.replaceState(null,'','#'+row.dataset.id);
    scrollActiveRowIntoView();
  }

  function findRowByUrl(url){
    return rows.find(row=>{
      try {
        return new URL(row.getAttribute('href'),location.href).href === url;
      } catch {
        return false;
      }
    });
  }

  function syncFromFrame(){
    let frameUrl;

    try {
      frameUrl=frame.contentWindow.location.href;
    } catch {
      return;
    }

    if (frameUrl === new URL('home.html',location.href).href) {
      title.textContent='Home';
      open.href='home.html';
      rows.forEach(row=>row.classList.remove('active','next'));
      updateSidebarState();
      applySidebarFilters();
      history.replaceState(null,'',location.pathname);
      return;
    }

    const row=findRowByUrl(frameUrl);
    if (!row) return;

    setTitleFromRow(row);
    open.href=row.href;
    setCurrentLesson(row);
    rows.forEach(item=>item.classList.toggle('active',item === row));
    updateSidebarState(row);
    applySidebarFilters();
    history.replaceState(null,'','#'+row.dataset.id);
  }

  function loadFromHash(){
    const id=decodeURIComponent(location.hash.replace('#',''));
    const row=id ? document.querySelector('.row[data-id="'+id+'"]') : null;

    if (row) {
      loadRow(row);
    } else {
      loadHome();
    }
  }

  function updatePartProgress(){
    document.querySelectorAll('.part').forEach(part=>{
      const partChecks=[...part.querySelectorAll('.ck')];
      const summary=part.querySelector('summary');
      const small=summary?.querySelector('small');
      if (!partChecks.length || !small) return;

      if (!small.dataset.baseText) small.dataset.baseText=small.textContent;
      const completed=partChecks.filter(c=>c.checked).length;
      small.textContent=`${completed}/${partChecks.length} done`;
    });
  }

  function updateSidebarState(activeRow=rows.find(row=>row.classList.contains('active'))){
    rows.forEach(row=>row.classList.toggle('done',localStorage.getItem(key(row.dataset.id)) === '1'));

    const startIndex=activeRow ? rows.indexOf(activeRow)+1 : 0;
    const nextRow=rows.slice(startIndex).find(row=>localStorage.getItem(key(row.dataset.id)) !== '1')
      || rows.find(row=>localStorage.getItem(key(row.dataset.id)) !== '1');
    rows.forEach(row=>row.classList.toggle('next',row === nextRow && row !== activeRow));
  }

  function scrollActiveRowIntoView(){
    if (!sidebar) return;
    const active=rows.find(row=>row.classList.contains('active'));
    if (!active) return;

    // make sure the lesson's part is expanded before measuring
    const part=active.closest('.part');
    if (part && !part.open) part.open=true;

    requestAnimationFrame(()=>{
      if (active.classList.contains('hide')) return;
      const sideRect=sidebar.getBoundingClientRect();
      const rowRect=active.getBoundingClientRect();
      // center the active row within the sidebar viewport
      const delta=(rowRect.top - sideRect.top) - (sidebar.clientHeight/2 - rowRect.height/2);
      sidebar.scrollTop += delta;
    });
  }

  function partStorageId(part){
    return part.querySelector('.row')?.dataset.part || part.querySelector('summary')?.textContent.trim() || '';
  }

  function setPartOpen(part,open){
    syncingPartOpen=true;
    part.dataset.skipOpenMemory='1';
    part.open=open;
    setTimeout(()=>delete part.dataset.skipOpenMemory,150);
    syncingPartOpen=false;
  }

  function restoreSidebarOpenPart(){
    const savedPart=localStorage.getItem(sidebarOpenPartKey) || '';

    syncingPartOpen=true;
    document.querySelectorAll('.part').forEach(part=>{
      part.dataset.skipOpenMemory='1';
      part.open = savedPart ? partStorageId(part) === savedPart : false;
      setTimeout(()=>delete part.dataset.skipOpenMemory,150);
    });
    syncingPartOpen=false;
  }

  function rememberSidebarOpenPart(part){
    if (syncingPartOpen || part.dataset.skipOpenMemory === '1') return;

    const partId=partStorageId(part);
    if (!partId) return;

    if (part.open) {
      localStorage.setItem(sidebarOpenPartKey,partId);
      syncingPartOpen=true;
      document.querySelectorAll('.part').forEach(item=>{
        if (item !== part) item.open=false;
      });
      syncingPartOpen=false;
    } else if (localStorage.getItem(sidebarOpenPartKey) === partId) {
      localStorage.removeItem(sidebarOpenPartKey);
    }
  }

  function initSidebarOpenMemory(){
    document.querySelectorAll('.part').forEach(part=>{
      part.addEventListener('toggle',()=>rememberSidebarOpenPart(part));
    });
    restoreSidebarOpenPart();
  }

  function applySidebarFilters(){
    const searchTerms=search.value.toLocaleLowerCase().trim().split(/\s+/).filter(Boolean);
    const activePart=rows.find(row=>row.classList.contains('active'))?.dataset.part || '';
    const shouldTemporarilyOpen=searchTerms.length > 0 || currentFilter !== 'all';

    rows.forEach(row=>{
      const searchableText=rowSearchText.get(row) || '';
      const matchesSearch=searchTerms.every(term=>searchableText.includes(term));
      const isDone=localStorage.getItem(key(row.dataset.id)) === '1';
      const matchesFilter=currentFilter === 'all'
        || (currentFilter === 'todo' && !isDone)
        || (currentFilter === 'done' && isDone)
        || (currentFilter === 'current' && (!activePart || row.dataset.part === activePart));
      row.classList.toggle('hide',!(matchesSearch && matchesFilter));
    });

    document.querySelectorAll('.part').forEach(part=>{
      const visible=[...part.querySelectorAll('.row')].some(row=>!row.classList.contains('hide'));
      part.classList.toggle('hide',!visible);
      if (shouldTemporarilyOpen && visible) setPartOpen(part,true);
    });

    if (!shouldTemporarilyOpen) restoreSidebarOpenPart();
  }

  function stats(){let d=checks.filter(c=>c.checked).length,t=checks.length;done.textContent=d;total.textContent=t;pct.textContent=t?Math.round(d*100/t)+'%':'0%';updatePartProgress();updateSidebarState();applySidebarFilters()}
  window.markLessonDone=id=>{
    setLessonDone(id,true);
    const checkbox=document.querySelector('.ck[data-id="'+id+'"]');
    if (checkbox) checkbox.checked=true;
    stats();
  };
  checks.forEach(c=>{c.checked=localStorage.getItem(key(c.dataset.id))==='1';c.onclick=e=>e.stopPropagation();c.onchange=()=>{c.checked?localStorage.setItem(key(c.dataset.id),'1'):localStorage.removeItem(key(c.dataset.id));stats()}});
  rows.forEach(r=>r.onclick=e=>{if(e.target.classList.contains('ck'))return;e.preventDefault();loadRow(r)});
  // ธีม: sync เข้า iframe ทุกครั้งที่โหลด + ปุ่มสลับบนแถบบน
  function applyThemeToFrame(mode){
    try { applyTheme(mode,frame.contentDocument.documentElement); } catch {}
    try { frame.contentWindow.postMessage({type:'zts-theme',mode},'*'); } catch {}
  }
  function currentTheme(){
    return document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
  }
  function syncThemeButton(){
    if (!themeToggle) return;
    const light=currentTheme() === 'light';
    themeToggle.textContent=light ? '🌙' : '☀️';
    themeToggle.title=light ? 'สลับเป็นโหมดมืด' : 'สลับเป็นโหมดสว่าง';
    themeToggle.setAttribute('aria-label',themeToggle.title);
  }
  if (themeToggle) {
    syncThemeButton();
    themeToggle.addEventListener('click',()=>{
      const mode=currentTheme() === 'light' ? 'dark' : 'light';
      applyTheme(mode);
      try { localStorage.setItem(themeKey,mode); } catch {}
      syncThemeButton();
      applyThemeToFrame(mode);
    });
  }
  frame.addEventListener('load',()=>applyThemeToFrame(currentTheme()));

  frame.addEventListener('load',syncFromFrame);
  window.addEventListener('hashchange',loadFromHash);
  // Lesson pages announce themselves on load (see announce block below). This keeps the
  // header/sidebar in sync even when reading the iframe URL fails (e.g. Next navigates the
  // iframe itself and the frame URL can't be read to match a row).
  window.addEventListener('message',event=>{
    const data=event.data;
    if (!data || data.type !== 'zts-lesson' || !data.id) return;
    const row=rows.find(item=>item.dataset.id === data.id);
    if (!row) return;
    setTitleFromRow(row);
    open.href=row.href;
    setCurrentLesson(row);
    rows.forEach(item=>item.classList.toggle('active',item === row));
    updateSidebarState(row);
    applySidebarFilters();
    history.replaceState(null,'','#'+row.dataset.id);
    scrollActiveRowIntoView();
  });
  resolvedHomeLink.addEventListener('click',e=>{e.preventDefault();loadHome()})
  search.oninput=applySidebarFilters;
  filterControls.forEach(button=>button.addEventListener('click',()=>{
    currentFilter=button.dataset.filter || 'all';
    filterControls.forEach(item=>item.classList.toggle('active',item === button));
    applySidebarFilters();
  }));
  reset.onclick=()=>{if(confirm('ล้างสถานะเรียนจบทั้งหมด?')){checks.forEach(c=>{c.checked=false;localStorage.removeItem(key(c.dataset.id))});stats()}};
  initSidebarOpenMemory();
  stats();
  loadFromHash();
  // after a refresh, bring the open lesson back into view instead of resetting to the top
  scrollActiveRowIntoView();
}
})();
