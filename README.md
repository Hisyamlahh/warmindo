Nama : Hisyam Arsyad Zakiyuddin
NIM  : 230103226

# 🍜 Warmindo JugaJago — Aplikasi POS & Table Management

Aplikasi Point of Sale (POS) dan Table Management modern berbasis **Flutter** dan **Supabase** yang dirancang khusus untuk mendigitalkan seluruh alur operasional warung makan Warmindo (Indomie, aneka minuman, topping, dan snack).

---

## 🎯 1. Tujuan Aplikasi

1. **Digitalisasi Kasir Warmindo**: Menggantikan pencatatan pesanan manual berbasis kertas menjadi sistem kasir digital yang cepat, akurat, dan minim kesalahan hitung.
2. **Efisiensi Perputaran Meja (*Table Turnover*)**: Mempercepat alur pemesanan meja melalui integrasi QR Code dinamis dan monitoring realtime status ketersediaan meja pelanggan.
3. **Fleksibilitas Alur Pembayaran**: Mendukung model bisnis *"Makan Dulu Bayar Belakangan"* (Pending Order) maupun pembayaran langsung di awal (*Paid Order*) baik secara Tunai (Cash) maupun QRIS.
4. **Pencatatan Keuangan & Stok Otomatis**: Memastikan setiap menu yang terjual langsung memotong stok bahan baku dan tercatat otomatis dalam riwayat transaksi harian.

---

## 👥 2. Target Pengguna (Persona)

1. **Kasir (Cashier / Frontliner)**:
   - Bertanggung jawab menerima pesanan pelanggan di kasir atau mengikat pesanan ke meja.
   - Mengoperasikan kalkulator uang tunai, generate QRIS, memproses transaksi lunas maupun pending, dan mencetak nota struk fisik/digital.
   - Memantau ketersediaan meja dan mengosongkan status meja saat tamu selesai makan.
2. **Admin / Pemilik Warung (Owner)**:
   - Memiliki kendali penuh terhadap manajemen menu (menambah menu baru, unggah foto dari galeri HP, update harga, dan ubah stok).
   - Mendaftarkan meja makan baru dan men-generate stiker QR meja untuk dicetak.
   - Memantau seluruh laporan riwayat transaksi dan pembatalan pesanan.
3. **Pelayan / Waiter**:
   - Memindai stiker QR meja pelanggan menggunakan kamera HP untuk langsung memulai pesanan makan di tempat (*Dine-in*).
4. **Pelanggan Warmindo (End-Customer)**:
   - Mendapatkan kepastian pesanan melalui struk pembayaran berformat thermal/digital (bisa dibagikan ke WhatsApp) dan kenyamanan meja yang teratur.

---

## 🌟 3. Fitur Utama

### A. Autentikasi & Multi-Role (Admin vs Kasir)
- Login aman menggunakan **Supabase Auth** (Email & Password).
- Role-based Access Control (RBAC):
  - **Admin**: Akses penuh ke Katalog Menu (CRUD + Galeri Foto), Scan QR Meja, Generator QR Meja Baru, dan Riwayat Transaksi.
  - **Kasir**: Akses operasional harian (Katalog Menu, Scan QR Meja, Manajemen Meja, Pembayaran, dan Riwayat Penjualan). Tombol penambahan meja baru diproteksi khusus Admin.
- Auto-login & proteksi sesi lokal yang aman.

### B. POS, Katalog Menu & CRUD Foto Galeri
- Filter menu berdasarkan kategori (*Semua*, *Indomie Kuah*, *Indomie Goreng*, *Minuman*, *Topping*, *Snack*).
- Pencarian menu instan secara *real-time*.
- **Admin CRUD Menu**: Tambah menu baru dengan upload foto langsung dari galeri HP ke Supabase Storage, edit harga, ubah stok, dan hapus menu.
- Indikator stok barang otomatis (*Tersedia*, *Sisa X*, *Habis*).
- Keranjang belanja (*Cart*) interaktif dengan fitur catatan khusus per item (misal: "Pedas mampus", "Tanpa sawi").

### C. Manajemen Meja & Integrasi QR Code
- **Scan QR Meja**: Menggunakan kamera perangkat dengan overlay viewfinder. Otomatis mengenali meja terdaftar, mengubah status meja menjadi `occupied` (TERISI), dan langsung membuka katalog menu.
- **Input Manual Nomor Meja**: Alternatif jika stiker QR meja rusak atau pencahayaan redup.
- **Validasi Meja Fiktif**: Sistem otomatis menolak QR atau nomor meja yang tidak terdaftar di database dengan peringatan merah.
- **Monitoring Meja Realtime**: Kartu ringkasan meja (*Total*, *Tersedia*, *Terisi*) serta tombol cepat ubah status (*Tandai Terisi* / *Kosongkan Meja*).
- **Generator QR Meja (Admin)**: Membuat QR meja baru dan mengunduh gambar stiker QR ke galeri perangkat untuk dicetak.

### D. Checkout & Fleksibilitas Metode Pembayaran
- **Pembayaran Tunai (Cash)**: Dilengkapi tombol nominal cepat (*Uang Pas*, *Rp 20.000*, *Rp 50.000*, *Rp 100.000*) serta validasi otomatis jika uang tunai yang diinput kurang.
- **Pembayaran QRIS**: Generate kode QR pembayaran dinamis sesuai total belanjaan.
- **Simpan & Bayar Nanti (Pending Order)**: Alur khusus agar pelanggan bisa makan terlebih dahulu; pesanan tercatat pending, stok bahan langsung terpotong, dan meja tetap berstatus terisi.

### E. Cetak Nota & Riwayat Transaksi
- Tampilan struk digital bergaya kasir thermal (*monospaced layout*).
- **Unduh & Cetak Nota (PNG)**: Mengonversi struk menjadi file gambar PNG berkualitas tinggi untuk dicetak ke thermal printer Bluetooth (ESC/POS) atau dibagikan ke WhatsApp pelanggan.
- **Riwayat Transaksi Komprehensif**: Filter rentang tanggal dan filter status (*Semua*, *Lunas*, *Pending*, *Batal*).
- **Pelunasan & Pembatalan Pending**: Pelunasan instan pesanan pending di kasir atau pembatalan pesanan dengan **restorasi stok otomatis**.

---

## 🔄 4. Alur Pengguna (User Flow)

```
[ Pelanggan Datang ]
         │
         ├───► [ Meja Kosong / Scan QR Meja ] ───► Status Meja: TERISI
         │                                               │
         ▼                                               ▼
[ Layar Login POS ] ───► [ Kasir / Admin Masuk ke Dashboard ]
                                 │
                                 ├───► [ Pilih Menu di Katalog ]
                                 │            │
                                 │            ▼
                                 ├───► [ Buka Keranjang Belanja ]
                                 │            │
                                 │            ▼
                                 └───► [ Halaman Pembayaran / Checkout ]
                                              │
                    ┌─────────────────────────┴────────────────────────┐
                    ▼                                                  ▼
         [ Bayar Langsung Lunas ]                         [ Simpan & Bayar Nanti ]
     (Pilih Tunai / QRIS -> Lunas)                           (Status: PENDING)
                    │                                                  │
                    ▼                                                  ▼
         [ Tampil Layar Struk ]                            [ Pelanggan Makan Dulu ]
                    │                                                  │
                    ▼                                                  ▼
         [ Unduh Nota PNG / Cetak ]                         [ Pelanggan Bayar di Kasir ]
                    │                                                  │
                    ▼                                                  ▼
         [ Transaksi Selesai & Riwayat ] ◄─────────────── [ Buka Riwayat -> Bayar Sekarang ]
                    │
                    ▼
         [ Pelanggan Pulang ] ───► Kasir Tekan: "Kosongkan Meja" ───► Status Meja: TERSEDIA
```

---

## ⚠️ 5. Batasan Pengujian (Testing Limitations)

Dalam pelaksanaan pengujian aplikasi dan otomatisasi UI (Maestro E2E / UAT), terdapat beberapa batasan teknis lingkungan uji:

1. **Simulasi Hardware Bluetooth Printer**: Pengujian cetak nota fisik dialihkan ke validasi render gambar PNG resolusi tinggi dan verifikasi *system share sheet* Android karena tidak tersedianya hardware fisik printer thermal mini di lingkungan CI/CD.
2. **Kamera Fisik pada Emulator**: Pengujian alur QR scanner pada emulator Android memanfaatkan fitur *input manual nomor meja* dan simulasi injeksi payload stiker QR mock.
3. **Gateway Pembayaran QRIS Dinamis**: Fitur QRIS pada aplikasi meng-generate string pembayaran dinamis sesuai standar QRIS/NMID merchant internal; verifikasi pembayaran sukses disimulasikan melalui konfirmasi kasir tanpa memotong saldo e-wallet perbankan riil.
4. **Restriksi Keamanan Vendor OS (Android 16 / MIUI)**:
   - Pada Android 16 (TECNO/Transsion), pengujian otomatis Maestro CLI dibatasi oleh aturan SELinux port internal gRPC (`somaxconn`).
   - Pada Xiaomi MIUI, pengujian otomatis memerlukan pengaktifan opsi *"Mulai di latar belakang"* dan *"Instal via USB (Setelan keamanan)"* agar driver pengujian tidak di-kill oleh sistem keamanan vendor.
5. **Ketergantungan Jaringan Supabase**: Seluruh data menu, otentikasi, dan riwayat pesanan bergantung pada koneksi internet aktif menuju server Supabase cloud; pengujian offline mode hanya mencakup cache sesi lokal.

---

## 🧪 6. Pengujian Otomatis (Maestro E2E Testing)

Aplikasi dilengkapi suite pengujian otomatis UI *End-to-End* berbasis **Maestro 2.x** dengan minimal 4 skenario alur utama, validasi input, dan penanganan kondisi gagal:

- **`maestro/flows/landing.yaml`**: Menguji cold start, verifikasi layar login, dan validasi input error (email kosong & format email salah).
- **`maestro/flows/login.yaml`**: Menguji alur sukses login kasir dan verifikasi assertion seluruh tombol navigasi tab (Katalog, Scan QR, Meja, Riwayat).
- **`maestro/flows/order_checkout.yaml`**: Menguji alur E2E lengkap: login, memilih menu, buka keranjang, checkout tunai uang pas, validasi struk, hingga pengecekan ke tab riwayat.
- **`maestro/flows/scrolling.yaml`**: Menguji kestabilan gestur swipe scrolling naik-turun pada daftar katalog produk dan daftar meja.
- **`maestro/flows/riwayat.yaml`**: Menguji filter status transaksi (Lunas, Pending, Batal, Semua), inspeksi nota struk transaksi, dialog pelunasan pesanan pending, dan dialog konfirmasi pembatalan pesanan.

### Menjalankan Pengujian Maestro:
```powershell
# Jalankan salah satu flow
maestro test maestro/flows/riwayat.yaml

# Jalankan seluruh suite pengujian
maestro test maestro/flows/landing.yaml maestro/flows/login.yaml maestro/flows/order_checkout.yaml maestro/flows/scrolling.yaml maestro/flows/riwayat.yaml
```

---

## 📊 7. Dokumen UAT (User Acceptance Testing)

Dokumen UAT komprehensif tersedia dalam format spreadsheet Excel:
- 📁 **File Excel**: [`UAT_Warmindo_JugaJago.xlsx`](UAT_Warmindo_JugaJago.xlsx)
- Memuat 15 skenario pengujian lengkap yang mencakup:
  - **Tujuan Pengujian**
  - **Persona / Peran Pengguna**
  - **Kriteria Penerimaan (Acceptance Criteria)**
  - **Prasyarat**
  - **Langkah Pengujian**
  - **Hasil yang Diharapkan Pengguna**
  - **Hasil Aktual**
  - **Status Kelulusan (Lulus / Gagal - PASS)**
  - **Bukti Pengujian (Test Evidence)**

---

## 🛠️ Tech Stack & Library

- **Framework**: Flutter 3.32+ / Dart 3.8+
- **Backend & Database**: Supabase PostgreSQL dengan Row Level Security (RLS)
- **State Management**: Provider (`MultiProvider`, `ChangeNotifier`)
- **Navigation & Routing**: GoRouter dengan route guarding
- **QR Engine**: `qr_flutter` (generator) & `mobile_scanner` (scanner kamera)
- **Testing**: Maestro CLI 2.12.0 & Maestro Studio E2E Testing
- **Utilities**: `intl`, `uuid`, `share_plus`, `path_provider`, `screenshot`, `openpyxl`

---

## 🚀 Panduan Menjalankan Aplikasi

```bash
# 1. Mengambil dependensi
flutter pub get

# 2. Menjalankan aplikasi di emulator / HP
flutter run
```
