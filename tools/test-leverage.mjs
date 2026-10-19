import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const source = readFileSync(new URL('../web/script.js', import.meta.url), 'utf8');
const start = source.indexOf('function computeLeverage()');
const end = source.indexOf('function renderLeverage()', start);
assert.ok(start >= 0 && end > start);
const context = {
  CHECKLIST: [{ done: true, lev: 20 }, { done: false, lev: 500 }],
  LAWYER_LEVERAGE: { retained: 100, emailed: 30 },
  BASELINE_PROJECTION: 50,
  CEILING_PROJECTION: 200,
  document: { querySelectorAll: () => statuses.map(status => ({ dataset: { status } })) },
};
let statuses = [];
const compute = runInNewContext(source.slice(start, end) + '\ncomputeLeverage;', context);
assert.equal(compute().total, 70);
statuses = ['emailed', 'emailed', 'emailed', 'unknown'];
assert.equal(compute().counselLev, 80);
statuses = ['retained', 'retained'];
assert.equal(compute().counselLev, 100);
assert.equal(compute().counselRetained, true);
statuses.push('emailed', 'emailed');
assert.equal(compute().total, 200);
console.log('Leverage evidence, counsel cap, retainer deduplication and ceiling: ok');
