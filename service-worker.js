// EDUVO Service Worker
// الهدف: التطبيق يفتح بدون إنترنت للصفحات اللي اتزارت قبل كده، لكن أي تحديث (ألوان، خطوط، كود)
// يوصل فورًا لأي جهاز أول ما يكون عنده إنترنت — من غير ما يفضل عالق على نسخة قديمة مخزنة.
//
// ⚠️ مهم: كل مرة تعمل تعديل مهم وترفعه على GitHub، غيّر رقم النسخة (CACHE_NAME) تحت
// عشان أي جهاز فتح الموقع قبل كده يمسح الكاش القديم ويجيب النسخة الجديدة تلقائيًا.

const CACHE_NAME = 'eduvo-cache-v4-supabase';

const CORE_ASSETS = [
  './index.html',
  './manifest.json',
  './css/styles.css',
  './js/app.js',
  './screens/auth.html',
  './screens/dashboard.html',
  './screens/subjects.html',
  './screens/subject-detail.html',
  './screens/ai.html',
  './screens/books.html',
  './screens/planner.html',
  './screens/courses.html',
  './screens/lecture.html',
  './screens/profile.html',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS))
  );
  // فعّل نسخة الـ Service Worker الجديدة فورًا من غير ما تستنى إغلاق كل التابات القديمة
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;

  // لا تتدخل في طلبات خارجية (جوجل، الذكاء الاصطناعي، خطوط، إلخ) — سيبها تروح للإنترنت مباشرة
  if (request.method !== 'GET' || !request.url.startsWith(self.location.origin)) {
    return;
  }

  // استراتيجية "الشبكة أولاً": حاول تجيب أحدث نسخة من الإنترنت دايمًا، وتجاهل كاش المتصفح العادي
  // كمان (cache: 'no-store') عشان الملف الجديد يوصل فورًا حتى لو المتصفح نفسه بيحاول يكاش الاستجابة.
  // لو نجحت: رجّعها للمستخدم وخزّنها كنسخة احتياطية للأوفلاين.
  // لو فشلت (مفيش إنترنت): رجّع آخر نسخة كانت متخزنة كحل بديل مؤقت بس.
  event.respondWith(
    fetch(request, { cache: 'no-store' })
      .then((response) => {
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
        return response;
      })
      .catch(() => caches.match(request))
  );
});
