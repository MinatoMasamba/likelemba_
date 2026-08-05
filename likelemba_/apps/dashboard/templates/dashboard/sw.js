{% load static %}const CACHE_NAME = 'likelemba-shell-v1';
const APP_SHELL = [
  '{% static "dashboard/style.css" %}',
  '{% static "dashboard/app.css" %}',
  '{% static "dashboard/theme.js" %}',
  '{% static "dashboard/img/favicon.png" %}',
];

self.addEventListener('install', function (event) {
  event.waitUntil(caches.open(CACHE_NAME).then(function (cache) { return cache.addAll(APP_SHELL); }));
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (key) { return key !== CACHE_NAME; }).map(function (key) { return caches.delete(key); }));
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', function (event) {
  if (event.request.method !== 'GET') return;

  var url = new URL(event.request.url);
  if (url.pathname.startsWith('/static/')) {
    event.respondWith(
      caches.match(event.request).then(function (cached) { return cached || fetch(event.request); })
    );
  }
  // Pages et appels API : toujours le réseau, jamais mis en cache. Ce sont
  // des soldes/cotisations qui doivent rester à jour, et un cache partagé
  // par origine (pas par utilisateur) exposerait les données d'un compte au
  // suivant sur un appareil partagé.
});
