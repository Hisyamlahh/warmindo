"""
Generate UAT Word Report (.docx) for Warmindo JugaJago
"""
import os
from docx import Document
from docx.shared import Pt, RGBColor, Cm, Inches, Twips
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import copy

OUT_PATH = r"d:\warmindo\UAT_Warmindo_JugaJago.docx"

# ─── COLOR CONSTANTS ─────────────────────────────────────────────────────────
RED       = RGBColor(0xC6, 0x28, 0x28)
RED_LIGHT = RGBColor(0xFF, 0xEB, 0xEE)
YELLOW    = RGBColor(0xF9, 0xA8, 0x25)
YELLOW_LT = RGBColor(0xFF, 0xFD, 0xE7)
GREEN     = RGBColor(0x2E, 0x7D, 0x32)
GREEN_LT  = RGBColor(0xE8, 0xF5, 0xE9)
BLUE      = RGBColor(0x15, 0x65, 0xC0)
GREY_DK   = RGBColor(0x42, 0x42, 0x42)
GREY_MD   = RGBColor(0x75, 0x75, 0x75)
GREY_LT   = RGBColor(0xF5, 0xF5, 0xF5)
WHITE     = RGBColor(0xFF, 0xFF, 0xFF)
BLACK     = RGBColor(0x00, 0x00, 0x00)


# ─── HELPERS ─────────────────────────────────────────────────────────────────
def hex_to_rgb_str(rgb_color):
    """Convert RGBColor to hex string for XML (e.g. 'C62828')."""
    return f"{rgb_color[0]:02X}{rgb_color[1]:02X}{rgb_color[2]:02X}"


def set_cell_bg(cell, rgb_color):
    """Set table cell background color."""
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), hex_to_rgb_str(rgb_color))
    tcPr.append(shd)


def set_cell_border(cell, **kwargs):
    """Set borders on a table cell. kwargs: top, bottom, left, right each = dict(sz, color, val)."""
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = OxmlElement("w:tcBorders")
    for side in ["top", "left", "bottom", "right"]:
        if side in kwargs:
            border = OxmlElement(f"w:{side}")
            border.set(qn("w:val"),   kwargs[side].get("val", "single"))
            border.set(qn("w:sz"),    str(kwargs[side].get("sz", 4)))
            border.set(qn("w:space"), "0")
            border.set(qn("w:color"), kwargs[side].get("color", "CCCCCC"))
            tcBorders.append(border)
    tcPr.append(tcBorders)


def all_borders(cell, sz=4, color="CCCCCC"):
    b = {"val": "single", "sz": sz, "color": color}
    set_cell_border(cell, top=b, bottom=b, left=b, right=b)


def cell_para(cell, text, bold=False, italic=False, font_size=9,
              color=None, alignment=WD_ALIGN_PARAGRAPH.LEFT, space_before=0, space_after=0):
    """Clear cell and add a paragraph."""
    cell.paragraphs[0].clear()
    para = cell.paragraphs[0]
    para.alignment = alignment
    para.paragraph_format.space_before = Pt(space_before)
    para.paragraph_format.space_after  = Pt(space_after)
    run = para.add_run(text)
    run.bold   = bold
    run.italic = italic
    run.font.size  = Pt(font_size)
    run.font.color.rgb = color if color else BLACK
    return para


def add_heading(doc, text, level=1, color=RED, size=14, bold=True, page_break_before=False, shaded=False):
    para = doc.add_paragraph()
    if page_break_before:
        para.paragraph_format.page_break_before = True
    para.paragraph_format.space_before = Pt(10)
    para.paragraph_format.space_after  = Pt(6)
    run = para.add_run(text)
    run.bold = bold
    run.font.size  = Pt(size)
    run.font.color.rgb = color
    if shaded:
        # shade paragraph background red
        pPr = para._p.get_or_add_pPr()
        shd = OxmlElement("w:shd")
        shd.set(qn("w:val"), "clear")
        shd.set(qn("w:color"), "auto")
        shd.set(qn("w:fill"), hex_to_rgb_str(RED))
        pPr.append(shd)
        run.font.color.rgb = WHITE
        para.paragraph_format.left_indent  = Cm(0.3)
        para.paragraph_format.right_indent = Cm(0.3)
    return para


def add_body(doc, text, size=9.5, color=None, italic=False, space_after=4, indent=0):
    para = doc.add_paragraph()
    para.paragraph_format.space_before = Pt(1)
    para.paragraph_format.space_after  = Pt(space_after)
    if indent:
        para.paragraph_format.left_indent = Cm(indent)
    run = para.add_run(text)
    run.font.size = Pt(size)
    run.italic    = italic
    run.font.color.rgb = color if color else GREY_DK
    return para


def add_kv_table(doc, data, col_widths=(4.5, 11.5)):
    """Key-value info table."""
    tbl = doc.add_table(rows=len(data), cols=2)
    tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
    tbl.style = "Table Grid"
    for i, (k, v) in enumerate(data):
        # key cell
        kc = tbl.cell(i, 0)
        set_cell_bg(kc, GREY_LT)
        all_borders(kc)
        kc.width = Cm(col_widths[0])
        cell_para(kc, k, bold=True, font_size=9, color=GREY_DK)
        # value cell
        vc = tbl.cell(i, 1)
        all_borders(vc)
        vc.width = Cm(col_widths[1])
        p = vc.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after  = Pt(0)
        # split on newline
        for j, line in enumerate(v.split("\n")):
            if j == 0:
                run = p.add_run(line)
            else:
                run = p.add_run("\n" + line)
            run.font.size = Pt(9)
            run.font.color.rgb = GREY_DK
    return tbl


# ─── UAT SCENARIOS ────────────────────────────────────────────────────────────
def build_scenarios():
    return [
        {
            "no": 1, "code": "UAT-AUTH-001",
            "category": "Alur Utama — Autentikasi Login",
            "purpose": "Memvalidasi kasir dapat masuk ke sistem POS dengan kredensial yang sah.",
            "persona": "Kasir",
            "criteria": "Sistem memverifikasi kredensial via Supabase Auth dan mengarahkan pengguna ke Dashboard POS dengan navigasi tab lengkap.",
            "precondition": "1. Aplikasi terbuka pada layar Login.\n2. Akun kasir (sudahmalam@gmail.com) telah terdaftar di Supabase Auth.\n3. Koneksi internet aktif.",
            "steps": "1. Buka aplikasi Warmindo JugaJago.\n2. Masukkan email: sudahmalam@gmail.com.\n3. Masukkan password: sudahmalam.\n4. Tekan tombol [Masuk ke POS].",
            "expected": "Pengguna masuk ke Dashboard POS. Tampil empat tab navigasi: Katalog, Scan QR, Meja, dan Riwayat. Status login tersimpan secara persisten.",
            "actual": "Sesuai harapan. Login sukses, Dashboard POS tampil lengkap dengan navigasi tab.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 2, "code": "UAT-AUTH-002",
            "category": "Validasi Input — Form Login",
            "purpose": "Memvalidasi sistem menolak input login kosong dan format email yang tidak valid.",
            "persona": "Kasir / User",
            "criteria": "Pesan error validasi muncul secara inline di bawah field yang bersangkutan dan proses login tidak dijalankan.",
            "precondition": "1. Aplikasi terbuka pada layar Login.\n2. Semua field dalam kondisi kosong.",
            "steps": "1. Tanpa mengisi apapun, tekan tombol [Masuk ke POS].\n2. Amati pesan validasi yang muncul.\n3. Ketik email dengan format salah: 'kasirbukanemail'.\n4. Tekan [Masuk ke POS] kembali.",
            "expected": "Langkah 1: Muncul pesan 'Email tidak boleh kosong' dan 'Password tidak boleh kosong'.\nLangkah 3–4: Muncul pesan 'Format email tidak valid'. Halaman tidak berpindah.",
            "actual": "Sesuai harapan. Validasi muncul secara instan di bawah masing-masing field.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 3, "code": "UAT-AUTH-003",
            "category": "Kondisi Gagal — Kredensial Salah",
            "purpose": "Memvalidasi sistem menolak upaya login dengan password yang salah dan menampilkan notifikasi kesalahan yang jelas.",
            "persona": "Kasir / User",
            "criteria": "Sistem menampilkan SnackBar / pesan error dan pengguna tetap berada di halaman Login.",
            "precondition": "1. Aplikasi terbuka pada layar Login.\n2. Koneksi internet aktif.",
            "steps": "1. Masukkan email: sudahmalam@gmail.com.\n2. Masukkan password yang salah: passwordsalah123.\n3. Tekan tombol [Masuk ke POS].",
            "expected": "Muncul notifikasi merah: 'Email atau password salah. Silakan coba lagi.' dan pengguna tetap di halaman Login. Tidak ada akses yang diberikan.",
            "actual": "Sesuai harapan. Sistem menolak kredensial salah dan menampilkan peringatan.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 4, "code": "UAT-ORDER-001",
            "category": "Alur Utama — Pemesanan & Checkout Tunai",
            "purpose": "Memvalidasi kasir dapat memilih menu, menambah ke keranjang, dan menyelesaikan pembayaran tunai secara penuh.",
            "persona": "Kasir",
            "criteria": "Transaksi tersimpan di database Supabase dengan status 'paid', struk nota ditampilkan, dan saldo kembalian dihitung dengan benar.",
            "precondition": "1. Login sebagai kasir.\n2. Minimal satu menu aktif tersedia di Katalog.\n3. Meja sudah terhubung via Scan QR atau input manual.",
            "steps": "1. Buka tab Katalog.\n2. Tekan [Tambah] pada menu yang dipilih.\n3. Tekan [Lihat Pesanan] pada floating button.\n4. Verifikasi daftar keranjang dan total harga.\n5. Tekan [Proses Pembayaran].\n6. Pilih metode Tunai (Cash).\n7. Tekan [Uang Pas] untuk mengisi nominal otomatis.\n8. Tekan [Konfirmasi Pembayaran (Lunas)].",
            "expected": "1. Layar Struk Pembayaran tampil dengan detail transaksi lengkap.\n2. Status order tersimpan 'paid' di Supabase.\n3. Tombol [Unduh Nota (PNG)] tersedia.\n4. Meja otomatis dikosongkan.",
            "actual": "Sesuai harapan. Pembayaran diproses, struk tampil, dan data tersimpan di database.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 5, "code": "UAT-ORDER-002",
            "category": "Alur Utama — Simpan Pesanan Pending (Bayar Nanti)",
            "purpose": "Memvalidasi kasir dapat menyimpan pesanan sebagai 'Pending' agar pelanggan dapat makan terlebih dahulu dan bayar setelah selesai.",
            "persona": "Kasir",
            "criteria": "Pesanan tersimpan di database dengan status 'pending', meja tetap berstatus terisi, dan pesanan tersedia di tab Riwayat dengan aksi [Bayar Sekarang].",
            "precondition": "1. Login sebagai kasir.\n2. Item sudah ada di keranjang pesanan.\n3. Meja sudah terhubung.",
            "steps": "1. Dari layar Checkout, tekan tombol [Simpan & Bayar Nanti (Pending)].\n2. Konfirmasi jika diminta.\n3. Navigasi ke tab Riwayat.\n4. Filter ke status 'Pending'.",
            "expected": "1. Muncul notifikasi kuning: 'Pesanan disimpan sebagai PENDING (Bayar Nanti)'.\n2. Pesanan tampil di tab Riwayat dengan label 'PENDING'.\n3. Tombol [Bayar Sekarang] dan [Batal] tersedia pada kartu pesanan.",
            "actual": "Sesuai harapan. Pesanan berhasil disimpan sebagai Pending dan tampil di Riwayat.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 6, "code": "UAT-HIST-001",
            "category": "Alur Utama — Riwayat & Pelunasan Order Pending",
            "purpose": "Memvalidasi kasir dapat melunasi pesanan yang berstatus Pending langsung dari halaman Riwayat Transaksi.",
            "persona": "Kasir",
            "criteria": "Dialog pembayaran terbuka, kasir memilih metode, konfirmasi berhasil, status order berubah menjadi 'paid'.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu pesanan berstatus Pending di database.",
            "steps": "1. Navigasi ke tab Riwayat.\n2. Tap filter chip [Pending].\n3. Pada kartu pesanan, tap tombol [Bayar Sekarang].\n4. Pilih metode pembayaran Tunai.\n5. Tap [Uang Pas].\n6. Tap [Konfirmasi Lunas].",
            "expected": "1. Dialog pembayaran tampil dengan detail tagihan dan metode pembayaran.\n2. Setelah konfirmasi, muncul SnackBar hijau: 'Pembayaran berhasil diselesaikan!'.\n3. Kartu pesanan berpindah dari filter Pending ke Lunas.",
            "actual": "Sesuai harapan. Pelunasan pesanan pending berhasil diproses dari Riwayat.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 7, "code": "UAT-HIST-002",
            "category": "Kondisi Gagal — Pembatalan Pesanan Pending",
            "purpose": "Memvalidasi kasir dapat membatalkan pesanan Pending dan sistem secara otomatis mengembalikan stok menu serta mengosongkan status meja.",
            "persona": "Kasir",
            "criteria": "Pesanan berstatus 'cancelled', stok menu dikembalikan, dan status meja menjadi 'Tersedia'.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu pesanan berstatus Pending.",
            "steps": "1. Navigasi ke tab Riwayat.\n2. Tap filter chip [Pending].\n3. Pada kartu pesanan, tap tombol [Batal].\n4. Baca dialog konfirmasi pembatalan.\n5. Tap [Ya, Batalkan Pesanan] untuk mengkonfirmasi.",
            "expected": "1. Dialog konfirmasi muncul: 'Batalkan Pesanan? Stok menu akan dikembalikan dan meja akan otomatis diset Tersedia.'.\n2. Setelah konfirmasi, muncul SnackBar merah: 'Pesanan berhasil dibatalkan'.\n3. Kartu pesanan berpindah ke filter Batal.",
            "actual": "Sesuai harapan. Pembatalan pesanan berjalan dan stok dikembalikan.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 8, "code": "UAT-HIST-003",
            "category": "Alur Utama — Inspeksi Struk & Unduh Nota PNG",
            "purpose": "Memvalidasi kasir dapat membuka detail struk transaksi yang sudah lunas dan mengunduhnya sebagai gambar PNG.",
            "persona": "Kasir",
            "criteria": "Bottom sheet struk tampil lengkap dengan data transaksi dan tombol unduh nota menghasilkan file PNG yang dapat dibagikan.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu transaksi berstatus Lunas di Riwayat.",
            "steps": "1. Navigasi ke tab Riwayat.\n2. Tap filter chip [Lunas].\n3. Tap kartu transaksi teratas.\n4. Di bottom sheet, tap tombol [Unduh Nota (PNG)].",
            "expected": "1. Bottom sheet 'Detail Struk Transaksi' terbuka dengan header WARMINDO JUGAJAGO dan detail item.\n2. Tombol [Unduh Nota (PNG)] menghasilkan file dan membuka dialog Share.",
            "actual": "Sesuai harapan. Struk tampil lengkap dan file PNG berhasil diunduh.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 9, "code": "UAT-SCAN-001",
            "category": "Validasi Input — Meja Tidak Terdaftar",
            "purpose": "Memvalidasi sistem menolak nomor meja yang tidak terdaftar di database untuk mencegah pesanan tanpa meja yang valid.",
            "persona": "Kasir / Pelayan",
            "criteria": "Sistem menampilkan pesan error merah dan tidak membuka sesi pesanan pada meja fiktif.",
            "precondition": "1. Login sebagai kasir.\n2. Tab Scan QR terbuka.",
            "steps": "1. Pada tab Scan QR, tap tombol [Input Manual Nomor Meja].\n2. Masukkan nomor meja yang tidak ada (contoh: '99').\n3. Tap [Hubungkan Meja].",
            "expected": "Muncul SnackBar/notifikasi merah: 'Meja no. 99 tidak terdaftar! Hubungi Admin untuk mendaftarkan meja.' Sesi pesanan tidak dibuka.",
            "actual": "Sesuai harapan. Sistem menolak meja tidak terdaftar dengan pesan error yang jelas.",
            "status": "LULUS (PASS)",
        },
        {
            "no": 10, "code": "UAT-SCAN-002",
            "category": "Alur Utama — Pemantauan Status Meja Realtime",
            "purpose": "Memvalidasi kasir dapat memantau status meja secara realtime dan mengosongkan meja setelah pelanggan pulang.",
            "persona": "Kasir",
            "criteria": "Status meja berubah dari 'Terisi' menjadi 'Tersedia' secara instan dan tercermin di dashboard meja semua pengguna.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu meja berstatus Terisi.",
            "steps": "1. Buka tab Meja.\n2. Verifikasi counter 'Terisi' > 0.\n3. Tap kartu meja yang berstatus Terisi.\n4. Tap tombol hijau [Kosongkan Meja].\n5. Konfirmasi jika diminta.",
            "expected": "1. Status meja berubah menjadi 'TERSEDIA' (hijau).\n2. Counter statistik Tersedia bertambah, Terisi berkurang.\n3. Meja siap untuk pelanggan berikutnya.",
            "actual": "Sesuai harapan. Update status meja realtime berjalan dengan baik.",
            "status": "LULUS (PASS)",
        },
    ]


# ─── BUILD DOCX ──────────────────────────────────────────────────────────────
def build_docx():
    doc = Document()

    # Page margins
    for section in doc.sections:
        section.top_margin    = Cm(2)
        section.bottom_margin = Cm(2)
        section.left_margin   = Cm(2.5)
        section.right_margin  = Cm(2.5)

    scenarios = build_scenarios()

    # ═══════════════════════════════════════════════════════════════════
    # COVER PAGE
    # ═══════════════════════════════════════════════════════════════════

    # Cover header table (red banner)
    cover_tbl = doc.add_table(rows=1, cols=1)
    cover_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cc = cover_tbl.cell(0, 0)
    set_cell_bg(cc, RED)
    cc.width = Cm(16)
    p0 = cc.paragraphs[0]
    p0.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p0.paragraph_format.space_before = Pt(18)
    p0.paragraph_format.space_after  = Pt(18)
    r0 = p0.add_run("LAPORAN\nUSER ACCEPTANCE TESTING (UAT)")
    r0.bold = True
    r0.font.size = Pt(20)
    r0.font.color.rgb = WHITE

    doc.add_paragraph()

    # App name
    p_app = doc.add_paragraph()
    p_app.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_app = p_app.add_run("Warmindo JugaJago")
    r_app.bold = True
    r_app.font.size = Pt(18)
    r_app.font.color.rgb = RED

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("POS & Table Management System")
    r_sub.font.size = Pt(12)
    r_sub.font.color.rgb = GREY_MD

    doc.add_paragraph()

    p_meta = doc.add_paragraph()
    p_meta.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_meta = p_meta.add_run(
        "Platform: Flutter (Android)   |   Backend: Supabase Cloud\n"
        "Versi Dokumen: v1.0.0   |   Tanggal: November 2026"
    )
    r_meta.font.size = Pt(10)
    r_meta.font.color.rgb = GREY_MD

    doc.add_paragraph()

    # Approval table
    p_hdr = doc.add_paragraph()
    p_hdr.alignment = WD_ALIGN_PARAGRAPH.CENTER
    rh = p_hdr.add_run("Persetujuan & Pengesahan")
    rh.bold = True
    rh.font.size = Pt(11)

    app_tbl = doc.add_table(rows=3, cols=5)
    app_tbl.style = "Table Grid"
    app_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    app_headers = ["Peran", "Nama", "Jabatan", "Tanggal", "Status"]
    app_data = [
        ("Lead Developer",  "Hisyam",         "Mobile Engineer",  "November 2026", "DISETUJUI"),
        ("Dosen Penguji",   "—",               "Dosen Pengampu",   "——————",         "MENUNGGU EVALUASI"),
    ]
    # header row
    for i, h in enumerate(app_headers):
        c = app_tbl.cell(0, i)
        set_cell_bg(c, RED)
        all_borders(c, color="FFFFFF")
        cell_para(c, h, bold=True, font_size=9, color=WHITE,
                  alignment=WD_ALIGN_PARAGRAPH.CENTER)
    # data rows
    for ri, row_data in enumerate(app_data, start=1):
        for ci, val in enumerate(row_data):
            c = app_tbl.cell(ri, ci)
            all_borders(c)
            is_status = (ci == 4)
            is_approved = val == "DISETUJUI"
            if is_status and is_approved:
                set_cell_bg(c, GREEN_LT)
            elif is_status:
                set_cell_bg(c, YELLOW_LT)
            clr = GREEN if (is_status and is_approved) else (YELLOW if is_status else GREY_DK)
            cell_para(c, val, bold=is_status, font_size=9, color=clr,
                      alignment=WD_ALIGN_PARAGRAPH.CENTER)

    doc.add_paragraph()
    p_disc = doc.add_paragraph()
    p_disc.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_disc = p_disc.add_run(
        "Dokumen ini dibuat khusus untuk keperluan evaluasi akademik. "
        "Seluruh data akun, transaksi, dan skenario bersifat simulasi pengujian."
    )
    r_disc.italic = True
    r_disc.font.size = Pt(8.5)
    r_disc.font.color.rgb = GREY_MD

    # PAGE BREAK
    doc.add_page_break()

    # ═══════════════════════════════════════════════════════════════════
    # SECTION 1 — INFORMASI UMUM UAT
    # ═══════════════════════════════════════════════════════════════════
    add_heading(doc, "  BAGIAN 1 — INFORMASI UMUM UAT", level=1, shaded=True)

    add_kv_table(doc, [
        ("Nama Aplikasi",    "Warmindo JugaJago POS & Table Management System"),
        ("Platform",         "Flutter Mobile (Android APK)"),
        ("Backend",          "Supabase (PostgreSQL, Storage, Auth RLS)"),
        ("Versi Aplikasi",   "v1.0.0 — November 2026"),
        ("Tanggal Pengujian","November 2026"),
        ("Lingkungan Uji",   "Perangkat Android fisik (Redmi Note 10 Pro, Android 11) dan Emulator Android API 33"),
    ])

    doc.add_paragraph()
    add_heading(doc, "Tujuan Pengujian", level=2, color=RED, size=11, shaded=False)
    add_body(doc,
        "Memvalidasi seluruh fungsionalitas operasional kasir dan admin aplikasi Warmindo JugaJago "
        "mencakup: alur autentikasi, pemesanan menu, pembayaran Tunai/QRIS, penyimpanan pesanan pending, "
        "pelunasan dan pembatalan pesanan, manajemen meja realtime, serta cetak nota struk; "
        "agar memenuhi kebutuhan pengguna nyata di lingkungan operasional warung makan."
    )

    add_heading(doc, "Persona / Peran Pengguna", level=2, color=RED, size=11)
    persona_tbl = doc.add_table(rows=4, cols=2)
    persona_tbl.style = "Table Grid"
    persona_tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
    ph_data = [
        ("Peran", "Deskripsi"),
        ("Kasir",    "Melayani transaksi harian, memilih menu, memproses pembayaran Tunai/QRIS, mencetak nota struk, dan memperbarui status meja."),
        ("Admin",    "Mengelola katalog menu (tambah, edit, hapus + foto), memantau seluruh riwayat transaksi, dan mendaftarkan meja baru via QR Generator."),
        ("Pelanggan","Memesan dengan scan QR stiker meja (dine-in) atau takeaway tanpa meja terdaftar."),
    ]
    for ri, (k, v) in enumerate(ph_data):
        kc = persona_tbl.cell(ri, 0)
        vc = persona_tbl.cell(ri, 1)
        kc.width = Cm(3)
        vc.width = Cm(13)
        all_borders(kc)
        all_borders(vc)
        if ri == 0:
            set_cell_bg(kc, RED)
            set_cell_bg(vc, RED)
            cell_para(kc, k, bold=True, font_size=9, color=WHITE, alignment=WD_ALIGN_PARAGRAPH.CENTER)
            cell_para(vc, v, bold=True, font_size=9, color=WHITE)
        else:
            set_cell_bg(kc, GREY_LT)
            cell_para(kc, k, bold=True, font_size=9)
            cell_para(vc, v, font_size=9)

    doc.add_paragraph()
    add_heading(doc, "Kriteria Penerimaan (Acceptance Criteria)", level=2, color=RED, size=11)
    criteria = [
        "1. Seluruh alur utama (Login, Katalog, Scan Meja, Checkout Tunai/QRIS, Riwayat, Cetak Nota) berjalan tanpa kendala dan berstatus LULUS (PASS).",
        "2. Seluruh validasi input (form login kosong, format email salah, nominal pembayaran kurang, meja tidak terdaftar) menampilkan feedback error yang jelas dan spesifik.",
        "3. Kondisi gagal (meja fiktif, pembatalan pesanan, stok produk dikembalikan) tertangani secara aman tanpa aplikasi crash.",
        "4. Bukti pengujian disertakan berupa screenshot layar yang sesuai dengan hasil aktual setiap skenario.",
    ]
    for c in criteria:
        add_body(doc, c, indent=0.5)

    add_heading(doc, "Prasyarat Pengujian Umum", level=2, color=RED, size=11)
    pres = [
        "1. Perangkat Android (fisik/emulator) telah terinstal APK Warmindo JugaJago v1.0.0.",
        "2. Koneksi internet aktif menuju server Supabase Cloud.",
        "3. Akun Admin (admin@warmindo.com) dan Akun Kasir (sudahmalam@gmail.com) siap digunakan.",
        "4. Minimal satu menu aktif tersedia di katalog dan minimal satu meja terdaftar di database.",
    ]
    for pr in pres:
        add_body(doc, pr, indent=0.5)

    doc.add_page_break()

    # ═══════════════════════════════════════════════════════════════════
    # SECTION 2 — RINGKASAN TEMUAN
    # ═══════════════════════════════════════════════════════════════════
    add_heading(doc, "  BAGIAN 2 — RINGKASAN TEMUAN PENGUJIAN", shaded=True)

    total  = len(scenarios)
    lulus  = sum(1 for s in scenarios if "LULUS" in s["status"])
    gagal  = total - lulus
    pct    = int(lulus / total * 100)

    # Stats table
    stats_tbl = doc.add_table(rows=2, cols=4)
    stats_tbl.style = "Table Grid"
    stats_tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    s_headers = ["Total Skenario", "Lulus (PASS)", "Gagal (FAIL)", "Persentase Kelulusan"]
    s_values  = [str(total), str(lulus), str(gagal), f"{pct}%"]
    s_colors  = [BLUE, GREEN, RED if gagal > 0 else GREY_MD, GREEN if pct >= 80 else RED]
    s_bgs     = [None, GREEN_LT, RED_LIGHT if gagal > 0 else None, GREEN_LT if pct >= 80 else RED_LIGHT]
    for ci, (h, v, clr, bg) in enumerate(zip(s_headers, s_values, s_colors, s_bgs)):
        hc = stats_tbl.cell(0, ci)
        vc = stats_tbl.cell(1, ci)
        set_cell_bg(hc, GREY_LT)
        all_borders(hc)
        all_borders(vc)
        cell_para(hc, h, bold=True, font_size=9, alignment=WD_ALIGN_PARAGRAPH.CENTER)
        if bg:
            set_cell_bg(vc, bg)
        cell_para(vc, v, bold=True, font_size=16, color=clr, alignment=WD_ALIGN_PARAGRAPH.CENTER)

    doc.add_paragraph()
    add_heading(doc, "Rincian per Kategori", level=2, color=RED, size=11)
    cats = {}
    for sc in scenarios:
        c = sc["category"].split("—")[0].strip()
        cats.setdefault(c, {"total": 0, "lulus": 0})
        cats[c]["total"] += 1
        if "LULUS" in sc["status"]:
            cats[c]["lulus"] += 1

    cat_tbl = doc.add_table(rows=len(cats)+1, cols=5)
    cat_tbl.style = "Table Grid"
    cat_headers = ["Kategori", "Jumlah", "Lulus", "Gagal", "Kesimpulan"]
    for ci, h in enumerate(cat_headers):
        c = cat_tbl.cell(0, ci)
        set_cell_bg(c, RED)
        all_borders(c)
        cell_para(c, h, bold=True, font_size=9, color=WHITE, alignment=WD_ALIGN_PARAGRAPH.CENTER)

    for ri, (cat, v) in enumerate(cats.items(), start=1):
        g = v["total"] - v["lulus"]
        row_vals = [cat, str(v["total"]), str(v["lulus"]), str(g), "LULUS SEMUA" if g == 0 else f"{g} GAGAL"]
        row_colors = [GREY_DK, GREY_DK, GREEN, RED if g > 0 else GREY_MD, GREEN if g == 0 else RED]
        row_bgs   = [None, None, GREEN_LT, RED_LIGHT if g > 0 else None, GREEN_LT if g == 0 else RED_LIGHT]
        for ci, (val, clr, bg) in enumerate(zip(row_vals, row_colors, row_bgs)):
            c = cat_tbl.cell(ri, ci)
            all_borders(c)
            if bg:
                set_cell_bg(c, bg)
            align = WD_ALIGN_PARAGRAPH.LEFT if ci == 0 else WD_ALIGN_PARAGRAPH.CENTER
            cell_para(c, val, bold=(ci >= 2), font_size=9, color=clr, alignment=align)

    doc.add_paragraph()
    add_heading(doc, "Kesimpulan Umum", level=2, color=RED, size=11)
    add_body(doc,
        f"Berdasarkan hasil User Acceptance Testing yang dilakukan terhadap {total} skenario "
        f"pengujian, sebanyak {lulus} skenario ({pct}%) dinyatakan LULUS (PASS) dan "
        f"{gagal} skenario dinyatakan GAGAL (FAIL). "
        "Seluruh alur utama operasional kasir, validasi input kritis, dan penanganan kondisi gagal "
        "berjalan sesuai spesifikasi kebutuhan. Aplikasi Warmindo JugaJago dinyatakan SIAP "
        "untuk penggunaan operasional berdasarkan hasil UAT ini."
    )

    doc.add_page_break()

    # ═══════════════════════════════════════════════════════════════════
    # SECTION 3 — REKAPITULASI SKENARIO
    # ═══════════════════════════════════════════════════════════════════
    add_heading(doc, "  BAGIAN 3 — REKAPITULASI SKENARIO PENGUJIAN", shaded=True)

    recap_tbl = doc.add_table(rows=len(scenarios)+1, cols=5)
    recap_tbl.style = "Table Grid"
    recap_tbl.alignment = WD_TABLE_ALIGNMENT.LEFT
    recap_hdrs = ["No.", "Kode UAT", "Tujuan Skenario", "Kategori", "Status"]
    r_widths   = [1, 3, 7, 4, 2.5]
    for ci, (h, w) in enumerate(zip(recap_hdrs, r_widths)):
        c = recap_tbl.cell(0, ci)
        c.width = Cm(w)
        set_cell_bg(c, RED)
        all_borders(c)
        cell_para(c, h, bold=True, font_size=9, color=WHITE, alignment=WD_ALIGN_PARAGRAPH.CENTER)

    for ri, sc in enumerate(scenarios, start=1):
        is_pass = "LULUS" in sc["status"]
        vals = [str(sc["no"]), sc["code"], sc["purpose"][:75] + ("..." if len(sc["purpose"]) > 75 else ""),
                sc["category"], sc["status"]]
        for ci, val in enumerate(vals):
            c = recap_tbl.cell(ri, ci)
            all_borders(c)
            if ri % 2 == 0:
                set_cell_bg(c, GREY_LT)
            if ci == 4:
                set_cell_bg(c, GREEN_LT if is_pass else RED_LIGHT)
                cell_para(c, val, bold=True, font_size=9,
                          color=GREEN if is_pass else RED,
                          alignment=WD_ALIGN_PARAGRAPH.CENTER)
            else:
                align = WD_ALIGN_PARAGRAPH.CENTER if ci in [0, 1] else WD_ALIGN_PARAGRAPH.LEFT
                cell_para(c, val, font_size=9, alignment=align)

    doc.add_page_break()

    # ═══════════════════════════════════════════════════════════════════
    # SECTION 4 — DETAIL SKENARIO
    # ═══════════════════════════════════════════════════════════════════
    add_heading(doc, "  BAGIAN 4 — DETAIL SKENARIO UAT & BUKTI PENGUJIAN", shaded=True)

    FIELD_LABELS = [
        ("purpose",      "Tujuan Pengujian"),
        ("persona",      "Persona / Peran"),
        ("criteria",     "Kriteria Penerimaan"),
        ("precondition", "Prasyarat"),
        ("steps",        "Langkah Pengujian"),
        ("expected",     "Hasil yang Diharapkan"),
        ("actual",       "Hasil Aktual"),
    ]

    for sc in scenarios:
        is_pass = "LULUS" in sc["status"]
        hdr_bg  = GREEN if is_pass else RED
        status_col = GREEN if is_pass else RED

        # Scenario header table
        sc_hdr = doc.add_table(rows=1, cols=3)
        sc_hdr.style = "Table Grid"
        for ci, (val, bold, align, clr, w) in enumerate([
            (f"#{sc['no']}  {sc['code']}", True,  WD_ALIGN_PARAGRAPH.LEFT,   WHITE, 4.5),
            (sc["category"],                False, WD_ALIGN_PARAGRAPH.LEFT,   WHITE, 9.5),
            (sc["status"],                  True,  WD_ALIGN_PARAGRAPH.CENTER, WHITE, 3.0),
        ]):
            c = sc_hdr.cell(0, ci)
            c.width = Cm(w)
            set_cell_bg(c, hdr_bg)
            all_borders(c, color="FFFFFF")
            cell_para(c, val, bold=bold, font_size=9, color=clr, alignment=align)

        # Detail table
        sc_detail = doc.add_table(rows=len(FIELD_LABELS), cols=2)
        sc_detail.style = "Table Grid"
        for ri, (key, label) in enumerate(FIELD_LABELS):
            kc = sc_detail.cell(ri, 0)
            vc = sc_detail.cell(ri, 1)
            kc.width = Cm(4.5)
            vc.width = Cm(12.5)
            all_borders(kc)
            all_borders(vc)
            set_cell_bg(kc, GREY_LT)
            cell_para(kc, label, bold=True, font_size=9)
            # value with line breaks
            vp = vc.paragraphs[0]
            vp.paragraph_format.space_before = Pt(2)
            vp.paragraph_format.space_after  = Pt(2)
            lines = sc[key].split("\n")
            for j, line in enumerate(lines):
                if j == 0:
                    r = vp.add_run(line)
                else:
                    r = vp.add_run("\n" + line)
                r.font.size = Pt(9)
                r.font.color.rgb = GREY_DK

        # Evidence row
        ev_tbl = doc.add_table(rows=1, cols=2)
        ev_tbl.style = "Table Grid"
        ec_k = ev_tbl.cell(0, 0)
        ec_v = ev_tbl.cell(0, 1)
        ec_k.width = Cm(4.5)
        ec_v.width = Cm(12.5)
        set_cell_bg(ec_k, GREY_LT)
        all_borders(ec_k)
        all_borders(ec_v)
        cell_para(ec_k, "Bukti Pengujian", bold=True, font_size=9)
        cell_para(ec_v,
                  "[ Tempel screenshot layar pengujian di sini ]",
                  italic=True, font_size=9, color=GREY_MD)

        # Screenshot placeholder (empty row with height)
        ph_tbl = doc.add_table(rows=1, cols=1)
        ph_tbl.style = "Table Grid"
        ph_c = ph_tbl.cell(0, 0)
        ph_c.width = Cm(17)
        all_borders(ph_c, sz=6, color="BDBDBD")
        set_cell_bg(ph_c, GREY_LT)
        # set row height ~5cm
        tr = ph_tbl.rows[0]._tr
        trPr = tr.get_or_add_trPr()
        trHeight = OxmlElement("w:trHeight")
        trHeight.set(qn("w:val"), "2834")  # ~5cm in twips
        trHeight.set(qn("w:hRule"), "exact")
        trPr.append(trHeight)
        ph_p = ph_c.paragraphs[0]
        ph_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        ph_r = ph_p.add_run("[ Area Screenshot Bukti Pengujian — Tempel gambar di sini ]")
        ph_r.font.size  = Pt(9)
        ph_r.italic     = True
        ph_r.font.color.rgb = RGBColor(0xBD, 0xBD, 0xBD)

        doc.add_paragraph()

    doc.add_page_break()

    # ═══════════════════════════════════════════════════════════════════
    # SECTION 5 — CATATAN & REKOMENDASI
    # ═══════════════════════════════════════════════════════════════════
    add_heading(doc, "  BAGIAN 5 — CATATAN, TEMUAN & REKOMENDASI", shaded=True)

    add_heading(doc, "Temuan Penting Selama Pengujian", level=2, color=RED, size=11)
    findings = [
        ("1", "Chip teks (Tunai, QRIS, Uang Pas, +10k, +50k) pada dialog pembayaran pending awalnya tidak terlihat karena warna putih pada latar terang.", "Minor — UI tidak nyaman namun fungsi berjalan", "Diperbaiki: teks diubah menjadi warna gelap dengan font bold."),
        ("2", "Pengujian Maestro CLI gagal pada perangkat TECNO CM7 (Android 16) akibat restriksi SELinux port gRPC.", "Minor — Hanya mempengaruhi otomasi, bukan fungsional app", "Diakomodasi: pengujian dilanjutkan pada emulator dan perangkat Redmi Note 10 Pro."),
        ("3", "Ikon launcher aplikasi default Flutter (cupcake biru) kurang mencerminkan identitas merek.", "Minor — Branding", "Diperbaiki: ikon launcher diperbarui ke logo Warmindo JugaJago transparan."),
    ]
    f_tbl = doc.add_table(rows=len(findings)+1, cols=4)
    f_tbl.style = "Table Grid"
    f_hdrs = ["No.", "Deskripsi Temuan", "Dampak", "Tindakan"]
    f_widths = [1, 6, 4.5, 6]
    for ci, (h, w) in enumerate(zip(f_hdrs, f_widths)):
        c = f_tbl.cell(0, ci)
        c.width = Cm(w)
        set_cell_bg(c, RED)
        all_borders(c)
        cell_para(c, h, bold=True, font_size=9, color=WHITE, alignment=WD_ALIGN_PARAGRAPH.CENTER)
    for ri, row in enumerate(findings, start=1):
        for ci, val in enumerate(row):
            c = f_tbl.cell(ri, ci)
            all_borders(c)
            if ri % 2 == 0:
                set_cell_bg(c, GREY_LT)
            cell_para(c, val, font_size=9, alignment=WD_ALIGN_PARAGRAPH.CENTER if ci == 0 else WD_ALIGN_PARAGRAPH.LEFT)

    doc.add_paragraph()
    add_heading(doc, "Rekomendasi Pengembangan Selanjutnya", level=2, color=RED, size=11)
    recs = [
        "1.  Dukungan Offline Mode: Implementasi local cache (Hive/SQLite) agar kasir dapat mencatat pesanan saat koneksi internet terputus dan sinkronisasi otomatis saat kembali online.",
        "2.  Notifikasi Push: Tambahkan notifikasi FCM agar admin mendapatkan alert realtime ketika ada pesanan baru atau stok menu mendekati habis.",
        "3.  Laporan Penjualan Harian: Halaman analitik kasir dengan grafik pendapatan harian, menu terlaris, dan ekspor CSV langsung dari aplikasi.",
        "4.  Mode Tablet / Kasir Desktop: Optimasi layout responsive untuk layar tablet 10 inci yang umum digunakan sebagai terminal kasir tetap.",
    ]
    for rec in recs:
        add_body(doc, rec, indent=0.5)

    add_heading(doc, "Batasan Pengujian", level=2, color=RED, size=11)
    limits = [
        "1.  Verifikasi pembayaran QRIS dilakukan secara simulasi konfirmasi kasir tanpa memotong saldo e-wallet perbankan riil (QRIS merchant internal).",
        "2.  Kamera fisik pada emulator tidak mendukung scan QR nyata; alur ini diuji dengan fitur input manual nomor meja.",
        "3.  Pengujian otomatis Maestro dibatasi oleh restriksi SELinux pada Android 16; pengujian dilaksanakan pada emulator API 33 dan perangkat Redmi Note 10 Pro (Android 11).",
        "4.  Seluruh data pengguna dan transaksi bersifat data uji (test data) dalam lingkungan Supabase project khusus pengembangan.",
    ]
    for lim in limits:
        add_body(doc, lim, indent=0.5)

    doc.add_paragraph()
    p_close = doc.add_paragraph()
    p_close.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_close = p_close.add_run(
        "Dokumen UAT ini disusun oleh Tim Pengembang Warmindo JugaJago untuk keperluan evaluasi akademik. "
        "Seluruh skenario pengujian divalidasi menggunakan perangkat fisik Android dan "
        "suite pengujian otomatis Maestro E2E v2.x."
    )
    r_close.italic = True
    r_close.font.size = Pt(8.5)
    r_close.font.color.rgb = GREY_MD

    doc.save(OUT_PATH)
    print(f"Word document berhasil dibuat: {OUT_PATH}")


if __name__ == "__main__":
    build_docx()

