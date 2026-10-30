/* ᄉᆡ미 기픈 믈 — 수능 국어 개념서 */
(function(){
'use strict';
const BOOK = window.BOOK || [], KICHUL = window.KICHUL || {}, PASSAGES = window.PASSAGES || {};
const CIRCLED = ['', '①', '②', '③', '④', '⑤'];
const PART_INFO = {
  '언어(문법)':     {slug: 'lang', color: 'var(--p-lang)', note: '2028 수능 · 화법과 언어'},
  '문학':           {slug: 'lit',  color: 'var(--p-lit)',  note: '2028 수능 · 문학'},
  '독서':           {slug: 'read', color: 'var(--p-read)', note: '2028 수능 · 독서와 작문'},
  '화법·작문·매체': {slug: 'sw',   color: 'var(--p-sw)',   note: '2028 수능 · 화법과 언어 · 독서와 작문'}
};
const STEPS = [
  {key: 'core',  name: '핵심'},
  {key: 'more',  name: '설명'},
  {key: 'ex',    name: '예문'},
  {key: 'trap',  name: '함정'},
  {key: 'exam',  name: '기출'}
];
const $ = s => document.querySelector(s);
const main = $('#main'), side = $('#side'), q = $('#q'), gnav = $('#gnav');

/* ---------- 저장 ---------- */
const store = {
  get(k, d){ try{ const v = localStorage.getItem('smgm:' + k); return v ? JSON.parse(v) : d; }catch(e){ return d; } },
  set(k, v){ try{ localStorage.setItem('smgm:' + k, JSON.stringify(v)); }catch(e){} }
};
let done = store.get('done', {});
let solved = store.get('solved', {});
let seen = store.get('seen', {});        // 개념별로 지나간 단계 {id: [0,1,...]}
let checks = store.get('checks', {});    // 함정 확인 {id: [i,...]}
let marks = store.get('marks', {});      // 형광펜 {id: ['낱말',...]}

/* ---------- 색인 ---------- */
const concepts = [], parts = [];
BOOK.forEach(ch => {
  let p = parts.find(x => x.name === ch.part);
  if(!p){ p = {name: ch.part, chapters: [], info: PART_INFO[ch.part] || {slug: 'p' + parts.length, color: 'var(--blue)', note: ''}}; parts.push(p); }
  p.chapters.push(ch);
  ch.partObj = p;
  ch.concepts.forEach(c => { c.chapter = ch; concepts.push(c); });
});
const byId = new Map(concepts.map((c, i) => [c.id, i]));
const pad = n => String(n).padStart(2, '0');

/* ---------- 개념끼리 잇기: 제목에서 낱말을 뽑아 다른 개념 글 속에서 찾음 ---------- */
const STOP = new Set(['개념','특징','방법','구성','갈래','흐름','구별','읽기','기능','관계','표현','변화','특성','원리','이해','종류','유형','심화','핵심','감상','문항','접근','적용','체계','구조','요소','전략','태도','정서','그리고','맥락','상황','의미','국어','자료','시대','작품','인물','대화','말투','갈등','주제','정보','배경','소재','공간','시간','장면','어휘','단어','문장','글쓰기','내용','과정','결과','사례','관점','견해','신뢰성','적절성','읽는 법']);
const termOf = new Map();   // 낱말 → 개념 id
/* 우선순위: 제목 전체와 같음(3) > 제목이 그 낱말로 시작함(2) > 제목을 나눈 조각(1). 같으면 앞 개념 */
const termScore = new Map();
const putTerm = (t, id, sc) => { if(t.length < 2 || STOP.has(t)) return; if((termScore.get(t) || 0) < sc){ termScore.set(t, sc); termOf.set(t, id); } };
concepts.forEach(c => {
  const base = c.title.split(/[:(]/)[0].trim();
  putTerm(base, c.id, 3);
  base.split(/[·,]|와 |과 |및 |, /).map(s => s.trim().replace(/[①-⑳]/g, '').trim()).forEach(t => putTerm(t, c.id, 1));
});
[...termOf.keys()].forEach(t => {
  const owner = concepts.find(c => c.title.startsWith(t) && c.title !== t);
  if(owner && (termScore.get(t) || 0) < 2){ termScore.set(t, 2); termOf.set(t, owner.id); }
});
const TERMS = [...termOf.keys()].sort((a, b) => b.length - a.length);
const TERM_RE = TERMS.length ? new RegExp('(?<![가-힣])(' + TERMS.map(t => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|') + ')', 'g') : null;
const outLinks = new Map(), inLinks = new Map();
concepts.forEach(c => { outLinks.set(c.id, new Set()); inLinks.set(c.id, new Set()); });
if(TERM_RE) concepts.forEach(c => {
  const text = [c.summary, JSON.stringify(c.body || []), JSON.stringify(c.examples || []), JSON.stringify(c.traps || [])].join(' ').replace(/\*\*/g, '');
  for(const m of text.matchAll(TERM_RE)){
    const t = termOf.get(m[1]);
    if(t && t !== c.id){ outLinks.get(c.id).add(t); inLinks.get(t).add(c.id); }
  }
});
/* 기출 → 그 기출을 쓰는 개념들 */
const itemConcepts = new Map();
concepts.forEach(c => (c.kichul || []).forEach(k => { if(!itemConcepts.has(k)) itemConcepts.set(k, []); itemConcepts.get(k).push(c.id); }));

/* ---------- 글자 ---------- */
function esc(s){
  const h = String(s ?? '')
    .replace(/[가-힣](?=[ᅠ-ᇿힰ-퟿])/g, c => c.normalize('NFD'))
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  return /[﷐-﷓]/.test(h) ? markup(h) : h;
}
/* 원본 문제지의 밑줄(U+FDD0…FDD1)·글자 상자(U+FDD2…FDD3) */
function markup(h){
  let out = '', u = false, b = false;
  for(const c of h){
    if(c === '﷐'){ if(!u){ out += '<u class="ul">'; u = true; } }
    else if(c === '﷑'){ if(u){ out += '</u>'; u = false; } }
    else if(c === '﷒'){ if(!b){ out += '<span class="bx">'; b = true; } }
    else if(c === '﷓'){ if(b){ if(u){ out += '</u>'; u = false; } out += '</span>'; b = false; } }
    else out += c;
  }
  return out + (u ? '</u>' : '') + (b ? '</span>' : '');
}
function plain(s){ return String(s ?? '').replace(/[﷐-﷓]/g, ''); }
function rich(s){ return esc(s).replace(/\*\*(.+?)\*\*/g, '<strong class="term">$1</strong>'); }
const examName = it => it.exam.replace('학년도 ', ' ').replace('대학수학능력시험', '수능').replace('모의평가', '모평');
const firstSentence = s => { const t = plain(s).replace(/\*\*/g, ''); const m = /^(.+?[.다요])(\s|$)/.exec(t); return m ? m[1] : t; };

/* 그려진 글 속 낱말을 다른 개념으로 잇기(개념마다 처음 한 번만) */
function linkTerms(root, selfId){
  if(!TERM_RE) return;
  const used = new Set([selfId]);
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode: n => n.parentElement.closest('a,button,th,.ex .e,.no-link') ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT
  });
  const nodes = []; while(walker.nextNode()) nodes.push(walker.currentNode);
  nodes.forEach(n => {
    const s = n.nodeValue; TERM_RE.lastIndex = 0;
    let m, last = 0, frag = null;
    while((m = TERM_RE.exec(s))){
      const id = termOf.get(m[1]);
      if(!id || used.has(id)) continue;
      used.add(id);
      frag = frag || document.createDocumentFragment();
      frag.append(s.slice(last, m.index));
      const a = document.createElement('a');
      a.href = '#/c/' + id; a.className = 'xref'; a.dataset.id = id; a.textContent = m[1];
      frag.append(a);
      last = m.index + m[1].length;
    }
    if(frag){ frag.append(s.slice(last)); n.replaceWith(frag); }
  });
}

/* ---------- 미리 보기 카드(낱말에 커서를 올리면) ---------- */
const peek = document.createElement('div');
peek.className = 'peek'; peek.hidden = true; document.body.append(peek);
let peekT;
function showPeek(a){
  const c = concepts[byId.get(a.dataset.id)]; if(!c) return;
  peek.innerHTML = `<div class="peek-k">${esc(c.chapter.chapter)}${done[c.id] ? ' · <b>이해함</b>' : ''}</div><div class="peek-t">${esc(c.title)}</div><p>${esc(firstSentence(c.summary))}</p><span class="peek-go">눌러서 이 개념으로 ›</span>`;
  peek.hidden = false;
  const r = a.getBoundingClientRect(), w = Math.min(320, innerWidth - 24);
  peek.style.width = w + 'px';
  let x = Math.min(Math.max(12, r.left + r.width / 2 - w / 2), innerWidth - w - 12);
  let y = r.bottom + 10;
  peek.style.left = x + 'px'; peek.style.top = y + 'px';
  const ph = peek.offsetHeight;
  if(y + ph > innerHeight - 12){ peek.style.top = (r.top - ph - 10) + 'px'; }
  requestAnimationFrame(() => peek.classList.add('on'));
}
function hidePeek(){ peek.classList.remove('on'); peek.hidden = true; }
document.addEventListener('pointerover', e => {
  if(e.pointerType !== 'mouse') return;
  const a = e.target.closest('a.xref, a.chip-c');
  clearTimeout(peekT);
  if(a) peekT = setTimeout(() => showPeek(a), 180); else hidePeek();
});
addEventListener('scroll', hidePeek, {passive: true});

/* ---------- 머리·목차 ---------- */
function renderNav(active){
  gnav.innerHTML = parts.map(p => `<a href="#/p/${p.info.slug}" class="${active === p ? 'on' : ''}">${esc(p.name)}</a>`).join('');
}
function renderToc(){
  let h = '';
  parts.forEach(p => {
    h += `<div class="toc-part">${esc(p.name)}</div>`;
    p.chapters.forEach(ch => {
      const n = ch.concepts.filter(c => done[c.id]).length;
      h += `<details class="toc-ch" data-ch="${ch.id}"><summary><span>${esc(ch.chapter)}</span><span class="cnt">${n}/${ch.concepts.length}</span></summary><ul>`;
      ch.concepts.forEach(c => {
        h += `<li><a href="#/c/${c.id}" data-id="${c.id}" class="${done[c.id] ? 'done' : ''}"><span class="dot"></span><span>${esc(c.title)}</span></a></li>`;
      });
      h += '</ul></details>';
    });
  });
  side.innerHTML = h;
}
function markToc(id){
  side.querySelectorAll('a.on').forEach(a => a.classList.remove('on'));
  if(!id) return;
  const a = side.querySelector(`a[data-id="${id}"]`);
  if(a){
    a.classList.add('on');
    a.closest('details').open = true;
    const r = a.getBoundingClientRect(), sr = side.getBoundingClientRect();
    if(r.top < sr.top || r.bottom > sr.bottom) a.scrollIntoView({block: 'center'});
  }
}
function setPage(kind, title){
  document.body.classList.toggle('home', kind === 'home');
  document.title = title ? `${title} — ᄉᆡ미 기픈 믈` : 'ᄉᆡ미 기픈 믈 — 수능 국어 개념서';
}

/* ---------- 첫 화면 ---------- */
function renderHome(){
  const total = concepts.length, nDone = concepts.filter(c => done[c.id]).length;
  const nEx = concepts.reduce((a, c) => a + (c.examples || []).length, 0);
  const last = store.get('last', null);
  const lastC = last && byId.has(last) ? concepts[byId.get(last)] : null;
  let h = `<section class="hero"><div class="hero-in">
      <div class="eyebrow">수능 국어 개념서</div>
      <h1>ᄉᆡ미 기픈 믈</h1>
      <p class="lead">깊이 판 개념은 마르지 않습니다.<br>핵심 → 설명 → 예문 → 함정 → 기출, 다섯 걸음이면 한 개념이 끝납니다.</p>
      <div class="cta">
        ${lastC ? `<a class="btn primary" href="#/c/${lastC.id}">이어서 공부하기</a><a class="btn ghost" href="#/c/${lastC.id}">${esc(lastC.title)} ›</a>` : `<a class="btn primary" href="#/c/${concepts[0] ? concepts[0].id : ''}">시작하기</a>`}
        <a class="btn ghost" href="#/p/${parts[0] ? parts[0].info.slug : ''}">목차 보기 ›</a>
      </div>
      <div class="stats">
        <div><b>${total}</b><span>개념</span></div>
        <div><b>${nEx}</b><span>예문</span></div>
        <div><b>${Object.keys(KICHUL).length}</b><span>평가원 기출</span></div>
        <div><b>${nDone}</b><span>이해한 개념</span></div>
      </div>
  </div></section>`;
  h += `<section class="home-sec"><div class="sec-title"><h2>영역</h2></div><div class="parts">`;
  parts.forEach(p => {
    const cs = p.chapters.flatMap(ch => ch.concepts);
    const d = cs.filter(c => done[c.id]).length;
    h += `<a class="part-tile" href="#/p/${p.info.slug}" style="--pc:${p.info.color}">
      <span class="k">${esc(p.info.note)}</span>
      <h3>${esc(p.name)}</h3>
      <span class="meta">장 ${p.chapters.length}개 · 개념 ${cs.length}개</span>
      <ol>${p.chapters.map(ch => `<li>${esc(ch.chapter)}</li>`).join('')}</ol>
      <div class="prog"><span>진도</span><span>${d} / ${cs.length}</span></div>
      <div class="bar"><i style="width:${cs.length ? Math.round(d / cs.length * 100) : 0}%"></i></div>
      <span class="more">살펴보기 ›</span>
    </a>`;
  });
  h += `</div></section>`;
  h += `<section class="home-sec"><div class="sec-title"><h2>한 개념, 다섯 걸음</h2></div>
    <div class="how">${STEPS.map((s, i) => `<div><b>${s.name}</b><span>${['한 문장 요약과 표로 뼈대를 잡아요.', '필요할 때만 펼쳐 자세히 읽어요.', '먼저 생각하고, 눌러서 풀이를 확인해요.', '선지 함정을 하나씩 체크해요.', '평가원 기출로 바로 확인해요.'][i]}</span></div>`).join('')}</div></section>`;
  h += `<section class="home-sec"><div class="sec-title"><h2>2028 수능 국어</h2></div>
    <div class="exam-grid">
      <div><b>10</b><h4>화법과 언어</h4><p>발표·토의 상황 속에서 문법을 함께 묻습니다.</p></div>
      <div><b>20</b><h4>독서와 작문</h4><p>읽은 내용을 글쓰기에 반영하는 통합 문항이 늘어납니다.</p></div>
      <div><b>15</b><h4>문학</h4><p>갈래 복합 지문과 &lt;보기&gt; 감상이 중심입니다.</p></div>
      <div><b>45</b><h4>선택 과목 없음</h4><p>모두 같은 45문항을 80분 동안 풉니다.</p></div>
    </div></section>`;
  h += `<p class="foot">학습 기록은 이 브라우저에만 저장됩니다 · 기출 문항·지문·선택지의 저작권은 한국교육과정평가원에 있으며 비영리 학습용입니다 · ${esc(window.BUILT || '')}</p>`;
  main.innerHTML = h;
  renderNav(null); markToc(null); setPage('home');
}

/* ---------- 영역 화면 ---------- */
function renderPart(slug){
  const p = parts.find(x => x.info.slug === slug);
  if(!p){ renderHome(); return; }
  const cs = p.chapters.flatMap(ch => ch.concepts);
  const d = cs.filter(c => done[c.id]).length;
  let h = `<section class="band" style="--pc:${p.info.color}"><div class="band-in">
    <div class="crumb"><a href="#/">처음</a> › ${esc(p.info.note)}</div>
    <h1>${esc(p.name)}</h1>
    <p class="sub">장 ${p.chapters.length}개 · 개념 ${cs.length}개 · 이해한 개념 ${d}개</p>
  </div></section><div class="page">`;
  p.chapters.forEach(ch => {
    const n = ch.concepts.filter(c => done[c.id]).length;
    h += `<section class="ch-block" id="ch-${ch.id}"><div class="sec-title row"><h2>${esc(ch.chapter)}</h2><span class="ch-prog">${n}/${ch.concepts.length}</span></div>`;
    if(ch.intro) h += `<p class="intro">${esc(firstSentence(ch.intro))}</p>`;
    h += `<ol class="path">${ch.concepts.map((c, i) => {
      const nk = (c.kichul || []).filter(k => KICHUL[k]).length;
      return `<li><a class="ccard${done[c.id] ? ' done' : ''}" href="#/c/${c.id}">
        <span class="no">${i + 1}</span>
        <h3>${esc(c.title)}</h3>
        <p>${esc(firstSentence(c.summary))}</p>
        <div class="foot-row">${c.level === '심화' ? '<span class="pill deep">심화</span>' : ''}<span class="pill">기출 ${nk}</span>${done[c.id] ? '<span class="pill ok">이해함</span>' : ''}</div>
      </a></li>`;
    }).join('')}</ol></section>`;
  });
  h += '</div>';
  main.innerHTML = h;
  renderNav(p); markToc(null); setPage('part', p.name);
}

/* ---------- 개념 화면: 다섯 걸음 ---------- */
function tableHtml(t){
  return `<div class="tbl-wrap"><table>${t.head ? `<thead><tr>${t.head.map(x => `<th>${rich(x)}</th>`).join('')}</tr></thead>` : ''}<tbody>${(t.rows || []).map(r => `<tr>${r.map(x => `<td>${rich(x)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}
/* 본문을 '핵심'(표·정리 상자)과 '설명'(문단·목록)으로 나눔. 소제목은 따라가는 쪽에 붙임 */
function splitBody(body){
  const core = [], more = [];
  let head = null, headInCore = false, headInMore = false;
  (body || []).forEach(b => {
    if(b.h != null){ head = b.h; headInCore = headInMore = false; return; }
    const isCore = !!(b.table || b.box != null);
    const out = isCore ? core : more;
    if(head && !(isCore ? headInCore : headInMore)){ out.push(`<h3>${rich(head)}</h3>`); if(isCore) headInCore = true; else headInMore = true; }
    if(b.table) out.push(tableHtml(b.table));
    else if(b.box != null) out.push(`<div class="box">${b.title ? `<span class="bt">${rich(b.title)}</span>` : ''}${rich(b.box)}</div>`);
    else if(b.p != null) out.push(`<p>${rich(b.p)}</p>`);
    else if(b.list) out.push(`<ul>${b.list.map(x => `<li>${rich(x)}</li>`).join('')}</ul>`);
  });
  return {core: core.join(''), more: more.join('')};
}
let kFilter = 'all';
const stepOf = {};   // 개념별 현재 단계(이번 방문 동안)
function renderConcept(id, stepArg){
  const i = byId.get(id);
  if(i == null){ renderHome(); return; }
  const c = concepts[i], ch = c.chapter, p = ch.partObj;
  const prev = concepts[i - 1], next = concepts[i + 1];
  const ks = (c.kichul || []).filter(k => KICHUL[k]);
  const ci = ch.concepts.indexOf(c);
  const {core, more} = splitBody(c.body);
  /* 내용이 없는 단계는 건너뜀 */
  const has = {core: true, more: !!more, ex: (c.examples || []).length > 0, trap: (c.traps || []).length > 0, exam: true};
  const steps = STEPS.map((s, k) => ({...s, k})).filter(s => has[s.key]);
  let cur = stepArg != null ? stepArg : (stepOf[id] ?? steps[0].k);
  if(!steps.some(s => s.k === cur)) cur = steps[0].k;
  stepOf[id] = cur;
  seen[id] = [...new Set([...(seen[id] || []), cur])]; store.set('seen', seen);
  store.set('last', id);
  const pos = steps.findIndex(s => s.k === cur);

  /* 머리: 제목 + 장 안의 길(점) */
  let h = `<section class="band slim" style="--pc:${p.info.color}"><div class="band-in">
    <div class="crumb"><a href="#/">처음</a> › <a href="#/p/${p.info.slug}">${esc(p.name)}</a> › <a href="#/p/${p.info.slug}" data-ch="${ch.id}">${esc(ch.chapter)}</a></div>
    <h1>${esc(c.title)}${c.level === '심화' ? ' <span class="pill deep">심화</span>' : ''}</h1>
    <ol class="trail" aria-label="${esc(ch.chapter)}의 개념 순서">${ch.concepts.map((x, j) => `<li><a href="#/c/${x.id}" class="${x === c ? 'here' : ''}${done[x.id] ? ' ok' : ''}" data-tip="${j + 1}. ${esc(x.title)}" aria-label="${j + 1}. ${esc(x.title)}"></a></li>`).join('')}</ol>
  </div></section>`;

  /* 단계 막대 */
  h += `<nav class="stepper" role="tablist" aria-label="학습 단계"><div class="stepper-in">${steps.map((s, j) => {
    const vis = (seen[id] || []).includes(s.k);
    return `<button role="tab" aria-selected="${s.k === cur}" data-step="${s.k}" class="${s.k === cur ? 'on' : ''}${vis ? ' seen' : ''}"><span class="n">${vis && s.k !== cur ? '✓' : j + 1}</span>${s.name}${s.key === 'exam' ? ` <small>${ks.length}</small>` : ''}</button>`;
  }).join('')}<span class="glider" style="--i:${pos};--n:${steps.length}"></span></div></nav>`;

  h += `<div class="concept-grid"><article class="article step-pane" data-key="${STEPS[cur].key}">`;
  const key = STEPS[cur].key;
  if(key === 'core'){
    h += `<p class="summary">${rich(c.summary)}</p>`;
    h += core || '';
    if(ci === 0 && ch.intro) h += `<details class="aside-note"><summary>이 장은 어떻게 나오나요?</summary><p>${rich(ch.intro)}</p></details>`;
  } else if(key === 'more'){
    h += `<p class="lead-q">핵심을 떠올리며 읽어 보세요. 굵은 낱말을 누르면 형광펜이 칠해집니다.</p><div class="body">${more}</div>`;
  } else if(key === 'ex'){
    h += `<div class="pane-head"><p class="lead-q">먼저 스스로 풀어 보고, 카드를 눌러 확인하세요.</p><button class="btn small" data-act="reveal-all">모두 보기</button></div>
      <div class="ex-list">${c.examples.map((e, j) => `<button class="ex" data-ex="${j}" aria-expanded="false"><span class="ex-n">${j + 1}</span><span class="e">${rich(e.ex)}</span>${e.note ? `<span class="n">${rich(e.note)}</span>` : ''}<span class="ex-hint">눌러서 풀이 보기</span></button>`).join('')}</div>`;
  } else if(key === 'trap'){
    const ck = new Set(checks[id] || []);
    h += `<div class="pane-head"><p class="lead-q">하나씩 읽고 ‘알았어요’를 눌러 체크하세요.</p><span class="trap-count">${ck.size}/${c.traps.length}</span></div>
      <ul class="traps">${c.traps.map((t, j) => `<li class="${ck.has(j) ? 'ok' : ''}"><span class="t">${rich(t)}</span><button class="chk" data-trap="${j}" aria-pressed="${ck.has(j)}"><span class="box-i"></span>알았어요</button></li>`).join('')}</ul>`;
  } else if(key === 'exam'){
    if(ks.length){
      const nSolved = ks.filter(k => solved[k]).length, nWrong = ks.filter(k => solved[k] && !solved[k].ok).length;
      h += `<div class="pane-head"><div class="k-filter" role="group" aria-label="기출 거르기">
        <button data-f="all" class="${kFilter === 'all' ? 'on' : ''}">전체 ${ks.length}</button>
        <button data-f="todo" class="${kFilter === 'todo' ? 'on' : ''}">안 푼 ${ks.length - nSolved}</button>
        <button data-f="wrong" class="${kFilter === 'wrong' ? 'on' : ''}">틀린 ${nWrong}</button></div>
        <span class="k-score">${nSolved ? `맞힌 문항 ${nSolved - nWrong}/${nSolved}` : ''}</span></div>`;
      h += `<div class="k-list">${ks.map(k => kichulHtml(k, id)).join('')}</div>`;
    } else h += '<p class="k-empty">이 개념에 딱 맞는 평가원 기출은 아직 없습니다. 연결된 개념의 기출로 이어서 연습해 보세요.</p>';
    h += `<div class="finish"><button class="btn ${done[id] ? '' : 'primary'}" id="doneBtn">${done[id] ? '✓ 이해한 개념 (취소)' : '이 개념을 이해했어요'}</button></div>`;
  }
  /* 단계 아래: 다음 걸음 */
  const nextStep = steps[pos + 1];
  h += `<div class="step-next">${pos > 0 ? `<button class="btn" data-step="${steps[pos - 1].k}">‹ ${steps[pos - 1].name}</button>` : '<span></span>'}${nextStep ? `<button class="btn primary" data-step="${nextStep.k}">다음: ${nextStep.name} ›</button>` : (next ? `<a class="btn primary" href="#/c/${next.id}">다음 개념: ${esc(next.title)} ›</a>` : '')}</div>`;
  h += `</article>`;

  /* 오른쪽: 이어지는 개념 */
  const outs = [...outLinks.get(id)].slice(0, 8), ins = [...inLinks.get(id)].filter(x => !outLinks.get(id).has(x)).slice(0, 8);
  const chips = arr => arr.map(x => { const t = concepts[byId.get(x)]; return `<a class="chip-c${done[x] ? ' ok' : ''}" href="#/c/${x}" data-id="${x}">${esc(t.title)}</a>`; }).join('');
  h += `<aside class="rail">`;
  h += `<div class="rail-card"><h2 class="rail-h">학습 흐름</h2><div class="flow">
      ${prev ? `<a class="flow-i" href="#/c/${prev.id}"><small>앞 개념</small><span>${esc(prev.title)}</span></a>` : ''}
      <div class="flow-i here"><small>지금</small><span>${esc(c.title)}</span></div>
      ${next ? `<a class="flow-i" href="#/c/${next.id}"><small>다음 개념</small><span>${esc(next.title)}</span></a>` : ''}
    </div></div>`;
  if(outs.length || ins.length){
    h += `<div class="rail-card"><h2 class="rail-h">이어지는 개념</h2>`;
    if(outs.length) h += `<p class="rail-sub">이 개념 안에 나오는 개념</p><div class="chips">${chips(outs)}</div>`;
    if(ins.length) h += `<p class="rail-sub">이 개념을 바탕으로 하는 개념</p><div class="chips">${chips(ins)}</div>`;
    h += `</div>`;
  }
  h += `</aside></div>`;
  main.innerHTML = h;

  const pane = main.querySelector('.step-pane');
  if(key !== 'exam') linkTerms(pane, id);
  /* 형광펜 되살리기 */
  const mk = new Set(marks[id] || []);
  pane.querySelectorAll('strong.term').forEach(s => { if(mk.has(s.textContent)) s.classList.add('hl'); });
  if(key === 'exam') applyFilter();
  const db = $('#doneBtn');
  if(db) db.onclick = () => {
    if(done[id]) delete done[id]; else { done[id] = 1; celebrate(db); }
    store.set('done', done);
    setTimeout(() => { const y = scrollY; renderToc(); renderConcept(id); scrollTo(0, y); }, done[id] ? 650 : 0);
  };
  renderNav(p); markToc(id); setPage('concept', c.title);
}
function goStep(k){
  const m = /^#\/c\/([\w-]+)/.exec(location.hash); if(!m) return;
  renderConcept(m[1], k);
  const st = main.querySelector('.stepper');
  if(st && st.getBoundingClientRect().top < 0) st.scrollIntoView({block: 'start'});
}
function celebrate(el){
  el.classList.add('pop');
  const r = el.getBoundingClientRect();
  for(let i = 0; i < 14; i++){
    const s = document.createElement('i'); s.className = 'spark';
    s.style.left = (r.left + r.width / 2) + 'px'; s.style.top = (r.top + r.height / 2) + 'px';
    s.style.setProperty('--a', (i / 14 * 360) + 'deg');
    document.body.append(s); setTimeout(() => s.remove(), 700);
  }
}

/* ---------- 기출 ---------- */
function applyFilter(){
  main.querySelectorAll('.kq').forEach(d => {
    const s = solved[d.dataset.key];
    d.hidden = kFilter === 'todo' ? !!s : kFilter === 'wrong' ? !(s && !s.ok) : false;
  });
}
function kichulHtml(key){
  const it = KICHUL[key], s = solved[key];
  const res = s ? `<span class="res ${s.ok ? 'o' : 'x'}">${s.ok ? '맞힘' : '틀림'}</span>` : '<span class="res"></span>';
  const stem = plain(it.stem).replace(/^\d+\.\s*/, '');
  return `<details class="kq" data-key="${esc(key)}"><summary><span class="src">${esc(examName(it))} ${it.no}번</span>${res}<span class="st">${esc(stem)}</span></summary><div class="kq-body"></div></details>`;
}
function imgs(f, alt){ return String(f).split(' ').map(s => `<img class="fig" src="${esc(s)}" alt="${esc(alt)}" loading="lazy">`).join(''); }
function kichulBody(key){
  const it = KICHUL[key];
  let left = '', right = '';
  if(it.pkey && PASSAGES[it.pkey]){
    const p = PASSAGES[it.pkey];
    left = `<details class="passage" open><summary>지문 (${esc(it.range)}번)</summary>` +
      (p.fig ? `<div class="ptext">${imgs(p.fig, `${it.range}번 지문`)}</div>` : `<div class="ptext">${esc(p.text)}</div>`) + '</details>';
  }
  right += `<p class="stem">${esc(it.stem)}${it.score === 3 && !/3점/.test(it.stem) ? ' [3점]' : ''}</p>`;
  if(it.fig && it.fig.m === 'bogi') right += imgs(it.fig.f, '보기');
  else if(it.bogi){
    const m = /^<\s*([^<>]{1,12}?)\s*>\s*/.exec(it.bogi);
    right += `<div class="bogi">${m ? `<span class="bl">&lt; ${esc(m[1])} &gt;</span>` : ''}${esc(m ? it.bogi.slice(m[0].length) : it.bogi)}</div>`;
  }
  if(it.fig && it.fig.m === 'ch') right += imgs(it.fig.f, '선택지');
  const ch = it.choices || [];
  right += '<ul class="choices">';
  for(let n = 1; n <= 5; n++) right += `<li><button type="button" data-n="${n}"><span class="cn">${CIRCLED[n]}</span><span>${ch[n - 1] != null ? esc(ch[n - 1]) : ''}</span></button></li>`;
  right += '</ul><div class="verdict" hidden></div>';
  right += `<div class="kq-tools">${it.explain ? '<button class="btn small" data-act="exp">해설 보기</button>' : ''}<button class="btn small" data-act="reset">다시 풀기</button></div><div class="explain" hidden></div><div class="also" hidden></div>`;
  return {cls: left ? 'kq-body two' : 'kq-body', html: left ? `${left}<div>${right}</div>` : right};
}
function openBody(d){
  const b = d.querySelector('.kq-body');
  if(!b.innerHTML){ const r = kichulBody(d.dataset.key); b.className = r.cls; b.innerHTML = r.html; }
}
function grade(det, n){
  const key = det.dataset.key, it = KICHUL[key], ok = n === it.answer;
  det.querySelectorAll('.choices button').forEach(b => {
    const k = +b.dataset.n;
    b.classList.remove('sel-o', 'sel-x', 'ans', 'shake', 'pop');
    if(k === n) b.classList.add(ok ? 'sel-o' : 'sel-x', ok ? 'pop' : 'shake');
    if(k === it.answer) b.classList.add('ans');
  });
  const v = det.querySelector('.verdict');
  v.hidden = false;
  v.className = 'verdict ' + (ok ? 'o' : 'x');
  v.textContent = ok ? `정답이에요. (${CIRCLED[it.answer]})` : `아쉬워요. 정답은 ${CIRCLED[it.answer]}이에요. 해설을 확인해 보세요.`;
  solved[key] = {ok, n, t: Date.now()};
  store.set('solved', solved);
  const r = det.querySelector('summary .res');
  if(r){ r.className = 'res ' + (ok ? 'o' : 'x'); r.textContent = ok ? '맞힘' : '틀림'; }
  /* 이 문항이 함께 묻는 개념 */
  const cur = (/^#\/c\/([\w-]+)/.exec(location.hash) || [])[1];
  const others = (itemConcepts.get(key) || []).filter(x => x !== cur);
  const also = det.querySelector('.also');
  if(others.length){ also.hidden = false; also.innerHTML = `<span>이 문항으로 함께 익히는 개념</span>${others.map(x => `<a class="chip-c" href="#/c/${x}" data-id="${x}">${esc(concepts[byId.get(x)].title)}</a>`).join('')}`; }
  const sc = main.querySelector('.k-score');
  if(sc){ const m = /^#\/c\/([\w-]+)/.exec(location.hash); if(m){ const ks = (concepts[byId.get(m[1])].kichul || []).filter(k => KICHUL[k]); const ns = ks.filter(k => solved[k]); sc.textContent = `맞힌 문항 ${ns.filter(k => solved[k].ok).length}/${ns.length}`; } }
}
main.addEventListener('toggle', e => {
  const d = e.target;
  if(d.classList && d.classList.contains('kq') && d.open) openBody(d);
}, true);
main.addEventListener('click', e => {
  const stepBtn = e.target.closest('[data-step]');
  if(stepBtn){ goStep(+stepBtn.dataset.step); return; }
  const f = e.target.closest('.k-filter button');
  if(f){ kFilter = f.dataset.f; main.querySelectorAll('.k-filter button').forEach(b => b.classList.toggle('on', b === f)); applyFilter(); return; }
  const chLink = e.target.closest('a[data-ch]');
  if(chLink){ pendingAnchor = 'ch-' + chLink.dataset.ch; }
  const cid = (/^#\/c\/([\w-]+)/.exec(location.hash) || [])[1];
  /* 예문 카드 뒤집기 */
  const ex = e.target.closest('button.ex');
  if(ex && !e.target.closest('a')){ const o = ex.classList.toggle('open'); ex.setAttribute('aria-expanded', String(o)); return; }
  const btn = e.target.closest('button');
  if(btn && btn.dataset.act === 'reveal-all'){
    const all = [...main.querySelectorAll('button.ex')], open = !all.every(b => b.classList.contains('open'));
    all.forEach((b, j) => setTimeout(() => { b.classList.toggle('open', open); b.setAttribute('aria-expanded', String(open)); }, j * 60));
    btn.textContent = open ? '모두 가리기' : '모두 보기'; return;
  }
  /* 함정 체크 */
  if(btn && btn.dataset.trap != null && cid){
    const j = +btn.dataset.trap, set = new Set(checks[cid] || []);
    set.has(j) ? set.delete(j) : set.add(j);
    checks[cid] = [...set]; store.set('checks', checks);
    const li = btn.closest('li'); li.classList.toggle('ok', set.has(j)); btn.setAttribute('aria-pressed', String(set.has(j)));
    const total = main.querySelectorAll('.traps li').length;
    const cnt = main.querySelector('.trap-count'); if(cnt){ cnt.textContent = `${set.size}/${total}`; cnt.classList.toggle('full', set.size === total); }
    return;
  }
  /* 형광펜 */
  const term = e.target.closest('strong.term');
  if(term && cid){
    term.classList.toggle('hl');
    const set = new Set(marks[cid] || []);
    term.classList.contains('hl') ? set.add(term.textContent) : set.delete(term.textContent);
    marks[cid] = [...set]; store.set('marks', marks); return;
  }
  if(!btn) return;
  const det = btn.closest('.kq');
  if(!det) return;
  if(btn.dataset.n){ grade(det, +btn.dataset.n); return; }
  if(btn.dataset.act === 'exp'){
    const exd = det.querySelector('.explain');
    exd.hidden = !exd.hidden;
    if(!exd.innerHTML) exd.innerHTML = esc(KICHUL[det.dataset.key].explain);
    btn.textContent = exd.hidden ? '해설 보기' : '해설 닫기';
  }
  if(btn.dataset.act === 'reset'){ const b = det.querySelector('.kq-body'); b.innerHTML = ''; openBody(det); }
});

/* ---------- 검색 ---------- */
function renderSearch(term){
  const t = term.trim();
  if(!t){ route(); return; }
  const hits = concepts.map(c => {
    let s = 0;
    if(c.title.includes(t)) s += 10;
    if((c.summary || '').includes(t)) s += 3;
    if(JSON.stringify([c.body, c.examples, c.traps]).includes(t)) s += 1;
    return {c, s};
  }).filter(x => x.s > 0).sort((a, b) => b.s - a.s);
  const mk = s => esc(s).split(esc(t)).join(`<mark>${esc(t)}</mark>`);
  main.innerHTML = `<section class="band slim"><div class="band-in"><div class="crumb">찾기</div><h1>‘${esc(t)}’ ${hits.length}개</h1></div></section><div class="page">` +
    (hits.length ? `<div class="results">${hits.map(({c}) => `<a class="ccard" href="#/c/${c.id}"><span class="no">${esc(c.chapter.chapter)}</span><h3>${mk(c.title)}</h3><p>${mk(firstSentence(c.summary))}</p></a>`).join('')}</div>` : '<p class="k-empty">찾는 개념이 없습니다. 다른 낱말로 찾아보세요.</p>') + '</div>';
  setPage('search', '찾기'); renderNav(null); markToc(null);
}
let st;
q.addEventListener('input', () => { clearTimeout(st); st = setTimeout(() => renderSearch(q.value), 150); });
q.addEventListener('keydown', e => { if(e.key === 'Escape'){ q.value = ''; q.blur(); route(); } });

/* ---------- 이동 ---------- */
let pendingAnchor = null;
function route(){
  const h = location.hash;
  let m;
  hidePeek();
  if((m = /^#\/c\/([\w-]+)/.exec(h))) renderConcept(m[1]);
  else if((m = /^#\/p\/([\w-]+)/.exec(h))) renderPart(m[1]);
  else renderHome();
}
window.addEventListener('hashchange', () => {
  q.value = ''; kFilter = 'all';
  route(); closeNav();
  const a = pendingAnchor && document.getElementById(pendingAnchor);
  pendingAnchor = null;
  if(a) a.scrollIntoView(); else window.scrollTo(0, 0);
  main.focus({preventScroll: true});
});
const menuBtn = $('#menuBtn'), scrim = $('#scrim');
function closeNav(){ document.body.classList.remove('nav-open'); scrim.hidden = true; menuBtn.setAttribute('aria-expanded', 'false'); }
menuBtn.onclick = () => {
  const open = !document.body.classList.contains('nav-open');
  document.body.classList.toggle('nav-open', open);
  scrim.hidden = !open;
  menuBtn.setAttribute('aria-expanded', String(open));
};
scrim.onclick = closeNav;
$('#themeBtn').onclick = () => {
  const cur = document.documentElement.dataset.theme || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const nx = cur === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.theme = nx; store.set('theme', nx);
};

/* 읽은 정도 막대, 맨 위로 */
const bar = $('#progress i'), toTop = $('#toTop');
let ticking = false;
addEventListener('scroll', () => {
  if(ticking) return; ticking = true;
  requestAnimationFrame(() => {
    const max = document.documentElement.scrollHeight - innerHeight;
    bar.style.width = (max > 0 ? Math.min(100, scrollY / max * 100) : 0) + '%';
    toTop.hidden = scrollY < 700;
    ticking = false;
  });
}, {passive: true});
toTop.onclick = () => scrollTo({top: 0, behavior: 'smooth'});
/* 창 크기를 바꾸는 동안에는 목차가 미끄러지는 움직임을 끔 */
let rt;
addEventListener('resize', () => {
  document.body.classList.add('resizing'); hidePeek();
  clearTimeout(rt); rt = setTimeout(() => document.body.classList.remove('resizing'), 250);
  if(innerWidth >= 1360) closeNav();
});

/* 단축키: / 찾기, ← → 앞뒤 단계(끝에서는 앞뒤 개념), Esc 닫기 */
addEventListener('keydown', e => {
  const typing = /INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName);
  if(e.key === 'Escape'){ closeNav(); hidePeek(); }
  if(typing || e.ctrlKey || e.metaKey || e.altKey) return;
  if(e.key === '/'){ e.preventDefault(); q.focus(); return; }
  const m = /^#\/c\/([\w-]+)/.exec(location.hash);
  if(m && (e.key === 'ArrowLeft' || e.key === 'ArrowRight')){
    const btns = [...main.querySelectorAll('.stepper button')];
    const at = btns.findIndex(b => b.classList.contains('on'));
    const to = btns[at + (e.key === 'ArrowRight' ? 1 : -1)];
    if(to){ goStep(+to.dataset.step); return; }
    const i = byId.get(m[1]), t = concepts[i + (e.key === 'ArrowRight' ? 1 : -1)];
    if(t) location.hash = '#/c/' + t.id;
  }
});

renderToc();
route();
})();
