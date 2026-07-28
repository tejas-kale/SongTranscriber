const CACHE_NAME = 'song-transcriber-v2';
const ASSETS = ['./index.html', './manifest.json', './icon.png'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Pass through OpenRouter API requests without caching
  try {
    const url = new URL(e.request.url);
    if (url.hostname === 'openrouter.ai') return;
  } catch (_) { /* ignore non-parseable URLs */ }
  if (e.request.method !== 'GET') { e.respondWith(fetch(e.request)); return; }

  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (res.ok && res.type === 'basic') {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return res;
      });
    })
  );
});
