const CACHE = "gpe-neon-v656b";
const ASSETS = ["./index.html", "./site.webmanifest", "./gpe-logo.png", "./user-guide.html"];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)).catch(() => null));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});

self.addEventListener("push", (event) => {
  let data = { title: "GPE Neon Cloud", body: "You have a new update." };
  try { data = event.data ? event.data.json() : data; } catch (e) {}
  event.waitUntil(self.registration.showNotification(data.title || "GPE", { body: data.body || "", icon: "gpe-logo.png" }));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(self.clients.openWindow("./index.html"));
});
