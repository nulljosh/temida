// Web save test on the QA account (.env.qa): add, edit and remove a fact, a deadline and a lawyer,
// reload, print what reads back. Local files by default; `node tests/web/save.mjs live` uses the live site.

import { open, qa } from './harness.mjs';
const local = process.argv[2] !== 'live';
let { b, p, errors } = await open(qa(), { local });
async function add(label, values) {
  await p.click(`.author-add[data-label="${label}"]`);
  await p.waitForSelector('dialog.author-dlg[open]');
  for (const [name, v] of Object.entries(values)) {
    if (name === 'due') await p.$eval('dialog [name=due]', (e, v) => { e.value = v; }, v);
    else await p.type(`dialog [name=${name}]`, v);
  }
  await p.click('dialog button[type=submit]');
  await p.waitForSelector('dialog.author-dlg', { hidden: true, timeout: 10000 });
}
await add('Add fact', { key: 'Web fact', value: 'Added on the web' });
await add('Add deadline', { title: 'Web deadline', due: '2026-12-01', desc: 'Added on the web' });
await add('Add lawyer', { name: 'Web Lawyer', sub: 'Test firm', phone: '555-0100', email: 'lawyer@example.com' });
// edit the fact, then add and remove a throwaway one
await p.click('#facts .author-row button[data-label="Edit"]');
await p.waitForSelector('dialog.author-dlg[open]');
await p.$eval('dialog [name=value]', e => { e.value = 'Edited on the web'; });
await p.click('dialog button[type=submit]');
await p.waitForSelector('dialog.author-dlg', { hidden: true, timeout: 10000 });
await add('Add fact', { key: 'Remove me', value: 'x' });
await p.evaluate(() => [...document.querySelectorAll('#facts .author-row button[data-label="Remove"]')].find(b => b.getAttribute('aria-label').includes('Remove me')).click());
await new Promise(r => setTimeout(r, 2500));
await b.close();
({ b, p, errors: errors } = await open(qa(), { local }));
const got = await p.evaluate(() => ({
  facts: [...document.querySelectorAll('#facts .row')].map(r => r.querySelector('.k').textContent + '=' + r.querySelector('.v').textContent),
  deadlines: [...document.querySelectorAll('#timeline .tl-title')].map(e => e.textContent + ' @ ' + e.closest('.tl-item').querySelector('.tl-when').textContent),
  lawyers: [...document.querySelectorAll('#lawyers .lawyer-name')].map(e => e.textContent),
}));
console.log(JSON.stringify(got));

console.log(errors.join('\n') || 'no errors'); await b.close();
