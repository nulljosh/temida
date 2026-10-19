// Owner regression: booleans and counts only. Never screenshot or print page text.
import { open } from './harness.mjs';
import fs from 'fs';
const e = Object.fromEntries(fs.readFileSync(new URL('../../.env', import.meta.url), 'utf8').trim().split('\n').filter(l => l.includes('=')).map(l => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1).replace(/^["']|["']$/g, '')]));
const { b, p, errors } = await open({ email: e.BRIEF_LOGIN_EMAIL, password: e.BRIEF_LOGIN_PASSWORD }, { local: process.argv[2] !== 'live' });
const r = await p.evaluate(() => {
  const m = document.querySelector('.page > main');
  return { ready: !!document.body.dataset.ready, shell: !!document.body.dataset.shell, mainVisibleHeight: Math.round(m.getBoundingClientRect().height) > 500,
    landingMainUntouched: !!document.querySelector('.lp-main .lp-card'), adds: [...document.querySelectorAll('.author-add')].map(b => b.dataset.label), witnessRowsAdded: document.querySelectorAll('#witnesses .witness').length, groundsEditable: document.querySelectorAll('#grounds-case .author-row').length + '/' + document.querySelectorAll('#grounds-case .ground').length,
    dupOfSheet: [...document.querySelectorAll('#facts .row')].map(r => { const s = [...document.querySelectorAll('.page .facts:not(#facts)')].find(e => e.getClientRects().length); const t = (s ? s.textContent : '').toLowerCase(); return t.includes(r.querySelector('.v').textContent.trim().toLowerCase().slice(0, 24)); }), sheetRows: ([...document.querySelectorAll('.page .facts:not(#facts)')].find(e => e.getClientRects().length) || { querySelectorAll: () => [] }).querySelectorAll('.k').length, totalFacts: (window.briefCases().rcmp.facts || []).length,
    factsList: !!document.getElementById('facts'), factRowsAdded: document.querySelectorAll('#facts .row').length, caseTabs: document.querySelectorAll('.cs-btn').length };
});
console.log(JSON.stringify(r)); console.log(errors.length ? 'ERRORS: ' + errors.length + ' ' + errors.map(x => x.split('|')[0]).join(' / ') : 'no errors');
await b.close();
