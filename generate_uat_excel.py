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

    title_font = Font(name="Segoe UI", size=16, bold=True, color="FFFFFF")
    subtitle_font = Font(name="Segoe UI", size=11, bold=True, color="333333")
    header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
    bold_font = Font(name="Segoe UI", size=10, bold=True, color="222222")
    normal_font = Font(name="Segoe UI", size=10, color="222222")
    status_font = Font(name="Segoe UI", size=10, bold=True, color="008000")

    thin_border_side = Side(border_style="thin", color="CCCCCC")
    thin_border = Border(left=thin_border_side, right=thin_border_side, top=thin_border_side, bottom=thin_border_side)
    thick_bottom = Border(bottom=Side(border_style="medium", color="E51A22"))

    # ==========================================
    # SHEET 1: RINGKASAN & INFORMASI UAT
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
        ("Automation Tool", "Maestro UI Testing (Maestro CLI 2.12.0 & Maestro Studio)"),
        ("Versi Aplikasi", "1.0.0 (Release Candidate)"),
        ("Tanggal Pengujian", "November 2026"),
        ("PIC Pengujian (Tester)", "Admin & Kasir Warmindo"),
        ("Tujuan Pengujian", "Memvalidasi seluruh alur operasional kasir, scan QR meja, pending order, cetak nota, dan otomasi Maestro E2E")
    ]

    ws_info.append([])
    ws_info.append([])

    start_row = 4
    for idx, (label, val) in enumerate(info_rows, start=start_row):
        ws_info.cell(row=idx, column=2, value=label).font = bold_font
        ws_info.cell(row=idx, column=2).fill = sub_fill
        ws_info.cell(row=idx, column=2).border = thin_border
        
        ws_info.merge_cells(start_row=idx, start_column=3, end_row=idx, end_column=6)
        val_cell = ws_info.cell(row=idx, column=3, value=val)
        val_cell.font = normal_font
        val_cell.border = thin_border
        for c in range(3, 7):
            ws_info.cell(row=idx, column=c).border = thin_border

    # Summary Sign-off Table
    sign_row = 14
    ws_info.cell(row=sign_row, column=2, value="Kriteria Kelulusan UAT (Acceptance Criteria)").font = subtitle_font
    criteria = [
        ("Kriteria 1", "Seluruh alur utama (CRUD Menu, Scan QR, Checkout Tunai/QRIS, Meja, Nota) berstatus PASS"),
        ("Kriteria 2", "Meja yang tidak terdaftar berhasil ditolak secara otomatis oleh sistem"),
        ("Kriteria 3", "Meja terisi otomatis saat scan/order, dan pengosongan meja dapat dilakukan manual"),
        ("Kriteria 4", "Nota pesanan dapat diunduh dalam format gambar PNG untuk cetak printer Bluetooth"),
        ("Kriteria 5", "Pengujian otomatis E2E dengan Maestro UI Testing (minimal 4 flow) berhasil tereksekusi dengan validasi assertion")
    ]
    for i, (k, desc) in enumerate(criteria, start=sign_row+1):
        ws_info.cell(row=i, column=2, value=k).font = bold_font
        ws_info.cell(row=i, column=2).border = thin_border
        ws_info.merge_cells(start_row=i, start_column=3, end_row=i, end_column=6)
        ws_info.cell(row=i, column=3, value=desc).font = normal_font
        for c in range(3, 7):
            ws_info.cell(row=i, column=c).border = thin_border

    # Approval Box
    app_row = 21
    ws_info.cell(row=app_row, column=2, value="Persetujuan & Pengesahan (Sign-off)").font = subtitle_font
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

    # ==========================================
    # SHEET 2: HASIL PENGUJIAN UAT (26 TEST CASES)
    # ==========================================
    ws_test = wb.create_sheet(title="Hasil Pengujian UAT")
    ws_test.views.sheetView[0].showGridLines = True

    # Header Row
    headers = [
        "No.", 
        "Kode UAT", 
        "Modul", 
        "Skenario Pengujian", 
        "Langkah Pengujian (Test Steps)", 
        "Data Uji", 
        "Hasil yang Diharapkan (Expected Result)", 
        "Hasil Aktual", 
        "Status (Pass/Fail)", 
        "Catatan"
    ]

    ws_test.append(headers)
    for col_idx in range(1, len(headers) + 1):
        cell = ws_test.cell(row=1, column=col_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin_border
    ws_test.row_dimensions[1].height = 28

    test_cases = [
        # MODUL 1: AUTENTIKASI & HAK AKSES
        (
            1, "UAT-AUTH-001", "Autentikasi", 
            "Login sebagai Admin",
            "1. Buka aplikasi Warmindo JugaJago\n2. Masukkan email & password Admin\n3. Tekan tombol Masuk",
            "Email: admin@warmindo.com\nRole: admin",
            "Pengguna berhasil login, badge menampilkan role ADMIN, tab Menu, Scan QR, Meja (dengan tombol Generate Meja Baru), dan Riwayat dapat diakses",
            "Sesuai harapan", "PASS", "Full CRUD & QR Generator aktif"
        ),
        (
            2, "UAT-AUTH-002", "Autentikasi", 
            "Login sebagai Kasir",
            "1. Logout dari akun Admin\n2. Masukkan email & password Kasir\n3. Tekan tombol Masuk",
            "Email: kasir@warmindo.com\nRole: kasir",
            "Pengguna berhasil login, badge menampilkan KASIR, tidak dapat menambah meja baru, namun tetap dapat memantau & mengubah status meja",
            "Sesuai harapan", "PASS", "Tombol Generate QR Meja diproteksi"
        ),
        (
            3, "UAT-AUTH-003", "Autentikasi", 
            "Validasi Form Login Kosong & Format Email Salah",
            "1. Buka layar login\n2. Tekan 'Masuk ke POS' tanpa input email/password\n3. Masukkan 'kasirbukanemail' lalu tekan tombol masuk",
            "Data kosong & format email tidak valid",
            "Muncul pesan error validasi 'Email tidak boleh kosong' dan 'Format email tidak valid'. Tombol tidak memproses submit.",
            "Sesuai harapan", "PASS", "Tervalidasi di landing.yaml"
        ),

        # MODUL 2: KATALOG & CRUD MENU DENGAN FOTO GALERI
        (
            4, "UAT-MENU-001", "Katalog Menu", 
            "Menambah Menu Baru dengan Foto dari Galeri HP",
            "1. Masuk sebagai Admin ke tab Katalog\n2. Tekan tombol '+ Tambah Menu'\n3. Masukkan nama, harga, stok, kategori\n4. Tekan 'Pilih Gambar dari Galeri'\n5. Pilih file JPG/PNG dari HP\n6. Tekan Simpan",
            "Nama: Mie Dok-Dok Spesial\nHarga: 15.000\nStok: 50\nFoto: dok_dok.jpg",
            "Foto berhasil diunggah ke storage Supabase 'products', menu baru langsung tampil di katalog dengan foto dan stok yang benar",
            "Sesuai harapan", "PASS", "Support JPG, PNG, WebP"
        ),
        (
            5, "UAT-MENU-002", "Katalog Menu", 
            "Edit Menu & Ganti Foto Galeri",
            "1. Pada kartu menu di katalog, tekan ikon titik tiga / Edit\n2. Ubah harga atau stok\n3. Ganti gambar dengan memilih foto baru dari galeri\n4. Tekan Simpan Perubahan",
            "Harga baru: 16.000\nFoto baru: dok_dok_v2.png",
            "Data menu dan gambar berhasil diperbarui secara realtime di database dan tampilan katalog",
            "Sesuai harapan", "PASS", "Realtime update"
        ),
        (
            6, "UAT-MENU-003", "Katalog Menu", 
            "Filter Kategori & Pencarian Menu",
            "1. Ketik kata kunci 'Goreng' di kolom pencarian\n2. Pilih chip filter 'Indomie Kuah'\n3. Pilih 'Semua'",
            "Keyword: 'Goreng', Chip: 'Indomie Kuah'",
            "Daftar menu terfilter secara instan sesuai pencarian atau kategori yang dipilih",
            "Sesuai harapan", "PASS", "Responsif & cepat"
        ),

        # MODUL 3: SCAN QR & VALIDASI NOMOR MEJA
        (
            7, "UAT-SCAN-001", "Scan QR Meja", 
            "Scan QR Stiker Meja yang Terdaftar",
            "1. Pelayan/Kasir buka tab 'Scan QR'\n2. Arahkan kamera ke stiker QR Meja 03 yang terdaftar\n3. Tunggu sistem membaca QR",
            "QR Meja 03 (Format: warmindo_table_03)",
            "Aplikasi langsung menampilkan notifikasi 'Meja 03 terhubung!', status meja di DB otomatis berubah jadi 'occupied', dan layar otomatis beralih ke Katalog Menu",
            "Sesuai harapan", "PASS", "Auto-redirect ke katalog"
        ),
        (
            8, "UAT-SCAN-002", "Scan QR Meja", 
            "Input Manual Nomor Meja yang Terdaftar",
            "1. Di tab Scan QR, tekan 'Input Manual'\n2. Masukkan nomor meja yang valid (misal: '02')\n3. Tekan 'Hubungkan Meja'",
            "Input: '02'",
            "Aplikasi mengenali Meja 02, status Meja 02 di database berubah menjadi 'occupied', dan kasir langsung dialihkan ke Katalog Menu",
            "Sesuai harapan", "PASS", "Alternatif saat kamera bermasalah"
        ),
        (
            9, "UAT-SCAN-003", "Scan QR Meja", 
            "Penolakan Meja yang Tidak Terdaftar (Peringatan Otomatis)",
            "1. Buka tab Scan QR\n2. Arahkan ke QR acak / input nomor meja yang belum dibuat Admin (misal: '99' atau 'XYZ')\n3. Tekan Hubungkan Meja",
            "Input: '99' (belum terdaftar)",
            "Aplikasi MENOLAK dan menampilkan notifikasi merah: 'Meja no 99 tidak terdaftar! Silakan hubungi Admin untuk mendaftarkan meja.' dan tidak menghubungkan sesi",
            "Sesuai harapan", "PASS", "Mencegah transaksi di meja fiktif"
        ),

        # MODUL 4: MANAJEMEN STATUS MEJA (KASIR & ADMIN)
        (
            10, "UAT-TABLE-001", "Manajemen Meja", 
            "Pemantauan Status Meja Realtime oleh Kasir",
            "1. Kasir membuka tab 'Meja'\n2. Perhatikan kartu ringkasan di atas (Total, Tersedia, Terisi)\n3. Filter chip 'Tersedia' dan 'Terisi'",
            "Status filter meja",
            "Kasir dapat melihat secara jelas meja mana yang kosong (hijau) dan meja mana yang terisi pelanggan (merah) untuk mengarahkan tamu",
            "Sesuai harapan", "PASS", "Informasi jelas untuk tamu datang"
        ),
        (
            11, "UAT-TABLE-002", "Manajemen Meja", 
            "Status Meja Otomatis Terisi Saat Order / Scan",
            "1. Lakukan scan meja atau input meja pada pesanan\n2. Buat pesanan (Lunas maupun Bayar Nanti)\n3. Buka tab Meja",
            "Meja yang dipesan",
            "Status meja otomatis berubah menjadi 'TERISI' (occupied) tanpa perlu ditekan manual",
            "Sesuai harapan", "PASS", "Otomatisasi berjalan baik"
        ),
        (
            12, "UAT-TABLE-003", "Manajemen Meja", 
            "Pengosongan Meja Manual Saat Pelanggan Pulang",
            "1. Pelanggan selesai makan dan meninggalkan meja\n2. Kasir/pelayan membuka tab 'Meja'\n3. Pada kartu meja yang terisi, tekan tombol hijau 'Kosongkan Meja (Pelanggan Pulang)'",
            "Meja berstatus TERISI",
            "Status meja berubah menjadi 'TERSEDIA' (available), warna kartu menjadi hijau, dan counter meja tersedia bertambah",
            "Sesuai harapan", "PASS", "Manual release sesuai permintaan"
        ),
        (
            13, "UAT-TABLE-004", "Manajemen Meja", 
            "Tandai Terisi Secara Manual",
            "1. Pelanggan datang langsung duduk tanpa scan\n2. Kasir membuka tab 'Meja'\n3. Tekan tombol merah 'Tandai Terisi (Pelanggan Duduk)' pada meja yang bersangkutan",
            "Meja berstatus TERSEDIA",
            "Status meja seketika menjadi 'TERISI' (occupied)",
            "Sesuai harapan", "PASS", "Fleksibel untuk operasional lapangan"
        ),
        (
            14, "UAT-TABLE-005", "Manajemen Meja", 
            "Generate & Unduh QR Meja Baru (Khusus Admin)",
            "1. Login Admin -> Buka tab Meja\n2. Tekan 'Generate QR Meja Baru (Admin)'\n3. Masukkan 'Meja 10'\n4. Buka pratinjau QR -> Tekan 'Unduh / Cetak'",
            "Nomor meja: '10'",
            "Meja 10 terdaftar di database, gambar stiker QR tersimpan di galeri perangkat dan siap dicetak stiker meja",
            "Sesuai harapan", "PASS", "Stiker QR meja siap cetak"
        ),

        # MODUL 5: CHECKOUT & METODE PEMBAYARAN
        (
            15, "UAT-CHECK-001", "Checkout", 
            "Pembayaran Tunai (Cash) Lunas di Awal",
            "1. Pilih beberapa menu di Katalog\n2. Buka Keranjang -> Tekan 'Lanjut ke Pembayaran'\n3. Pilih metode 'Tunai'\n4. Masukkan nominal uang yang diterima (atau klik tombol cepat uang pas / +10k / +50k)\n5. Tekan 'Konfirmasi Pembayaran (Lunas)'",
            "Tagihan: Rp 28.000\nUang Diterima: Rp 50.000",
            "Sistem menghitung kembalian Rp 22.000, stok produk berkurang, pesanan tersimpan berstatus 'paid', meja tetap terisi, dan nota langsung tampil",
            "Sesuai harapan", "PASS", "Validasi nominal uang pas/lebih"
        ),
        (
            16, "UAT-CHECK-002", "Checkout", 
            "Pembayaran dengan QRIS Dinamis",
            "1. Buka halaman pembayaran\n2. Pilih metode 'QRIS'\n3. QR dinamis langsung ter-generate di layar\n4. Pelanggan scan QRIS dan bayar\n5. Kasir tekan 'Selesai & Cetak Struk (QRIS)'",
            "Metode: QRIS, Tagihan: Rp 35.000",
            "Transaksi tersimpan dengan status 'paid', metode 'qris', stok berkurang, dan struk pembayaran QRIS langsung tampil",
            "Sesuai harapan", "PASS", "QRIS otomatis sesuai tagihan"
        ),
        (
            17, "UAT-CHECK-003", "Checkout", 
            "Simpan & Bayar Nanti (Pending / Pelanggan Makan Dulu)",
            "1. Catat pesanan meja\n2. Masuk halaman checkout\n3. Tekan tombol oranye 'Simpan & Bayar Nanti (Pending)'\n4. Tanpa perlu input uang tunai",
            "Pesanan Meja 03, Bayar Nanti",
            "Pesanan tersimpan dengan status 'pending', stok bahan mi langsung berkurang, meja tetap 'occupied', keranjang bersih, struk pending muncul",
            "Sesuai harapan", "PASS", "Alur makan dulu bayar belakangan"
        ),
        (
            18, "UAT-CHECK-004", "Checkout", 
            "Batalkan Transaksi Saat Pemesanan",
            "1. Masuk halaman checkout\n2. Tekan tombol 'Batalkan Transaksi Ini'\n3. Konfirmasi pembatalan",
            "Keranjang aktif",
            "Keranjang belanja dikosongkan dan kasir dikembalikan ke halaman menu",
            "Sesuai harapan", "PASS", "Reset keranjang aman"
        ),

        # MODUL 6: RIWAYAT & PENYELESAIAN PESANAN PENDING
        (
            19, "UAT-HIST-001", "Riwayat Transaksi", 
            "Filter Riwayat (Semua, Lunas, Pending, Batal)",
            "1. Buka tab 'Riwayat'\n2. Tekan chip 'Pending'\n3. Tekan chip 'Lunas'\n4. Tekan chip 'Batal'",
            "Status filter: All, Paid, Pending, Cancelled",
            "Daftar transaksi terfilter dengan akurat sesuai status yang dipilih beserta badge warna masing-masing",
            "Sesuai harapan", "PASS", "Filter status berfungsi 100%"
        ),
        (
            20, "UAT-HIST-002", "Riwayat Transaksi", 
            "Selesaikan Pembayaran Pesanan Pending (Bayar di Kasir)",
            "1. Buka tab Riwayat -> Filter 'Pending'\n2. Pada kartu pesanan pending, tekan tombol hijau 'Bayar Sekarang'\n3. Masukkan uang tunai atau pilih QRIS\n4. Tekan 'Konfirmasi Lunas'",
            "Pesanan pending sebelumnya",
            "Status pesanan langsung berubah dari 'pending' menjadi 'paid', riwayat ter-update otomatis",
            "Sesuai harapan", "PASS", "Pelunasan transaksi sukses"
        ),
        (
            21, "UAT-HIST-003", "Riwayat Transaksi", 
            "Batalkan Pesanan Pending & Restorasi Stok Produk",
            "1. Pada pesanan pending di Riwayat, tekan tombol merah 'Batal'\n2. Konfirmasi pembatalan pada dialog peringatan",
            "Pesanan pending",
            "Status pesanan menjadi 'cancelled', stok produk otomatis dikembalikan (bertambah lagi sejumlah yang dipesan), meja diset tersedia",
            "Sesuai harapan", "PASS", "Stok otomatis dipulihkan"
        ),

        # MODUL 7: UNDUH & CETAK NOTA STRUK PEMBAYARAN
        (
            22, "UAT-PRINT-001", "Cetak & Unduh Nota", 
            "Unduh Nota Struk Menjadi Gambar PNG",
            "1. Selesaikan transaksi atau buka detail transaksi di Riwayat\n2. Pada tampilan struk, tekan tombol hijau 'Unduh & Cetak Nota (PNG)'",
            "Struk transaksi",
            "Struk dikonversi menjadi gambar PNG beresolusi tinggi, file tersimpan di perangkat, dan dialog share/cetak otomatis terbuka",
            "Sesuai harapan", "PASS", "File nota_warmindo_[id].png dibuat"
        ),
        (
            23, "UAT-PRINT-002", "Cetak & Unduh Nota", 
            "Cetak ke Thermal Printer Bluetooth / Kirim WhatsApp",
            "1. Setelah nota diunduh dan dialog share sistem terbuka\n2. Pilih aplikasi Bluetooth Printer (RawBT / ESC-POS) atau pilih WhatsApp untuk kirim nota ke pelanggan",
            "File PNG nota yang diunduh",
            "Aplikasi printer thermal menerima gambar nota untuk dicetak langsung ke kertas kasir, atau gambar nota terkirim rapi ke chat WA",
            "Sesuai harapan", "PASS", "Kompatibel printer thermal & WA"
        ),

        # MODUL 8: AUTOMATION UI TESTING DENGAN MAESTRO
        (
            24, "UAT-MAESTRO-001", "Automation E2E", 
            "Uji Otomatis Flow Landing & Validasi Form Error (landing.yaml)",
            "1. Jalankan `maestro test maestro/flows/landing.yaml`\n2. Amati eksekusi cold start dan assertion validasi error",
            "Flow landing.yaml",
            "Maestro berhasil memvalidasi elemen form login kasir dan pesan error 'Email tidak boleh kosong' serta 'Format email tidak valid'",
            "Sesuai harapan", "PASS", "Status Completed 100%"
        ),
        (
            25, "UAT-MAESTRO-002", "Automation E2E", 
            "Uji Otomatis Login & Navigasi Antar Tab (login.yaml)",
            "1. Jalankan `maestro test maestro/flows/login.yaml`\n2. Amati login otomatis dan perpindahan tab Katalog, Meja, dan Riwayat",
            "Flow login.yaml",
            "Login berhasil masuk ke POS, seluruh tab (Katalog, Scan QR, Meja, Riwayat) diverifikasi aktif dengan assertion elemen di setiap tab",
            "Sesuai harapan", "PASS", "Status Completed 100%"
        ),
        (
            26, "UAT-MAESTRO-003", "Automation E2E", 
            "Uji Otomatis Pemesanan, Bayar Tunai, Struk & Riwayat (order_checkout.yaml)",
            "1. Jalankan `maestro test maestro/flows/order_checkout.yaml`\n2. Amati pemilihan menu, checkout uang pas, cetak struk, dan pengecekan di riwayat",
            "Flow order_checkout.yaml",
            "Alur pemesanan hingga pembayaran lunas selesai otomatis, struk pembayaran tampil, dan riwayat transaksi terkonfirmasi",
            "Sesuai harapan", "PASS", "Alur E2E lengkap teruji"
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

        # Highlight Status column
        status_cell = ws_test.cell(row=row_idx, column=9)
        status_cell.font = status_font
        status_cell.fill = pass_fill
        status_cell.alignment = Alignment(horizontal="center", vertical="top")

        # Alignment for No & Kode
        ws_test.cell(row=row_idx, column=1).alignment = Alignment(horizontal="center", vertical="top")
        ws_test.cell(row=row_idx, column=2).alignment = Alignment(horizontal="center", vertical="top")

    # Column Widths
    col_widths = {
        "A": 6,   # No.
        "B": 18,  # Kode UAT
        "C": 18,  # Modul
        "D": 26,  # Skenario
        "E": 34,  # Langkah
        "F": 24,  # Data Uji
        "G": 34,  # Hasil Harapan
        "H": 18,  # Hasil Aktual
        "I": 14,  # Status
        "J": 26   # Catatan
    }
    for col_letter, width in col_widths.items():
        ws_test.column_dimensions[col_letter].width = width

    # Info sheet widths
    ws_info.column_dimensions["A"].width = 5
    ws_info.column_dimensions["B"].width = 28
    ws_info.column_dimensions["C"].width = 25
    ws_info.column_dimensions["D"].width = 25
    ws_info.column_dimensions["E"].width = 25
    ws_info.column_dimensions["F"].width = 25

    # Save workbook
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    wb.save(file_path)
    print(f"UAT Excel generated successfully at: {file_path}")

if __name__ == "__main__":
    generate_uat_excel("d:/warmindo/UAT_Warmindo_JugaJago.xlsx")
