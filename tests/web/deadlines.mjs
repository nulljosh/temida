// v10: checks addMonths from web/author.js on the edge cases, then saves a deadline worked out from a rule on the
// QA account (.env.qa), edits a second one by hand, reloads and prints the timeline. `live` uses the live site.
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { open, qa } from './harness.mjs';
const src = readFileSync(new URL('../../web/author.js', import.meta.url), 'utf8');
const addMonths = new Function(src.match(/function addMonths[\s\S]*?\n  }/)[0] + '; return addMonths')();
assert.equal(addMonths('2026-10-19', 24), '2028-10-19');
assert.equal(addMonths('2021-08-08', 180), '2036-08-08');
assert.equal(addMonths('2026-03-15', 2), '2026-05-15');
assert.equal(addMonths('2024-02-29', 24), '2026-02-28');
assert.equal(addMonths('2025-12-31', 2), '2026-02-28');
console.log('addMonths ok');

const local = process.argv[2] !== 'live';
let { b, p, errors } = await open(qa(), { local });
async function form(open, values) {
  await open();
  await p.waitForSelector('dialog.author-dlg[open]');
  for (const [name, v] of Object.entries(values))
    await p.$eval(`dialog [name=${name}]`, (e, v) => { e.value = v; e.dispatchEvent(new Event('change')); e.dispatchEvent(new Event('input')); }, v);
  await p.click('dialog button[type=submit]');
  await p.waitForSelector('dialog.author-dlg', { hidden: true, timeout: 10000 });
}
const add = v => form(() => p.click('.author-add[data-label="Add deadline"]'), v);
const edit = who => p.evaluate(who => [...document.querySelectorAll('#timeline .author-row button[data-label="Edit"]')].find(b => b.getAttribute('aria-label').includes(who)).click(), who);
await add({ rule: 'basic', start: '2026-10-19', title: 'Rule deadline', desc: 'From the Limitation Act' });
await add({ rule: 'notice', start: '2025-12-31', title: 'Hand deadline', desc: '' });
await form(() => edit('Hand deadline'), { due: '2027-01-15' });
await new Promise(r => setTimeout(r, 2500));
await b.close();
({ b, p, errors } = await open(qa(), { local }));
console.log(JSON.stringify(await p.evaluate(() => [...document.querySelectorAll('#timeline .tl-item')].map(d =>
  d.querySelector('.tl-when').textContent + ' / ' + d.querySelector('.tl-title').textContent + ' / ' + ((d.querySelector('.tl-rule') || {}).textContent || '-')))));
console.log(errors.join('\n') || 'no errors'); await b.close();
