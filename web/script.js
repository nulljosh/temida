// ===== APP =====
// Auth, session and the private markup injection all happen in auth.js, which
// appends this file only once the DOM shell is populated. So every top-level
// render below can assume its nodes exist.
const _sb = window._sb || null;
const _userId = window._userId || null;


async function loadAndShow() {
  const overlay = document.getElementById('authOverlay');
  if (overlay) overlay.classList.add('hidden');
  await fetchCaseData();
  await Promise.all([loadChecklistFromDB(), loadLawyerStatusFromDB(), loadDocumentsFromDB()]);
  const empty = document.getElementById('emptyState');
  if (empty) empty.style.display = hasBriefData() ? 'none' : 'block';
  setActiveCase(webActiveCase || 'rcmp');
}

let webActiveCase = 'rcmp';

// ===== DATA =====
let FACTS, FAMILY_FACTS, MUNI_FACTS, BYLAW_FACTS, WITNESSES, FAMILY_WITNESSES, MUNI_WITNESSES, BYLAW_WITNESSES, GROUNDS, SCENARIOS, STACK_HEADS, SCALE, LAWYERS, TIMELINE, CHECKLIST, JOURNAL_SEED, CALL_SCRIPT, FAMILY_GROUNDS, FAMILY_SCENARIOS, FAMILY_STACK_HEADS, FAMILY_LAWYERS, FAMILY_CHECKLIST, FAMILY_TIMELINE, FAMILY_CALL_SCRIPT, MUNI_GROUNDS, MUNI_SCENARIOS, MUNI_STACK_HEADS, MUNI_LAWYERS, MUNI_CHECKLIST, MUNI_TIMELINE, MUNI_CALL_SCRIPT, BYLAW_GROUNDS, BYLAW_SCENARIOS, BYLAW_STACK_HEADS, BYLAW_LAWYERS, BYLAW_CHECKLIST, BYLAW_TIMELINE, BYLAW_CALL_SCRIPT;

async function fetchCaseData() {
  if (!_sb) return;
  const { data } = await _sb.from('brief_data').select('value').eq('key','cases').single();
  window._hasCases = !!data;
  if (!data) return;
  window._caseTitle = data.value && data.value.TITLE;
  ({ FACTS, FAMILY_FACTS, MUNI_FACTS, BYLAW_FACTS, WITNESSES, FAMILY_WITNESSES, MUNI_WITNESSES, BYLAW_WITNESSES, GROUNDS, SCENARIOS, STACK_HEADS, SCALE, LAWYERS, TIMELINE, CHECKLIST, JOURNAL_SEED, CALL_SCRIPT, FAMILY_GROUNDS, FAMILY_SCENARIOS, FAMILY_STACK_HEADS, FAMILY_LAWYERS, FAMILY_CHECKLIST, FAMILY_TIMELINE, FAMILY_CALL_SCRIPT, MUNI_GROUNDS, MUNI_SCENARIOS, MUNI_STACK_HEADS, MUNI_LAWYERS, MUNI_CHECKLIST, MUNI_TIMELINE, MUNI_CALL_SCRIPT,
     BYLAW_GROUNDS, BYLAW_SCENARIOS, BYLAW_STACK_HEADS, BYLAW_LAWYERS, BYLAW_CHECKLIST, BYLAW_TIMELINE, BYLAW_CALL_SCRIPT } = data.value);
}

// Fallbacks (|| []) keep new users (no brief_data:cases row yet) from crashing
// the render pipeline — they get an empty shell instead of undefined.forEach.
// Party names are private: they come from the user's own fragments row, never source.
function TITLE(k) { return (window._fragTitles || {})[k] || window._caseTitle || 'Brief'; }

function CASES() {
  return {
    rcmp:   { facts:FACTS||[],        witnesses:WITNESSES||[],        grounds:GROUNDS||[],        scenarios:SCENARIOS||[],        stack:STACK_HEADS||[],        lawyers:LAWYERS||[],        timeline:TIMELINE||[],        script:CALL_SCRIPT||'',        maxHigh:600, file:'CASE-0001', title:TITLE('rcmp') },
    family: { facts:FAMILY_FACTS||[], witnesses:FAMILY_WITNESSES||[], grounds:FAMILY_GROUNDS||[], scenarios:FAMILY_SCENARIOS||[], stack:FAMILY_STACK_HEADS||[], lawyers:FAMILY_LAWYERS||[], timeline:FAMILY_TIMELINE||[], script:FAMILY_CALL_SCRIPT||'', maxHigh:200, file:'CASE-0002', title:TITLE('family') },
    muni:   { facts:MUNI_FACTS||[],   witnesses:MUNI_WITNESSES||[],   grounds:MUNI_GROUNDS||[],   scenarios:MUNI_SCENARIOS||[],   stack:MUNI_STACK_HEADS||[],   lawyers:MUNI_LAWYERS||[],   timeline:MUNI_TIMELINE||[],   script:MUNI_CALL_SCRIPT||'',   maxHigh:8,   file:'CASE-0003', title:TITLE('muni') },
    // ponytail: amounts here are a small fine, so `high` stays in the same thousands-of-dollars
    // unit as the other cases (0.077 = $77) and maxHigh scales to match.
    bylaw:  { facts:BYLAW_FACTS||[],  witnesses:BYLAW_WITNESSES||[],  grounds:BYLAW_GROUNDS||[],  scenarios:BYLAW_SCENARIOS||[],  stack:BYLAW_STACK_HEADS||[],  lawyers:BYLAW_LAWYERS||[],  timeline:BYLAW_TIMELINE||[],  script:BYLAW_CALL_SCRIPT||'',  maxHigh:0.12, file:'CASE-0004', title:TITLE('bylaw') },
  };
}
function hasBriefData() { return !!window._hasCases; } // a new brief has no grounds yet, but it exists
function C() { return CASES()[webActiveCase] || CASES().rcmp; }

const CL_STORE        = 'brief.v3.checklist';
const CL_STORE_FAMILY = 'brief.v3.checklist.family';
const CL_STORE_MUNI   = 'brief.v3.checklist.muni';
const CL_STORE_BYLAW  = 'brief.v3.checklist.bylaw';
function getActiveChecklist() { return (webActiveCase === 'family' ? FAMILY_CHECKLIST : webActiveCase === 'muni' ? MUNI_CHECKLIST : webActiveCase === 'bylaw' ? BYLAW_CHECKLIST : CHECKLIST) || []; }
function getClStore() { return webActiveCase === 'family' ? CL_STORE_FAMILY : webActiveCase === 'muni' ? CL_STORE_MUNI : webActiveCase === 'bylaw' ? CL_STORE_BYLAW : CL_STORE; }

function setActiveCase(id) {
  webActiveCase = id;
  document.body.dataset.activecase = id;
  document.querySelectorAll('.cs-btn').forEach(b => b.classList.toggle('active', b.dataset.case === id));
  const f = document.getElementById('stripFile');
  if (f) f.textContent = C().file;
  document.title = C().title;
  const bt = document.getElementById('briefTitle');
  if (bt) bt.textContent = C().title;
  renderFacts();
  renderWitnesses();
  renderGrounds('grounds-case', '');
  renderGrounds('grounds-money', '2');
  renderScenarios();
  renderStack();
  document.querySelectorAll('.stack-toggle button').forEach(b => b.classList.toggle('active', b.dataset.m === stackMode));
  renderLawyers();
  renderChecklist();
  renderTimeline();
  if (id === 'rcmp') {
    renderLeverage();
    renderScaleBands();
  }
  const scriptEl = document.getElementById('scriptText');
  if (scriptEl) scriptEl.textContent = C().script;
}

// ===== LEVERAGE =====
const LAWYER_LEVERAGE = { none:0, voicemail:5, emailed:15, callback:40, consulted:50, retained:180 };
const BASELINE_PROJECTION = 400;
const CEILING_PROJECTION  = 3000;

let _lawyerStatuses = {};
const STATUS_CYCLE = ['none','voicemail','emailed','callback','consulted','retained','declined'];
const STATUS_LABEL = { none:'Not contacted', voicemail:'Voicemail left', emailed:'Email sent', callback:'Callback received', consulted:'Consulted June 26, 2026', retained:'Retained', declined:'Declined' };
// Fixed UI words go through tr() (auth.js). Dates follow the picked language; the date inside a status label is left as written.
const LOC = () => { const l = document.documentElement.lang; return !l || l === 'en' ? 'en-US' : l; };
const PA_M = ['ਜਨਵਰੀ','ਫ਼ਰਵਰੀ','ਮਾਰਚ','ਅਪ੍ਰੈਲ','ਮਈ','ਜੂਨ','ਜੁਲਾਈ','ਅਗਸਤ','ਸਤੰਬਰ','ਅਕਤੂਬਰ','ਨਵੰਬਰ','ਦਸੰਬਰ']; // Chrome ships no Punjabi month names
const dfmt = (d, o) => LOC() === 'pa' ? d.getDate() + ' ' + PA_M[d.getMonth()] + ' ' + d.getFullYear() : d.toLocaleDateString(LOC(), o).toUpperCase();
const fmtD = (iso, o) => dfmt(new Date(iso + 'T12:00:00'), o);
const sl = st => st === 'consulted' ? tr('Consulted') + ' June 26, 2026' : tr(STATUS_LABEL[st]);
const SC_COLOR = { green:'var(--good)', blue:'var(--info)', amber:'var(--warn)', red:'var(--danger)' };

// Rolls up the case's projected leverage from three sources: completed checklist
// items (each worth a fixed weight), plus lawyer-contact status chips read straight
// from the DOM. Only one "retained" lawyer counts at full weight (dedup guard); any
// additional non-retained statuses (contacted, replied, etc.) stack but are capped
// at 80 total until an actual retainer exists, so status-chip spam can't inflate the
// projection past what an unrepresented case realistically has. Total is clamped to
// CEILING_PROJECTION regardless.
function computeLeverage() {
  const evidence = (CHECKLIST||[]).reduce((s,x) => s + (x.done ? x.lev : 0), 0);
  let counselLev = 0, counselRetained = false;
  document.querySelectorAll('.tag.status').forEach(chip => {
    const st = chip.dataset.status;
    if (st === 'retained') {
      if (!counselRetained) { counselLev += LAWYER_LEVERAGE.retained; counselRetained = true; }
    } else if (LAWYER_LEVERAGE[st]) {
      counselLev += LAWYER_LEVERAGE[st];
    }
  });
  if (!counselRetained) counselLev = Math.min(counselLev, 80);
  const total = Math.min(CEILING_PROJECTION, BASELINE_PROJECTION + evidence + counselLev);
  return { evidence, counselLev, counselRetained, total };
}

function renderLeverage() {
  const el = document.getElementById('leverage-widget');
  if (!el) return;
  const { evidence, counselLev, counselRetained, total } = computeLeverage();
  const delta = total - BASELINE_PROJECTION;
  const pct = Math.min(100, ((total - BASELINE_PROJECTION) / (CEILING_PROJECTION - BASELINE_PROJECTION)) * 100);

  const tlv = document.getElementById('triLiveVal');
  if (tlv) {
    tlv.textContent = '$' + total + 'k';
    const tls = document.getElementById('triLiveSub');
    if (tls) tls.textContent = delta > 0 ? '+$' + delta + 'k ' + tr('earned through leverage') : tr('baseline - no leverage yet');
  }

  pushSparkline(total);

  const pendingItems = (CHECKLIST||[]).filter(x => !x.done).sort((a,b) => b.lev - a.lev).slice(0,3);
  const counselLine = counselRetained ? '' :
    '<div class="lev-row"><div class="lev-row-l"><div class="lev-dot"></div><div>' +
    '<div class="lev-row-name">' + tr('Retain counsel') + '</div>' +
    '<div class="lev-row-sub">' + tr('one signed retainer unlocks the biggest single step') + '</div>' +
    '</div></div><div class="lev-row-amt tnum">+$' + LAWYER_LEVERAGE.retained + 'k</div></div>';

  const pendingLines = pendingItems.map(it =>
    '<div class="lev-row" data-cl="' + it.i + '">' +
    '<div class="lev-row-l"><div class="lev-dot"></div><div>' +
    '<div class="lev-row-name">' + it.label + '</div>' +
    '<div class="lev-row-sub">' + tr(it.pri === 'now' ? 'Priority - immediate' : 'Soon - pre-retainer') + '</div>' +
    '</div></div><div class="lev-row-amt tnum">+$' + it.lev + 'k</div></div>'
  ).join('');

  el.innerHTML =
    '<div class="section-hd"><div class="lbl"><b>' + tr('Settlement leverage') + '</b> - ' + tr('live projection') + '</div><div class="hint">' + tr('complete actions to move projection') + '</div></div>' +
    '<div class="lev-card">' +
    '<div class="lev-tot">' +
    '<div class="lev-tot-l">' +
    '<div class="lev-tot-lbl">' + tr('Projected settlement today') + '</div>' +
    '<div class="lev-tot-val tnum" id="levTotVal">$' + total + 'k</div>' +
    '<div class="lev-tot-delta">' +
    '<span class="lev-delta-pill">+$' + delta + 'k ' + tr('vs baseline') + '</span>' +
    '<span class="lev-tot-sub">' + tr('baseline') + ' $' + BASELINE_PROJECTION + 'k - ' + tr('trial ceiling') + ' $' + (CEILING_PROJECTION/1000).toFixed(2) + 'M</span>' +
    '</div></div>' +
    '<div class="lev-tot-r"><div class="lev-breakdown">' +
    '<div class="lev-bd-row"><span>' + tr('Baseline') + '</span><span class="tnum">$' + BASELINE_PROJECTION + 'k</span></div>' +
    '<div class="lev-bd-row"><span>' + tr('Evidence built') + '</span><span class="tnum lev-pos">+$' + evidence + 'k</span></div>' +
    '<div class="lev-bd-row"><span>' + tr('Counsel posture') + '</span><span class="tnum lev-pos">+$' + counselLev + 'k</span></div>' +
    '</div></div></div>' +
    '<div class="lev-bar">' +
    '<div class="lev-bar-track"></div>' +
    '<div class="lev-bar-fill" style="width:' + pct + '%"></div>' +
    '<div class="lev-bar-marker" style="left:' + pct + '%"></div>' +
    '<span class="lev-bar-val" style="left:clamp(28px,' + pct + '%,calc(100% - 28px))">$' + total + 'k</span>' +
    '<div class="lev-bar-anchors"><span>' + tr('Baseline') + '</span><span>' + tr('Ceiling') + '</span></div>' +
    '</div></div>' +
    '<div class="lev-list"><div class="lev-list-hd">' + tr('Top levers not yet pulled') + '</div>' +
    counselLine + pendingLines + '</div>';

  const pill = document.getElementById('pillVal');
  if (pill) pill.textContent = '$' + total + 'k';

  renderTrajectory(total);
}

function pushSparkline(v) {
  const KEY = 'brief.v3.spark';
  let hist = JSON.parse(localStorage.getItem(KEY) || '[]');
  if (hist.length === 0) hist.push(BASELINE_PROJECTION, v);
  else if (hist[hist.length-1] !== v) hist.push(v);
  if (hist.length > 16) hist = hist.slice(-16);
  localStorage.setItem(KEY, JSON.stringify(hist));
  drawSparkline(hist);
}

function drawSparkline(hist) {
  const svg = document.getElementById('pillSpark');
  if (!svg || hist.length < 2) return;
  const W = 36, H = 12, min = Math.min(...hist), max = Math.max(...hist), rng = max - min || 1;
  const pts = hist.map((v,i) => (i/(hist.length-1)*W).toFixed(1) + ',' + (H-2-(v-min)/rng*(H-4)).toFixed(1)).join(' ');
  svg.querySelector('polyline').setAttribute('points', pts);
}

function renderTrajectory(currentTotal) {
  const el = document.getElementById('trajectory');
  if (!el) return;
  const steps = [
    { lbl:tr('Today'),       val:currentTotal,                                           delta:0,   kind:'now' },
    { lbl:'+ ' + tr('Retain counsel'), val:Math.min(CEILING_PROJECTION, currentTotal+180),          delta:180, kind:'next' },
    { lbl:'+ ' + tr('Top 5 evidence'), val:Math.min(CEILING_PROJECTION, currentTotal+180+295),      delta:295, kind:'next' },
    { lbl:'+ ' + tr('Claim filed'), val:Math.min(CEILING_PROJECTION, currentTotal+180+295+100),  delta:100, kind:'next' },
    { lbl:tr('Trial-ready'), val:CEILING_PROJECTION,                                      delta:0,   kind:'ceiling' },
  ];
  const details = [
    { l:tr('Where you stand today'),    m:'Current projection of $' + currentTotal + 'k based on completed evidence and counsel posture.', v:'$' + currentTotal + 'k' },
    { l:tr('Retain counsel'),           m:'A signed retainer changes how the other side responds.', v:'+$180k' },
    { l:tr('Complete top 5 evidence'),  m:'The five evidence items with the most leverage, from the checklist.', v:'+$295k' },
    { l:tr('Claim filed'),              m:'Filing turns negotiation into a live court process with deadlines on both sides.', v:'+$100k' },
    { l:tr('Trial-ready evidence'),     m:'Full pleadings and expert reports. A trial is now a credible step.', v:'$' + CEILING_PROJECTION/1000 + 'M ' + tr('ceiling') },
  ];

  const stepsHtml = steps.map((s,i) => {
    const left = (i / (steps.length-1)) * 100;
    return '<div class="traj-step ' + (s.kind==='now'?'now':'') + '" data-i="' + i + '" style="left:' + left + '%">' +
      '<div class="val">$' + s.val + 'k</div>' +
      (s.delta > 0 ? '<div class="traj-delta">+$' + s.delta + 'k</div>' : '') +
      '<div class="dot"></div><div class="lbl">' + s.lbl + '</div></div>';
  }).join('');

  el.innerHTML =
    '<div class="section-hd"><div class="lbl"><b>' + tr('Trajectory') + '</b> - ' + tr('what each next move adds') + '</div><div class="hint">' + tr('tap a step to focus') + '</div></div>' +
    '<div class="traj-card" tabindex="0">' +
    '<div class="traj-track" id="trajTrack"><div class="traj-line"></div>' + stepsHtml + '</div>' +
    '<div class="traj-detail">' +
    '<div class="det-l" id="trajDetailLbl">' + tr('Focus') + '</div>' +
    '<div class="det-m" id="trajDetailMsg">' + details[1].m + '</div>' +
    '<div class="det-r" id="trajDetailVal">' + details[1].v + '</div>' +
    '</div></div>';

  el.querySelectorAll('.traj-step').forEach(step => {
    step.addEventListener('click', () => {
      const i = parseInt(step.dataset.i);
      document.getElementById('trajDetailLbl').textContent = details[i].l;
      document.getElementById('trajDetailMsg').textContent = details[i].m;
      document.getElementById('trajDetailVal').textContent = details[i].v;
      el.querySelectorAll('.traj-step').forEach(s => s.classList.remove('focus'));
      step.classList.add('focus');
      const pv = Math.min(100, ((steps[i].val - BASELINE_PROJECTION) / (CEILING_PROJECTION - BASELINE_PROJECTION)) * 100);
      const fill = document.querySelector('.lev-bar-fill'), marker = document.querySelector('.lev-bar-marker');
      if (fill) fill.style.width = pv + '%';
      if (marker) marker.style.left = pv + '%';
      clearTimeout(window.__trajT);
      if (i !== 0) window.__trajT = setTimeout(renderLeverage, 2400);
      else renderLeverage();
    });
  });
}

// ===== RENDER =====

function setToday() {
  document.getElementById('todayStr').textContent = dfmt(new Date(), {month:'long',day:'numeric',year:'numeric'});
}
setToday();

(function(){
  const incident = new Date('2023-08-01').getTime();
  const expired  = new Date('2025-08-01').getTime();
  const ultimate = new Date('2038-08-01').getTime();
  const now = new Date();
  const nowMs = now.getTime();
  const total = ultimate - incident;
  const pNow = ((nowMs - incident) / total) * 100;
  const pExp = ((expired - incident) / total) * 100;
  const daysSince = Math.floor((nowMs - incident) / 86400000);
  const daysToUlt = Math.floor((ultimate - nowMs) / 86400000);


  const nowClamped = Math.max(8, Math.min(92, pNow));
  const nowRow = document.getElementById('clockNowRow');
  if (!nowRow) return; // the limitation clock is part of the owner's own layout
  const nowLabel = document.createElement('div');
  nowLabel.className = 'clock-now-label';
  nowLabel.style.cssText = 'left:' + nowClamped + '%;bottom:0';
  const whatEl = document.createElement('div'); whatEl.className = 'what'; 
  const whenEl = document.createElement('div'); whenEl.className = 'when'; whenEl.textContent = now.toLocaleDateString('en-US',{month:'long',day:'numeric',year:'numeric'}).toUpperCase();
  window.__relabelClock = () => {
    document.getElementById('daysOut').textContent = daysToUlt.toLocaleString(LOC()) + ' ' + tr('days to ultimate').toUpperCase();
    whatEl.textContent = tr('Today') + ' - ' + daysSince.toLocaleString(LOC()) + ' ' + tr('days in');
  };
  nowLabel.appendChild(whatEl); nowLabel.appendChild(whenEl);
  nowRow.appendChild(nowLabel);
  window.__relabelClock();

  const therapyStart = new Date('2026-05-01').getTime();
  const pTherapy = ((therapyStart - incident) / total) * 100;
  const curve = [];
  for (let i = 0; i <= 80; i++) {
    const x = (i/80)*100;
    const t = x < pTherapy ? x/pTherapy : (x-pTherapy)/(100-pTherapy);
    const y = x < pTherapy ? 0.45+0.55*t : 1.0-0.85*t*t;
    curve.push([x,y]);
  }
  const W=1000, H=70;
  const pathD = curve.map((p,i)=>(i===0?'M':'L')+(p[0]/100*W).toFixed(1)+','+(((1-p[1])*(H-4)+2)).toFixed(1)).join(' ');
  const areaD = pathD + ' L' + W + ',' + H + ' L0,' + H + ' Z';
  const curveYpx = (1-(curve.find(p=>p[0]>=pNow)||curve[curve.length-1])[1])*H;
  const stemHeight = (96-16)-curveYpx;

  const track = document.getElementById('clockTrack');
  track.innerHTML =
    '<svg class="clock-decay-svg" viewBox="0 0 ' + W + ' ' + H + '" preserveAspectRatio="none">' +
    '<defs><linearGradient id="decayGrad" x1="0" x2="0" y1="0" y2="1">' +
    '<stop offset="0%" stop-color="var(--warn)" stop-opacity="0.32"/>' +
    '<stop offset="100%" stop-color="var(--warn)" stop-opacity="0"/>' +
    '</linearGradient></defs>' +
    '<path d="' + areaD + '" fill="url(#decayGrad)"/>' +
    '<path d="' + pathD + '" fill="none" stroke="var(--warn)" stroke-width="1.4" vector-effect="non-scaling-stroke" opacity="0.75"/>' +
    '</svg>' +
    '<div class="clock-line"></div>' +
    '<div class="clock-segment expired" style="left:0%;width:' + pExp + '%"></div>' +
    '<div class="clock-segment runway" style="left:' + pExp + '%;width:' + (pNow-pExp) + '%"></div>' +
    '<div class="clock-tick t-incident" style="left:0%;transform:translateX(-50%)"><div class="dot"></div></div>' +
    '<div class="clock-tick t-expired" style="left:' + pExp + '%;transform:translateX(-50%)"><div class="dot"></div></div>' +
    '<div class="clock-tick t-now" style="left:' + pNow + '%;transform:translateX(-50%)"><div class="stem" style="height:' + Math.max(0,stemHeight).toFixed(1) + 'px"></div><div class="dot"></div></div>' +
    '<div class="clock-tick t-ultimate" style="left:100%;transform:translateX(-50%)"><div class="dot"></div></div>';

  const labels = document.getElementById('clockLabels');
  const tight = pExp < 18;
  if (tight) {
    labels.innerHTML =
      '<div class="clock-label left exp"><div class="when">Aug 2023 to Aug 2025</div><div class="what">Incident to Basic expired</div></div>' +
      '<div class="clock-label right"><div class="when">Aug 2038</div><div class="what">Ultimate</div></div>';
  } else {
    labels.innerHTML =
      '<div class="clock-label left"><div class="when">Aug 2023</div><div class="what">Incident</div></div>' +
      '<div class="clock-label exp mid" style="left:' + pExp + '%;transform:translateX(-50%)"><div class="when">Aug 2025</div><div class="what">Basic expired</div></div>' +
      '<div class="clock-label right"><div class="when">Aug 2038</div><div class="what">Ultimate</div></div>';
  }

  const capSpan = document.getElementById('clockCapDecay');
  if (capSpan) {
    const pastPeak = Date.now() > new Date('2026-05-31').getTime();
    capSpan.innerHTML = pastPeak
      ? '<b>peaked May 2026, now decaying</b>'
      : 'peaks May 2026 &middot; decays toward ultimate &middot; <b>time is an enemy</b>';
  }
})();

function renderGrounds(containerId, suffix) {
  const c = document.getElementById(containerId);
  if (!c) return;
  while (c.firstChild) c.removeChild(c.firstChild);
  const data = C().grounds;
  const maxHigh = C().maxHigh;
  data.forEach(g => {
    const w = document.createElement('div');
    w.className = 'ground';
    w.dataset.id = g.id + suffix;
    w.tabIndex = 0; w.setAttribute('role', 'button');
    w.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); w.click(); } });
    const pct = (g.high / maxHigh) * 100;

    const hd = document.createElement('div'); hd.className = 'ground-hd';
    const n = document.createElement('div'); n.className = 'ground-n serif'; n.textContent = g.n;
    const info = document.createElement('div'); info.className = 'ground-info';
    const title = document.createElement('div'); title.className = 'ground-title serif'; title.textContent = g.title;
    const sec = document.createElement('div'); sec.className = 'ground-sec'; sec.textContent = g.sec;
    info.appendChild(title); info.appendChild(sec);
    const val = document.createElement('div'); val.className = 'ground-val tnum'; val.textContent = g.val;
    const grade = document.createElement('div'); grade.className = 'ground-grade g-' + g.grade; grade.textContent = g.grade;
    hd.appendChild(n); hd.appendChild(info); hd.appendChild(val); hd.appendChild(grade);

    const mag = document.createElement('div'); mag.className = 'ground-mag';
    const fill = document.createElement('div'); fill.className = 'ground-mag-fill';
    fill.dataset.w = pct.toFixed(1);
    fill.style.background = 'var(--grade-' + g.grade.toLowerCase() + ')';
    mag.appendChild(fill);

    const body = document.createElement('div'); body.className = 'ground-body';
    const inner = document.createElement('div'); inner.className = 'ground-inner';
    const desc = document.createElement('div'); desc.className = 'ground-desc'; desc.textContent = g.desc;
    const cite = document.createElement('div'); cite.className = 'ground-cite'; cite.textContent = g.cite;
    inner.appendChild(desc);
    if (g.risk) {
      const parts = g.risk.split(' · Counter:');
      const da = document.createElement('div'); da.className = 'ground-da';
      const daLbl = document.createElement('span'); daLbl.className = 'ground-da-label'; daLbl.textContent = tr("They'll argue");
      const daTxt = document.createElement('span'); daTxt.className = 'ground-da-text'; daTxt.textContent = parts[0].replace(/^AG argues\s*/i, '');
      da.append(daLbl, daTxt); inner.appendChild(da);
      if (parts[1]) {
        const counter = document.createElement('div'); counter.className = 'ground-da ground-da-counter';
        const cLbl = document.createElement('span'); cLbl.className = 'ground-da-label'; cLbl.textContent = tr('Counter');
        const cTxt = document.createElement('span'); cTxt.className = 'ground-da-text'; cTxt.textContent = parts[1].trim();
        counter.append(cLbl, cTxt); inner.appendChild(counter);
      }
    }
    if (g.cite) inner.appendChild(cite); // grounds added in the app have no citation yet
    body.appendChild(inner);

    w.appendChild(hd); w.appendChild(mag); w.appendChild(body);
    c.appendChild(w);

    w.addEventListener('click', () => {
      const open = w.classList.contains('open');
      c.querySelectorAll('.ground').forEach(x => x.classList.remove('open'));
      if (!open) {
        w.classList.add('open');
        w.querySelector('.ground-mag-fill').style.width = w.querySelector('.ground-mag-fill').dataset.w + '%';
      }
    });
  });
}
renderGrounds('grounds-case', '');
renderGrounds('grounds-money', '2');

function renderScenarios() {
  const c = document.getElementById('scenarios');
  if (!c) return;
  while (c.firstChild) c.removeChild(c.firstChild);
  const data = C().scenarios;
  data.forEach((s,i) => {
    const d = document.createElement('div'); d.className = 'scen';
    const row = document.createElement('div'); row.className = 'scen-row';
    const left = document.createElement('div');
    const name = document.createElement('div'); name.className = 'scen-name serif'; name.textContent = s.name;
    const desc = document.createElement('div'); desc.className = 'scen-desc'; desc.textContent = s.desc;
    left.appendChild(name); left.appendChild(desc);
    const right = document.createElement('div'); right.className = 'scen-right';
    const amt = document.createElement('div'); amt.className = 'scen-amt tnum'; amt.style.color = SC_COLOR[s.color] || s.color; amt.textContent = s.amt;
    const pct = document.createElement('div'); pct.className = 'scen-pct'; pct.textContent = s.pct + '% ' + tr('probability');
    right.appendChild(amt); right.appendChild(pct);
    row.appendChild(left); row.appendChild(right);
    const barTrack = document.createElement('div'); barTrack.className = 'bar-track';
    const barFill = document.createElement('div'); barFill.className = 'bar-fill';
    barFill.dataset.w = s.pct; barFill.style.background = s.color; barFill.style.transitionDelay = (i*100) + 'ms';
    barTrack.appendChild(barFill);
    d.appendChild(row); d.appendChild(barTrack);
    c.appendChild(d);
  });
}
renderScenarios();

let stackMode = 'strong';
function renderStack() {
  const c = document.getElementById('stackRows');
  if (!c) return;
  c.innerHTML = '';
  const heads = C().stack;
  const total = heads.reduce((s,h) => s + (stackMode==='strong'?h.high:h.low), 0);
  const max = Math.max(...heads.map(h => stackMode==='strong'?h.high:h.low));
  document.getElementById('stackTot').textContent = '$' + (total/1000).toFixed(2) + 'M';
  heads.forEach(h => {
    const v = stackMode==='strong' ? h.high : h.low;
    const pct = (v/max)*100;
    const r = document.createElement('div'); r.className = 'stack-row';
    const badge = document.createElement('div'); badge.className = 'badge g-' + h.grade; badge.textContent = h.grade;
    const mid = document.createElement('div'); mid.className = 'mid';
    const info = document.createElement('div');
    const lbl = document.createElement('div'); lbl.className = 'label'; lbl.textContent = h.label;
    const sub = document.createElement('div'); sub.className = 'sub'; sub.textContent = h.sub;
    info.appendChild(lbl); info.appendChild(sub);
    const meter = document.createElement('div'); meter.className = 'meter';
    const mFill = document.createElement('div'); mFill.dataset.w = pct.toFixed(1); mFill.style.background = 'var(--grade-' + h.grade.toLowerCase() + ')';
    meter.appendChild(mFill); mid.appendChild(info); mid.appendChild(meter);
    const amtEl = document.createElement('div'); amtEl.className = 'amt tnum'; amtEl.textContent = '$' + (v<1000 ? v+'k' : (v/1000).toFixed(2)+'M');
    r.appendChild(badge); r.appendChild(mid); r.appendChild(amtEl);
    c.appendChild(r);
  });
  requestAnimationFrame(() => requestAnimationFrame(() => {
    c.querySelectorAll('.meter > div').forEach(b => b.style.width = b.dataset.w + '%');
  }));
}
renderStack();
document.querySelectorAll('.stack-toggle button').forEach(b => {
  b.addEventListener('click', () => {
    stackMode = b.dataset.m;
    document.querySelectorAll('.stack-toggle button').forEach(x => x.classList.remove('active'));
    b.classList.add('active');
    renderStack();
  });
});

function renderScaleBands() {
  if (!SCALE) return;
  const c = document.getElementById('scaleBands');
  if (!c) return;
  c.textContent = '';
  SCALE.forEach(band => {
    const d = document.createElement('div'); d.className = 'scale-band'; d.tabIndex = 0;
    const hd = document.createElement('div'); hd.className = 'scale-band-hd';
    const lbl = document.createElement('div'); lbl.className = 'lbl'; lbl.textContent = band.band;
    const max = document.createElement('div'); max.className = 'max';
    max.textContent = tr('scale: $0 to $') + (band.max>=1000 ? (band.max/1000).toFixed(1)+'M' : band.max+'k');
    hd.appendChild(lbl); hd.appendChild(max); d.appendChild(hd);

    const track = document.createElement('div'); track.className = 'scale-track';
    const line = document.createElement('div'); line.className = 'line'; track.appendChild(line);
    band.marks.forEach(m => {
      const mk = document.createElement('div'); mk.className = 'scale-mark' + (m.isThis?' this':'');
      mk.style.left = (m.k / band.max * 100) + '%';
      const dot = document.createElement('div'); dot.className = 'dot';
      const mlbl = document.createElement('div'); mlbl.className = 'lbl'; mlbl.textContent = m.lbl;
      mk.appendChild(dot); mk.appendChild(mlbl); track.appendChild(mk);
    });
    d.appendChild(track);

    const list = document.createElement('div'); list.className = 'scale-list';
    band.rows.forEach(row => {
      const rowEl = document.createElement('div'); rowEl.className = 'row';
      const name = document.createElement('div'); name.className = 'name';
      const nameText = document.createTextNode(row.name + ' ');
      const yr = document.createElement('span'); yr.className = 'yr'; yr.textContent = '- ' + row.yr + ' - ' + row.note;
      name.appendChild(nameText); name.appendChild(yr);
      const v = document.createElement('div'); v.className = 'v tnum'; v.textContent = row.v;
      rowEl.appendChild(name); rowEl.appendChild(v); list.appendChild(rowEl);
    });
    d.appendChild(list);
    c.appendChild(d);
  });
}

function renderLawyers() {
  const c = document.getElementById('lawyers');
  if (!c) return;
  while (c.firstChild) c.removeChild(c.firstChild);
  const data = C().lawyers;
  data.forEach(L => {
    const isPriority = L.fit >= 5; // the best fits lead, from the data, not names in source
    const d = document.createElement('div'); d.className = 'lawyer' + (isPriority ? ' priority' : ''); d.dataset.lawyerId = L.id;

    const av = document.createElement('div'); av.className = 'lawyer-av'; av.textContent = L.init;
    const body = document.createElement('div'); body.className = 'lawyer-body';
    const nameRow = document.createElement('div'); nameRow.className = 'lawyer-name-row';
    const name = document.createElement('div'); name.className = 'lawyer-name'; name.textContent = L.name;
    const fits = document.createElement('div'); fits.className = 'fit-dots fit-' + L.fit; fits.dataset.fit = L.fit; fits.title = tr('Case fit') + ' ' + L.fit + '/5';
    fits.textContent = '●'.repeat(L.fit) + '○'.repeat(5-L.fit);
    nameRow.appendChild(name); if (L.fit) nameRow.appendChild(fits); // lawyers added in the app have no fit yet
    const sub = document.createElement('div'); sub.className = 'lawyer-sub'; sub.textContent = L.sub;
    const tags = document.createElement('div'); tags.className = 'lawyer-tags';
    L.tags.forEach(t => { const tg = document.createElement('span'); tg.className = 'tag ' + (t.c||''); tg.textContent = t.t; tags.appendChild(tg); });
    const chip = document.createElement('span'); chip.className = 'tag status ' + L.status; chip.dataset.status = L.status; chip.textContent = sl(L.status);
    chip.tabIndex = 0; chip.setAttribute('role', 'button');
    tags.appendChild(chip);
    body.appendChild(nameRow); body.appendChild(sub); body.appendChild(tags);

    const actions = document.createElement('div'); actions.className = 'lawyer-actions';
    L.contacts.forEach(ct => {
      const a = document.createElement('a'); a.className = 'contact' + (ct.primary?' primary':''); a.href = ct.href;
      const ic = document.createElement('span'); ic.className = 'ic'; ic.textContent = ct.kind;
      const lbl = document.createElement('span'); lbl.textContent = ct.label;
      a.appendChild(ic); a.appendChild(lbl); actions.appendChild(a);
    });

    d.appendChild(av); d.appendChild(body); d.appendChild(actions);
    c.appendChild(d);

    chip.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); chip.click(); } });
    chip.addEventListener('click', e => {
      e.stopPropagation();
      const cur = chip.dataset.status;
      const next = STATUS_CYCLE[(STATUS_CYCLE.indexOf(cur)+1)%STATUS_CYCLE.length];
      chip.dataset.status = next;
      chip.className = 'tag status ' + next;
      chip.textContent = sl(next);
      _lawyerStatuses[L.id] = next;
      if (_userId && webActiveCase === 'rcmp') _sb.from('brief_lawyer_status').upsert({ user_id:_userId, lawyer_id:L.id, status:next });
      if (webActiveCase === 'rcmp') renderLeverage();
    });
  });
}
renderLawyers();

// Facts, same {key, value} rows the apps add. Accounts on the shell page render into #facts. The owner's
// own layout has a fixed fact sheet instead, so the list goes right after it and skips any label the
// sheet already shows: only facts added later in an app or here appear, each once.
function renderFacts() {
  let c = document.getElementById('facts');
  const sheet = [...document.querySelectorAll('.page .facts:not(#facts)')].find(e => e.getClientRects().length); // the open case's sheet
  if (!c && sheet) c = Object.assign(document.createElement('div'), { id: 'facts', className: 'facts' });
  if (!c) return;
  if (sheet) { const add = document.querySelector('.author-add[data-label="Add fact"]'); sheet.after(c); if (add) c.after(add); }
  const shown = new Set(sheet ? [...sheet.querySelectorAll('.k')].map(k => k.textContent.trim().toLowerCase()) : []);
  const sheetText = sheet ? sheet.textContent.toLowerCase() : '';
  const onSheet = f => shown.has(f.key.trim().toLowerCase()) || (String(f.value).trim().length >= 8 && sheetText.includes(String(f.value).trim().toLowerCase()));
  c.rows = C().facts.filter(f => f && f.key && !onSheet(f));
  c.textContent = '';
  c.rows.forEach(f => {
    const row = document.createElement('div'); row.className = 'row';
    const k = document.createElement('div'); k.className = 'k'; k.textContent = f.key;
    const v = document.createElement('div'); v.className = 'v'; v.textContent = f.value;
    row.append(k, v); c.appendChild(row);
  });
}

// Witnesses, same shape as the apps. The owner's layout has fixed witness cards, so the list goes after the
// open case's last card and skips anyone it already shows, the same way renderFacts does.
function renderWitnesses() {
  let c = document.getElementById('witnesses');
  const cards = [...document.querySelectorAll('.page .witness')].filter(e => !e.closest('#witnesses') && e.getClientRects().length);
  const last = cards[cards.length - 1];
  if (!c && last) c = Object.assign(document.createElement('div'), { id: 'witnesses' });
  if (!c) return;
  if (last) { const add = document.querySelector('.author-add[data-label="Add witness"]'); last.after(c); if (add) c.after(add); }
  const shown = new Set(cards.map(e => (e.querySelector('.witness-name') || {}).textContent).filter(Boolean).map(t => t.trim().toLowerCase()));
  c.rows = C().witnesses.filter(w => w && w.name && !shown.has(w.name.trim().toLowerCase()));
  c.textContent = '';
  c.rows.forEach(w => {
    const d = document.createElement('div'); d.className = 'witness';
    const hd = document.createElement('div'); hd.className = 'witness-hd';
    const av = document.createElement('div'); av.className = 'witness-av'; av.textContent = w.initials || '';
    const main = document.createElement('div'); main.className = 'witness-main';
    const name = document.createElement('div'); name.className = 'witness-name'; name.textContent = w.name;
    const role = document.createElement('div'); role.className = 'witness-role'; role.textContent = [w.role, w.date].filter(Boolean).join(' · ');
    main.append(name, role); hd.append(av, main); d.appendChild(hd);
    if (w.statement) { const st = document.createElement('div'); st.className = 'witness-stmt'; st.textContent = w.statement; d.appendChild(st); }
    c.appendChild(d);
  });
}

function renderTimeline() {
  const c = document.getElementById('timeline');
  if (!c) return;
  while (c.firstChild) c.removeChild(c.firstChild);
  const data = C().timeline;
  data.forEach((t,i) => {
    const d = document.createElement('div'); d.className = 'tl-item';
    const when = document.createElement('div'); when.className = 'tl-when'; // a known day reads in the viewer's language
    when.textContent = t.due ? new Date(t.due + 'T12:00').toLocaleDateString(document.documentElement.lang || undefined, { dateStyle: 'medium' }) : t.when;
    const rail = document.createElement('div'); rail.className = 'tl-rail';
    const dot = document.createElement('div'); dot.className = 'tl-dot ' + (t.state||'');
    rail.appendChild(dot);
    if (i < data.length-1) { const line = document.createElement('div'); line.className = 'tl-line'; rail.appendChild(line); }
    const body = document.createElement('div'); body.className = 'tl-body';
    const title = document.createElement('div'); title.className = 'tl-title serif'; title.textContent = t.title;
    const desc = document.createElement('div'); desc.className = 'tl-desc'; desc.textContent = t.desc;
    body.appendChild(title); body.appendChild(desc);
    if (t.rule) { const r = document.createElement('div'); r.className = 'tl-rule'; r.textContent = t.rule; body.appendChild(r); }
    d.appendChild(when); d.appendChild(rail); d.appendChild(body);
    c.appendChild(d);
  });
}
renderFacts();
renderWitnesses();
renderTimeline();

function renderChecklist() {
  const c = document.getElementById('checklist');
  if (!c) return;
  while (c.firstChild) c.removeChild(c.firstChild);
  const cl = getActiveChecklist();
  const store = getClStore();
  const saved = JSON.parse(localStorage.getItem(store) || '{}');
  cl.forEach(it => { if (saved[it.i] !== undefined) it.done = saved[it.i]; });
  cl.sort((a, b) => (a.done === b.done) ? b.lev - a.lev : a.done ? 1 : -1);
  cl.forEach(it => {
    const d = document.createElement('div'); d.className = 'cl-item'; d.dataset.i = it.i;
    d.tabIndex = 0; d.setAttribute('role', 'checkbox'); d.setAttribute('aria-checked', !!it.done);
    d.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); d.click(); } });
    const box = document.createElement('div'); box.className = 'cl-box' + (it.done?' done':'');
    const lbl = document.createElement('div'); lbl.className = 'cl-label' + (it.done?' done':''); lbl.textContent = it.label;
    const lev = document.createElement('div'); lev.className = 'cl-lev' + (it.done?' done':''); lev.textContent = '+$' + it.lev + 'k';
    const pri = document.createElement('div'); pri.className = 'cl-pri ' + it.pri; pri.dataset.pri = it.pri; pri.textContent = tr(it.pri);
    d.appendChild(box); d.appendChild(lbl); d.appendChild(lev); d.appendChild(pri);
    c.appendChild(d);
    d.addEventListener('click', () => {
      setChecklistItem(it.i, !it.done);
      // Repaint in place rather than re-rendering: renderChecklist re-sorts, and
      // rows jumping out from under the cursor is worse than a stale sort order.
      box.classList.toggle('done', it.done);
      lbl.classList.toggle('done', it.done);
      lev.classList.toggle('done', it.done);
      d.setAttribute('aria-checked', it.done);
    });
  });
  updateClProg();
}
renderChecklist();

// Single write path for a checklist item -- the row click and the WebMCP tool
// both land here, so persistence and the leverage recompute can't drift.
function setChecklistItem(index, done) {
  const cl = getActiveChecklist();
  const it = cl.find(x => String(x.i) === String(index));
  if (!it) return { error: `No checklist item ${index}` };
  it.done = !!done;
  const store = getClStore();
  const s = JSON.parse(localStorage.getItem(store) || '{}');
  s[it.i] = it.done;
  localStorage.setItem(store, JSON.stringify(s));
  if (_userId && webActiveCase === 'rcmp') _sb.from('brief_checklist').upsert({ user_id:_userId, item_index:parseInt(it.i), completed:it.done });
  updateClProg();
  if (webActiveCase === 'rcmp') renderLeverage();
  return { index: it.i, label: it.label, done: it.done };
}

function updateClProg() {
  const cl = getActiveChecklist();
  const done = cl.filter(x => x.done).length;
  if (!document.getElementById('clCount')) return;
  document.getElementById('clCount').textContent = done;
  document.getElementById('clTotal').textContent = cl.length;
  document.getElementById('clBar').style.width = (done/cl.length*100) + '%';
}

const DATE_S = {month:'short',day:'numeric',year:'numeric'};
function renderJournalEntries(entries) {
  const list = document.getElementById('journalList');
  if (!list) return;
  while (list.firstChild) list.removeChild(list.firstChild);
  entries.forEach(e => {
    const d = document.createElement('div'); d.className = 'j-entry';
    const when = document.createElement('div'); when.className = 'when'; when.dataset.d = e.date; when.textContent = fmtD(e.date, DATE_S);
    const what = document.createElement('div'); what.className = 'what serif'; what.textContent = e.text;
    d.appendChild(when); d.appendChild(what);
    list.appendChild(d);
  });
}

const J_STORE = 'brief.v3.journal';
(function(){
  const saved = JSON.parse(localStorage.getItem(J_STORE) || '[]');
  const map = {};
  (JOURNAL_SEED || []).forEach(e => map[e.date] = e);
  saved.forEach(e => map[e.date] = e);
  renderJournalEntries(Object.values(map).sort((a,b) => b.date.localeCompare(a.date)));

  const btn = document.getElementById('jAddBtn');
  const form = document.getElementById('jForm');
  const dateI = document.getElementById('jDate');
  const txtI = document.getElementById('jText');
  if (!btn || !form) return;
  const today = new Date().toISOString().slice(0,10);
  dateI.value = today; dateI.max = today;

  btn.addEventListener('click', () => { form.classList.toggle('open'); if (form.classList.contains('open')) txtI.focus(); });
  document.getElementById('jCancel').addEventListener('click', () => { form.classList.remove('open'); txtI.value = ''; });
  document.getElementById('jSave').addEventListener('click', () => {
    const txt = txtI.value.trim(); if (!txt) return;
    const s = JSON.parse(localStorage.getItem(J_STORE) || '[]');
    s.push({ date:dateI.value, text:txt });
    localStorage.setItem(J_STORE, JSON.stringify(s));
    const m = {};
    (JOURNAL_SEED || []).forEach(e => m[e.date] = e);
    s.forEach(e => m[e.date] = e);
    renderJournalEntries(Object.values(m).sort((a,b) => b.date.localeCompare(a.date)));
    txtI.value = ''; form.classList.remove('open');
  });
})();

function renderDocuments(entries) {
  const list = document.getElementById('documentsList');
  if (!list) return;
  while (list.firstChild) list.removeChild(list.firstChild);
  entries.forEach(e => {
    const d = document.createElement('div'); d.className = 'j-entry';
    const when = document.createElement('div'); when.className = 'when'; when.dataset.d = e.date; when.textContent = fmtD(e.date, DATE_S);
    const what = document.createElement('div'); what.className = 'what serif';
    const title = document.createElement('div'); title.style.fontWeight = '700'; title.textContent = e.title;
    const body = document.createElement('div'); body.textContent = e.text;
    what.appendChild(title); what.appendChild(body);
    d.appendChild(when); d.appendChild(what);
    list.appendChild(d);
  });
}

async function loadDocumentsFromDB() {
  if (!_sb || !_userId) return;
  const { data } = await _sb.from('brief_documents').select('*').eq('user_id', _userId).order('date', { ascending: false });
  renderDocuments(data || []);
}

(function(){
  const btn = document.getElementById('dAddBtn');
  const form = document.getElementById('dForm');
  if (!btn || !form) return;
  const dateI = document.getElementById('dDate');
  const titleI = document.getElementById('dTitle');
  const txtI = document.getElementById('dText');
  const today = new Date().toISOString().slice(0,10);
  dateI.value = today; dateI.max = today;

  btn.addEventListener('click', () => { form.classList.toggle('open'); if (form.classList.contains('open')) titleI.focus(); });
  document.getElementById('dCancel').addEventListener('click', () => { form.classList.remove('open'); titleI.value = ''; txtI.value = ''; });
  document.getElementById('dSave').addEventListener('click', async () => {
    const title = titleI.value.trim(); const txt = txtI.value.trim();
    if (!title || !txt || !_sb || !_userId) return;
    await _sb.from('brief_documents').insert({ user_id: _userId, date: dateI.value, title, text: txt });
    titleI.value = ''; txtI.value = ''; form.classList.remove('open');
    await loadDocumentsFromDB();
  });
})();

function animateBars() {
  document.querySelectorAll('#scenarios .bar-fill').forEach(b => b.style.width = b.dataset.w + '%');
}
document.querySelectorAll('.tab-btn').forEach(b => {
  b.addEventListener('click', e => {
    e.preventDefault();
    document.getElementById('panel-' + b.dataset.tab)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});
setTimeout(animateBars, 500);

(function(){
  const mq = window.matchMedia('(prefers-color-scheme: light)');
  let mode = 'auto';
  function applySystem() { if (mode === 'auto') document.body.dataset.theme = mq.matches ? 'white' : 'dark'; }
  window.__setTheme = function(m) { mode = m; if (m === 'auto') applySystem(); else document.body.dataset.theme = m; };
  applySystem();
  if (mq.addEventListener) mq.addEventListener('change', applySystem);
})();

const TWEAKS = { theme:'auto', accent:'red', hero:100, density:'comfortable', annot:true, decay:true };
(function(){
  const panel = document.getElementById('twPanel');
  function apply(t) {
    window.__setTheme(t.theme);
    document.body.dataset.accent = t.accent;
    document.body.dataset.density = t.density;
    document.body.dataset.annot = t.annot ? 'on' : 'off';
    document.body.dataset.decay = t.decay ? 'on' : 'off';
    document.documentElement.style.setProperty('--hero-scale', (t.hero/100).toFixed(2));
    document.getElementById('twHeroVal').textContent = (t.hero/100).toFixed(2) + 'x';
    panel.querySelectorAll('.tw-seg[data-key="theme"] button').forEach(b => b.classList.toggle('active', b.dataset.v === t.theme));
    panel.querySelectorAll('.tw-swatches[data-key="accent"] button').forEach(b => b.classList.toggle('active', b.dataset.v === t.accent));
    panel.querySelectorAll('.tw-seg[data-key="density"] button').forEach(b => b.classList.toggle('active', b.dataset.v === t.density));
    document.getElementById('twHero').value = t.hero;
    document.getElementById('twAnnot').checked = t.annot;
    document.getElementById('twDecay').checked = t.decay;
  }
  function set(patch) { Object.assign(TWEAKS, patch); apply(TWEAKS); }
  panel.querySelectorAll('.tw-seg button').forEach(b => b.addEventListener('click', () => set({ [b.parentElement.dataset.key]: b.dataset.v })));
  panel.querySelectorAll('.tw-swatches button').forEach(b => b.addEventListener('click', () => set({ [b.parentElement.dataset.key]: b.dataset.v })));
  document.getElementById('twHero').addEventListener('input', e => set({ hero: parseInt(e.target.value) }));
  document.getElementById('twAnnot').addEventListener('change', e => set({ annot: e.target.checked }));
  document.getElementById('twDecay').addEventListener('change', e => set({ decay: e.target.checked }));
  document.getElementById('twClose').addEventListener('click', () => { panel.hidden = true; });
  document.addEventListener('keydown', e => { if (e.shiftKey && e.key === 'T') panel.hidden = !panel.hidden; });
  const tweaksBtn = document.getElementById('tweaksBtn');
  if (tweaksBtn) tweaksBtn.addEventListener('click', () => { panel.hidden = !panel.hidden; });
  apply(TWEAKS);
})();

const scriptEl = document.getElementById('scriptText');
if (scriptEl) scriptEl.textContent = CALL_SCRIPT;
const copyBtn = document.getElementById('copyScript');
if (copyBtn) copyBtn.addEventListener('click', function() {
  navigator.clipboard.writeText(document.getElementById('scriptText').textContent).then(() => {
    this.textContent = tr('Copied'); this.classList.add('copied');
    setTimeout(() => { this.textContent = tr('Copy'); this.classList.remove('copied'); }, 1800);
  });
});

// ===== SERVER SYNC (called after auth) =====
function loadChecklistFromDB() {
  if (!_sb) return;
  return _sb.from('brief_checklist').select('*').then(res => {
    (res.data||[]).forEach(r => {
      const it = (CHECKLIST||[]).find(x => x.i === String(r.item_index));
      if (it) it.done = r.completed;
    });
    const s = {};
    (CHECKLIST||[]).forEach(it => s[it.i] = it.done);
    localStorage.setItem(CL_STORE, JSON.stringify(s));
    document.querySelectorAll('.cl-item').forEach(row => {
      const it = CHECKLIST.find(x => x.i === row.dataset.i);
      if (!it) return;
      row.setAttribute('aria-checked', !!it.done);
      row.querySelector('.cl-box').classList.toggle('done', it.done);
      row.querySelector('.cl-label').classList.toggle('done', it.done);
      const lev = row.querySelector('.cl-lev');
      if (lev) lev.classList.toggle('done', it.done);
    });
    updateClProg();
    if (webActiveCase === 'rcmp') renderLeverage();
    document.body.dataset.ready = '1';
  });
}

function loadLawyerStatusFromDB() {
  if (!_sb) return;
  return _sb.from('brief_lawyer_status').select('*').then(res => {
    (res.data||[]).forEach(r => { _lawyerStatuses[r.lawyer_id] = r.status; });
    document.querySelectorAll('.lawyer[data-lawyer-id]').forEach(card => {
      const id = card.dataset.lawyerId;
      const status = _lawyerStatuses[id] || (LAWYERS.find(l => l.id === id) || {}).status || 'none';
      const chip = card.querySelector('.tag.status');
      if (!chip) return;
      chip.dataset.status = status;
      chip.className = 'tag status ' + status;
      chip.textContent = sl(status);
    });
    if (webActiveCase === 'rcmp') renderLeverage();
  });
}

function initData() {
  loadChecklistFromDB();
  loadLawyerStatusFromDB();
}

renderLeverage();

// ===== Deep links =====
// ?case=<key> selects the active case on load; any key in the CASES registry works.
// ?token= is gone: it was the last anon path to the dossier (SECURITY DEFINER RPC,
// no expiry) and had been dead since the token was revoked 2026-07-28. Sign in.
(function() {
  var params = new URLSearchParams(location.search);
  var qc = params.get('case');
  if (qc && Object.prototype.hasOwnProperty.call(CASES(), qc)) setActiveCase(qc);
})();

// auth.js has already established the session and injected the markup.
// Accessors for webmcp.js. Kept to reads plus the one checklist write -- no
// delete surface exists here, deliberately.
window.briefCases = CASES;
window.briefActiveCase = () => webActiveCase;
window.briefChecklist = () => getActiveChecklist().map(({ i, label, lev, pri, done }) => ({ index: i, label, leverage: lev, priority: pri, done: !!done }));
window.briefLeverage = computeLeverage;
window.briefSetChecklistItem = (index, done) => {
  const result = setChecklistItem(index, done);
  if (!result.error) renderChecklist(); // no cursor to disturb when a tool did it
  return result;
};
window.briefOpenCase = setActiveCase;
window.briefRefresh = async () => { await fetchCaseData(); setActiveCase(webActiveCase); }; // author.js after a save

document.body.appendChild(Object.assign(document.createElement('script'), { src: 'webmcp.js?v=2' }));
document.body.appendChild(Object.assign(document.createElement('script'), { src: 'author.js?v=9' }));

// ===== LANGUAGE =====
// i18n.js fires 'themis-lang' after every language change; script.js rebuilds only what holds its own fixed words.
const FIELD_LABELS = { jDate:'Date', jText:'Journal entry', dDate:'Date', dTitle:'Title', dText:'Document text' };
function labelFields() {
  Object.keys(FIELD_LABELS).forEach(id => {
    const el = document.getElementById(id);
    if (!el || (el.labels && el.labels.length) || (el.hasAttribute('aria-label') && !el.dataset.al)) return;
    el.dataset.al = '1'; el.setAttribute('aria-label', tr(FIELD_LABELS[id]));
  });
}
function retranslate() {
  setToday(); labelFields();
  if (window.__relabelClock) window.__relabelClock();
  document.querySelectorAll('[data-d]').forEach(e => { e.textContent = fmtD(e.dataset.d, DATE_S); });
  document.querySelectorAll('.tag.status').forEach(c => { c.textContent = sl(c.dataset.status); });
  document.querySelectorAll('.cl-pri[data-pri]').forEach(e => { e.textContent = tr(e.dataset.pri); });
  document.querySelectorAll('.fit-dots[data-fit]').forEach(e => { e.title = tr('Case fit') + ' ' + e.dataset.fit + '/5'; });
  renderGrounds('grounds-case', ''); renderGrounds('grounds-money', '2');
  renderScenarios(); animateBars();
  if (webActiveCase === 'rcmp') { renderScaleBands(); renderLeverage(); }
}
document.addEventListener('themis-lang', retranslate);
labelFields();
if (window.temidaShell) window.temidaShell();

window.appLoadAndShow = loadAndShow;
if (_userId) loadAndShow();
