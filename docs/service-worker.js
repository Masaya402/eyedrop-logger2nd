const CACHE = 'eyedrop-cache-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/main.js',
  '/manifest.json',
  'https://cdn.jsdelivr.net/npm/@picocss/pico@2.0.3/css/pico.min.css'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(ASSETS))
  );
});

self.addEventListener('fetch', e => {
  e.respondWith(
    caches.match(e.request).then(res => res || fetch(e.request))
  );
});
