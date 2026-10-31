# 🍜 Warmindo POS — Aplikasi Kasir Mobile

Aplikasi Point of Sale (POS) modern berbasis **Flutter** dan **Supabase** yang dirancang khusus untuk operasional warung makan Warmindo (Indomie, minuman, topping, snack).

---

## 🌟 Fitur Utama

### 1. Autentikasi & Multi-Role (Admin vs Kasir)
- Login menggunakan Supabase Auth (Email & Password).
- Role-based Access Control (RBAC):
  - **Admin**: Akses penuh ke Katalog, Scan QR Meja, Generate QR Meja & Pembayaran, dan Riwayat Penjualan.
  - **Kasir**: Akses operasional harian (Katalog, Scan QR Meja, Proses Pembayaran, dan Riwayat Transaksi).
- Auto-login & sesi tersimpan aman.

### 2. Manajemen Meja & Integrasi QR Code
- **Scan QR Meja**: Menggunakan kamera perangkat dengan overlay viewfinder dan toggle senter. Otomatis mengikat sesi pesanan ke nomor meja dan menandai meja sebagai `occupied`.
- **Input Manual Meja**: Opsi alternatif jika QR code di meja rusak atau dalam kondisi redup.
- **Generate QR Code Meja (Admin)**: Cetak QR Meja resolusi tinggi, unduh gambar ke galeri, atau bagikan langsung.

### 3. POS & Katalog Menu
- Filter per kategori (*Indomie Kuah*, *Indomie Goreng*, *Minuman*, *Topping*, *Snack*).
- Pencarian menu instan secara *real-time*.
- Keranjang pesanan (*Cart*) dengan penambahan catatan per menu (misal: "Pedas level 5", "Es sedikit").
- Indikator stok barang otomatis (*Tersedia* / *Habis*).

### 4. Checkout & Fleksibilitas Pembayaran
- **Tunai (Cash)**: Kalkulator kembalian otomatis dengan tombol nominal cepat (*Uang Pas*, *Rp 20.000*, *Rp 50.000*, *Rp 100.000*).
- **QRIS / QR Code**: Generate QR pembayaran dinamis berbasis total tagihan.
- Sinkronisasi otomatis ke Supabase: stok berkurang, status meja kembali `available`, status pembayaran menjadi `paid`.

### 5. Struk & Riwayat Transaksi
- Tampilan struk digital bergaya thermal receipt monospaced.
- Fitur **Bagikan Struk** ke WhatsApp / Media Sosial pelanggan.
- Riwayat transaksi lengkap dengan filter rentang tanggal dan status transaksi (*Lunas*, *Batal*, *Pending*).

---

## 🛠️ Tech Stack & Library

- **Framework**: Flutter 3.32+ / Dart 3.8+
- **Backend & Database**: Supabase PostgreSQL dengan Row Level Security (RLS)
- **State Management**: Provider (`MultiProvider`, `ChangeNotifier`)
- **Navigation & Routing**: GoRouter dengan route guarding
- **QR Engine**: `qr_flutter` (generator) & `mobile_scanner` (scanner kamera)
- **Utilities**: `intl`, `uuid`, `share_plus`, `path_provider`, `flutter_secure_storage`

---

## 🚀 Panduan Instalasi & Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (>= 3.0.0)
- Akun [Supabase](https://supabase.com)

### 2. Konfigurasi Database Supabase
Jalankan skrip SQL migrasi yang tersedia di:
```bash
supabase/migrations/001_initial_schema.sql
```
Skrip ini akan otomatis membuat:
- Tipe enum (`user_role`, `table_status`, `payment_method_enum`, `payment_status_enum`)
- Tabel `profiles`, `categories`, `products`, `tables`, `orders`, `order_items`
- Kebijakan Row Level Security (RLS) lengkap
- Kategori bawaan dan trigger sinkronisasi profil pengguna saat register

### 3. Konfigurasi Kredensial Supabase
Buka file `lib/core/constants/app_constants.dart` dan masukkan kredensial proyek Supabase Anda:
```dart
static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 4. Menjalankan Aplikasi
```bash
# Mengambil dependensi
flutter pub get

# Menjalankan aplikasi
flutter run
```

---

## 📂 Struktur Proyek

```
lib/
├── core/
│   ├── constants/       # AppConstants & Supabase config
│   ├── router/          # GoRouter configuration & route guards
│   ├── services/        # SupabaseService singleton
│   ├── theme/           # AppTheme & color palette
│   ├── utils/           # FormatUtils (Rupiah & Tanggal)
│   └── widgets/         # LoadingButton, EmptyState, StatusBadge
├── features/
│   ├── auth/            # Login screen & AuthProvider
│   ├── cart/            # Cart screen, CartProvider, CartItemModel
│   ├── catalog/         # Catalog screen, CatalogProvider, Product/Table/Order models
│   ├── checkout/        # Checkout screen, CheckoutProvider, ReceiptWidget, ReceiptScreen
│   ├── dashboard/       # Main navigation dashboard (Role-based tabs)
│   ├── history/         # History screen & HistoryProvider
│   ├── qr_generator/    # Table & Payment QR code generator
│   ├── qr_scanner/      # Camera QR code scanner & payload parser
│   └── splash/          # Splash screen & session check
└── main.dart            # MultiProvider & app entry point
```
