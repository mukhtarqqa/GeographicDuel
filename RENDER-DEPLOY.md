# Render.com арқылы Geographic Duel орналастыру (Deploy Guide)

Бұл нұсқаулықта **Geographic Duel** жобасының нақты уақыттағы WebSocket серверін (`server/server.js`) және Flutter Web клиентін **[Render.com](https://render.com/)** бұлтты платформасына тегін әрі оңай орналастыру қадамдары баяндалған.

---

## 🏗 Архитектуралық құрылымы

```
[Ойыншылар (Flutter Web / Android)]
          │
          ├───► 1. Render Web Service (Node.js WebSocket: wss://<app>.onrender.com)
          │
          └───► 2. Firebase Cloud (Firestore, Auth, Google Sign-In)
```

---

## 1-БӨЛІМ. Node.js WebSocket серверін Render-ге орналастыру (Web Service)

Сервер `server/server.js` файлында орналасқан және автоматты түрде Render ұсынатын `PORT` айнымалысын қабылдайды.

### 1-Қадам. Репозиторийді дайындау
Барлық код GitHub репозиторийіңізге жүктелген болуы тиіс (`git push origin main`).

### 2-Қадам. Render.com-да жаңа Web Service ашу
1. [Render Dashboard](https://dashboard.render.com/) кіріңіз.
2. **New +** ➔ **Web Service** батырмасын басыңыз.
3. Өзіңіздің `geographic-duel` GitHub репозиторийіңізді таңдаңыз.

### 3-Қадам. Параметрлерді енгізу:
- **Name:** `geographic-duel-server` (немесе қалаған атауыңыз)
- **Region:** `Frankfurt (EU Central)` немесе `Singapore`
- **Branch:** `main`
- **Root Directory:** `server` *(Өте маңызды! Сервер бөлек каталогта орналасқан)*
- **Runtime:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `node server.js`
- **Instance Type:** `Free`

### 4-Қадам. Айнымалылар (Environment Variables):
- `NODE_ENV` = `production`

**Deploy Web Service** батырмасын басыңыз. 1-2 минутта сервер іске қосылады және сізге дайын қауіпсіз WSS домені беріледі:
👉 `https://geographic-duel-server.onrender.com`
👉 `wss://geographic-duel-server.onrender.com`

---

## 2-БӨЛІМ. Flutter Web қолданбасын Render-ге орналастыру (Static Site)

Flutter Web қолданбасын тікелей Render Static Site ретінде хостингке қоюға болады.

### 1-Қадам. Render-де Static Site құру
1. Render Dashboard-та **New +** ➔ **Static Site** таңдаңыз.
2. Сол репозиторийді таңдаңыз.

### 2-Қадам. Параметрлер:
- **Name:** `geographic-duel-web`
- **Branch:** `main`
- **Build Command:**
  ```bash
  cd $HOME && git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter && export PATH="$PATH:$HOME/flutter/bin" && cd $RENDER_PROJECT_ROOT && flutter config --no-analytics && flutter build web --release
  ```
- **Publish Directory:** `build/web`

### Немесе жеңілдетілген тәсіл (GitHub Actions арқылы):
Жергілікті компьютерде немесе GitHub Actions арқылы `flutter build web` орындап, `build/web` файлын Firebase Hosting немесе Render-ге тікелей жүктеуге болады.

---

## 3-БӨЛІМ. Flutter қолданбасын Render серверіне қосу

Серверіңіз Render-де іске қосылғаннан кейін, оның WSS мекенжайын Flutter қолданбасында көрсету жеткілікті:

`lib/data/services/gameplay_socket_service.dart` файлындағы URL:
```dart
static const String serverUrl = 'wss://geographic-duel-server.onrender.com';
```

Серверде тексеруге арналған денсаулық тексеру эндпоинті бар:
`https://geographic-duel-server.onrender.com/health` ➔ `{"status":"ok","players":0,"activeMatches":0}`

---

## 💡 Render Free тарифының ерекшелігі (Keep-Alive)
Render Free тарифінде серверге 15 минут бойы сұраныс түспесе, ол «ұйқы» режиміне өтеді (Spin down). Алғашқы қосылу кезінде сервер ояну үшін 30 секунд кетуі мүмкін.
Бұған жол бермеу үшін [cron-job.org](https://cron-job.org/) сияқты тегін қызметтен әр 10 минут сайын `https://geographic-duel-server.onrender.com/health` сілтемесіне GET сұраныс жіберіп қоюға болады.
