// ponytail: network-first, cache only as an offline fallback.
// It used to be cache-first over a precached list pinned to '?v=40'. That serves a stale
// '/' and stylesheet forever unless every deploy bumps CACHE *and* every asset's ?v — which
// is exactly how the site shipped correct CSS that nobody could see. Never go back to it.
const CACHE = 'themis-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET' || !e.request.url.startsWith(self.location.origin)) return;
  e.respondWith(
    fetch(e.request)
      .then(r => {
        const copy = r.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy));
        return r;
      })
      .catch(() => caches.match(e.request))
  );
});
