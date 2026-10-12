# Vercel-де Geographic Duel-ді іске қосу нұсқаулығы (Deploy Guide)

**Vercel** — бұл Flutter Web клиентін тегін әрі өте жылдам хостингке қоюға арналған ең жақсы платформа. Ол әлемдік CDN арқылы жұмыс істейді және Firebase Cloud-пен тікелей байланысады.

---

## ⚡ 1-ТӘСІЛ: 1 командамен Vercel-ге жүктеу (Ең оңай әрі жылдам)

Жергілікті компьютерде веб-нұсқасын жинап, оны Vercel-ге тікелей жіберу:

### 1-Қадам. Flutter Web-ті жинау (Build):
Терминалда орындаңыз:
```bash
flutter build web --release
```
*(Бұл команда барлық кодты `build/web` каталогына дайын сайт ретінде жинайды).*

### 2-Қадам. Vercel-ге 1 командамен жүктеу:
```bash
npx vercel build/web --prod
```
- Егер Vercel-ге бірінші рет кірсеңіз, браузерде авторизация жасауды сұрайды (Google немесе GitHub арқылы).
- **Set up and deploy?** ➔ басыңыз `Y` (Yes).
- **Which scope?** ➔ өзіңіздің аккаунтыңызды таңдаңыз.
- Бар болғаны 10-15 секундта сізге дайын сілтеме беріледі:  
  👉 **`https://geographic-duel.vercel.app`** 🎉

---

## 🔄 2-ТӘСІЛ: GitHub арқылы автоматты деплой (Vercel Dashboard)

Егер әрбір `git push` жасаған сайын сайттың автоматты түрде жаңарғанын қаласаңыз:

1. [Vercel Dashboard](https://vercel.com/) кіріңіз.
2. **Add New...** ➔ **Project** батырмасын басыңыз.
3. Өзіңіздің `geographic-duel` GitHub репозиторийіңізді таңдап, **Import** басыңыз.
4. **Build & Development Settings** бөлімінде:
   - **Framework Preset:** `Other`
   - **Build Command:** 
     ```bash
     curl -s -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz && tar xf flutter_linux_*.tar.xz && export PATH="$PATH:`pwd`/flutter/bin" && flutter build web --release
     ```
   - **Output Directory:** `build/web`
5. **Deploy** батырмасын басыңыз.

---

## 🔑 Маңызды: Firebase-те доменді рұқсат ету (Authorized Domains)

Сайтыңыз Vercel-де ашылған соң (`https://geographic-duel.vercel.app`), онда Google логин қатесіз жұмыс істеуі үшін:

1. **[Firebase Console](https://console.firebase.google.com/)** ➔ жобаңызды ашыңыз.
2. **Authentication** ➔ **Settings** қойындысы ➔ **Authorized domains** (Уполномоченные домены).
3. **Add domain** батырмасын басып, Vercel доменіңізді қосыңыз (мысалы, `geographic-duel.vercel.app`).

Осыдан кейін ойын дүние жүзінің кез келген нүктесінде Google аккаунтымен де, қонақ ретінде де бірден ашылып, жұмыс істейді!
