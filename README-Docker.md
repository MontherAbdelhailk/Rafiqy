# 🐳 تشغيل Rafiq Backend بـ Docker

## المتطلبات الوحيدة
- تثبيت **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** (مجاني لـ Windows / Mac / Linux)
- لا يلزم تثبيت Node.js أو PostgreSQL!

---

## خطوات التشغيل (3 خطوات فقط)

### 1️⃣ استنسخ المشروع
```bash
git clone https://github.com/YOUR_USERNAME/rafiq.git
cd rafiq
```

### 2️⃣ اعمل ملف `.env`
```bash
# على Windows (PowerShell)
Copy-Item .env.docker .env

# على Mac / Linux
cp .env.docker .env
```
> **⚠️ مهم:** افتح ملف `.env` وغيّر `JWT_SECRET` و `JWT_REFRESH_SECRET` لأي نص طويل عشوائي.

### 3️⃣ شغّل المشروع
```bash
docker compose up -d
```

✅ الـ API هيكون شغّال على: **http://localhost:5000**

---

## أول مرة فقط – تهيئة قاعدة البيانات

بعد ما الـ containers اشتغلوا، شغّل الأوامر دي **مرة واحدة بس**:

```bash
# إنشاء الجداول
docker compose exec api npm run db:migrate

# إضافة بيانات تجريبية (اختياري)
docker compose exec api npm run db:seed
```

---

## أوامر مفيدة

| الأمر | الوظيفة |
|-------|----------|
| `docker compose up -d` | تشغيل كل شيء في الخلفية |
| `docker compose down` | إيقاف كل شيء |
| `docker compose logs -f api` | عرض لوجات الـ API |
| `docker compose logs -f db` | عرض لوجات قاعدة البيانات |
| `docker compose restart api` | إعادة تشغيل الـ API فقط |
| `docker compose down -v` | إيقاف وحذف البيانات كلها (⚠️ خطر) |

---

## هيكل الملفات

```
rafiq/
├── docker-compose.yml       ← إعداد الـ containers
├── .env.docker              ← قالب متغيرات البيئة
├── .env                     ← متغيراتك الشخصية (لا تتحمّل على GitHub)
└── backend/
    └── Dockerfile           ← بناء صورة الـ API
```

---

## الاتصال بقاعدة البيانات من PgAdmin (اختياري)

| الإعداد | القيمة |
|---------|--------|
| Host | `localhost` |
| Port | `5432` |
| Database | `rafiq_db` |
| Username | `rafiq_user` |
| Password | `rafiq_pass` |

---

## حل المشاكل الشائعة

**❌ خطأ: port 5000 already in use**
```bash
# على Windows
netstat -ano | findstr :5000
taskkill /PID <رقم_الـ_PID> /F
```

**❌ الـ API بيقول "cannot connect to database"**
```bash
# تأكد إن قاعدة البيانات شغّالة وسليمة
docker compose ps
docker compose logs db
```

**❌ تغييرات الكود مش بتظهر**
```bash
# أعد بناء الصورة
docker compose up -d --build
```
