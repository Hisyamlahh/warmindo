# Otomatisasi Testing UI dengan Maestro
### Studi Kasus: Aplikasi Mobile Kasir "Warmindo JugaJago"
Disusun untuk Presentasi Kuliah Otomasi Pengujian Perangkat Lunak

---

## Slide 1 — Judul
# Otomatisasi Testing UI dengan Maestro
### Untuk Flutter Mobile Developers
**Aplikasi**: Warmindo JugaJago POS & Table Management  
**Oleh**: [Nama Mahasiswa] • [Tanggal]

---

## Slide 2 — Agenda
1. Kenapa Otomasi Testing UI?
2. Apa itu Maestro?
3. Prasyarat & Arsitektur
4. Struktur Direktori Proyek
5. Menulis Test Flow (YAML)
6. Assertion & Interaksi
7. Demo Pengujian Lokal
8. Integrasi CI/CD (GitHub Actions)
9. Best Practices & Q&A

---

## Slide 3 — Kenapa Testing UI?
- **Manual testing boros waktu**: Setiap ada perubahan kecil/refactor kode, kasir harus mengetes manual ulang.
- **Konsistensi**: Manual testing rawan typo dan human error, sedangkan Maestro konsisten 100%.
- **Regression Detection**: Bug pada layout atau logika navigasi langsung terdeteksi dalam hitungan detik.
- **Fast Feedback di CI/CD**: Terintegrasi otomatis pada setiap *pull request* / *commit*.

| Aspek | Manual Testing | Otomasi (Maestro) |
| :--- | :--- | :--- |
| **Waktu Eksekusi** | Lama (tiap perubahan) | Cepat (hitungan detik) |
| **Konsistensi** | Rawan typo / human error | Konsisten 100% |
| **CI/CD** | Tidak bisa otomatis | Berjalan otomatis di cloud |
| **Regression** | Sulit dicek menyeluruh | Cepat terdeteksi |
| **Dokumentasi** | Hanya cerita lisan | Kode YAML yang jelas |

---

## Slide 4 — Apa Itu Maestro?
- Framework otomasi testing UI modern dari **RunMedix**.
- Dirancang khusus untuk mobile (**Android & iOS**).
- **Ringan & Cepat**: Tanpa Selenium, tanpa Appium (tidak butuh bytecode/dependency berat).
- Menggunakan file konfigurasi **YAML deklaratif** yang sangat mudah dibaca.
- Mendukung: `assertVisible`, `tapOn`, `inputText`, `swipe`, `scroll`, `screenshot`.

> *"Maestro is for developers who want to automate app flows without fighting the test infrastructure."*

---

## Slide 5 — Prasyarat Pengujian
1. **Flutter SDK**: `flutter doctor` tanpa error kritis.
2. **Device Android Terhubung**:
   ```bash
   adb devices
   ```
3. **Maestro CLI Terpasang**:
   ```bash
   # macOS / Linux:
   brew tap magicalmaestro/tap && brew install maestro
   # Alternatif (npm):
   npm install -g @magicalmaestro/cli
   ```
4. **Verifikasi Instalasi**:
   ```bash
   maestro --version
   ```

---

## Slide 6 — Struktur Proyek Maestro

Sesuai standar yang diinstruksikan dosen:

```text
warmindo/
├── maestro/
│   └── flows/
│       ├── landing.yaml         # Verifikasi Splash & Layar Login Kasir
│       ├── login.yaml           # Alur Login Kasir & Masuk Dashboard
│       ├── order_checkout.yaml  # Alur Order, Pembayaran & Struk Transaksi
│       ├── scrolling.yaml       # Uji Swipe Daftar Menu & Meja
│       └── riwayat.yaml         # Uji Filter Riwayat, Dialog Pending & Batal
├── .github/
│   └── workflows/
│       └── maestro.yaml         # CI/CD Otomatis di GitHub Actions
└── tools/
    ├── run-maestro-tests.sh     # Script helper eksekusi lokal
    └── pre-commit.sh            # Git pre-commit hook validator
```

---

## Slide 7 — Format Penulisan Flow (Maestro 2.0)
Format standar yang benar:
`appId` → `info` → `---` → *daftar command*.

```yaml
appId: com.warmindo.warmindo_pos
info:
  title: Landing
  description: Verifikasi app bar & form login tampil.
---
- launchApp
- assertVisible: "Masuk ke Akun Kasir"
- tapOn:
    text: "Masuk ke POS"
- assertVisible: "Email tidak boleh kosong"
```

---

## Slide 8 — Alur 1: `landing.yaml`
**Tujuan**: Memastikan cold start aplikasi berhasil mendarat di halaman login dan memvalidasi form validation.

```yaml
appId: com.warmindo.warmindo_pos
info:
  title: Landing
  description: Verifikasi halaman login dan form validation
---
- launchApp
- assertVisible: "Masuk ke Akun Kasir"
- assertVisible: "Silakan login untuk mengelola transaksi Warmindo"
- tapOn:
    text: "Masuk ke POS"
- assertVisible: "Email tidak boleh kosong"
```

---

## Slide 9 — Alur 2: `login.yaml`
**Tujuan**: Menguji input kredensial kasir/admin dan memastikan navigasi ke Dashboard berhasil.

```yaml
appId: com.warmindo.warmindo_pos
info:
  title: Login
  description: Input email & password, login ke Dashboard
---
- launchApp
- assertVisible: "Masuk ke Akun Kasir"
- tapOn:
    text: "Email"
- inputText: "admin@warmindo.com"
- tapOn:
    text: "Password"
- inputText: "password123"
- tapOn:
    text: "Masuk ke POS"
- assertVisible: "Katalog"
- assertVisible: "Meja"
- assertVisible: "Riwayat"
```

---

## Slide 10 — Alur 3: `scrolling.yaml` (Mengapa `swipe`?)
> **Catatan Penting dari Dosen**:
> Gunakan `swipe` daripada `scroll` di Maestro 2.x, karena `swipe` jauh lebih stabil untuk navigasi list view di Flutter.

```yaml
appId: com.warmindo.warmindo_pos
info:
  title: Scroll
  description: Geser layar katalog menu dan navigasi tab
---
- launchApp
# Login dan buka katalog...
- assertVisible: "Katalog"
- swipe:
    direction: down
- assertVisible: "Katalog"
- swipe:
    direction: up
- tapOn:
    text: "Meja"
- assertVisible: "Total Meja"
- swipe:
    direction: down
```

---

## Slide 11 — Langkah Eksekusi Demo Pengujian

### 1. Periksa Device:
```bash
adb devices
```
### 2. Bangun APK Debug:
```bash
flutter build apk --debug --no-tree-shake-icons
```
### 3. Install APK ke Device:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
### 4. Jalankan Pengujian:
```bash
maestro test maestro/flows/landing.yaml maestro/flows/login.yaml maestro/flows/scrolling.yaml
```
*(Atau cukup jalankan: `bash tools/run-maestro-tests.sh`)*

---

## Slide 12 — Output Pengujian

### Output Berhasil:
```text
Running on Android Device
 > Flow landing ... COMPLETED
 > Flow login ... COMPLETED
 > Flow scrolling ... COMPLETED
```

### Jika Terjadi Kegagalan:
- Maestro otomatis menyimpan screenshot dan hierarki XML/JSON UI di folder:  
  `~/.maestro/tests/<timestamp>/`
- Sangat mempermudah *debugging* selector mana yang belum muncul atau salah ketik.

---

## Slide 13 — Otomasi CI/CD di GitHub Actions
Di berkas `.github/workflows/maestro.yaml`:
- Berjalan otomatis saat ada `push` atau `pull_request`.
- Membangun APK Android secara otomatis.
- Membuka Emulator Android di runner GitHub.
- Menjalankan seluruh test flow Maestro.
- Mengunggah test artifact jika ada kendala.

---

## Slide 14 — Kesimpulan & Best Practices
1. **Satu File = Satu Flow**: Memisahkan alur fungsional agar mudah di-maintain.
2. **Gunakan `---`**: Pemisah standar Maestro 2.0.
3. **Gunakan Text / ID yang Stabil**: Hindari selector yang berubah-ubah.
4. **Dokumentasikan dengan `info.title` & `info.description`**.
5. **Jalankan via Script Lokal**: `tools/run-maestro-tests.sh` untuk kecepatan iterasi developer.

---

# Terima Kasih! Ada Pertanyaan? (Q&A)

