# Barcode World — Chatwoot Team Setup Guide

## 1. المتطلبات الأساسية

كل عضو في الفريق لازم يكون عنده:

- Windows 10/11 مع تفعيل WSL2.
- Docker Desktop ويكون شغال.
- Git.
- PowerShell.
- مساحة تخزين كافية للـ Docker Images والـ Dependencies.

## 2. تحميل المشروع لأول مرة

افتح PowerShell:

```powershell
git clone <TEAM_REPOSITORY_URL>
cd barcode-world-chatwoot
```

استبدل `<TEAM_REPOSITORY_URL>` برابط مستودع الفريق الفعلي.

> لا تستخدم رابط Fork قبل التأكد إنه موجود وإن أعضاء الفريق عندهم صلاحية الوصول إليه.

## 3. إعداد Git لنهايات الأسطر

لتقليل مشاكل تشغيل ملفات Linux داخل Docker على Windows:

```powershell
git config --local core.autocrlf false
```

لو ظهرت مشاكل `\r` أو `no such file or directory` في ملفات التشغيل، افتح الملفات المتأثرة في VS Code وغيّر Line Ending إلى LF بدل CRLF.

## 4. إعداد Environment Variables

لو ملف `.env` مش موجود:

```powershell
Copy-Item .env.example .env
```

راجع إعدادات `.env` مع مسؤول الـ Backend.

الإعدادات المهمة لبيئة التطوير المحلية:

```dotenv
FRONTEND_URL=http://localhost:3000

POSTGRES_HOST=postgres
POSTGRES_PORT=5432

REDIS_URL=redis://redis:6379

SMTP_ADDRESS=mailhog
SMTP_PORT=1025
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_ENABLE_STARTTLS_AUTO=false

MAILER_SENDER_EMAIL=notifications@barcodeworld.local
```

**مهم:** لا تستبدل الملف بالكامل بالقيم السابقة. احتفظ بباقي المتغيرات المطلوبة في المشروع، مثل كلمات مرور قاعدة البيانات ومفاتيح Rails، وتأكد إن إعدادات SMTP تستخدم `smtp` وليس `sendmail`.

لا ترفع `.env` أو أي مفاتيح سرية إلى GitHub.

## 5. بناء وتشغيل Docker لأول مرة

من داخل مجلد المشروع:

```powershell
docker compose build
```

ثم:

```powershell
docker compose up -d postgres redis mailhog
```

تأكد إن الخدمات جاهزة:

```powershell
docker compose ps
```

## 6. تهيئة قاعدة البيانات

بعد تشغيل PostgreSQL:

```powershell
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```

نفّذ الأمر ده أثناء إعداد البيئة لأول مرة.

**تحذير:** لا تستخدم `db:reset` أو `docker compose down -v` على بيئة فيها بيانات مهمة.

## 7. تشغيل التطبيق

```powershell
docker compose up -d rails sidekiq vite
```

اعرض حالة الخدمات:

```powershell
docker compose ps
```

راقب السجلات لو التطبيق اتأخر:

```powershell
docker compose logs -f rails vite
```

أول تشغيل ممكن يستغرق وقتًا بسبب تجهيز Vite والـ Dependencies.

## 8. روابط الخدمات

| الخدمة | الرابط |
|---|---|
| Chatwoot Dashboard | http://localhost:3000 |
| Vite Development Server | http://localhost:3036/vite-dev/ |
| MailHog | http://localhost:8025 |

MailHog يستقبل رسائل التفعيل التجريبية محليًا، ولا يرسلها إلى Gmail الحقيقي.

## 9. التشغيل اليومي

بعد فتح Docker Desktop، نفّذ:

```powershell
cd "D:\path\to\barcode-world-chatwoot"
docker compose up -d
```

لمتابعة السجلات:

```powershell
docker compose logs -f rails vite sidekiq
```

## 10. إيقاف المشروع

```powershell
docker compose down
```

الأمر يوقف ويحذف حاويات المشروع وشبكاته، لكنه يحتفظ بالـ Named Volumes.

## 11. تحديث المشروع

```powershell
git pull
docker compose up -d --build
```

لو التحديث يحتوي على تغييرات في قاعدة البيانات، راجع تعليمات الـ Migration الخاصة بالتحديث قبل تطبيقها.

## 12. حل المشاكل الشائعة

**Port already allocated**

لو المنفذ `5432` أو `6379` مستخدم، راجع الـ Port Mapping في `docker-compose.yaml`.

يمكن استخدام `6380:6379` لـ Redis على جهاز المطور، مع بقاء الاتصال الداخلي:

```dotenv
REDIS_URL=redis://redis:6379
```

**Rails أو Vite لا يعمل**

```powershell
docker compose logs --tail=100 rails
docker compose logs --tail=100 vite
```

**مشكلة CRLF**

تأكد إن ملفات Shell Scripts تستخدم LF، خصوصًا:

- `docker/entrypoints/rails.sh`
- `docker/entrypoints/vite.sh`
- `bin/rails`
- `bin/vite`

**رسائل التفعيل لا تصل**

افتح MailHog:

http://localhost:8025

وتأكد من إعدادات SMTP وتشغيل Sidekiq.

**ERR_EMPTY_RESPONSE أو Timeout**

```powershell
docker compose ps
docker compose logs --tail=100 rails
docker compose logs --tail=100 vite
```

قد يكون التطبيق ما زال يبدأ أو ينتظر تجهيز Vite.

## 13. قواعد العمل داخل الفريق

- كل عضو يعمل على Branch منفصل.
- لا ترفع `.env` أو كلمات المرور.
- لا تعدّل بيانات بيئة مشتركة بدون تنسيق.
- لا تحذف Docker Volumes بدون نسخة احتياطية.
- استخدم Pull Requests لمراجعة التغييرات.
- عند حدوث خطأ، شارك رسالة الخطأ والسجلات بعد إخفاء البيانات الحساسة.

## 14. ملاحظة مهمة عن حساب Barcode World

كل مطور عنده قاعدة بيانات محلية مستقلة.

تحميل الكود من GitHub لا ينقل تلقائيًا:

- حساب Administrator.
- حساب شركة Barcode World.
- القنوات المتصلة.
- بيانات العملاء والمحادثات.
- إعدادات Branding المخزنة في قاعدة البيانات.

يجب تجهيز هذه البيانات لكل بيئة على حدة، أو استخدام بيانات تهيئة تجريبية معتمدة من الفريق.

---

**Barcode World Development Team**

Chatwoot + Docker + PostgreSQL + Redis + Sidekiq + Vite + MailHog
