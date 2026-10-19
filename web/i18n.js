// Landing translations. English lives in index.html; the other languages swap text in by selector.
// Picks ?lang=, then the saved choice, then the browser language. The sign-in modal, onboarding and the signed-in shell are translated too.
(function () {
  // [key, selector, how]: how is 'text' (default), 'last' (last text node, after an icon), 'alt', 'label' (aria-label + title), 'aria' (aria-label only), 'h1'.
  var SLOTS = [
    ['features', '.lp-links a[href="#features"]'], ['download', '.lp-links a[href="#download"]'],
    ['login', '.lp-nav [data-auth=login], .lp-cta-row [data-auth=login]'], ['register', '.lp-nav [data-auth=register]'],
    ['kicker', '.th-kicker'], ['h1', '.lp-h1', 'h1'], ['lead', '.lp-lead'],
    ['cta', '.lp-cta-row [data-auth=register]'], ['appstore', '.lp-appstore span'], ['alt', '.th-art svg', 'aria'],
    ['featTitle', '#features h2'],
    ['c1l', '.lp-card:nth-child(1) .lp-card-no', 'last'], ['c1h', '.lp-card:nth-child(1) h3'], ['c1p', '.lp-card:nth-child(1) p'],
    ['c2l', '.lp-card:nth-child(2) .lp-card-no', 'last'], ['c2h', '.lp-card:nth-child(2) h3'], ['c2p', '.lp-card:nth-child(2) p'],
    ['c3l', '.lp-card:nth-child(3) .lp-card-no', 'last'], ['c3h', '.lp-card:nth-child(3) h3'], ['c3p', '.lp-card:nth-child(3) p'],
    ['c4l', '.lp-card:nth-child(4) .lp-card-no', 'last'], ['c4h', '.lp-card:nth-child(4) h3'], ['c4p', '.lp-card:nth-child(4) p'],
    ['c5l', '.lp-card:nth-child(5) .lp-card-no', 'last'], ['c5h', '.lp-card:nth-child(5) h3'], ['c5p', '.lp-card:nth-child(5) p'],
    ['dlTitle', '#download h2'], ['dlSub', '#download > p'], ['anyBrowser', '.th-plat-row > div:nth-child(3) small'],
    ['soon', '.th-plat-row span.lp-btn'], ['openWeb', '.th-plat-row [data-auth=login]'],
    ['fIphone', '.th-icons a[href^="https://apps"]', 'label'], ['fCreate', '.th-icons [data-auth=register]', 'label'],
    ['login', '.th-icons [data-auth=login]', 'label'], ['fPrivacy', '.th-icons a[href="privacy.html"]', 'label'],
    ['fBrand', '.th-icons a[href="brand/"]', 'label'], ['fPortfolio', '.th-icons a[href="https://jaybulb.com"]', 'label'],
    ['fTop', '.th-icons button:last-child', 'label'], ['notAdvice', '.th-fine', 'last'], ['language', '#lang', 'label']
  ];
  // Translations live in i18n.json (landing slots by key, sign-in strings keyed by their English text).
  // English never fetches it.
  var LANGS = ['fr', 'es', 'zh-Hans', 'zh-Hant', 'pa'], T = {}, cur = 'en', loading;
  function load() {
    return loading || (loading = fetch('i18n.json?v=10').then(function (r) { return r.json(); }).then(function (j) { T = j; }).catch(function () {}));
  }
  // Sign-in modal: static text translated by its English source; auth.js calls temidaT() for the rest.
  var AUTH = [['#authModalClose', 'label'], ['#authEmail', 'ph'], ['#authFormEmail .auth-btn'], ['#authPassword', 'ph'],
    ['#authFormPass .auth-btn[type=submit]'], ['#authSignup'], ['#authForgot'], ['#authBack'], ['.auth-footer'], ['#authTitle'], ['#authSub']];
  window.temidaT = function (s) { return ((T[cur] || {}).auth || {})[s] || s; };
  // Translate a block of plain markup (onboarding, empty state): leaf text and placeholders, English kept in data-en.
  window.temidaTree = function (root) {
    if (!root) return;
    root.querySelectorAll('h1, p, b, span, button, div, input[placeholder]').forEach(function (n) {
      if (n.tagName === 'INPUT') { n.dataset.en = n.dataset.en || n.placeholder; n.placeholder = window.temidaT(n.dataset.en); return; }
      if (n.children.length || !n.textContent.trim()) return;
      n.dataset.en = n.dataset.en || n.textContent; n.textContent = window.temidaT(n.dataset.en);
    });
  };
  // Signed-in shell: swap fixed labels in place. Only text that equals a known English label is touched, so case content
  // never changes. `only` limits a pass to label elements (used on the database markup); SKIP is where script.js renders data.
  var SKIP = '#facts,#grounds-case,#grounds-money,#scenarios,#stackRows,#lawyers,#timeline,#checklist,#journalList,#documentsList,#scaleBands,#scriptText,#leverage-widget,#trajectory';
  var FRAG = '.tab-btn,.section-hd b,.section-hd .lbl,.section-hd .hint,.lbl,.hint,.k,.na-lbl,.l-lbl,.defeats,button,textarea,input';
  var seenT = new WeakMap(), seenA = new WeakMap();
  window.temidaApp = function (root, only) {
    if (!root) return;
    var w = document.createTreeWalker(root, 4), n, nodes = [];
    while ((n = w.nextNode())) nodes.push(n);
    nodes.forEach(function (n) {
      var p = n.parentNode, rec = seenT.get(n), cur = n.nodeValue;
      if (/^(SCRIPT|STYLE|TEXTAREA)$/.test(p.nodeName) || p.closest(SKIP) || (only && !p.matches(only))) return;
      if (rec && rec[1] === cur) cur = rec[0];
      var k = cur.trim(), v = k && window.temidaT(k);
      if (!k || (v === k && !rec)) return;
      var out = cur.replace(k, function () { return v; });
      seenT.set(n, [cur, out]); n.nodeValue = out;
    });
    [root].concat([].slice.call(root.querySelectorAll('[title],[aria-label],[placeholder]'))).forEach(function (e) {
      if (e.closest(SKIP) || (only && !e.matches(only))) return;
      var r = seenA.get(e) || {};
      ['title', 'aria-label', 'placeholder'].forEach(function (a) {
        var cur = e.getAttribute(a), rec = r[a];
        if (cur === null) return;
        if (rec && rec[1] === cur) cur = rec[0];
        var v = window.temidaT(cur);
        if (v === cur && !rec) return;
        e.setAttribute(a, v); r[a] = [cur, v]; seenA.set(e, r);
      });
    });
  };
  // script.js calls this once it has rendered; apply() calls it on every language change.
  window.temidaShell = function () {
    ['.strip', '#twPanel', '.page footer'].forEach(function (q) { window.temidaApp(document.querySelector(q)); });
    ['.page header.hero', '.page main'].forEach(function (q) { window.temidaApp(document.querySelector(q), FRAG); });
  };
  var lastText = function (el) { for (var n = el.lastChild; n; n = n.previousSibling) if (n.nodeType === 3 && n.nodeValue.trim()) return n; };
  var en = {};
  function read(how, el) {
    if (how === 'alt') return el.alt;
    if (how === 'label' || how === 'aria') return el.getAttribute('aria-label');
    if (how === 'h1') return el.innerHTML.replace(/<br>/g, '|');
    if (how === 'last') return lastText(el).nodeValue;
    if (how === 'ph') return el.placeholder;
    return el.textContent;
  }
  function write(how, el, v) {
    if (how === 'alt') el.alt = v;
    else if (how === 'aria') el.setAttribute('aria-label', v);
    else if (how === 'label') { el.setAttribute('aria-label', v); el.title = v; }
    else if (how === 'h1') { el.textContent = ''; v.split('|').forEach(function (s, i) { if (i) el.appendChild(document.createElement('br')); el.appendChild(document.createTextNode(s)); }); }
    else if (how === 'last') lastText(el).nodeValue = v;
    else if (how === 'ph') el.placeholder = v;
    else el.textContent = v;
  }
  SLOTS.forEach(function (s) {
    document.querySelectorAll(s[1]).forEach(function (el, i) { if (!i && !(s[0] in en)) en[s[0]] = read(s[2], el); });
  });
  en.notAdvice = 'Not legal advice';
  var authEn = AUTH.map(function (a) { var el = document.querySelector(a[0]); return el && read(a[1], el); }); // the fine print is one text node; apply() swaps only its last phrase
  function apply(lang) {
    cur = lang;
    var t = T[lang] || {};
    document.documentElement.lang = LANGS.indexOf(lang) > -1 ? lang : 'en';
    window.temidaTree(document.getElementById('emptyState')); window.temidaTree(document.getElementById('onboard')); window.temidaShell();
    AUTH.forEach(function (a, i) { var el = document.querySelector(a[0]); if (el && authEn[i]) write(a[1], el, window.temidaT(authEn[i])); });
    SLOTS.forEach(function (s) {
      var v = t[s[0]] || en[s[0]];
      if (s[0] === 'notAdvice') { var n = lastText(document.querySelector(s[1])); n.nodeValue = n.nodeValue.replace(/ [^·]+$/, ' ' + v); return; }
      document.querySelectorAll(s[1]).forEach(function (el) { write(s[2], el, v); });
    });
    document.dispatchEvent(new Event('themis-lang'));
  }
  function pick() {
    var q = new URLSearchParams(location.search).get('lang'), saved;
    try { saved = localStorage.getItem('themis-lang'); } catch (e) {}
    var want = [q, saved].concat(navigator.languages || [navigator.language]);
    for (var i = 0; i < want.length; i++) {
      var w = (want[i] || '').toLowerCase();
      if (!w) continue;
      if (w === 'en' || w.indexOf('en-') === 0) return 'en';
      if (w.indexOf('zh') === 0) return /hant|tw|hk|mo/.test(w) ? 'zh-Hant' : 'zh-Hans';
      var base = w.split('-')[0];
      if (LANGS.indexOf(base) > -1) return base;
    }
    return 'en';
  }
  var sel = document.getElementById('lang'), lang = pick();
  if (sel) {
    sel.value = lang;
    sel.addEventListener('change', function () {
      try { localStorage.setItem('themis-lang', sel.value); } catch (e) {}
      if (sel.value === 'en') apply('en'); else load().then(function () { apply(sel.value); });
    });
  }
  if (lang !== 'en') load().then(function () { apply(lang); });
})();
