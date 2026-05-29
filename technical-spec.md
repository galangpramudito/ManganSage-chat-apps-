# Spesifikasi Teknis — Aplikasi Real-Time Chat
> Dokumen ini merupakan kompilasi hasil diskusi teknis lengkap sebagai panduan implementasi.

---

## 1. Tech Stack

| Komponen | Teknologi | Keterangan |
|---|---|---|
| UI Framework | Flutter | Native Android & iOS |
| State Management | Riverpod + Freezed | Reaktif, code-generated |
| HTTP Client | Dio | REST API + interceptor |
| Real-Time | Laravel Reverb + Laravel Echo | WebSocket first-party Laravel |
| Database Lokal | SQLite (sqflite) | Offline-first |
| Auth | Laravel Sanctum | Token-based |
| Notifikasi | Firebase Cloud Messaging (FCM) | Background push notification |
| Token Storage | flutter_secure_storage | Encrypted (Keychain / EncryptedSharedPrefs) |
| Navigasi | GoRouter | Declarative + redirect guard |
| Avatar Cache | cached_network_image | Hemat bandwidth |

---

## 2. Backend & API Contract

### 2.1 Authentication

#### `POST /api/register`
```json
// Request
{
  "name": "Andi Pratama",
  "email": "andi@email.com",
  "password": "password123",
  "password_confirmation": "password123"
}

// Response 201
{
  "user": { "id": 1, "name": "Andi Pratama", "email": "andi@email.com" },
  "token": "1|sanctum_token_here"
}
```

#### `POST /api/login`
```json
// Request
{ "email": "andi@email.com", "password": "password123" }

// Response 200
{
  "user": { "id": 1, "name": "Andi Pratama", "email": "andi@email.com" },
  "token": "1|sanctum_token_here"
}
```

#### `POST /api/logout`
```
Header: Authorization: Bearer {token}
Response 200: { "message": "Logged out" }
```

---

### 2.2 Users (Global Contact List)

#### `GET /api/users`
```json
// Response 200
{
  "data": [
    { "id": 2, "name": "Budi Santoso", "email": "budi@email.com", "is_online": true, "avatar": null },
    { "id": 3, "name": "Citra Dewi", "email": "citra@email.com", "is_online": false, "avatar": null }
  ]
}
```
> User yang sedang login tidak ikut muncul. Filter: `where('id', '!=', auth()->id())`

---

### 2.3 Conversations (Inbox)

#### `GET /api/conversations`
```json
// Response 200
{
  "data": [
    {
      "id": 1,
      "participant": { "id": 2, "name": "Budi Santoso", "avatar": null },
      "last_message": { "body": "Hei, apa kabar?", "created_at": "2025-01-10T10:00:00Z", "is_read": false },
      "unread_count": 3
    }
  ]
}
```

#### `POST /api/conversations`
```json
// Request
{ "user_id": 2 }

// Response 200 atau 201
{ "id": 1, "participant": { "id": 2, "name": "Budi Santoso" } }
```
> Gunakan `firstOrCreate` di Laravel untuk mencegah duplikasi conversation.

#### `DELETE /api/conversations/{id}`
```
// Soft delete sepihak via pivot table
Response 200: { "message": "Conversation removed" }
```

---

### 2.4 Messages (Chat Room)

#### `GET /api/conversations/{id}/messages`
```json
// Query: ?page=1&per_page=20
// Response 200
{
  "data": [
    {
      "id": 101,
      "sender_id": 1,
      "body": "Hei, apa kabar?",
      "is_read": false,
      "created_at": "2025-01-10T10:00:00Z"
    }
  ],
  "meta": { "current_page": 1, "last_page": 5, "per_page": 20 }
}
```
> Urutkan `ORDER BY created_at DESC` di backend, balik urutan di Flutter.

#### `POST /api/conversations/{id}/messages`
```json
// Request
{ "body": "Hei, apa kabar?" }

// Response 201
{
  "id": 101,
  "sender_id": 1,
  "body": "Hei, apa kabar?",
  "is_read": false,
  "created_at": "2025-01-10T10:00:00Z"
}
```

#### `POST /api/conversations/{id}/read`
```
// Tandai semua pesan di conversation ini sebagai dibaca
Response 200: { "message": "Marked as read" }
```

---

### 2.5 FCM Token

#### `POST /api/user/fcm-token`
```json
// Request
{ "fcm_token": "device_token_dari_flutter" }

// Response 200
{ "message": "Token updated" }
```

---

## 3. Database Schema (Laravel Migration)

```
users
  id, name, email, password, avatar (nullable), is_online (bool), last_seen (timestamp), fcm_token (nullable), timestamps

conversations
  id, timestamps

conversation_user  (pivot)
  conversation_id, user_id, deleted_at (soft delete sepihak)

messages
  id, conversation_id (FK), sender_id (FK → users), body, created_at

message_reads
  id, message_id (FK), user_id (FK), read_at (timestamp)
```

---

## 4. WebSocket — Laravel Reverb

### Setup
```bash
php artisan install:broadcasting
# Pilih Reverb
```

### .env
```env
BROADCAST_CONNECTION=reverb
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=localhost
REVERB_PORT=8080
REVERB_SCHEME=http
```

> Production: jalankan Reverb sebagai proses terpisah dengan **Supervisor**.
```bash
php artisan reverb:start
```

### Event Channels

| Event | Channel | Payload |
|---|---|---|
| Pesan baru | `private-user.{userId}` | `{ conversation_id, message }` |
| Pesan dibaca | `private-user.{userId}` | `{ conversation_id, read_at }` |
| Status online | `presence-online` | `{ user_id, is_online }` |

### Contoh Event Laravel
```php
class MessageSent implements ShouldBroadcast
{
    public function broadcastOn() {
        return new PrivateChannel('user.' . $this->recipientId);
    }

    public function broadcastAs() {
        return 'message.sent';
    }
}
```

### Koneksi di Flutter
```dart
LaravelEcho(
  broadcaster: 'reverb',
  options: {
    'wsHost': 'your-server.com',
    'wsPort': 8080,
    'forceTLS': false, // true di production dengan SSL
    'key': 'your-app-key',
  }
)
```

---

## 5. Notifikasi Push — FCM

### Arsitektur
```
User B kirim pesan
       ↓
Laravel terima via API
       ↓
Broadcast via Reverb (foreground) + Kirim FCM (background)
       ↓
Flutter tentukan mana yang diproses
```

### Backend — Kirim Notifikasi
```php
// Setelah simpan pesan di MessageController
$recipient = User::find($recipientId);

if ($recipient->fcm_token) {
    $message = CloudMessage::withTarget('token', $recipient->fcm_token)
        ->withNotification(Notification::create(
            title: $sender->name,
            body: $request->body
        ))
        ->withData([
            'conversation_id' => (string) $conversationId,
            'sender_id'       => (string) $sender->id,
            'type'            => 'new_message'
        ]);

    Firebase::messaging()->send($message);
}
```

### Flutter — 3 Kondisi Handler

| Kondisi | Handler |
|---|---|
| Foreground | `FirebaseMessaging.onMessage` → tampilkan local notification |
| Background | `FirebaseMessaging.onBackgroundMessage` → sistem handle otomatis |
| Terminated | `getInitialMessage()` → cek saat app pertama dibuka |

```dart
// main.dart
await Firebase.initializeApp();
await FirebaseMessaging.instance.requestPermission();

final token = await FirebaseMessaging.instance.getToken();
await apiService.updateFcmToken(token);

// Foreground
FirebaseMessaging.onMessage.listen((message) {
  final convId = message.data['conversation_id'];
  final activeId = ref.read(activeConversationProvider);
  if (convId != activeId) localNotif.show(message);
});

// Tap dari background
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final convId = message.data['conversation_id'];
  router.push('/chat/$convId');
});

// Background handler — harus top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
```

### Token Refresh Otomatis
```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  apiService.updateFcmToken(newToken);
});
```

---

## 6. Arsitektur Flutter — Riverpod

### Struktur Folder
```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── router/
│   ├── network/            # Dio instance + interceptors
│   ├── websocket/          # Laravel Echo setup
│   └── local_db/           # SQLite helper
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── providers/
│   │   └── screens/        # LoginScreen, RegisterScreen
│   ├── users/
│   │   ├── data/
│   │   ├── providers/
│   │   └── screens/        # UsersScreen
│   ├── conversations/
│   │   ├── data/
│   │   ├── providers/
│   │   └── screens/        # InboxScreen
│   └── messages/
│       ├── data/
│       ├── providers/
│       └── screens/        # ChatRoomScreen
│
└── shared/
    ├── widgets/            # Avatar, BubbleWidget, StatusIndicator
    └── models/             # User, Conversation, Message (freezed)
```

### Provider Map
```dart
// Auth
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>

// Users
final usersListProvider = FutureProvider<List<User>>

// Conversations
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Conversation>>
final unreadCountProvider = Provider<int>  // derived dari conversationsProvider

// Messages
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Message>, int>
// family int = conversationId

// Active Chat
final activeConversationProvider = StateProvider<int?>
```

### MessagesNotifier
```dart
class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier(this.ref, this.conversationId) : super([]);

  int _currentPage = 1;
  bool _hasMore = true;

  Future<void> loadInitial() async {
    // 1. Tampil dari SQLite (instant)
    final cached = await localDb.getMessages(conversationId);
    state = cached;

    // 2. Sync dari API di background
    final fresh = await repo.getMessages(conversationId, page: 1);
    await localDb.upsertMessages(fresh);
    state = fresh;
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _currentPage++;
    final older = await repo.getMessages(conversationId, page: _currentPage);
    if (older.isEmpty) { _hasMore = false; return; }
    state = [...older, ...state]; // posisi scroll tidak bergeser
  }

  void addMessage(Message msg) {
    state = [...state, msg];
    localDb.upsertMessages([msg]);
  }
}
```

### ConversationsNotifier
```dart
class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  Future<void> loadAll() async {
    state = await localDb.getConversations();
    final fresh = await repo.getConversations();
    await localDb.upsertConversations(fresh);
    state = fresh;
  }

  void updateLastMessage(Message msg) {
    state = [
      for (final c in state)
        if (c.id == msg.conversationId)
          c.copyWith(lastMessage: msg, unreadCount: c.unreadCount + 1)
        else c
    ];
  }

  void removeLocally(int conversationId) {
    state = state.where((c) => c.id != conversationId).toList();
    localDb.deleteConversation(conversationId);
    repo.deleteConversation(conversationId);
  }
}
```

### WebSocket Listener
```dart
void initWebSocket(String userId, WidgetRef ref) {
  echo.private('user.$userId')
    .listen('message.sent', (data) {
      final msg = Message.fromJson(data);
      ref.read(messagesProvider(msg.conversationId).notifier).addMessage(msg);
      ref.read(conversationsProvider.notifier).updateLastMessage(msg);
    })
    .listen('message.read', (data) {
      // update status centang biru
    });
}
```

---

## 7. Keamanan

### Token Storage
```dart
class SecureStorage {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) => _storage.write(key: 'sanctum_token', value: token);
  Future<String?> getToken()           => _storage.read(key: 'sanctum_token');
  Future<void> clear()                 => _storage.deleteAll();
}
```

### Dio Auth Interceptor
```dart
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.getToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) _handleSessionExpired();
    handler.next(err);
  }

  void _handleSessionExpired() {
    storage.clear();
    router.go('/login');
  }
}
```

### Session Expired — Skenario

| Skenario | Handling |
|---|---|
| Token expired saat request | Interceptor 401 → clear → redirect login |
| App dibuka setelah lama | Validasi token ke `/api/user` → redirect jika 401 |
| Logout manual | Hit logout API → clear storage → disconnect WebSocket → redirect |
| Reinstall / device baru | Token tidak ada → langsung LoginScreen |

### GoRouter Redirect Guard
```dart
redirect: (context, state) async {
  final token = await secureStorage.getToken();
  final isOnAuth = state.matchedLocation.startsWith('/login') ||
                   state.matchedLocation.startsWith('/register');

  if (token == null) return isOnAuth ? null : '/login';

  try {
    await ref.read(authProvider.notifier).validateSession();
    return isOnAuth ? '/inbox' : null;
  } catch (_) {
    await secureStorage.clear();
    return '/login';
  }
},
```

### Logout — Bersih Total
```dart
void handleLogout() async {
  await secureStorage.clear();
  echo.disconnect();
  ref.invalidate(conversationsProvider);
  ref.invalidate(messagesProvider);
  router.go('/login');
}
```

### Keamanan Tambahan (Production)
```bash
# Build dengan obfuscation
flutter build apk --obfuscate --split-debug-info=build/debug-info
```

---

## 8. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  freezed_annotation: ^2.x
  dio: ^5.x
  laravel_echo: ^latest
  sqflite: ^2.x
  flutter_secure_storage: ^9.x
  go_router: ^13.x
  cached_network_image: ^3.x
  firebase_core: ^latest
  firebase_messaging: ^15.x
  flutter_local_notifications: ^17.x
  kreait/laravel-firebase: ^latest   # composer (backend)

dev_dependencies:
  build_runner: ^2.x
  riverpod_generator: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
```
