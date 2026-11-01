// Hero wall: Temida's screens on sample data (never a real case). Each card plays its screen, holds, and starts over.
(function () {
  var wall = document.getElementById('bwall'); if (!wall) return;
  var still = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var n = innerWidth <= 560 ? 3 : innerWidth <= 900 ? 6 : 9;
  var el = function (t, c, x) { var e = document.createElement(t); if (c) e.className = c; if (x != null) e.textContent = x; return e; };
  var money = function (v) { return '$' + Math.round(v).toLocaleString('en-US'); };
  var wait = function (ms) { return new Promise(function (r) { setTimeout(r, still ? 0 : ms); }); };
  var head = function (a, l, r) { var h = el('div', 'bc-hd'); h.appendChild(el('span', '', l)); h.appendChild(el('span', '', r || '')); a.appendChild(h); return h; };

  var DEADLINES = [['Reply to the notice', 9], ['Serve the claim', 14], ['Hearing day', 21]];
  var RANGES = [[4200, 9800, 16500], [1800, 3400, 6200], [12000, 21500, 30000]];
  var TASKS = [['Find the tenancy agreement', 'Photograph the damage', 'Send the demand letter', 'File the claim'],
               ['Order the records', 'List the witnesses', 'Draft the timeline', 'Book a legal clinic call']];
  var DAYS = [[['Mar 2', 'Notice received'], ['Mar 9', 'Repair requested'], ['Apr 1', 'Second letter sent'], ['Apr 15', 'Reply due']],
              [['Jun 3', 'Contract signed'], ['Jul 18', 'Work stopped'], ['Aug 2', 'Invoice disputed'], ['Aug 30', 'Claim filed']]];
  var NOTES = ['Called the office. They said the repair is booked for Friday, and they will send it in writing.',
               'Original letter is in the blue folder. Scanned copy saved to Files.',
               'Clinic said to keep every receipt and write down each call the same day.'];

  var PLAYS = [
    function deadline(a, i) {
      var d = DEADLINES[i % DEADLINES.length]; head(a, 'Next deadline', '');
      a.appendChild(el('div', 'bc-big', d[0])); var s = a.appendChild(el('div', 'bc-sub'));
      var bar = a.appendChild(el('div', 'bc-bar')).appendChild(el('i'));
      var go = function (left) { s.textContent = 'in ' + left + (left === 1 ? ' day' : ' days'); bar.style.width = (100 - left / d[1] * 100) + '%'; };
      return (function step(left) { go(left); return left <= 1 ? wait(2400) : wait(900).then(function () { return step(left - 1); }); })(d[1]);
    },
    function range(a, i) {
      var r = RANGES[i % RANGES.length]; head(a, 'Your range', 'Money');
      var rows = ['Low', 'Likely', 'High'].map(function (l) {
        var row = a.appendChild(el('div', 'bc-row')); row.appendChild(el('span', 'bc-sub', l));
        var bar = row.appendChild(el('div', 'bc-bar')).appendChild(el('i')); var b = row.appendChild(el('b', '', '$0')); return [bar, b];
      });
      return wait(400).then(function () {
        rows.forEach(function (x, j) { x[0].style.width = (r[j] / r[2] * 100) + '%'; });
        var t0 = performance.now();
        return new Promise(function (done) { (function tick(t) { var p = still ? 1 : Math.min(1, (t - t0) / 900);
          rows.forEach(function (x, j) { x[1].textContent = money(r[j] * p); }); p < 1 ? requestAnimationFrame(tick) : done(); })(t0); });
      }).then(function () { return wait(4200); });
    },
    function tasks(a, i) {
      var t = TASKS[i % TASKS.length]; var h = head(a, 'Tasks', '0 of ' + t.length);
      var lis = t.map(function (x) { var li = a.appendChild(el('div', 'bc-li')); li.appendChild(el('span', '', x)); return li; });
      return lis.reduce(function (p, li, j) { return p.then(function () { li.classList.add('on'); return wait(800); })
        .then(function () { li.classList.add('done'); h.lastChild.textContent = (j + 1) + ' of ' + t.length; return wait(500); }); }, Promise.resolve())
        .then(function () { return wait(2600); });
    },
    function timeline(a, i) {
      var d = DAYS[i % DAYS.length]; head(a, 'Timeline', 'Facts');
      var lis = d.map(function (x) { var li = a.appendChild(el('div', 'bc-li')); li.appendChild(el('em', '', x[0])); li.appendChild(el('span', '', x[1])); return li; });
      return lis.reduce(function (p, li) { return p.then(function () { li.classList.add('on', 'done'); return wait(1100); }); }, Promise.resolve())
        .then(function () { return wait(2400); });
    },
    function journal(a, i) {
      var s = NOTES[i % NOTES.length]; head(a, 'Journal', 'Today'); var p = a.appendChild(el('div', 'bc-txt'));
      if (still) { p.textContent = s; return wait(0); }
      var w = s.split(' ');
      return w.reduce(function (q, x, j) { return q.then(function () { p.textContent = w.slice(0, j + 1).join(' '); return wait(110); }); }, Promise.resolve())
        .then(function () { return wait(3000); });
    }
  ];

  for (var i = 0; i < n; i++) (function (i) {
    var a = wall.appendChild(el('div', 'bc')), play = PLAYS[(i * 2) % PLAYS.length], round = Math.floor(i / PLAYS.length);
    var run = function () { a.textContent = ''; return play(a, round++); };
    if (still) { run(); return; }
    wait(i * 120).then(function loop() { return run().then(loop); });
  })(i);
})();
