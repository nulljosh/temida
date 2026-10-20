// v11: the case search on the QA account (.env.qa) hides rows that do not match and brings them back when cleared.
import assert from 'node:assert/strict';
import { open, qa } from './harness.mjs';
const { b, p, errors } = await open(qa(), { local: process.argv[2] !== 'live' });
const shown = () => p.evaluate(() => [...document.querySelectorAll('#facts > *, #witnesses > *, #grounds-case > *, #timeline > *, #lawyers > *')]
  .filter(e => e.getClientRects().length).map(e => e.textContent));
const all = await shown();
await p.type('.case-search', 'witness');
const hits = await shown();
assert.ok(hits.length > 0 && hits.length < all.length, `${hits.length} of ${all.length}`);
assert.ok(hits.every(t => t.toLowerCase().includes('witness')));
await p.$eval('.case-search', e => { e.value = ''; e.dispatchEvent(new Event('input')); });
assert.equal((await shown()).length, all.length);
console.log(`search ok: ${hits.length} of ${all.length}`);
await p.screenshot({ path: process.env.SHOT || '/dev/null' }).catch(() => {});
console.log(errors.join('\n') || 'no errors'); await b.close();
