// Edit and Remove stay hidden until a row is pointed at or focused, and keyboard focus still reaches them (QA account).
import assert from 'node:assert/strict';
import { open, qa } from './harness.mjs';
const { b, p, errors } = await open(qa());
const op = () => p.$eval('#facts > * .author-row', e => getComputedStyle(e).opacity);
await p.mouse.move(0, 0); await new Promise(r => setTimeout(r, 300));
assert.equal(await op(), '0');
await p.hover('#facts > *'); await new Promise(r => setTimeout(r, 300));
assert.equal(await op(), '1');
await p.mouse.move(0, 0); await p.$eval('#facts > * .author-row button', e => e.focus()); await new Promise(r => setTimeout(r, 300));
assert.equal(await op(), '1');
await p.screenshot({ path: process.env.SHOT || '/dev/null' }).catch(() => {});
console.log('row actions ok;', errors.join(' ; ') || 'no errors'); await b.close();
// On a touch screen Edit and Remove stay inline, visible and at least 44px tall.
{
  const { b, p } = await open(qa(), { width: 390, touch: true });
  const r = await p.$eval('#facts > * .author-row', e => ({ op: getComputedStyle(e).opacity, pos: getComputedStyle(e).position, h: e.querySelector('button').getBoundingClientRect().height }));
  assert.deepEqual([r.op, r.pos], ['1', 'static']); assert.ok(r.h >= 44, `touch button ${r.h}px`);
  console.log('touch row actions ok'); await b.close();
}
