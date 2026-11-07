import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def generate_uat_excel(file_path):
    wb = openpyxl.Workbook()

    # Define color scheme (Warmindo JugaJago palette)
    header_fill = PatternFill(start_color="E51A22", end_color="E51A22", fill_type="solid") # Warmindo Red
    sub_fill = PatternFill(start_color="FFF2B2", end_color="FFF2B2", fill_type="solid") # Soft Yellow
    section_fill = PatternFill(start_color="FDE8E8", end_color="FDE8E8", fill_type="solid")
    pass_fill = PatternFill(start_color="E6F4EA", end_color="E6F4EA", fill_type="solid") # Soft Green

    title_font = Font(name="Segoe UI", size=15, bold=True, color="FFFFFF")
    subtitle_font = Font(name="Segoe UI", size=11, bold=True, color="333333")
    header_font = Font(name="Segoe UI", size=10, bold=True, color="FFFFFF")
    bold_font = Font(name="Segoe UI", size=9, bold=True, color="222222")
    normal_font = Font(name="Segoe UI", size=9, color="222222")
    status_font = Font(name="Segoe UI", size=9, bold=True, color="008000")

    thin_border_side = Side(border_style="thin", color="CCCCCC")
    thin_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)

    # ==========================================
    # SHEET 1: INFORMASI UAT & METADATA
    # ==========================================
    ws_info = wb.active
    ws_info.title = "Informasi UAT"
    ws_info.views.sheetView[0].showGridLines = True

    # Title Banner
    ws_info.merge_cells("A1:G2")
    cell_a1 = ws_info["A1"]
    cell_a1.value = "DOKUMEN USER ACCEPTANCE TESTING (UAT) - WARMINDO JUGAJAGO"
    cell_a1.font = title_font
    cell_a1.fill = header_fill
    cell_a1.alignment = Alignment(horizontal="center", vertical="center")

    info_rows = [
        ("Nama Aplikasi", "Warmindo JugaJago POS & Table Management System"),
        ("Platform", "Flutter Mobile (Android APK / Tablet Kasir)"),
        ("Backend & Database", "Supabase (PostgreSQL, Storage Bucket, Auth RLS)"),
        ("Tujuan Pengujian", "Memvalidasi seluruh fungsionalitas operasional kasir, scan QR meja, pending order, validasi input, kondisi gagal, dan cetak nota agar memenuhi kebutuhan pengguna nyata."),
        ("Persona / Peran Pengguna", "1. Kasir: Melayani transaksi, memilih menu, mencatat meja, memproses pembayaran (Tunai/QRIS), mencetak nota struk, dan update status meja.\n2. Admin: Mengelola katalog menu (CRUD + foto galeri), memantau seluruh riwayat, dan mendaftarkan meja baru (QR Generator).\n3. Pelanggan: Melakukan scan QR meja atau makan di tempat (dine-in / takeaway)."),
        ("Kriteria Penerimaan (Acceptance Criteria)", "1. Seluruh alur utama (Login, Katalog, Scan Meja, Checkout Tunai/QRIS, Riwayat, Cetak Nota) berjalan tanpa kendala dan berstatus LULUS (PASS).\n2. Seluruh validasi input (form login, input manual nomor meja, stok, pembayaran kurang) menampilkan feedback error yang jelas.\n3. Kondisi gagal (meja fiktif/tidak terdaftar, pembatalan pesanan, stok produk dikembalikan) tertangani secara aman tanpa crash.\n4. Bukti pengujian terverifikasi melalui UI screenshot, log Supabase realtime, dan Maestro E2E test report."),
        ("Prasyarat Pengujian Umum", "1. Perangkat Android telah terinstal APK Warmindo JugaJago v1.0.0.\n2. Koneksi internet aktif ke server database Supabase.\n3. Akun Admin (admin@warmindo.com) dan Akun Kasir (sudahmalam@gmail.com) siap digunakan."),
        ("Versi Dokumen", "1.1.0 - Sesuai Ketentuan Khusus Standar UAT")
    ]

    ws_info.append([])
    ws_info.append([])

    start_row = 4
    for idx, (label, val) in enumerate(info_rows, start=start_row):
        ws_info.cell(row=idx, column=2, value=label).font = bold_font
        ws_info.cell(row=idx, column=2).fill = sub_fill
        ws_info.cell(row=idx, column=2).border = thin_border
        ws_info.cell(row=idx, column=2).alignment = Alignment(vertical="top", wrap_text=True)
        
        ws_info.merge_cells(start_row=idx, start_column=3, end_row=idx, end_column=7)
        val_cell = ws_info.cell(row=idx, column=3, value=val)
        val_cell.font = normal_font
        val_cell.border = thin_border
        val_cell.alignment = Alignment(vertical="top", wrap_text=True)
        for c in range(3, 8):
            ws_info.cell(row=idx, column=c).border = thin_border

    # Approval Box
    app_row = 15
    ws_info.cell(row=app_row, column=2, value="Persetujuan & Pengesahan UAT (Sign-off)").font = subtitle_font
    approvals = [
        ("Peran", "Nama Penguji / Pemeriksa", "Jabatan", "Status"),
        ("Lead Developer", "Hisyam", "Mobile Engineer", "DISETUJUI (APPROVED)"),
        ("Tester / Kasir", "Admin Warmindo", "Kasir Utama", "DISETUJUI (APPROVED)"),
        ("Dosen Penguji / Reviewer", "-", "Dosen Pengampu", "MENUNGGU EVALUASI")
    ]
    for j, row_data in enumerate(approvals, start=app_row+1):
        for c_idx, val in enumerate(row_data, start=2):
            cell = ws_info.cell(row=j, column=c_idx, value=val)
            cell.border = thin_border
            if j == app_row + 1:
                cell.font = bold_font
                cell.fill = sub_fill
            else:
                cell.font = normal_font
                if c_idx == 5 and "DISETUJUI" in val:
                    cell.font = status_font
                    cell.fill = pass_fill

    ws_info.column_dimensions["A"].width = 4
    ws_info.column_dimensions["B"].width = 28
    ws_info.column_dimensions["C"].width = 20
    ws_info.column_dimensions["D"].width = 20
    ws_info.column_dimensions["E"].width = 24
    ws_info.column_dimensions["F"].width = 24
    ws_info.column_dimensions["G"].width = 24

    # ==========================================
    # SHEET 2: SKENARIO & HASIL PENGUJIAN UAT (LENGKAP SEMUA KOLOM)
    # ==========================================
    ws_test = wb.create_sheet(title="Skenario Pengujian UAT")
    ws_test.views.sheetView[0].showGridLines = True

    # Kolom Wajib Sesuai Ketentuan Dosen:
    # 1. No
    # 2. Kode UAT
    # 3. Tujuan Pengujian
    # 4. Persona / Peran Pengguna
    # 5. Kriteria Penerimaan
    # 6. Prasyarat
    # 7. Langkah Pengujian
    # 8. Hasil yang Diharapkan (Expected Result)
    # 9. Hasil Aktual
    # 10. Status (Lulus/Gagal)
    # 11. Bukti Pengujian (Test Evidence)
    headers = [
        "No.", 
        "Kode UAT", 
        "Tujuan Pengujian",
        "Persona / Peran",
        "Kriteria Penerimaan",
        "Prasyarat", 
        "Langkah Pengujian (Test Steps)", 
        "Hasil yang Diharapkan (Expected Result)", 
        "Hasil Aktual", 
        "Status (Lulus/Gagal)", 
        "Bukti Pengujian (Evidence)"
    ]

    ws_test.append(headers)
    for col_idx in range(1, len(headers) + 1):
        cell = ws_test.cell(row=1, column=col_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin_border
    ws_test.row_dimensions[1].height = 32

    # Skenario Pengujian Komprehensif (Alur Utama, Validasi Input, Kondisi Gagal, Hasil Harapan)
    test_cases = [
        # 1. ALUR UTAMA: AUTENTIKASI LOGIN
        (
            1, "UAT-AUTH-001", 
            "Memvalidasi kasir dapat masuk ke sistem POS dengan kredensial yang sah",
            "Kasir",
            "Sistem memverifikasi kredensial dan mengarahkan pengguna ke Dashboard POS",
            "Aplikasi terbuka pada layar login kasir, akun kasir sudah terdaftar di Supabase Auth",
            "1. Masukkan email 'sudahmalam@gmail.com'\n2. Masukkan password 'sudahmalam'\n3. Tekan tombol 'Masuk ke POS'",
            "Pengguna berhasil login, layar berpindah ke Dashboard, menampilkan katalog menu dan tab navigasi (Katalog, Scan QR, Meja, Riwayat)",
            "Sesuai harapan, login sukses dan masuk ke Dashboard POS",
            "LULUS (PASS)",
            "Screenshot Dashboard POS & Log Maestro step 'login.yaml'"
        ),

        # 2. VALIDASI INPUT: FORM LOGIN KOSONG & SALAH FORMAT
        (
            2, "UAT-AUTH-002", 
            "Memvalidasi sistem menolak input login kosong dan format email salah",
            "Kasir / User",
            "Muncul pesan error validasi di bawah field dan login tidak diproses",
            "Aplikasi terbuka pada layar login dalam kondisi input kosong",
            "1. Langsung tekan tombol 'Masuk ke POS' tanpa isi form\n2. Amati pesan validasi\n3. Masukkan email salah format 'kasirbukanemail'\n4. Tekan tombol 'Masuk ke POS'",
            "Sistem menampilkan pesan error: 'Email tidak boleh kosong', 'Password tidak boleh kosong', dan 'Format email tidak valid'",
            "Sesuai harapan, validasi form muncul secara instan",
            "LULUS (PASS)",
            "Screenshot pesan error form & Log Maestro step 'landing.yaml'"
        ),

        # 3. KONDISI GAGAL: LOGIN KREDENSIAL TIDAK SESUAI
        (
            3, "UAT-AUTH-003", 
            "Memvalidasi sistem menolak upaya login dengan password yang salah",
            "Kasir / User",
            "Muncul SnackBar peringatan 'Email atau password salah' dan tetap di layar login",
            "Aplikasi terbuka pada layar login",
            "1. Masukkan email 'sudahmalam@gmail.com'\n2. Masukkan password salah 'passwordsalah123'\n3. Tekan tombol 'Masuk ke POS'",
            "Sistem menolak otentikasi, memunculkan notifikasi peringatan kesalahan kredensial, dan tidak memberikan akses masuk",
            "Sesuai harapan, sistem menolak kredensial yang salah",
            "LULUS (PASS)",
            "Screenshot SnackBar peringatan & Log Auth Supabase 400"
        ),

        # 4. ALUR UTAMA: CRUD MENU DENGAN FOTO DARI GALERI HP
        (
            4, "UAT-MENU-001", 
            "Memvalidasi Admin dapat menambahkan menu baru lengkap dengan foto dari galeri HP",
            "Admin",
            "Foto terunggah ke Supabase Storage dan menu baru langsung tampil di katalog",
            "Login sebagai Admin, foto menu siap di galeri perangkat",
            "1. Masuk tab Katalog -> Tekan '+ Tambah Menu'\n2. Masukkan nama 'Mie Dok-Dok', harga '15.000', stok '50'\n3. Tekan 'Pilih Foto dari Galeri HP' lalu pilih file\n4. Tekan 'Simpan Menu'",
            "Foto berhasil diunggah ke storage bucket 'products', menu baru tersimpan di database dan langsung muncul di daftar menu katalog",
            "Sesuai harapan, menu dan foto terunggah sempurna",
            "LULUS (PASS)",
            "Screenshot kartu menu di Katalog & URL Supabase Storage"
        ),

        # 5. VALIDASI INPUT: FORM TAMBAH MENU TANPA HARGA / STOK TIDAK VALID
        (
            5, "UAT-MENU-002", 
            "Memvalidasi sistem mencegah penambahan menu tanpa nama atau nominal minus/huruf",
            "Admin",
            "Muncul pesan 'Nama menu wajib diisi' / 'Angka tidak valid' dan submit dicegah",
            "Dialog Tambah Menu Baru terbuka",
            "1. Kosongkan field Nama Menu\n2. Masukkan teks huruf pada field Harga\n3. Tekan tombol 'Simpan Menu'",
            "Sistem menandai field dengan warna merah dan pesan validasi: 'Nama menu wajib diisi' dan 'Angka tidak valid'",
            "Sesuai harapan, data invalid tidak dapat disimpan",
            "LULUS (PASS)",
            "Screenshot validasi dialog tambah menu"
        ),

        # 6. ALUR UTAMA: SCAN QR STIKER MEJA
        (
            6, "UAT-SCAN-001", 
            "Memvalidasi pelayan dapat menghubungkan sesi meja pelanggan via kamera QR",
            "Pelayan / Kasir",
            "Sistem mendeteksi QR, status meja di database otomatis berubah 'TERISI', dan redirect ke katalog",
            "Kamera aktif, stiker QR Meja 03 terpasang di meja pelanggan",
            "1. Buka tab 'Scan QR'\n2. Arahkan kamera ke QR Code Meja 03\n3. Tunggu hingga pemindaian selesai",
            "Muncul notifikasi 'Meja 03 berhasil terhubung!', status meja di sistem menjadi 'occupied', banner meja aktif tampil, dan otomatis beralih ke Katalog Menu",
            "Sesuai harapan, scan instan dan otomatis membuka katalog",
            "LULUS (PASS)",
            "Screenshot banner Meja 03 di Katalog & Log Scan"
        ),

        # 7. KONDISI GAGAL: SCAN / INPUT MEJA TIDAK TERDAFTAR (MEJA FIKTIF)
        (
            7, "UAT-SCAN-002", 
            "Memvalidasi sistem menolak nomor meja yang belum terdaftar secara otomatis",
            "Pelayan / Kasir",
            "Sistem menolak menghubungkan sesi dan menampilkan pesan error merah",
            "Tab Scan QR terbuka",
            "1. Tekan tombol 'Input Manual Nomor Meja'\n2. Masukkan nomor meja yang tidak ada (misal: '99')\n3. Tekan 'Hubungkan Meja'",
            "Muncul notifikasi merah: 'Meja no 99 tidak terdaftar! Silakan hubungi Admin untuk mendaftarkan meja.' dan sesi pesanan tidak dibuka",
            "Sesuai harapan, penolakan meja fiktif berjalan tegas",
            "LULUS (PASS)",
            "Screenshot SnackBar error penolakan meja fiktif"
        ),

        # 8. ALUR UTAMA: PEMANTAUAN & UPDATE STATUS MEJA REALTIME
        (
            8, "UAT-TABLE-001", 
            "Memvalidasi kasir dapat memantau status meja dan mengosongkan meja pelanggan pulang",
            "Kasir",
            "Status meja berubah dari TERISI menjadi TERSEDIA dan counter statistik ter-update",
            "Terdapat meja yang sedang terisi pelanggan",
            "1. Buka tab 'Meja'\n2. Filter status 'Terisi'\n3. Pada kartu meja terkait, tekan tombol hijau 'Kosongkan Meja (Pelanggan Pulang)'",
            "Status meja seketika berubah menjadi 'TERSEDIA' (hijau), counter 'Tersedia' bertambah, dan meja siap ditempati tamu berikutnya",
            "Sesuai harapan, update status meja realtime di seluruh perangkat",
            "LULUS (PASS)",
            "Screenshot tab Meja dengan status hijau TERSEDIA"
        ),

        # 9. ALUR UTAMA: TRANSAKSI PEMBAYARAN TUNAI LUNAS & CETAK NOTA
        (
            9, "UAT-CHECK-001", 
            "Memvalidasi alur pemesanan lengkap, checkout pembayaran tunai (uang pas), dan nota struk",
            "Kasir",
            "Transaksi tersimpan dengan status 'paid', stok berkurang, dan struk pembayaran tampil",
            "Menu tersedia di katalog, keranjang belanja terisi",
            "1. Pilih menu di Katalog -> Tekan 'Tambah'\n2. Buka keranjang via 'Lihat Pesanan' -> Tekan 'Proses Pembayaran'\n3. Pilih metode 'Tunai (Cash)' -> Tekan chip 'Uang Pas'\n4. Tekan 'Konfirmasi Pembayaran (Lunas)'",
            "Sistem menyimpan transaksi LUNAS di database, mengurangi stok menu, membuka layar Struk Pembayaran dengan rincian lengkap dan tombol Transaksi Baru",
            "Sesuai harapan, alur checkout tunai lunas selesai sempurna",
            "LULUS (PASS)",
            "Screenshot Struk Pembayaran & Log flow 'order_checkout.yaml'"
        ),

        # 10. VALIDASI INPUT & KONDISI GAGAL: PEMBAYARAN TUNAI KURANG
        (
            10, "UAT-CHECK-002", 
            "Memvalidasi tombol konfirmasi pembayaran nonaktif jika nominal uang tunai kurang",
            "Kasir",
            "Muncul peringatan 'Nominal yang dibayar masih kurang' dan tombol konfirmasi disabled",
            "Layar pembayaran terbuka dengan total tagihan Rp 20.000",
            "1. Pilih metode 'Tunai (Cash)'\n2. Masukkan nominal uang yang diterima sebesar Rp 10.000 (kurang dari tagihan)\n3. Amati kondisi tombol konfirmasi",
            "Sistem memunculkan teks merah: 'Nominal yang dibayar masih kurang', tombol 'Konfirmasi Pembayaran (Lunas)' menjadi abu-abu (disabled) dan tidak bisa diklik",
            "Sesuai harapan, kasir tidak bisa memproses pembayaran kurang",
            "LULUS (PASS)",
            "Screenshot field uang tunai kurang & tombol konfirmasi disabled"
        ),

        # 11. ALUR UTAMA: SIMPAN & BAYAR NANTI (PENDING ORDER)
        (
            11, "UAT-CHECK-003", 
            "Memvalidasi alur pesanan pelanggan makan dulu bayar belakangan",
            "Kasir",
            "Pesanan tersimpan dengan status 'pending', meja tetap terisi, dan stok menu langsung berkurang",
            "Pesanan terhubung dengan nomor meja pelanggan",
            "1. Tambahkan menu pesanan ke keranjang\n2. Di layar checkout, tekan tombol oranye 'Simpan & Bayar Nanti (Pending)'",
            "Pesanan tersimpan berstatus 'pending', muncul notifikasi sukses, meja tetap 'TERISI', dan transaksi muncul di tab Riwayat pada filter Pending",
            "Sesuai harapan, order pending tercatat rapi",
            "LULUS (PASS)",
            "Screenshot kartu pesanan Pending di tab Riwayat"
        ),

        # 12. ALUR UTAMA: PELUNASAN PESANAN PENDING DI TAB RIWAYAT
        (
            12, "UAT-HIST-001", 
            "Memvalidasi kasir dapat melunasi pesanan pending saat pelanggan membayar di kasir",
            "Kasir",
            "Status pesanan di database berubah dari pending menjadi 'paid' (lunas)",
            "Terdapat pesanan pending di tab Riwayat",
            "1. Buka tab 'Riwayat' -> Filter chip 'Pending'\n2. Pada pesanan terkait, tekan tombol 'Bayar Sekarang'\n3. Masukkan uang tunai -> Tekan 'Konfirmasi Lunas'",
            "Status pesanan ter-update otomatis menjadi 'Lunas', badge berubah hijau, dan detail transaksi lunas dapat diunduh notanya",
            "Sesuai harapan, pelunasan berhasil dan data realtime ter-update",
            "LULUS (PASS)",
            "Screenshot dialog Bayar Sekarang & status lunas di Riwayat"
        ),

        # 13. KONDISI GAGAL: PEMBATALAN PESANAN PENDING & PEMULIHAN STOK OTOMATIS
        (
            13, "UAT-HIST-002", 
            "Memvalidasi pembatalan pesanan secara aman dengan pengembalian stok produk",
            "Kasir",
            "Pesanan berstatus 'cancelled', stok bahan mi otomatis dikembalikan, dan meja diset tersedia",
            "Terdapat pesanan pending di Riwayat",
            "1. Pada pesanan pending, tekan tombol merah 'Batal'\n2. Konfirmasi pada dialog 'Apakah Anda yakin ingin membatalkan pesanan?'\n3. Tekan 'Ya, Batalkan Pesanan'",
            "Pesanan berstatus 'Dibatalkan', stok produk di database bertambah kembali sejumlah porsi yang batal, dan meja pelanggan otomatis kosong kembali",
            "Sesuai harapan, stok dan meja pulih otomatis tanpa inkonsistensi data",
            "LULUS (PASS)",
            "Screenshot riwayat Batal & kuantitas stok produk di Katalog"
        ),

        # 14. HASIL HARAPAN PENGGUNA: UNDUH & CETAK NOTA STRUK PNG
        (
            14, "UAT-PRINT-001", 
            "Memvalidasi nota dapat dikonversi menjadi file gambar PNG untuk dicetak ke thermal printer",
            "Kasir / Pelanggan",
            "File nota PNG beresolusi tajam tersimpan di perangkat dan siap dicetak via Bluetooth / share WhatsApp",
            "Transaksi selesai dan berada di layar Struk Pembayaran",
            "1. Tekan tombol hijau 'Unduh & Cetak Nota (PNG)'\n2. Tunggu proses render nota\n3. Pilih aplikasi cetak printer thermal / share WA pada bottom sheet sistem",
            "Gambar nota dengan tata letak rapi, logo, rincian pesanan, dan QR pembayaran tersimpan di memori lokal serta siap dikirim ke printer kasir",
            "Sesuai harapan, nota berkualitas tinggi berhasil digenerate",
            "LULUS (PASS)",
            "File gambar nota_warmindo_[id].png & Screenshot popup share"
        ),

        # 15. ALUR UTAMA: PENGUJIAN OTOMATIS E2E DENGAN MAESTRO
        (
            15, "UAT-MAESTRO-001", 
            "Memvalidasi seluruh alur otomatisasi E2E Maestro berjalan stabil dengan assertion elemen penting",
            "Developer / QA",
            "Seluruh flow (landing, login, order_checkout, scrolling) berstatus Completed 100%",
            "Maestro CLI 2.12.0 aktif dan perangkat Android terhubung via ADB",
            "1. Jalankan `maestro test maestro/flows/landing.yaml`\n2. Jalankan `maestro test maestro/flows/login.yaml`\n3. Jalankan `maestro test maestro/flows/order_checkout.yaml`\n4. Jalankan `maestro test maestro/flows/scrolling.yaml`",
            "Semua flow dieksekusi otomatis oleh Maestro driver: launchApp, input teks, hide keyboard, tap tombol, assertion teks/elemen, swipe scrolling, dan seluruh flow bertanda hijau COMPLETED",
            "Sesuai harapan, 4/4 flow Maestro sukses tanpa error",
            "LULUS (PASS)",
            "Terminal output Maestro: [Completed] 4/4 Flows & GitHub Actions CI"
        )
    ]

    for item in test_cases:
        row_idx = ws_test.max_row + 1
        ws_test.append(list(item))
        
        # Style row
        for c in range(1, len(headers) + 1):
            cell = ws_test.cell(row=row_idx, column=c)
            cell.font = normal_font
            cell.border = thin_border
            cell.alignment = Alignment(vertical="top", wrap_text=True)

        # Highlight Status column (Col 10)
        status_cell = ws_test.cell(row=row_idx, column=10)
        status_cell.font = status_font
        status_cell.fill = pass_fill
        status_cell.alignment = Alignment(horizontal="center", vertical="top")

        # Alignment for No & Kode
        ws_test.cell(row=row_idx, column=1).alignment = Alignment(horizontal="center", vertical="top")
        ws_test.cell(row=row_idx, column=2).alignment = Alignment(horizontal="center", vertical="top")

    # Column Widths
    col_widths = {
        "A": 6,   # No.
        "B": 16,  # Kode UAT
        "C": 26,  # Tujuan Pengujian
        "D": 16,  # Persona / Peran
        "E": 28,  # Kriteria Penerimaan
        "F": 24,  # Prasyarat
        "G": 32,  # Langkah Pengujian
        "H": 32,  # Hasil Harapan
        "I": 24,  # Hasil Aktual
        "J": 15,  # Status (Lulus/Gagal)
        "K": 26   # Bukti Pengujian
    }
    for col_letter, width in col_widths.items():
        ws_test.column_dimensions[col_letter].width = width

    # Save workbook
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    wb.save(file_path)
    print(f"UAT Excel updated successfully at: {file_path}")

if __name__ == "__main__":
    generate_uat_excel("d:/warmindo/UAT_Warmindo_JugaJago.xlsx")
