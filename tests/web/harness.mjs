// Loads temida.jaybulb.com but serves every same-origin file from the local web/ folder.
// puppeteer-core from any checkout that has it; set PUPPETEER to override.
const puppeteer = (await import(process.env.PUPPETEER || '/Users/joshua/Documents/Code/talli/node_modules/puppeteer-core/lib/esm/puppeteer/puppeteer-core.js')).default;
import fs from 'fs'; import path from 'path';
const WEB = new URL('../../web', import.meta.url).pathname;
const TYPES = { '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.html': 'text/html', '.svg': 'image/svg+xml' };
export async function open(creds, { local = true, width = 1280 } = {}) {
  const b = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: 'new' });
  const p = await b.newPage(); await p.setViewport({ width, height: 900 });
  const errors = [];
  p.on('pageerror', e => errors.push(e.stack.split('\n').slice(0, 3).join(' | ')));
  p.on('dialog', d => d.accept());
  if (local) {
    await p.setBypassServiceWorker(true);
    await p.setRequestInterception(true);
    p.on('request', r => {
      const u = new URL(r.url());
      if (u.host !== 'temida.jaybulb.com') return r.continue();
      const f = path.join(WEB, u.pathname === '/' ? 'index.html' : u.pathname);
      if (!fs.existsSync(f) || r.url().includes('sw.js')) return u.pathname.endsWith('sw.js') ? r.respond({ status: 404, body: '' }) : r.continue();
      r.respond({ status: 200, contentType: TYPES[path.extname(f)] || 'application/octet-stream', body: fs.readFileSync(f) });
    });
  }
  await p.goto('https://temida.jaybulb.com/?cb=' + Date.now(), { waitUntil: 'networkidle2' });
  await p.evaluate(() => document.querySelector('[data-auth="login"]').click());
  await p.type('#authEmail', creds.email); await p.click('#authFormEmail [type=submit]');
  await p.type('#authPassword', creds.password); await p.click('#authFormPass [type=submit]');
  await p.waitForSelector('body[data-ready], #onboard:not([hidden])', { timeout: 15000 }).catch(() => {});
  await new Promise(r => setTimeout(r, 1500));
  return { b, p, errors };
}
export const qa = () => { const e = Object.fromEntries(fs.readFileSync(new URL('../../.env.qa', import.meta.url), 'utf8').trim().split('\n').map(l => l.split('='))); return { email: e.QA_EMAIL, password: e.QA_PASSWORD }; };
