# Настройка Firebase для Geographic Duel

Приложение **Geographic Duel** поддерживает гибридный бэкенд:
1. **Локальный/удаленный WebSocket Realtime сервер** (`server/server.js`) — мгновенный 1v1 мультиплеер без настройки Google Cloud.
2. **Офлайн / Smart Bot** — интеллектуальный ИИ-соперник, если сервер или сеть недоступны.
3. **Google Cloud Firestore & Firebase Auth** — облачная база данных и синхронизация.

---

## 1. Как подключить свой Firebase проект (пошагово)

Если вы хотите подключить свой реальный Firebase проект:

### Шаг 1. Создайте проект в Firebase Console
1. Перейдите в [Firebase Console](https://console.firebase.google.com/).
2. Нажмите **Добавить проект** (например, `geographic-duel-prod`).
3. Включите **Authentication**:
   - Способы входа ➔ **Анонимный** ➔ Включить.
4. Включите **Cloud Firestore**:
   - Создать базу данных (в тестовом режиме или примените правила из файла `firestore.rules`).

### Шаг 2. Сгенерируйте конфигурацию FlutterFire
Выполните в терминале проекта:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Эта команда автоматически обновит файл `lib/firebase_options.dart` реальными ключами API вашего проекта.

Или просто вставьте ваши ключи в `lib/firebase_options.dart`:
```dart
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'ВАШ_РЕАЛЬНЫЙ_API_KEY',
    appId: 'ВАШ_APP_ID',
    messagingSenderId: 'ВАШ_SENDER_ID',
    projectId: 'ВАШ_PROJECT_ID',
    authDomain: 'ВАШ_PROJECT_ID.firebaseapp.com',
    storageBucket: 'ВАШ_PROJECT_ID.appspot.com',
  );
```

Как только в `lib/firebase_options.dart` будут вставлены не-демо ключи, приложение автоматически переключится в режим **Firebase Cloud**!

---

## 2. Развертывание правил безопасности Firestore

Для защиты базы данных примените готовые правила из файла `firestore.rules`:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 3. Запуск Realtime WebSocket сервера (Мультиплеер без Firebase)

Для игры вдвоем на одном компьютере (в двух вкладках браузера) или по локальной сети:
```bash
# В терминале:
cd server
npm start
```
Сервер запустится на `http://localhost:8088` и `ws://localhost:8088`. Приложение автоматически подключится к нему!
