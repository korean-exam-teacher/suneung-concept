/* ᄉᆡ미 기픈 믈 — 수능 국어 개념서 */
(function(){
'use strict';
const BOOK = window.BOOK || [], KICHUL = window.KICHUL || {}, PASSAGES = window.PASSAGES || {};
const CIRCLED = ['', '①', '②', '③', '④', '⑤'];
const PART_INFO = {
  '언어(문법)':      {slug: 'lang', en: 'LANGUAGE',   color: 'var(--p-lang)', note: '2028 수능 · 화법과 언어'},
  '문학':            {slug: 'lit',  en: 'LITERATURE', color: 'var(--p-lit)',  note: '2028 수능 · 문학'},
  '독서':            {slug: 'read', en: 'READING',    color: 'var(--p-read)', note: '2028 수능 · 독서와 작문'},
  '화법·작문·매체':  {slug: 'sw',   en: 'SPEAK · WRITE', color: 'var(--p-sw)', note: '2028 수능 · 화법과 언어 · 독서와 작문'}
};
const $ = s => document.querySelector(s);
const main = $('#main'), side = $('#side'), q = $('#q'), gnav = $('#gnav');

/* ---------- 저장 ---------- */
const store = {
  get(k, d){ try{ const v = localStorage.getItem('smgm:' + k); return v ? JSON.parse(v) : d; }catch(e){ return d; } },
  set(k, v){ try{ localStorage.setItem('smgm:' + k, JSON.stringify(v)); }catch(e){} }
};
let done = store.get('done', {});
let solved = store.get('solved', {});

/* ---------- 색인 ---------- */
const concepts = [], parts = [];
BOOK.forEach(ch => {
  let p = parts.find(x => x.name === ch.part);
  if(!p){ p = {name: ch.part, chapters: [], info: PART_INFO[ch.part] || {slug: 'p' + parts.length, en: '', color: 'var(--navy)', note: ''}}; parts.push(p); }
  p.chapters.push(ch);
  ch.partObj = p;
  ch.concepts.forEach(c => { c.chapter = ch; concepts.push(c); });
});
const byId = new Map(concepts.map((c, i) => [c.id, i]));
const pad = n => String(n).padStart(2, '0');

/* ---------- 글자 ---------- */
function esc(s){
  const h = String(s ?? '')
    .replace(/[가-힣](?=[ᅠ-ᇿힰ-퟿])/g, c => c.normalize('NFD'))
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  return /[﷐-﷓]/.test(h) ? marks(h) : h;
}
/* 원본 문제지의 밑줄(U+FDD0…FDD1)·글자 상자(U+FDD2…FDD3) */
function marks(h){
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
function rich(s){ return esc(s).replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>'); }
const examName = it => it.exam.replace('학년도 ', ' ').replace('대학수학능력시험', '수능').replace('모의평가', '모평');

/* ---------- 머리·목차 ---------- */
function renderNav(active){
  gnav.innerHTML = parts.map(p => `<a href="#/p/${p.info.slug}" class="${active === p ? 'on' : ''}">${esc(p.name)}</a>`).join('');
}
function renderToc(){
  let h = '';
  parts.forEach(p => {
    h += `<div class="toc-part" style="--pc:${p.info.color}">${esc(p.name)}</div>`;
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
    <div>
      <div class="eyebrow">수능 국어 개념서</div>
      <h1>ᄉᆡ미 기픈 믈</h1>
      <p class="lead">깊이 판 개념은 마르지 않습니다.<br>개념, 예문, 함정, 그리고 평가원 기출까지 한 곳에서.</p>
      <div class="cta">
        ${lastC ? `<a class="btn primary" href="#/c/${lastC.id}">이어서 공부하기</a><a class="btn ghost" href="#/c/${lastC.id}">${esc(lastC.title)} ›</a>` : `<a class="btn primary" href="#/c/${concepts[0] ? concepts[0].id : ''}">시작하기</a>`}
        <a class="btn ghost" href="#/p/${parts[0] ? parts[0].info.slug : ''}">목차 보기 ›</a>
      </div>
    </div>
    <div class="stats">
      <div><b>${total}</b><span>개념</span></div>
      <div><b>${nEx}</b><span>예문</span></div>
      <div><b>${Object.keys(KICHUL).length}</b><span>연결된 평가원 기출</span></div>
    </div>
  </div></section>`;
  h += `<section class="home-sec"><div class="sec-title"><h2>영역</h2><span class="en">PARTS</span></div><div class="parts">`;
  parts.forEach((p, i) => {
    const cs = p.chapters.flatMap(ch => ch.concepts);
    const d = cs.filter(c => done[c.id]).length;
    h += `<a class="part-tile" href="#/p/${p.info.slug}" style="--pc:${p.info.color}">
      <span class="num">${pad(i + 1)}</span>
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
  h += `<section class="home-sec"><div class="sec-title"><h2>2028 수능 국어</h2><span class="en">NEW FORMAT</span></div>
    <div class="exam-grid">
      <div><b>10</b><h4>화법과 언어</h4><p>1~10번. 발표·토의 상황 속에서 문법 개념을 함께 묻는 문항이 나옵니다.</p></div>
      <div><b>20</b><h4>독서와 작문</h4><p>11~30번. 지문을 읽고 그 내용을 글쓰기에 반영하는 통합 문항이 늘어납니다.</p></div>
      <div><b>15</b><h4>문학</h4><p>31~45번. 갈래 복합 지문과 &lt;보기&gt; 관점 감상이 중심입니다.</p></div>
      <div><b>45</b><h4>선택 과목 없음</h4><p>모든 수험생이 같은 45문항을 80분 동안 풉니다.</p></div>
    </div></section>`;
  h += `<section class="home-sec"><div class="sec-title"><h2>공부하는 순서</h2><span class="en">HOW TO</span></div>
    <div class="how">
      <div><b>개념 읽기</b><span>요약과 표로 뼈대를 잡습니다.</span></div>
      <div><b>예문 분석</b><span>직접 발음하고 쪼개 보며 손으로 익힙니다.</span></div>
      <div><b>함정 확인</b><span>‘자주 틀리는 점’으로 선지 함정을 미리 봅니다.</span></div>
      <div><b>기출 풀기</b><span>평가원 기출을 바로 풀고 채점·해설까지 확인합니다.</span></div>
    </div></section>`;
  h += `<p class="foot">학습 진행 ${nDone}/${total} (이 브라우저에만 저장) · 기출 문항·지문·선택지의 저작권은 한국교육과정평가원에 있습니다. 비영리 학습용입니다. · 만든 날 ${esc(window.BUILT || '')}</p>`;
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
    <p class="sub">${esc(p.info.note)} · 장 ${p.chapters.length}개 · 개념 ${cs.length}개 · 이해한 개념 ${d}개</p>
  </div></section><div class="page">`;
  p.chapters.forEach((ch, ci) => {
    h += `<section class="ch-block" id="ch-${ch.id}"><div class="sec-title"><h2>${esc(ch.chapter)}</h2><span class="en">CHAPTER ${pad(ci + 1)}</span></div>`;
    if(ch.intro) h += `<p class="intro">${rich(ch.intro)}</p>`;
    h += `<div class="cards">${ch.concepts.map((c, i) => {
      const nk = (c.kichul || []).filter(k => KICHUL[k]).length;
      return `<a class="ccard${done[c.id] ? ' done' : ''}" href="#/c/${c.id}">
        <div class="top-row"><span class="no">${pad(i + 1)}</span><span class="pill${c.level === '심화' ? ' deep' : ''}">${esc(c.level || '핵심')}</span></div>
        <h3>${esc(c.title)}</h3>
        <p>${esc(plain(c.summary).replace(/\*\*/g, ''))}</p>
        <div class="foot-row"><span class="pill">기출 ${nk}</span>${done[c.id] ? '<span class="pill ok">✓ 이해함</span>' : ''}</div>
      </a>`;
    }).join('')}</div></section>`;
  });
  h += '</div>';
  main.innerHTML = h;
  renderNav(p); markToc(null); setPage('part', p.name);
}

/* ---------- 개념 화면 ---------- */
function blockHtml(b){
  if(b.p != null) return `<p>${rich(b.p)}</p>`;
  if(b.h != null) return `<h3>${rich(b.h)}</h3>`;
  if(b.list) return `<ul>${b.list.map(x => `<li>${rich(x)}</li>`).join('')}</ul>`;
  if(b.table){
    const t = b.table;
    return `<div class="tbl-wrap"><table>${t.head ? `<thead><tr>${t.head.map(x => `<th>${rich(x)}</th>`).join('')}</tr></thead>` : ''}<tbody>${(t.rows || []).map(r => `<tr>${r.map(x => `<td>${rich(x)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
  }
  if(b.box != null) return `<div class="box">${b.title ? `<span class="bt">${rich(b.title)}</span>` : ''}${rich(b.box)}</div>`;
  return '';
}
const blockTitle = (ko, en, cnt) => `<div class="block-title"><h2>${ko}</h2><span class="en">${en}</span>${cnt != null ? `<span class="cnt">${cnt}</span>` : ''}</div>`;
let kFilter = 'all';
function renderConcept(id){
  const i = byId.get(id);
  if(i == null){ renderHome(); return; }
  const c = concepts[i], ch = c.chapter, p = ch.partObj;
  const prev = concepts[i - 1], next = concepts[i + 1];
  const ks = (c.kichul || []).filter(k => KICHUL[k]);
  const ci = ch.concepts.indexOf(c);
  store.set('last', id);
  let h = `<section class="band" style="--pc:${p.info.color}"><div class="band-in">
    <div class="crumb"><a href="#/">처음</a> › <a href="#/p/${p.info.slug}">${esc(p.name)}</a> › <a href="#/p/${p.info.slug}" data-ch="${ch.id}">${esc(ch.chapter)}</a> · ${pad(ci + 1)}/${pad(ch.concepts.length)}</div>
    <h1>${esc(c.title)}</h1>
    <div class="chips"><span class="tag">${esc(ch.chapter)}</span><span class="${c.level === '심화' ? 'deep' : ''}">${esc(c.level || '핵심')}</span><span>예문 ${(c.examples || []).length}</span><span>기출 ${ks.length}</span>${done[id] ? '<span>✓ 이해함</span>' : ''}</div>
  </div></section>`;
  h += `<div class="concept-grid"><article class="article">`;
  if(ci === 0 && ch.intro) h += `<div class="box" style="margin-top:0"><span class="bt">이 장에서는</span>${rich(ch.intro)}</div>`;
  h += `<div class="summary">${rich(c.summary)}</div>`;
  h += `<section class="body">${blockTitle('개념', 'CONCEPT')}${(c.body || []).map(blockHtml).join('')}</section>`;
  h += `</article><aside class="rail">`;
  if((c.examples || []).length){
    h += `<div class="rail-card">${blockTitle('예문', 'EXAMPLES', c.examples.length)}<div class="ex-list">${c.examples.map(e => `<div class="ex"><div class="ex-in"><div class="e">${rich(e.ex)}</div>${e.note ? `<div class="n">${rich(e.note)}</div>` : ''}</div></div>`).join('')}</div></div>`;
  }
  if((c.traps || []).length){
    h += `<div class="rail-card">${blockTitle('자주 틀리는 점', 'TRAPS', c.traps.length)}<ul class="traps">${c.traps.map(t => `<li>${rich(t)}</li>`).join('')}</ul></div>`;
  }
  h += `<div class="rail-card">${blockTitle('이 장의 개념', 'IN THIS CHAPTER')}<nav class="rail-nav">${ch.concepts.map((x, j) => `<a href="#/c/${x.id}" class="${x === c ? 'on' : ''}"><span>${pad(j + 1)} ${esc(x.title)}</span><small>${done[x.id] ? '✓' : ''}</small></a>`).join('')}</nav></div>`;
  h += `</aside></div>`;
  h += `<section class="kichul">${blockTitle('관련 평가원 기출', 'PAST EXAMS', ks.length)}`;
  if(ks.length){
    const nSolved = ks.filter(k => solved[k]).length, nWrong = ks.filter(k => solved[k] && !solved[k].ok).length;
    h += `<div class="k-filter" role="group" aria-label="기출 거르기">
      <button data-f="all" class="${kFilter === 'all' ? 'on' : ''}">전체 ${ks.length}</button>
      <button data-f="todo" class="${kFilter === 'todo' ? 'on' : ''}">안 푼 문항 ${ks.length - nSolved}</button>
      <button data-f="wrong" class="${kFilter === 'wrong' ? 'on' : ''}">틀린 문항 ${nWrong}</button></div>`;
    h += `<div class="k-list">${ks.map(kichulHtml).join('')}</div>`;
  } else h += '<p class="k-empty">이 개념에 연결된 기출이 아직 없습니다.</p>';
  h += '</section>';
  h += `<div class="done-row"><button class="btn ${done[id] ? '' : 'primary'}" id="doneBtn">${done[id] ? '✓ 이해했어요 (취소)' : '이 개념을 이해했어요'}</button></div>`;
  h += `<nav class="pager">${prev ? `<a href="#/c/${prev.id}"><small>‹ 이전 개념</small><b>${esc(prev.title)}</b></a>` : ''}${next ? `<a class="next" href="#/c/${next.id}"><small>다음 개념 ›</small><b>${esc(next.title)}</b></a>` : ''}</nav>`;
  main.innerHTML = h;
  applyFilter();
  $('#doneBtn').onclick = () => {
    if(done[id]) delete done[id]; else done[id] = 1;
    store.set('done', done);
    const y = scrollY; renderToc(); renderConcept(id); scrollTo(0, y);
  };
  renderNav(p); markToc(id); setPage('concept', c.title);
}
function applyFilter(){
  main.querySelectorAll('.kq').forEach(d => {
    const s = solved[d.dataset.key];
    d.hidden = kFilter === 'todo' ? !!s : kFilter === 'wrong' ? !(s && !s.ok) : false;
  });
}
function kichulHtml(key){
  const it = KICHUL[key], s = solved[key];
  const res = s ? `<span class="res ${s.ok ? 'o' : 'x'}">${s.ok ? '맞힘' : '틀림'}</span>` : '<span></span>';
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
  for(let n = 1; n <= 5; n++) right += `<li><button type="button" data-n="${n}">${CIRCLED[n]}<span>${ch[n - 1] != null ? esc(ch[n - 1]) : ''}</span></button></li>`;
  right += '</ul><div class="verdict" hidden></div>';
  right += `<div class="kq-tools">${it.explain ? '<button class="btn small" data-act="exp">해설 보기</button>' : ''}<button class="btn small" data-act="reset">다시 풀기</button></div><div class="explain" hidden></div>`;
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
    b.classList.toggle('sel-o', ok && k === n);
    b.classList.toggle('sel-x', !ok && k === n);
    b.classList.toggle('ans', k === it.answer);
  });
  const v = det.querySelector('.verdict');
  v.hidden = false;
  v.className = 'verdict ' + (ok ? 'o' : 'x');
  v.textContent = ok ? `정답입니다. (${CIRCLED[it.answer]})` : `오답입니다. 정답은 ${CIRCLED[it.answer]}입니다.`;
  solved[key] = {ok, n, t: Date.now()};
  store.set('solved', solved);
  const r = det.querySelector('summary .res, summary > span:nth-child(2)');
  if(r) r.outerHTML = `<span class="res ${ok ? 'o' : 'x'}">${ok ? '맞힘' : '틀림'}</span>`;
}
main.addEventListener('toggle', e => {
  const d = e.target;
  if(d.classList && d.classList.contains('kq') && d.open) openBody(d);
}, true);
main.addEventListener('click', e => {
  const f = e.target.closest('.k-filter button');
  if(f){ kFilter = f.dataset.f; main.querySelectorAll('.k-filter button').forEach(b => b.classList.toggle('on', b === f)); applyFilter(); return; }
  const chLink = e.target.closest('a[data-ch]');
  if(chLink){ pendingAnchor = 'ch-' + chLink.dataset.ch; }
  const btn = e.target.closest('button');
  if(!btn) return;
  const det = btn.closest('.kq');
  if(!det) return;
  if(btn.dataset.n){ grade(det, +btn.dataset.n); return; }
  if(btn.dataset.act === 'exp'){
    const ex = det.querySelector('.explain');
    ex.hidden = !ex.hidden;
    if(!ex.innerHTML) ex.innerHTML = esc(KICHUL[det.dataset.key].explain);
    btn.textContent = ex.hidden ? '해설 보기' : '해설 닫기';
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
  main.innerHTML = `<section class="band"><div class="band-in"><div class="crumb">찾기</div><h1>‘${esc(t)}’ ${hits.length}개</h1></div></section><div class="page">` +
    (hits.length ? `<div class="results">${hits.map(({c}) => `<a class="ccard" href="#/c/${c.id}"><div class="top-row"><span class="no">${esc(c.chapter.chapter)}</span><span class="pill${c.level === '심화' ? ' deep' : ''}">${esc(c.level || '핵심')}</span></div><h3>${mk(c.title)}</h3><p>${mk(plain(c.summary).replace(/\*\*/g, ''))}</p></a>`).join('')}</div>` : '<p class="k-empty">찾는 개념이 없습니다. 다른 낱말로 찾아보세요.</p>') + '</div>';
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
  document.body.classList.add('resizing');
  clearTimeout(rt); rt = setTimeout(() => document.body.classList.remove('resizing'), 250);
  if(innerWidth >= 1360) closeNav();
});

/* 단축키: / 찾기, ← → 앞뒤 개념, Esc 목차 닫기 */
addEventListener('keydown', e => {
  const typing = /INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName);
  if(e.key === 'Escape') closeNav();
  if(typing || e.ctrlKey || e.metaKey || e.altKey) return;
  if(e.key === '/'){ e.preventDefault(); q.focus(); return; }
  const m = /^#\/c\/([\w-]+)/.exec(location.hash);
  if(m && (e.key === 'ArrowLeft' || e.key === 'ArrowRight')){
    const i = byId.get(m[1]), t = concepts[i + (e.key === 'ArrowRight' ? 1 : -1)];
    if(t) location.hash = '#/c/' + t.id;
  }
});

renderToc();
route();
})();
