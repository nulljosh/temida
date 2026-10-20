// v9: add, edit or remove a fact, a ground, a witness, a lawyer or a deadline in the open case, same shapes as the apps
// (Store+Authoring.swift). The cases row is read fresh, one array changes, and the whole value goes
// back, so every other key in the brief survives untouched. Rows are found by content, not position.
(function () {
  const sb = window._sb, uid = window._userId;
  if (!sb || !uid) return;
  const PREFIX = { rcmp: '', family: 'FAMILY_', muni: 'MUNI_', bylaw: 'BYLAW_' };
  const KINDS = {
    fact:     { list: 'FACTS',    anchor: 'facts',    data: 'facts',    label: 'Add fact',   edit: 'Edit fact',
                fields: [['key', 'Label, like Date of incident', 'text', 'off'], ['value', 'Value', 'text', 'off']] },
    ground:   { list: 'GROUNDS',  anchor: 'grounds-case', data: 'grounds', label: 'Add ground', edit: 'Edit ground',
                fields: [['title', 'Ground, like Negligence', 'text', 'off'], ['sec', 'Law or section', 'text', 'off'], ['desc', 'Why it applies', 'text', 'off']] },
    witness:  { list: 'WITNESSES', anchor: 'witnesses', data: 'witnesses', label: 'Add witness', edit: 'Edit witness',
                fields: [['name', 'Name', 'text', 'name'], ['role', 'Role, like Bystander', 'text', 'off'], ['date', 'Date', 'date', 'off'], ['statement', 'What they saw', 'text', 'off']] },
    lawyer:   { list: 'LAWYERS',  anchor: 'lawyers',  data: 'lawyers',  label: 'Add lawyer', edit: 'Edit lawyer',
                fields: [['name', 'Name', 'text', 'name'], ['sub', 'Firm or practice', 'text', 'organization'], ['phone', 'Phone', 'tel', 'tel'], ['email', 'Email', 'email', 'email']] },
    deadline: { list: 'TIMELINE', anchor: 'timeline', data: 'timeline', label: 'Add deadline', edit: 'Edit deadline',
                fields: [['title', 'What is due', 'text', 'off'], ['rule', 'Rule', 'select', 'off'], ['start', 'Claim discovered', 'date', 'off'],
                         ['due', 'Due', 'date', 'off'], ['desc', 'Note', 'text', 'off']] },
  };
  // v10: a deadline worked out from BC law (checked against bclaws.gov.bc.ca 2026-10-19). Computed once on save
  // and stored as `due` (ISO) with the cite in `rule`, the same as ios/Sources/Models/Limitation.swift.
  const RULES = {
    basic:    { months: 24,  label: 'Basic limitation, 2 years (BC)', start: 'Claim discovered', title: 'Basic limitation period ends',
                hint: 'The day you first knew, or reasonably should have known, that you were harmed, who caused it, and that going to court is the right step (s. 8).',
                cite: 'Limitation Act (BC) s. 6(1): 2 years after the claim is discovered' },
    ultimate: { months: 180, label: 'Ultimate limitation, 15 years (BC)', start: 'Act or omission', title: 'Ultimate limitation period ends',
                cite: 'Limitation Act (BC) s. 21(1): 15 years after the act or omission' },
    notice:   { months: 2,   label: 'Notice to a municipality, 2 months (BC)', start: 'Damage sustained', title: 'Notice to the municipality is due',
                cite: 'Local Government Act (BC) s. 736(1): written notice within 2 months of the damage' },
  };
  // Feb 29 and month ends land on the last day of the shorter month, like Swift's Calendar. tests/web/limitation.mjs checks it.
  function addMonths(day, n) {
    const [y, m, d] = day.split('-').map(Number);
    const t = new Date(Date.UTC(y, m - 1 + n, 1));
    t.setUTCDate(Math.min(d, new Date(Date.UTC(t.getUTCFullYear(), t.getUTCMonth() + 1, 0)).getUTCDate()));
    return t.toISOString().slice(0, 10);
  }

  function contact(L, kind) {
    const c = (L.contacts || []).find(x => x.kind === kind);
    return c ? c.href.replace(/^(tel|mailto):/, '') : '';
  }
  const iso = s => { const d = new Date(s); return isNaN(d) ? '' : new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10); };
  // Stored dates are written in English ("Oct 19, 2026") so every platform, in any language, can read them back.
  const shown = s => s ? new Date(s + 'T12:00').toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : '';
  const initials = n => n.split(/\s+/).slice(0, 2).map(w => w[0] || '').join('').toUpperCase();
  // What the form shows for an existing row, and the fields that find it again.
  function current(kind, row) {
    if (kind === 'ground') return { match: { id: row.id }, values: { title: row.title, sec: row.sec, desc: row.desc } };
    if (kind === 'witness') return { match: { name: row.name, role: row.role, statement: row.statement }, values: { name: row.name, role: row.role, date: iso(row.date), statement: row.statement } };
    if (kind === 'fact') return { match: { key: row.key, value: row.value }, values: { key: row.key, value: row.value } };
    if (kind === 'lawyer') return { match: { id: row.id }, values: { name: row.name, sub: row.sub, phone: contact(row, 'tel'), email: contact(row, 'email') } };
    return { match: { title: row.title, when: row.when }, values: { title: row.title, due: row.due || iso(row.when), desc: row.desc } };
  }

  function item(kind, v, editing) {
    // Every key the app decoders require, or the row shows here and nowhere else. n is set in save().
    if (kind === 'ground') return editing ? { title: v.title, sec: v.sec, desc: v.desc }
      : { id: crypto.randomUUID(), n: '', title: v.title, sec: v.sec, desc: v.desc, val: '', cite: '', grade: '', risk: '', high: 0 };
    if (kind === 'witness') {
      const out = { initials: initials(v.name), name: v.name, role: v.role, date: shown(v.date), statement: v.statement };
      if (editing) { if (!v.date || v.date === editing.values.date) delete out.date; return out; }
      return Object.assign(out, { tags: [], annotations: [] });
    }
    if (kind === 'fact') return { key: v.key, value: v.value };
    if (kind === 'deadline') {
      const r = RULES[v.rule], day = r && v.start ? addMonths(v.start, r.months) : v.due;
      const out = { when: shown(day), title: v.title, desc: v.desc, state: 'warn' };
      if (day) out.due = day;
      if (r) out.rule = r.cite;
      if (editing) { // keep the dot and an unparsed date; a date picked by hand no longer follows a rule
        delete out.state;
        if (!r) { if (!v.due || v.due === editing.values.due) { delete out.when; delete out.due; } else out.rule = null; }
      }
      return out;
    }
    const contacts = [];
    if (v.phone) contacts.push({ kind: 'tel', href: 'tel:' + v.phone, label: v.phone, primary: true });
    if (v.email) contacts.push({ kind: 'email', href: 'mailto:' + v.email, label: v.email });
    const init = initials(v.name);
    if (editing) return { init, name: v.name, sub: v.sub, contacts };
    return { id: crypto.randomUUID(), init, name: v.name, sub: v.sub, tags: [], contacts, status: 'none' };
  }

  // change: { add: item } | { match, update: fields } | { match, remove: true }
  async function save(kind, change) {
    const { data, error } = await sb.from('brief_data').select('value').eq('key', 'cases');
    if (error) throw error;
    const row = (data || [])[0];
    const value = row ? row.value : {};
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Brief could not be read.'); // never overwrite it
    const key = PREFIX[window.briefActiveCase()] + KINDS[kind].list;
    const list = Array.isArray(value[key]) ? value[key].slice() : [];
    if (change.add && kind === 'ground') change.add.n = String(Math.max(0, ...list.map(r => parseInt(r && r.n) || 0)) + 1);
    if (change.add) list.push(change.add);
    else {
      const i = list.findIndex(r => r && typeof r === 'object' && Object.keys(change.match).every(k => r[k] === change.match[k]));
      if (i < 0) throw new Error(tr('This changed on another device. Reopen the case and try again.'));
      if (change.remove) list.splice(i, 1);
      else {
        const merged = Object.assign({}, list[i], change.update);
        if (change.update.contacts) // the form edits phone and email only; a website survives
          merged.contacts = change.update.contacts.concat((list[i].contacts || []).filter(c => c.kind !== 'tel' && c.kind !== 'email'));
        list[i] = merged;
      }
    }
    value[key] = list;
    const res = await sb.from('brief_data').upsert({ user_id: uid, key: 'cases', value });
    if (res.error) throw res.error;
    await window.briefRefresh();
  }

  function open(kind, editing) {
    const k = KINDS[kind];
    const dlg = document.createElement('dialog');
    dlg.className = 'author-dlg';
    const form = document.createElement('form');
    const h = document.createElement('h2'); h.textContent = tr(editing ? k.edit : k.label); form.appendChild(h);
    k.fields.forEach(([name, label, type, ac], i) => {
      const l = document.createElement('label'); l.textContent = tr(label); l.dataset.field = name;
      const inp = document.createElement(type === 'select' ? 'select' : 'input');
      if (type === 'select') [['', 'Pick the date myself'], ...Object.entries(RULES).map(([id, r]) => [id, r.label])]
        .forEach(([value, text]) => inp.add(new Option(tr(text), value)));
      else Object.assign(inp, { type, autocomplete: ac, value: editing ? editing.values[name] || '' : '' });
      Object.assign(inp, { name, required: i === 0 || kind === 'fact' });
      l.appendChild(inp); form.appendChild(l);
    });
    if (kind === 'deadline') { // a rule swaps the due date for a start date and shows the law it follows
      const f = n => form.querySelector('[data-field="' + n + '"]'), el = form.elements; // not form.title: that is the form's own attribute
      const note = document.createElement('p'); note.className = 'author-rule'; f('desc').after(note);
      const sync = () => {
        const r = RULES[el.rule.value];
        f('start').hidden = !r; f('due').hidden = !!r; note.hidden = !r;
        if (!r) return;
        f('start').firstChild.textContent = tr(r.start); f('start').title = r.hint ? tr(r.hint) : '';
        if (!el.start.value) el.start.value = iso(new Date());
        if (!el.title.value) el.title.value = tr(r.title);
        note.textContent = tr('Due') + ' ' + new Date(addMonths(el.start.value, r.months) + 'T12:00').toLocaleDateString(document.documentElement.lang || undefined, { dateStyle: 'medium' })
          + '. ' + r.cite + '. ' + (r.hint ? tr(r.hint) + ' ' : '') + tr('Worked out from BC law. Check it with a lawyer.');
      };
      el.rule.addEventListener('change', sync); el.start.addEventListener('input', sync); sync();
    }
    const err = document.createElement('p'); err.className = 'err'; err.setAttribute('role', 'status'); form.appendChild(err);
    const row = document.createElement('div'); row.className = 'author-btns';
    const cancel = document.createElement('button'); cancel.type = 'button'; cancel.textContent = tr('Cancel');
    const ok = document.createElement('button'); ok.type = 'submit'; ok.className = 'primary'; ok.textContent = tr('Save');
    row.append(cancel, ok); form.appendChild(row);
    dlg.appendChild(form);
    cancel.addEventListener('click', () => dlg.close());
    dlg.addEventListener('close', () => dlg.remove());
    form.addEventListener('submit', async e => {
      e.preventDefault();
      const v = Object.fromEntries([...new FormData(form)].map(([a, b]) => [a, String(b).trim()]));
      ok.disabled = true; err.textContent = '';
      try { await save(kind, editing ? { match: editing.match, update: item(kind, v, editing) } : { add: item(kind, v) }); dlg.close(); }
      catch (x) { err.textContent = (x && x.message) || tr('Could not save.'); ok.disabled = false; }
    });
    document.body.appendChild(dlg);
    dlg.showModal();
  }

  async function remove(kind, row) {
    if (!confirm(tr('Remove this from the case?'))) return;
    try { await save(kind, { match: current(kind, row).match, remove: true }); }
    catch (x) { alert((x && x.message) || tr('Could not save.')); }
  }

  // Edit and Remove under every lawyer and deadline. script.js rebuilds these lists on every
  // case switch, so the buttons are re-added whenever a list changes.
  function decorate(kind) {
    const list = document.getElementById(KINDS[kind].anchor);
    const rows = list.rows || (window.briefCases()[window.briefActiveCase()] || {})[KINDS[kind].data] || []; // facts: only the rows renderFacts drew
    [...list.children].forEach((el, i) => {
      const row = rows[i];
      const host = el.querySelector('.tl-body, .lawyer-body, .ground-info, .witness-main') || el; // inside the text column, not the grid
      if (!row || host.querySelector(':scope > .author-row')) return;
      const bar = document.createElement('div'); bar.className = 'author-row';
      const name = kind === 'lawyer' || kind === 'witness' ? row.name : kind === 'fact' ? row.key : row.title;
      [['Edit', () => open(kind, current(kind, row))], ['Remove', () => remove(kind, row)]].forEach(([label, fn]) => {
        const b = document.createElement('button');
        b.type = 'button'; b.dataset.label = label; b.textContent = tr(label);
        b.setAttribute('aria-label', tr(label) + ': ' + name);
        b.addEventListener('click', e => { e.stopPropagation(); fn(); });
        bar.appendChild(b);
      });
      host.appendChild(bar);
    });
  }

  Object.keys(KINDS).forEach(kind => {
    const anchor = document.getElementById(KINDS[kind].anchor);
    if (!anchor) return;
    const b = document.createElement('button');
    b.type = 'button'; b.className = 'author-add'; b.dataset.label = KINDS[kind].label;
    b.textContent = '+ ' + tr(KINDS[kind].label);
    b.addEventListener('click', () => open(kind));
    anchor.after(b);
    decorate(kind);
    new MutationObserver(() => { decorate(kind); filter(); }).observe(anchor, { childList: true });
  });
  // v11: search the open case. Filters the rows on the page; nothing is sent anywhere.
  const main = document.querySelector('.page > main'), search = document.createElement('input');
  search.type = 'search'; search.className = 'case-search'; search.placeholder = tr('Search this case'); search.setAttribute('aria-label', search.placeholder);
  const lists = [...Object.values(KINDS).map(k => k.anchor), 'journalList', 'documentsList'];
  function filter() {
    const q = search.value.trim().toLowerCase();
    lists.forEach(id => { const l = document.getElementById(id); if (l) [...l.children].forEach(el => { el.classList.toggle('case-hide', !!q && !el.textContent.toLowerCase().includes(q)); }); });
  }
  ['journalList', 'documentsList'].forEach(id => { const l = document.getElementById(id); if (l) new MutationObserver(filter).observe(l, { childList: true }); });
  search.addEventListener('input', filter);
  if (main) main.prepend(search);
  document.addEventListener('themis-lang', () => {
    document.querySelectorAll('.author-add').forEach(b => { b.textContent = '+ ' + tr(b.dataset.label); });
    document.querySelectorAll('.author-row button').forEach(b => { b.textContent = tr(b.dataset.label); });
    search.placeholder = tr('Search this case'); search.setAttribute('aria-label', search.placeholder);
  });
})();
