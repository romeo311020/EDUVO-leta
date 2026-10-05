# EDUVO + Supabase

النسخة دي مجهزة لاستخدام Supabase بدل تخزين حسابات الطلاب في `localStorage`.

## 1) إنشاء مشروع Supabase

1. افتح مشروعك في Supabase.
2. من **SQL Editor** افتح ملف `SUPABASE-SETUP.sql` وانفّذ الكود كله.
3. من **Authentication > Providers** فعّل **Phone**.
4. لو مش عايز OTP/SMS في البداية، عطّل **Confirm phone**. لو فعلته، لازم تكمل إعداد مزود SMS في Supabase.
5. لو هتستخدم Google، فعّل Google Provider واضبط Client ID/Secret والـRedirect URL في Supabase.

## 2) بيانات الاتصال

الموقع يقرأ:

- `supabaseUrl`
- `supabaseAnonKey`

من `data.json`.

استخدم فقط **Publishable/Anon key** في الموقع. ممنوع وضع **Service Role Key** داخل GitHub أو JavaScript.

## 3) تسجيل الطلاب

EDUVO يستخدم:

- Supabase Auth لتسجيل الدخول وكلمات المرور.
- جدول `students` لبيانات الطالب مثل الاسم والصف ورقم الهاتف والحالة.
- RLS لمنع الطالب من قراءة بيانات الطلاب الآخرين.

## 4) Google

زر Google في EDUVO يستخدم Supabase OAuth. لازم تضبط Google Provider داخل Supabase وتضيف رابط موقعك في Redirect URLs.

## 5) لوحة الإدارة

سياسات قاعدة البيانات تدعم مستخدمًا لديه `app_metadata.role = admin`.
بعد إنشاء حساب المدير من Supabase Auth، يمكن تعيين الدور من SQL Editor:

```sql
update auth.users
set raw_app_meta_data = jsonb_set(coalesce(raw_app_meta_data, '{}'::jsonb), '{role}', '"admin"', true)
where id = 'PUT-ADMIN-USER-UUID-HERE';
```

**ملاحظة:** لا تستخدم Service Role Key في `admin.html`.
