// Full-page shots of the signed-in web app on the QA account (.env.qa), phone and desktop, light and dark.
// Never point this at the owner login. Usage: OUT=<dir> node tests/web/shots.mjs
import { open, qa } from './harness.mjs';
const out = process.env.OUT || '.';
for (const [w, scheme] of [[1280, 'light'], [390, 'dark']]) {
  const { b, p, errors } = await open(qa(), { width: w });
  await p.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: scheme }]);
  await new Promise(r => setTimeout(r, 500));
  await p.screenshot({ path: `${out}/web-${w}-${scheme}.png`, fullPage: true });
  console.log(w, scheme, errors.join(' ; ') || 'no errors'); await b.close();
}
