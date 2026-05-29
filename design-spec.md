# Design Specification — Aplikasi Real-Time Chat
> Panduan desain visual dan UX sebagai referensi implementasi Flutter UI.

---

## 1. Identitas Visual

| Properti | Keputusan |
|---|---|
| Gaya | iMessage modern — elegan, clean, sedikit warna sebagai aksen premium |
| Mode | Light & Dark (keduanya) |
| Aksen | Biru safir (`#0A84FF`) + abu slate — kuat tapi tidak norak |
| Filosofi | Whitespace dan tipografi sebagai fondasi; warna aksen hanya pada elemen interaktif dan bubble sent |

---

## 2. Tipografi

**Font Utama:** `Inter` (open-source, feel mendekati SF Pro)

| Elemen | Style | Ukuran | Warna |
|---|---|---|---|
| Header layar | Inter Bold | 20px | Foreground utama |
| Nama kontak | Inter SemiBold | 16px | Foreground utama |
| Preview pesan | Inter Regular | 13px | Muted |
| Isi pesan (bubble) | Inter Regular | 15px | Foreground utama |
| Timestamp | Inter Regular | 11px | Muted |
| Indikator status | — | 11px | Lihat tabel status |

---

## 3. Skema Warna

### Light Mode
| Token | Hex | Penggunaan |
|---|---|---|
| `background` | `#F8F9FB` | Latar layar utama (bukan putih murni — sedikit warm) |
| `surface` | `#FFFFFF` | Background kartu / list |
| `surface-elevated` | `#EEF1F6` | Input bar, secondary surface |
| `foreground` | `#0D1117` | Teks utama |
| `muted` | `#8A94A6` | Teks sekunder, timestamp |
| `accent` | `#0A84FF` | Aksen utama — tombol, link, elemen aktif |
| `accent-soft` | `#E8F2FF` | Background elemen aksen yang subtle |
| `bubble-sent` | `#0A84FF` | Bubble pesan terkirim (biru safir) |
| `bubble-sent-text` | `#FFFFFF` | Teks di bubble terkirim |
| `bubble-received` | `#FFFFFF` | Bubble pesan diterima |
| `bubble-received-text` | `#0D1117` | Teks di bubble diterima |
| `bubble-received-border` | `#E2E6ED` | Border tipis bubble received |
| `divider` | `#E2E6ED` | Garis pemisah list |
| `online-dot` | `#34C759` | Indikator status online |
| `destructive` | `#FF3B30` | Tombol logout, swipe delete |

### Dark Mode
| Token | Hex | Penggunaan |
|---|---|---|
| `background` | `#0D1117` | Latar layar utama (biru-hitam, bukan hitam murni) |
| `surface` | `#161B22` | Background kartu / list |
| `surface-elevated` | `#21262D` | Input bar, secondary surface |
| `foreground` | `#F0F6FC` | Teks utama |
| `muted` | `#6E7681` | Teks sekunder, timestamp |
| `accent` | `#2F9EFF` | Aksen utama — lebih terang di dark mode |
| `accent-soft` | `#1A2D45` | Background elemen aksen yang subtle |
| `bubble-sent` | `#2F9EFF` | Bubble pesan terkirim |
| `bubble-sent-text` | `#FFFFFF` | Teks di bubble terkirim |
| `bubble-received` | `#21262D` | Bubble pesan diterima |
| `bubble-received-text` | `#F0F6FC` | Teks di bubble diterima |
| `bubble-received-border` | `#30363D` | Border tipis bubble received |
| `divider` | `#21262D` | Garis pemisah list |
| `online-dot` | `#3DD68C` | Indikator status online |
| `destructive` | `#FF453A` | Tombol logout, swipe delete |

---

## 4. Bubble Pesan

| Properti | Nilai |
|---|---|
| Border radius | `20` (rounded besar) |
| Sudut flat | Satu sudut di sisi pengirim pada pesan pertama rangkaian (iMessage-style tail subtle) |
| Max width | `75%` dari lebar layar |
| Padding horizontal | `16px` |
| Padding vertikal | `10px` |
| Jarak antar bubble (satu rangkaian) | `4px` |
| Jarak antar rangkaian berbeda pengirim | `12px` |
| Shadow bubble received (Light) | `0 1px 3px rgba(0,0,0,0.08)` — subtle depth |
| Shadow bubble received (Dark) | tidak ada shadow |
| Border bubble received | `1px solid bubble-received-border` |

### Aturan Tail / Ekor Bubble
- Tail **hanya muncul** pada pesan **pertama** dari setiap rangkaian pesan berurutan milik satu pengirim
- Pesan berikutnya dalam rangkaian yang sama: sudut rounded penuh tanpa tail

### Gradasi Bubble Sent (Opsional — Polish)
Untuk kesan lebih premium, bubble sent bisa memakai linear gradient:
```
Light: linear-gradient(135deg, #0A84FF → #0066CC)
Dark:  linear-gradient(135deg, #2F9EFF → #0A84FF)
```

---

## 5. Avatar & Identitas Pengguna

### Sistem Inisial
- Ambil **2 huruf pertama** dari nama depan + nama belakang → `"Andi Pratama"` = `AP`
- Nama 1 kata: ambil 1 huruf saja → `"Budi"` = `B`
- Shape: **lingkaran penuh**

### Ukuran Avatar
| Konteks | Ukuran |
|---|---|
| Daftar kontak / Inbox | `48px` |
| Di dalam chat room | `28px` |
| Layar Profil (besar) | `88px` |

### Warna Background — Deterministik
Warna ditentukan dari hash nama pengguna sehingga **konsisten di semua perangkat**.
Palet diperbarui agar lebih elegan dan kohesif dengan tema biru safir:

```
#0A84FF  (sapphire blue)
#34C759  (emerald)
#FF9F0A  (amber)
#FF375F  (rose)
#5E5CE6  (indigo)
#32ADE6  (sky)
#FF6B35  (tangerine)
#30D158  (mint)
#BF5AF2  (violet)
#AC8E68  (warm sand)
```

> Teks inisial selalu putih (`#FFFFFF`). Ring tipis `2px solid rgba(255,255,255,0.3)` di dalam lingkaran untuk kesan premium.

### Fallback (sebelum foto profil diupload)
- Tampilkan avatar inisial dengan warna deterministik
- Setelah pengguna upload foto: tampilkan foto via `cached_network_image`
- Foto profil bisa diubah di layar **Profil** (Tab ke-3)

---

## 6. Indikator Status Pesan

Posisi: pojok kanan bawah bubble, ukuran `11px`, tidak mencolok.

| Status | Ikon | Warna (Light) | Warna (Dark) |
|---|---|---|---|
| Sending (optimistic) | ⏱ jam pasir kecil | `#8A94A6` muted | `#6E7681` muted |
| Terkirim ke server | ✓ (satu centang) | `#8A94A6` muted | `#6E7681` muted |
| Terkirim ke perangkat | ✓✓ (dua centang) | `#8A94A6` muted | `#6E7681` muted |
| Sudah dibaca | ✓✓ (dua centang) | `#FFFFFF` putih (di atas bubble biru) | `#FFFFFF` putih |
| Gagal (failed) | ✕ | `#FF3B30` merah | `#FF453A` merah |

---

## 7. Navigasi & Struktur Layar

### Pola: Bottom Tab Bar — 3 Tab

```
┌─────────────────────────────┐
│                             │
│         Konten Layar        │
│                             │
├──────────┬──────────┬───────┤
│ 💬       │ 🔍       │ 👤   │
│ Obrolan  │ Pengguna │ Profil│
└──────────┴──────────┴───────┘
```

### Styling Tab Bar
- Background: `surface` (Light: `#FFFFFF`, Dark: `#161B22`)
- Border top: `1px solid divider`
- Tab aktif: ikon + label berwarna `accent`
- Tab tidak aktif: ikon + label berwarna `muted`
- Badge unread: background `accent`, teks putih, border radius penuh

Dipilih karena:
- Semua aksi utama dalam jangkauan ibu jari satu tangan
- Tidak ada menu tersembunyi
- Pola familiar dan intuitif

---

## 8. Spesifikasi Per Layar

### Tab 1 — Obrolan (Inbox)

- **Search bar:** collapse saat scroll ke bawah, muncul saat scroll ke atas (iOS behavior). Background `surface-elevated`, border radius `12px`
- **Kartu obrolan:** avatar inisial kiri, nama + preview pesan, timestamp kanan, badge unread kanan bawah
- **Badge unread:** background `accent` (`#0A84FF`), teks putih bold, min-width `20px`, border radius penuh
- **Swipe-to-delete:** geser kartu ke kiri untuk hapus — background merah `destructive` revealed
- **Empty state:** ilustrasi minimalis + teks "Belum ada obrolan. Mulai dari tab Pengguna."
- **Preview pesan yang belum dibaca:** nama kontak ditampilkan **Inter SemiBold** (bukan Regular) sebagai visual penanda

### Tab 2 — Pengguna (Global Contact List)

- **Search bar:** selalu visible di bagian atas (tidak collapse). Background `surface-elevated`
- **Daftar pengguna:** avatar inisial + nama + dot status online (`online-dot` hijau `8px`)
- **Tap item:** langsung navigasi ke ChatRoom — buat conversation baru jika belum ada
- **Filter:** pencarian lokal, tidak memanggil API ulang

### Tab 3 — Profil

- Background atas: `accent-soft` (`#E8F2FF` / `#1A2D45`) sebagai hero section subtle
- Avatar besar `88px` di tengah dengan ring `3px solid accent`
- Nama pengguna (Inter Bold 22px)
- Tombol "Ganti Foto Profil" — teks `accent`
- Tombol "Edit Nama" — teks `accent`
- Tombol "Logout" — teks `destructive`, border `1px solid destructive`, background transparan

### ChatRoom Screen

- **Header:** background `surface` dengan blur backdrop (`blur: 20px`) — efek frosted glass subtle
- Tombol back kiri dengan ikon `accent`
- Nama + avatar lawan di tengah/kanan
- **Input bar:** background `surface-elevated`, border radius `24px`, tombol kirim berwarna `accent` (lingkaran penuh saat ada teks, abu-abu saat kosong)
- Pesan diurutkan dari terlama (atas) ke terbaru (bawah)
- Scroll ke atas → load more (paginasi 20 pesan per page)
- Avatar lawan **hanya tampil pada pesan pertama** dari rangkaian berurutan (Smart Avatar Display)
- Auto-scroll ke bawah saat pesan baru masuk
- **Banner "Menghubungkan ulang...":** background `accent-soft`, teks `accent`, fade in di bawah header

---

## 9. Spacing & Layout System

| Token | Nilai |
|---|---|
| `spacing-xs` | `4px` |
| `spacing-sm` | `8px` |
| `spacing-md` | `16px` |
| `spacing-lg` | `24px` |
| `spacing-xl` | `32px` |
| `radius-bubble` | `20px` |
| `radius-avatar` | `50%` (lingkaran) |
| `radius-input` | `24px` |
| `radius-card` | `12px` |
| `radius-badge` | `10px` |

---

## 10. Animasi & Transisi

| Elemen | Animasi |
|---|---|
| Transisi antar layar | Slide horizontal standar, 300ms, curve `easeInOut` |
| Pesan baru masuk | Fade + slide dari bawah `8px`, 200ms, curve `easeOut` |
| Badge unread | Scale + fade in (0 → 1), 150ms |
| Swipe-to-delete | Slide kiri dengan background destructive revealed, spring physics |
| Indikator "Menghubungkan ulang..." | Fade in halus di bawah header, 300ms |
| Typing indicator (tiga titik) | Staggered bounce loop, muncul/hilang dengan fade 200ms |
| Tombol kirim | Scale 0.95 saat ditekan (haptic-like), 100ms |
| Avatar | Fade in saat load dari cache, 200ms |

Target performa: **60 FPS** stabil di semua animasi.

---

## 11. Tambahan Spesifikasi UX

### 11.1 Debouncing Tombol Kirim

**UX Rule:** Tombol kirim wajib dinonaktifkan sesaat setelah diketuk untuk mencegah pesan terkirim ganda.

```dart
bool _isSending = false;

Future<void> handleSend() async {
  if (_isSending || _controller.text.trim().isEmpty) return;
  setState(() => _isSending = true);

  await ref.read(messagesProvider(convId).notifier).sendMessage(_controller.text);
  _controller.clear();

  setState(() => _isSending = false);
}
```

**UI:** Tombol kirim opacity `0.4` saat `_isSending = true`. Warna tetap `accent` agar konsisten.

---

### 11.2 Indikator Upload Gambar (Untuk Fitur Media Kelak)

| Elemen | Detail |
|---|---|
| Thumbnail | Gambar asli, di-blur `sigmaX: 3, sigmaY: 3` |
| Overlay | `rgba(0,0,0,0.3)` di atas blur |
| Indikator | `CircularProgressIndicator` warna `accent` |
| Persentase | Teks `XX%`, Inter Regular 12px, putih |

Setelah upload selesai: blur dan overlay hilang, gambar tampil normal dengan status `sent`.

---

### 11.3 Typing Indicator — Tampilan UI

| Properti | Detail |
|---|---|
| Posisi | Di bawah pesan terakhir, rata kiri (sisi received) |
| Bentuk | Bubble kecil `received` style, background `bubble-received` |
| Tiga titik | Warna `muted`, staggered bounce loop |
| Durasi muncul | Selama whisper `typing` aktif, hilang 2 detik setelah `stop-typing` |
| Animasi muncul/hilang | Fade + scale `0.8 → 1.0`, 200ms |
