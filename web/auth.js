// Sign-in strings go through i18n.js when a language is picked; English otherwise.
const tr = s => (window.temidaT ? window.temidaT(s) : s);
// ===== ACCOUNT SIGN-IN + PRIVATE MARKUP LOADER =====
// Runs before script.js. Nothing case-specific ships in index.html any more:
// the hero and <main> are empty shells, and their real markup lives in the
// signed-in user's own brief_data row (key='fragments', scoped to the signed-in user by the API).
// That is what lets the site be public — a stranger fetching index.html gets a
// login screen and empty tags, not the case file. script.js is only appended
// once the markup is in the DOM, so its top-level renders still find their nodes.
//
// Accounts and data live in the spark-api Worker (Cloudflare D1). Nothing secret ships here:
// every request carries the signed-in user's own token, and the API scopes rows to that user.
const API_URL = 'https://api.jaybulb.com';

let _client = null;
let _uid = null;
let _appLoaded = false;

// ponytail: innerHTML is safe here — the only writer of this row is the row's
// own owner, and the API only returns your own rows.
// Accounts without their own fragments row get this structure-only page: the brief's title and the
// lists author.js can fill. No content lives here; script.js renders the cases row into it.
const SHELL_SECTIONS = [['facts', 'Facts', 'facts'], ['grounds-case', 'Grounds', ''], ['witnesses', 'Witnesses', ''], ['timeline', 'Deadlines', 'timeline'], ['lawyers', 'Lawyers', '']];
const SHELL = {
  hero: '<h1 class="hero-title serif" id="briefTitle"></h1>',
  main: SHELL_SECTIONS.map(([id, label, cls]) =>
    `<section class="shell-sec"><div class="section-hd"><span class="lbl">${label}</span></div><div id="${id}" class="${cls}"></div></section>`).join(''),
};
function injectFragments(frag) {
  if (!frag) { document.body.dataset.shell = '1'; frag = SHELL; }
  const hero = document.querySelector('header.hero');
  const main = document.querySelector('.page > main'); // not the landing's own <main>
  if (hero && frag.hero) hero.innerHTML = frag.hero;
  if (main && frag.main) main.innerHTML = frag.main;
  window._fragTitles = frag.titles || {};
}

function loadApp() {
  if (_appLoaded) return;
  _appLoaded = true;
  window._sb = _client;
  window._userId = _uid;
  const s = document.createElement('script');
  s.src = 'script.js?v=56';
  document.body.appendChild(s);
}

function hideSplash() {
  const s = document.getElementById('splash');
  if (!s || s.hidden) return;
  s.classList.add('out');
  setTimeout(() => { s.hidden = true; }, 400);
}
// The splash lifts once script.js has rendered (body[data-ready]), or after 5 s whatever happens.
new MutationObserver((_, o) => { if (document.body.dataset.ready) { hideSplash(); o.disconnect(); } })
  .observe(document.body, { attributes: true, attributeFilter: ['data-ready'] });
setTimeout(hideSplash, 5000);

// Onboarding gate, same as the apps: no `onboarded` flag and no cases row. Any read error means
// skip it, so an existing account never lands here by accident. ?onboarding previews it and writes nothing.
async function onboardingGate() {
  if (new URLSearchParams(location.search).has('onboarding')) return { preview: true, meta: {} };
  const [u, c] = await Promise.all([_client.auth.getUser(), _client.from('brief_data').select('key').eq('key', 'cases')]);
  if (u.error || c.error || !u.data.user) return null;
  const meta = u.data.user.user_metadata || {};
  return !meta.onboarded && (c.data || []).length === 0 ? { meta } : null;
}

// Markup lives here, not in index.html, because only a brand-new account ever sees it.
const ONBOARD_HTML = `<div class="onboard" id="onboard" hidden>
  <div class="ob-dots"><i></i><i></i><i></i></div>
  <section class="ob-step">
    <div class="ob-mark"></div>
    <h1>Welcome to Temida</h1>
    <p class="ob-sub">Your case, in one brief.</p>
    <ul class="ob-promises">
      <li><b>Private to you</b><span>Only your account can read your briefs.</span></li>
      <li><b>Everything in one place</b><span>Facts, people, dates and money, in order.</span></li>
      <li><b>Always know the next step</b><span>A checklist that tells you what to do now.</span></li>
    </ul>
    <button class="ob-btn" type="button" data-next>Get started</button>
    <p class="ob-fine">Planning aid, not legal advice.</p>
  </section>
  <section class="ob-step" hidden>
    <h1>What should we call you?</h1>
    <p class="ob-sub">Your name shows on your profile. You can change it later.</p>
    <input class="ob-input" id="obName" autocomplete="name" placeholder="Your name">
    <button class="ob-btn" type="button" data-next>Continue</button>
    <button class="ob-link" type="button" data-skip>Skip</button>
  </section>
  <section class="ob-step" hidden>
    <h1>Name your first brief</h1>
    <p class="ob-sub">Usually the parties, like Smith v. Acme. One brief per matter.</p>
    <input class="ob-input" id="obBrief" placeholder="Smith v. Acme">
    <button class="ob-btn" type="button" id="obStart" disabled>Start my brief</button>
    <button class="ob-link" type="button" id="obLater">Later</button>
    <p class="ob-err" id="obErr"></p>
  </section>
</div>`;

function runOnboarding(gate) {
  return new Promise(resolve => {
    if (!document.getElementById('onboard')) document.body.insertAdjacentHTML('beforeend', ONBOARD_HTML);
    const el = document.getElementById('onboard');
    if (window.temidaTree) window.temidaTree(el);
    const steps = el.querySelectorAll('.ob-step'), dots = el.querySelectorAll('.ob-dots i');
    const name = document.getElementById('obName'), brief = document.getElementById('obBrief');
    const start = document.getElementById('obStart'), err = document.getElementById('obErr');
    let at = 0;
    const go = i => {
      at = i;
      steps.forEach((s, j) => { s.hidden = j !== i; });
      dots.forEach((d, j) => { d.className = j < i ? 'done' : j === i ? 'on' : ''; });
      const f = steps[i].querySelector('input'); if (f) f.focus();
    };
    const finish = async title => {
      start.disabled = true; err.textContent = '';
      if (!gate.preview) {
        if (title) {
          const r = await _client.from('brief_data').upsert({ user_id: _uid, key: 'cases', value: emptyCasesValue(title) });
          if (r.error) { err.textContent = r.error.message; start.disabled = false; return; }
        }
        const data = { onboarded: '1' };
        if (name.value.trim()) data.full_name = name.value.trim();
        await _client.auth.updateUser({ data }); // a failed flag only means the flow shows once more
      }
      el.hidden = true;
      resolve();
    };
    name.value = gate.meta.full_name || '';
    el.querySelectorAll('[data-next]').forEach(b => { b.onclick = () => go(at + 1); });
    el.querySelector('[data-skip]').onclick = () => { name.value = gate.meta.full_name || ''; go(2); };
    name.onkeydown = e => { if (e.key === 'Enter') go(2); };
    brief.oninput = () => { start.disabled = !brief.value.trim(); };
    brief.onkeydown = e => { if (e.key === 'Enter' && brief.value.trim()) finish(brief.value.trim()); };
    start.onclick = () => finish(brief.value.trim());
    document.getElementById('obLater').onclick = () => finish('');
    el.hidden = false;
    go(0);
  });
}

async function loadAndShow() {
  const gate = await onboardingGate();
  if (gate) {
    hideSplash();
    const overlay = document.getElementById('authOverlay');
    if (overlay) overlay.classList.add('hidden');
    await runOnboarding(gate);
  }
  const { data } = await _client.from('brief_data').select('value').eq('key', 'fragments').single();
  injectFragments(data && data.value);
  const overlay = document.getElementById('authOverlay');
  if (overlay) overlay.classList.add('hidden');
  document.querySelectorAll('[data-app]').forEach(el => { el.inert = false; });
  // script.js runs its own loadAndShow (case data, checklists, documents) on load.
  if (_appLoaded && typeof window.appLoadAndShow === 'function') window.appLoadAndShow();
  loadApp();
}

// The client is a same-origin script. If it fails to load there is nothing to show —
// the page is an empty shell without a session, so fail visibly rather than blank.
try {
  if (typeof spark !== 'undefined') {
    _client = spark.createClient(API_URL);
    _client.auth.getSession().then(res => {
      if (res.data.session) { _uid = res.data.session.user.id; loadAndShow(); } else hideSplash();
    });
    _client.auth.onAuthStateChange((_ev, session) => {
      if (_ev === 'PASSWORD_RECOVERY') { showRecoveryForm(); return; }
      if (session && !_uid) { _uid = session.user.id; loadAndShow(); }
    });
  }
} catch (e) {
  const err = document.getElementById('authErrEmail');
  if (err) err.textContent = tr('Could not reach the auth service. Reload to retry.');
}

document.getElementById('authFormEmail').addEventListener('submit', e => {
  e.preventDefault();
  const email = document.getElementById('authEmail').value.trim().toLowerCase();
  const errEl = document.getElementById('authErrEmail');
  if (!email) { errEl.textContent = tr('Enter an email.'); return; }
  errEl.textContent = '';
  document.getElementById('authConfirmedEmail').textContent = email;
  document.getElementById('authStep1').style.display = 'none';
  document.getElementById('authStep2').style.display = 'block';
  document.getElementById('authPassword').focus();
});

document.getElementById('authFormPass').addEventListener('submit', e => {
  e.preventDefault();
  const email = document.getElementById('authEmail').value.trim().toLowerCase();
  const password = document.getElementById('authPassword').value;
  const errEl = document.getElementById('authErrPass');
  const btn = e.submitter || e.target.querySelector('[type=submit]');
  btn.textContent = tr('Signing in…'); btn.disabled = true;
  _client.auth.signInWithPassword({ email, password }).then(res => {
    if (res.error) { errEl.textContent = res.error.message; btn.textContent = tr('Sign in'); btn.disabled = false; }
  });
});

// A reset link lands here with ?recovery_token=...; the client announces it and we ask for the new password.
function showRecoveryForm() {
  if (document.getElementById('recoveryOverlay')) return;
  const o = document.createElement('div');
  o.id = 'recoveryOverlay';
  o.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,.7);display:flex;align-items:center;justify-content:center;z-index:9999';
  o.innerHTML = '<form style="background:Canvas;color:CanvasText;padding:1.5rem;border-radius:12px;display:grid;gap:.75rem;width:min(92vw,340px)"><strong>' + tr('Choose a new password') + '</strong><input type="password" minlength="8" required placeholder="' + tr('New password, 8 characters or more') + '" aria-label="' + tr('New password') + '" autocomplete="new-password" style="padding:.6rem"><button type="submit" style="padding:.6rem">' + tr('Save password') + '</button><span class="err" role="status" aria-live="polite"></span></form>';
  o.querySelector('form').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const res = await _client.auth.updateUser({ password: ev.target.querySelector('input').value });
    if (res.error) { ev.target.querySelector('.err').textContent = res.error.message; return; }
    o.remove();
    location.reload();
  });
  document.body.appendChild(o);
}

// First brief: instantiate an empty-but-valid cases workspace for a new user,
// persisted to their own brief_data row (scoped to the signed-in user by the API).
function emptyCasesValue(title) {
  const blank = { GROUNDS:[], SCENARIOS:[], STACK_HEADS:[], SCALE:{}, LAWYERS:[], TIMELINE:[], CHECKLIST:[], JOURNAL_SEED:[], CALL_SCRIPT:'',
    FAMILY_GROUNDS:[], FAMILY_SCENARIOS:[], FAMILY_STACK_HEADS:[], FAMILY_LAWYERS:[], FAMILY_CHECKLIST:[], FAMILY_TIMELINE:[], FAMILY_CALL_SCRIPT:'',
    MUNI_GROUNDS:[], MUNI_SCENARIOS:[], MUNI_STACK_HEADS:[], MUNI_LAWYERS:[], MUNI_CHECKLIST:[], MUNI_TIMELINE:[], MUNI_CALL_SCRIPT:'' };
  blank.TITLE = title || tr('Untitled brief');
  return blank;
}
const _firstBriefBtn = document.getElementById('firstBriefBtn');
if (_firstBriefBtn) _firstBriefBtn.addEventListener('click', () => {
  const title = (document.getElementById('firstBriefTitle').value || '').trim();
  const errEl = document.getElementById('firstBriefErr');
  if (!_client || !_uid) { errEl.textContent = 'Not signed in.'; return; }
  _firstBriefBtn.textContent = tr('Creating…'); _firstBriefBtn.disabled = true;
  const value = emptyCasesValue(title);
  _client.from('brief_data').upsert({ user_id:_uid, key:'cases', value }).then(res => {
    if (res.error) { errEl.textContent = res.error.message; _firstBriefBtn.textContent = tr('Start a brief'); _firstBriefBtn.disabled = false; return; }
    loadAndShow();
  });
});

// Sign-up: any new user registers their own account and starts with no briefs.
document.getElementById('authSignup').addEventListener('click', () => {
  const email = document.getElementById('authEmail').value.trim().toLowerCase();
  const password = document.getElementById('authPassword').value;
  const errEl = document.getElementById('authErrPass');
  const btn = document.getElementById('authSignup');
  if (!password || password.length < 8) { errEl.textContent = tr('Password must be at least 8 characters.'); return; }
  btn.textContent = tr('Creating…'); btn.disabled = true;
  _client.auth.signUp({ email, password }).then(res => {
    if (res.error) { errEl.textContent = res.error.message; btn.textContent = tr('Create account'); btn.disabled = false; return; }
    if (res.data && res.data.session) { errEl.textContent = ''; /* onAuthStateChange handles it */ }
    else { errEl.textContent = tr('Check your email to confirm your account.'); btn.textContent = tr('Create account'); btn.disabled = false; }
  });
});

document.getElementById('authForgot').addEventListener('click', () => {
  const email = document.getElementById('authEmail').value.trim().toLowerCase();
  const errEl = document.getElementById('authErrPass');
  if (!email) { errEl.textContent = tr('Enter an email first.'); return; }
  _client.auth.resetPasswordForEmail(email, { redirectTo: window.location.origin }).then(res => {
    errEl.textContent = res.error ? res.error.message : tr('Check your email for a reset link.');
  });
});

document.getElementById('authBack').addEventListener('click', () => {
  document.getElementById('authStep2').style.display = 'none';
  document.getElementById('authStep1').style.display = 'block';
  document.getElementById('authErrEmail').textContent = '';
  document.getElementById('authPassword').value = '';
});

// The ?token= deep link is gone (2026-08-10): it booted the app anonymously so
// script.js could pull the whole dossier through an anon SECURITY DEFINER RPC.
// The RPC is dropped; script.js now only loads behind a real session.

// ===== LANDING PAGE: sign-in modal =====
// The signed-out surface is a full landing page now, so the auth card only
// appears when a [data-auth] button opens it (nav, hero, closing CTA). `mode`
// decides which of the two step-2 buttons reads as primary — the flow itself,
// and every id bound above, is unchanged.
const _authModal = document.getElementById('authModal');
const _authOverlayEl = document.getElementById('authOverlay');

function setAuthMode(mode) {
  const register = mode === 'register';
  _authModal.classList.toggle('mode-register', register);
  document.getElementById('authTitle').textContent = register ? tr('Create an account') : tr('Sign in');
  document.getElementById('authSub').textContent = register
    ? tr("Free, and the brief is private to you")
    : tr("or create a free account");
  document.getElementById('authPassword')
    .setAttribute('autocomplete', register ? 'new-password' : 'current-password');
}

function openAuth(mode) {
  if (!_authModal) return;
  setAuthMode(mode);
  // Always reopen on step 1. The email input keeps whatever was typed before,
  // so a mis-click costs nothing.
  document.getElementById('authStep2').style.display = 'none';
  document.getElementById('authStep1').style.display = 'block';
  document.getElementById('authPassword').value = '';
  ['authErrEmail', 'authErrPass', 'authErrOauth'].forEach(id => {
    document.getElementById(id).textContent = '';
  });
  _authModal.hidden = false;
  if (_authOverlayEl) _authOverlayEl.style.overflow = 'hidden';
  document.getElementById('authEmail').focus();
}

function closeAuth() {
  if (!_authModal || _authModal.hidden) return;
  _authModal.hidden = true;
  if (_authOverlayEl) _authOverlayEl.style.overflow = '';
}

if (_authModal) {
  document.querySelectorAll('[data-auth]').forEach(btn =>
    btn.addEventListener('click', () => openAuth(btn.dataset.auth)));
  document.getElementById('authModalClose').addEventListener('click', closeAuth);
  // Backdrop click only — mousedown on the card must not close it mid-drag.
  _authModal.addEventListener('mousedown', e => { if (e.target === _authModal) closeAuth(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') closeAuth(); });
}

