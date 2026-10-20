// temidaT reads only each language's `auth` block, so every UI string author.js passes to tr() must live there.
// No browser, no account. Run: node tests/web/i18n.mjs
import assert from 'node:assert/strict'; import fs from 'fs';
const web = new URL('../../web/', import.meta.url);
const T = JSON.parse(fs.readFileSync(new URL('i18n.json', web), 'utf8'));
const src = fs.readFileSync(new URL('author.js', web), 'utf8');
const used = new Set([...src.matchAll(/tr\('([^']+)'\)/g), ...src.matchAll(/(?:label|edit): '([^']+)'/g), ...src.matchAll(/\['\w+', '([^']+)'/g), ...src.matchAll(/\['(Edit|Remove)'/g)].map(m => m[1]));
for (const [lang, t] of Object.entries(T)) {
  const stray = Object.keys(t).filter(k => /^[A-Z]/.test(k));
  assert.deepEqual(stray, [], `${lang}: UI strings outside auth are never read`);
  const missing = [...used].filter(s => /^[A-Z]/.test(s) && !/^[A-Z_]+$/.test(s) && !(s in t.auth));
  assert.deepEqual(missing, [], `${lang}: no translation`);
}
console.log(`i18n ok: ${used.size} strings, ${Object.keys(T).length} languages`);
