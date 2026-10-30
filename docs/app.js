/* ᄉᆡ미 기픈 믈 — 수능 국어 개념서 */
(function(){
'use strict';
const BOOK = window.BOOK || [], KICHUL = window.KICHUL || {}, PASSAGES = window.PASSAGES || {};
const CIRCLED = ['', '①', '②', '③', '④', '⑤'];
const PART_NOTE = {
  '언어(문법)': '2028 수능: 화법과 언어',
  '문학': '2028 수능: 문학',
  '독서': '2028 수능: 독서와 작문',
  '화법·작문·매체': '2028 수능: 화법과 언어 · 독서와 작문'
};
const $ = s => document.querySelector(s);
const main = $('#main'), side = $('#side'), q = $('#q');

/* ---------- 저장 ---------- */
const store = {
  get(k, d){ try{ const v = localStorage.getItem('smgm:' + k); return v ? JSON.parse(v) : d; }catch(e){ return d; } },
  set(k, v){ try{ localStorage.setItem('smgm:' + k, JSON.stringify(v)); }catch(e){} }
};
let done = store.get('done', {});
let solved = store.get('solved', {});

/* ---------- 색인 ---------- */
const concepts = [];
const parts = [];
BOOK.forEach(ch => {
  let p = parts.find(x => x.name === ch.part);
  if(!p){ p = {name: ch.part, chapters: []}; parts.push(p); }
  p.chapters.push(ch);
  ch.concepts.forEach(c => { c.chapter = ch; concepts.push(c); });
});
const byId = new Map(concepts.map((c, i) => [c.id, i]));

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
/* 내용 파일의 **굵게** */
function rich(s){ return esc(s).replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>'); }

/* ---------- 목차 ---------- */
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
  side.innerHTML = h || '<div class="toc-empty">내용이 없습니다.</div>';
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

/* ---------- 첫 화면 ---------- */
function renderHome(){
  const total = concepts.length, nDone = concepts.filter(c => done[c.id]).length;
  const nK = Object.keys(KICHUL).length;
  let h = `<section class="hero"><h1>ᄉᆡ미 기픈 믈</h1>
    <p>샘이 깊은 물은 가뭄에 마르지 않습니다. 개념을 깊이 파 두면 처음 보는 지문과 &lt;보기&gt;에도 흔들리지 않습니다.<br>
    개념 ${total}개 · 예문 ${concepts.reduce((a, c) => a + (c.examples || []).length, 0)}개 · 연결된 평가원 기출 ${nK}문항</p></section>
    <div class="notice"><b>공부하는 순서</b> — ① 개념 설명과 표를 읽고 ② 예문을 직접 발음하거나 분석해 본 뒤 ③ ‘자주 틀리는 점’을 확인하고 ④ 아래의 평가원 기출을 풀어 보세요. 다 익힌 개념은 ‘이해했어요’를 눌러 표시해 두면 목차에 초록 점이 찍힙니다(이 브라우저에만 저장).</div>
    <div class="notice"><b>2028학년도 수능부터</b> 국어는 선택 과목 없이 모두 같은 45문항(화법과 언어 10, 독서와 작문 20, 문학 15)을 풉니다. 문법은 ‘화법과 언어’에서 화법과 섞여 나올 수 있으니, 개념을 정확히 알고 상황에 적용하는 연습이 더 중요해졌습니다.</div>
    <div class="parts">`;
  parts.forEach(p => {
    const cs = p.chapters.flatMap(ch => ch.concepts);
    const d = cs.filter(c => done[c.id]).length;
    h += `<div class="part-card"><h2>${esc(p.name)}</h2><div class="meta">${esc(PART_NOTE[p.name] || '')} · 개념 ${cs.length}개</div>
      <div class="bar" title="${d}/${cs.length}"><i style="width:${cs.length ? Math.round(d / cs.length * 100) : 0}%"></i></div><ol>`;
    p.chapters.forEach(ch => { h += `<li><a href="#/c/${ch.concepts[0] ? ch.concepts[0].id : ''}">${esc(ch.chapter)}</a> <small>(${ch.concepts.length})</small></li>`; });
    h += '</ol></div>';
  });
  h += `</div><p class="foot">학습 진행: ${nDone}/${total} · 기출 문항·지문·선택지의 저작권은 한국교육과정평가원에 있습니다. 비영리 학습용입니다. 만든 날 ${esc(window.BUILT || '')}</p>`;
  main.innerHTML = h;
  markToc(null);
  document.title = 'ᄉᆡ미 기픈 믈 — 수능 국어 개념서';
}

/* ---------- 개념 ---------- */
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
function renderConcept(id){
  const i = byId.get(id);
  if(i == null){ renderHome(); return; }
  const c = concepts[i], ch = c.chapter;
  const prev = concepts[i - 1], next = concepts[i + 1];
  let h = `<div class="crumb">${esc(ch.part)} › ${esc(ch.chapter)}</div>
    <div class="c-head"><h1>${esc(c.title)}</h1><span class="badge${c.level === '심화' ? ' deep' : ''}">${esc(c.level || '핵심')}</span></div>`;
  if(ch.concepts[0] === c && ch.intro) h += `<div class="notice" style="margin-top:16px">${rich(ch.intro)}</div>`;
  h += `<div class="summary">${rich(c.summary)}</div>`;
  h += `<section class="sec body"><h2>개념</h2>${(c.body || []).map(blockHtml).join('')}</section>`;
  if((c.examples || []).length){
    h += `<section class="sec"><h2>예문</h2><div class="ex-list">${c.examples.map(e => `<div class="ex"><div class="e">${rich(e.ex)}</div><div class="n">${rich(e.note || '')}</div></div>`).join('')}</div></section>`;
  }
  if((c.traps || []).length){
    h += `<section class="sec"><h2>자주 틀리는 점</h2><ul class="traps">${c.traps.map(t => `<li>${rich(t)}</li>`).join('')}</ul></section>`;
  }
  const ks = (c.kichul || []).filter(k => KICHUL[k]);
  h += `<section class="sec"><h2>관련 평가원 기출 (${ks.length})</h2>`;
  h += ks.length ? `<div class="k-list">${ks.map(kichulHtml).join('')}</div>` : '<p class="k-empty">이 개념에 연결된 기출이 아직 없습니다.</p>';
  h += '</section>';
  h += `<div class="done-row"><button class="btn ${done[id] ? '' : 'primary'}" id="doneBtn">${done[id] ? '✓ 이해했어요 (취소)' : '이해했어요'}</button></div>`;
  h += `<nav class="pager">${prev ? `<a href="#/c/${prev.id}">← 이전<b>${esc(prev.title)}</b></a>` : '<span></span>'}${next ? `<a class="next" href="#/c/${next.id}">다음 →<b>${esc(next.title)}</b></a>` : ''}</nav>`;
  main.innerHTML = h;
  $('#doneBtn').onclick = () => {
    if(done[id]) delete done[id]; else done[id] = 1;
    store.set('done', done);
    renderToc(); renderConcept(id);
  };
  markToc(id);
  document.title = `${c.title} — ᄉᆡ미 기픈 믈`;
}
function kichulHtml(key){
  const it = KICHUL[key];
  const s = solved[key];
  const res = s ? `<span class="res ${s.ok ? 'o' : 'x'}">${s.ok ? '맞힘' : '틀림'}</span>` : '<span></span>';
  const stem = plain(it.stem).replace(/^\d+\.\s*/, '');
  return `<details class="kq" data-key="${esc(key)}"><summary><span class="src">${esc(it.exam.replace('학년도 ', ' ').replace('대학수학능력시험', '수능'))} ${it.no}번</span><span class="st">${esc(stem)}</span>${res}</summary><div class="kq-body"></div></details>`;
}
/* 그림 경로는 여러 개일 때 빈칸으로 이어져 있음 */
function imgs(f, alt){ return String(f).split(' ').map(s => `<img class="fig" src="${esc(s)}" alt="${esc(alt)}" loading="lazy">`).join(''); }
function kichulBody(key){
  const it = KICHUL[key];
  let h = '';
  if(it.pkey && PASSAGES[it.pkey]){
    const p = PASSAGES[it.pkey];
    h += `<details class="passage"><summary>지문 보기 (${esc(it.range)}번)</summary>`;
    h += p.fig ? imgs(p.fig, `${it.range}번 지문`) : `<div class="ptext">${esc(p.text)}</div>`;
    h += '</details>';
  }
  h += `<p class="stem">${esc(it.stem)}${it.score === 3 && !/3점/.test(it.stem) ? ' [3점]' : ''}</p>`;
  if(it.fig && it.fig.m === 'bogi') h += imgs(it.fig.f, '보기');
  else if(it.bogi){
    const m = /^<\s*([^<>]{1,12}?)\s*>\s*/.exec(it.bogi);
    h += `<div class="bogi">${m ? `<span class="bl">&lt; ${esc(m[1])} &gt;</span>` : ''}${esc(m ? it.bogi.slice(m[0].length) : it.bogi)}</div>`;
  }
  if(it.fig && it.fig.m === 'ch') h += imgs(it.fig.f, '선택지');
  const ch = it.choices || [];
  h += '<ul class="choices">';
  for(let n = 1; n <= 5; n++){
    h += `<li><button type="button" data-n="${n}">${CIRCLED[n]}<span>${ch[n - 1] != null ? esc(ch[n - 1]) : ''}</span></button></li>`;
  }
  h += '</ul><div class="verdict" hidden></div>';
  h += `<div class="kq-tools">${it.explain ? '<button class="btn small" data-act="exp">해설 보기</button>' : ''}<button class="btn small" data-act="reset">다시 풀기</button></div><div class="explain" hidden></div>`;
  return h;
}
function grade(det, n){
  const key = det.dataset.key, it = KICHUL[key];
  const ok = n === it.answer;
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
  const sum = det.querySelector('summary');
  sum.lastElementChild.outerHTML = `<span class="res ${ok ? 'o' : 'x'}">${ok ? '맞힘' : '틀림'}</span>`;
}

main.addEventListener('toggle', e => {
  const d = e.target;
  if(d.classList && d.classList.contains('kq') && d.open){
    const b = d.querySelector('.kq-body');
    if(!b.innerHTML) b.innerHTML = kichulBody(d.dataset.key);
  }
}, true);
main.addEventListener('click', e => {
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
  if(btn.dataset.act === 'reset'){
    det.querySelector('.kq-body').innerHTML = kichulBody(det.dataset.key);
  }
});

/* ---------- 검색 ---------- */
function renderSearch(term){
  const t = term.trim();
  if(!t){ route(); return; }
  const hits = concepts.map(c => {
    let s = 0;
    if(c.title.includes(t)) s += 10;
    if((c.summary || '').includes(t)) s += 3;
    const all = JSON.stringify([c.body, c.examples, c.traps]);
    if(all.includes(t)) s += 1;
    return {c, s};
  }).filter(x => x.s > 0).sort((a, b) => b.s - a.s);
  const mk = s => esc(s).split(esc(t)).join(`<mark>${esc(t)}</mark>`);
  main.innerHTML = `<h1 style="font-size:22px">‘${esc(t)}’ 찾기 결과 ${hits.length}개</h1>` +
    (hits.length ? `<div class="results">${hits.map(({c}) => `<a href="#/c/${c.id}"><small>${esc(c.chapter.part)} › ${esc(c.chapter.chapter)}</small><b>${mk(c.title)}</b><br>${mk(c.summary || '')}</a>`).join('')}</div>` : '<p class="k-empty">찾는 개념이 없습니다. 다른 낱말로 찾아보세요.</p>');
  markToc(null);
}
let st;
q.addEventListener('input', () => { clearTimeout(st); st = setTimeout(() => renderSearch(q.value), 150); });
q.addEventListener('keydown', e => { if(e.key === 'Escape'){ q.value = ''; route(); } });

/* ---------- 이동 ---------- */
function route(){
  const m = /^#\/c\/([\w-]+)/.exec(location.hash);
  if(m) renderConcept(m[1]); else renderHome();
}
window.addEventListener('hashchange', () => {
  q.value = '';
  route();
  closeNav();
  window.scrollTo(0, 0);
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

renderToc();
route();
})();
