// Web save test for grounds and witnesses on the QA account (.env.qa): add, edit, add and remove a throwaway,
// reload, print what reads back. Local files by default; `node tests/web/grounds.mjs live` uses the live site.
import { open, qa } from './harness.mjs';
const local = process.argv[2] !== 'live';
let { b, p, errors } = await open(qa(), { local });
async function form(open, values) {
  await open();
  await p.waitForSelector('dialog.author-dlg[open]');
  for (const [name, v] of Object.entries(values)) {
    if (name === 'date') await p.$eval('dialog [name=date]', (e, v) => { e.value = v; }, v);
    else await p.$eval(`dialog [name=${name}]`, (e, v) => { e.value = v; }, v);
  }
  await p.click('dialog button[type=submit]');
  await p.waitForSelector('dialog.author-dlg', { hidden: true, timeout: 10000 });
}
const add = (label, v) => form(() => p.click(`.author-add[data-label="${label}"]`), v);
const act = (list, who, label) => p.evaluate((list, who, label) => [...document.querySelectorAll(`#${list} .author-row button[data-label="${label}"]`)].find(b => b.getAttribute('aria-label').includes(who)).click(), list, who, label);
await add('Add ground', { title: 'Web ground', sec: 'Test Act s. 1', desc: 'Added on the web' });
await add('Add witness', { name: 'Web Witness', role: 'Bystander', date: '2026-10-01', statement: 'Saw it on the web' });
await form(() => act('grounds-case', 'Web ground', 'Edit'), { desc: 'Edited on the web' });
await form(() => act('witnesses', 'Web Witness', 'Edit'), { role: 'Neighbour' });
await add('Add ground', { title: 'Drop ground', sec: 'x', desc: 'x' });
await act('grounds-case', 'Drop ground', 'Remove');
await new Promise(r => setTimeout(r, 2500));
await b.close();
({ b, p, errors } = await open(qa(), { local }));
console.log(JSON.stringify(await p.evaluate(() => ({
  grounds: [...document.querySelectorAll('#grounds-case .ground')].map(g => g.querySelector('.ground-n').textContent + ' ' + g.querySelector('.ground-title').textContent + ' / ' + g.querySelector('.ground-sec').textContent + ' / ' + g.querySelector('.ground-desc').textContent),
  witnesses: [...document.querySelectorAll('#witnesses .witness')].map(w => w.querySelector('.witness-name').textContent + ' / ' + w.querySelector('.witness-role').textContent + ' / ' + (w.querySelector('.witness-stmt') || {}).textContent),
}))));
await p.screenshot({ path: process.env.SHOT || '/dev/null', fullPage: true }).catch(() => {});
console.log(errors.join('\n') || 'no errors'); await b.close();
