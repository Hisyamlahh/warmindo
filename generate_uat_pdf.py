"""
Generate UAT PDF Report for Warmindo JugaJago
"""
import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm, mm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY

# ─── COLOR PALETTE ────────────────────────────────────────────────────────────
RED       = colors.HexColor("#C62828")
RED_LIGHT = colors.HexColor("#FFEBEE")
YELLOW    = colors.HexColor("#F9A825")
YELLOW_LT = colors.HexColor("#FFFDE7")
GREEN     = colors.HexColor("#2E7D32")
GREEN_LT  = colors.HexColor("#E8F5E9")
BLUE_LT   = colors.HexColor("#E3F2FD")
BLUE      = colors.HexColor("#1565C0")
GREY_DK   = colors.HexColor("#424242")
GREY_MD   = colors.HexColor("#757575")
GREY_LT   = colors.HexColor("#F5F5F5")
WHITE     = colors.white
BLACK     = colors.black

OUT_PATH = r"d:\warmindo\UAT_Warmindo_JugaJago.pdf"

# ─── NUMBERED CANVAS (header & footer) ────────────────────────────────────────
class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self._draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def _draw_page_decorations(self, page_count):
        self.saveState()
        w, h = A4
        # --- top bar ---
        if self._pageNumber > 1:
            self.setFillColor(RED)
            self.rect(0, h - 25, w, 25, fill=1, stroke=0)
            self.setFillColor(WHITE)
            self.setFont("Helvetica-Bold", 8)
            self.drawString(40, h - 16, "LAPORAN USER ACCEPTANCE TESTING (UAT)  —  WARMINDO JUGAJAGO  v1.0.0")
        # --- bottom bar ---
        self.setFillColor(GREY_LT)
        self.rect(0, 0, w, 32, fill=1, stroke=0)
        self.setFillColor(GREY_MD)
        self.setFont("Helvetica", 7.5)
        self.drawString(40, 11, "Rahasia & Terbatas — Untuk Keperluan Evaluasi Akademik")
        self.drawRightString(w - 40, 11, f"Halaman {self._pageNumber} dari {page_count}")
        self.restoreState()


# ─── STYLES ───────────────────────────────────────────────────────────────────
def build_styles():
    base = getSampleStyleSheet()
    return {
        "cover_title": ParagraphStyle("cover_title",
            fontName="Helvetica-Bold", fontSize=22, textColor=WHITE,
            alignment=TA_CENTER, leading=28, spaceAfter=4),
        "cover_sub": ParagraphStyle("cover_sub",
            fontName="Helvetica", fontSize=13, textColor=WHITE,
            alignment=TA_CENTER, leading=18, spaceAfter=4),
        "cover_meta": ParagraphStyle("cover_meta",
            fontName="Helvetica", fontSize=10, textColor=WHITE,
            alignment=TA_CENTER, leading=14),
        "h1": ParagraphStyle("h1",
            fontName="Helvetica-Bold", fontSize=14, textColor=WHITE,
            backColor=RED, alignment=TA_LEFT, leading=20,
            leftIndent=8, rightIndent=8, spaceBefore=14, spaceAfter=6,
            borderPad=5),
        "h2": ParagraphStyle("h2",
            fontName="Helvetica-Bold", fontSize=11, textColor=RED,
            alignment=TA_LEFT, leading=16, spaceBefore=10, spaceAfter=4),
        "body": ParagraphStyle("body",
            fontName="Helvetica", fontSize=9, textColor=GREY_DK,
            alignment=TA_JUSTIFY, leading=13, spaceAfter=4),
        "body_bold": ParagraphStyle("body_bold",
            fontName="Helvetica-Bold", fontSize=9, textColor=GREY_DK,
            leading=13, spaceAfter=2),
        "table_hdr": ParagraphStyle("table_hdr",
            fontName="Helvetica-Bold", fontSize=8, textColor=WHITE,
            alignment=TA_CENTER, leading=11),
        "table_body": ParagraphStyle("table_body",
            fontName="Helvetica", fontSize=8, textColor=GREY_DK,
            alignment=TA_LEFT, leading=11),
        "table_body_bold": ParagraphStyle("table_body_bold",
            fontName="Helvetica-Bold", fontSize=8, textColor=GREY_DK,
            alignment=TA_LEFT, leading=11),
        "pass": ParagraphStyle("pass",
            fontName="Helvetica-Bold", fontSize=8, textColor=GREEN,
            alignment=TA_CENTER, leading=11),
        "fail": ParagraphStyle("fail",
            fontName="Helvetica-Bold", fontSize=8, textColor=RED,
            alignment=TA_CENTER, leading=11),
        "caption": ParagraphStyle("caption",
            fontName="Helvetica-Oblique", fontSize=8, textColor=GREY_MD,
            alignment=TA_CENTER, leading=11, spaceBefore=2, spaceAfter=8),
    }


# ─── HELPERS ──────────────────────────────────────────────────────────────────
def p(text, style):
    return Paragraph(text, style)

def spacer(h=6):
    return Spacer(1, h)

def hr():
    return HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#E0E0E0"),
                      spaceAfter=6, spaceBefore=6)

def section_heading(text, st):
    return p(f"&nbsp;&nbsp;{text}", st["h1"])

def kv_table(data, st, col_w=(5*cm, 11.5*cm)):
    rows = []
    for k, v in data:
        rows.append([
            p(k, st["body_bold"]),
            p(v, st["body"]),
        ])
    t = Table(rows, colWidths=col_w)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (0,-1), GREY_LT),
        ("VALIGN",     (0,0), (-1,-1), "TOP"),
        ("GRID",       (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("LEFTPADDING",(0,0),(-1,-1), 6),
        ("RIGHTPADDING",(0,0),(-1,-1), 6),
        ("TOPPADDING", (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
    ]))
    return t


# ─── UAT SCENARIOS ────────────────────────────────────────────────────────────
def build_scenarios():
    return [
        {
            "no": 1,
            "code": "UAT-AUTH-001",
            "category": "Alur Utama — Autentikasi",
            "purpose": "Memvalidasi kasir dapat masuk ke sistem POS dengan kredensial yang sah.",
            "persona": "Kasir",
            "criteria": "Sistem memverifikasi kredensial via Supabase Auth dan mengarahkan pengguna ke Dashboard POS dengan navigasi tab lengkap.",
            "precondition": "1. Aplikasi terbuka pada layar Login.\n2. Akun kasir (sudahmalam@gmail.com) telah terdaftar di Supabase Auth.\n3. Koneksi internet aktif.",
            "steps": "1. Buka aplikasi Warmindo JugaJago.\n2. Masukkan email: sudahmalam@gmail.com.\n3. Masukkan password: sudahmalam.\n4. Tekan tombol [Masuk ke POS].",
            "expected": "Pengguna masuk ke Dashboard POS. Tampil empat tab navigasi: Katalog, Scan QR, Meja, dan Riwayat. Status login tersimpan secara persisten.",
            "actual": "Sesuai harapan. Login sukses, Dashboard POS tampil lengkap dengan navigasi tab.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot layar Dashboard setelah login ]",
        },
        {
            "no": 2,
            "code": "UAT-AUTH-002",
            "category": "Validasi Input — Form Login",
            "purpose": "Memvalidasi sistem menolak input login kosong dan format email yang tidak valid.",
            "persona": "Kasir / User",
            "criteria": "Pesan error validasi muncul secara inline di bawah field yang bersangkutan dan proses login tidak dijalankan.",
            "precondition": "1. Aplikasi terbuka pada layar Login.\n2. Semua field dalam kondisi kosong.",
            "steps": "1. Tanpa mengisi apapun, tekan tombol [Masuk ke POS].\n2. Amati pesan validasi yang muncul.\n3. Ketik email dengan format salah: 'kasirbukanemail'.\n4. Tekan [Masuk ke POS] kembali.",
            "expected": "Langkah 1: Muncul pesan 'Email tidak boleh kosong' dan 'Password tidak boleh kosong'.\nLangkah 3–4: Muncul pesan 'Format email tidak valid'. Halaman tidak berpindah.",
            "actual": "Sesuai harapan. Validasi muncul secara instan di bawah masing-masing field.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot pesan validasi form login ]",
        },
        {
            "no": 3,
            "code": "UAT-AUTH-003",
            "category": "Kondisi Gagal — Kredensial Salah",
            "purpose": "Memvalidasi sistem menolak upaya login dengan password yang salah dan menampilkan notifikasi kesalahan yang jelas.",
            "persona": "Kasir / User",
            "criteria": "Sistem menampilkan SnackBar / pesan error dan pengguna tetap berada di halaman Login.",
            "precondition": "1. Aplikasi terbuka pada layar Login.\n2. Koneksi internet aktif.",
            "steps": "1. Masukkan email: sudahmalam@gmail.com.\n2. Masukkan password yang salah: passwordsalah123.\n3. Tekan tombol [Masuk ke POS].",
            "expected": "Muncul notifikasi merah: 'Email atau password salah. Silakan coba lagi.' dan pengguna tetap di halaman Login. Tidak ada akses yang diberikan.",
            "actual": "Sesuai harapan. Sistem menolak kredensial salah dan menampilkan peringatan.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot SnackBar error autentikasi ]",
        },
        {
            "no": 4,
            "code": "UAT-ORDER-001",
            "category": "Alur Utama — Pemesanan & Checkout Tunai",
            "purpose": "Memvalidasi kasir dapat memilih menu, menambah ke keranjang, dan menyelesaikan pembayaran tunai secara penuh.",
            "persona": "Kasir",
            "criteria": "Transaksi tersimpan di database Supabase dengan status 'paid', struk nota tercetak/ditampilkan, dan saldo kembalian dihitung dengan benar.",
            "precondition": "1. Login sebagai kasir.\n2. Minimal satu menu aktif tersedia di Katalog.\n3. Meja sudah terhubung via Scan QR atau input manual.",
            "steps": "1. Buka tab Katalog.\n2. Tekan [Tambah] pada menu yang dipilih.\n3. Tekan [Lihat Pesanan] pada floating button.\n4. Verifikasi daftar keranjang dan total harga.\n5. Tekan [Proses Pembayaran].\n6. Pilih metode Tunai (Cash).\n7. Tekan [Uang Pas] untuk mengisi nominal otomatis.\n8. Tekan [Konfirmasi Pembayaran (Lunas)].",
            "expected": "1. Layar Struk Pembayaran tampil dengan detail transaksi lengkap.\n2. Status order tersimpan 'paid' di Supabase.\n3. Tombol [Unduh Nota (PNG)] tersedia.\n4. Meja otomatis dikosongkan.",
            "actual": "Sesuai harapan. Pembayaran diproses, struk tampil, dan data tersimpan di database.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot layar Struk Pembayaran ]",
        },
        {
            "no": 5,
            "code": "UAT-ORDER-002",
            "category": "Alur Utama — Simpan Pesanan Pending (Bayar Nanti)",
            "purpose": "Memvalidasi kasir dapat menyimpan pesanan sebagai 'Pending' agar pelanggan dapat makan terlebih dahulu dan bayar setelah selesai.",
            "persona": "Kasir",
            "criteria": "Pesanan tersimpan di database dengan status 'pending', meja tetap berstatus terisi, dan pesanan tersedia di tab Riwayat dengan aksi [Bayar Sekarang].",
            "precondition": "1. Login sebagai kasir.\n2. Item sudah ada di keranjang pesanan.\n3. Meja sudah terhubung.",
            "steps": "1. Dari layar Checkout, tekan tombol [Simpan & Bayar Nanti (Pending)].\n2. Konfirmasi jika diminta.\n3. Navigasi ke tab Riwayat.\n4. Filter ke status 'Pending'.",
            "expected": "1. Muncul notifikasi kuning: 'Pesanan disimpan sebagai PENDING (Bayar Nanti)'.\n2. Pesanan tampil di tab Riwayat dengan label 'PENDING'.\n3. Tombol [Bayar Sekarang] dan [Batal] tersedia pada kartu pesanan.",
            "actual": "Sesuai harapan. Pesanan berhasil disimpan sebagai Pending dan tampil di Riwayat.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot kartu pesanan Pending di tab Riwayat ]",
        },
        {
            "no": 6,
            "code": "UAT-HIST-001",
            "category": "Alur Utama — Riwayat & Pelunasan Order Pending",
            "purpose": "Memvalidasi kasir dapat melunasi pesanan yang berstatus Pending langsung dari halaman Riwayat Transaksi.",
            "persona": "Kasir",
            "criteria": "Dialog pembayaran terbuka, kasir memilih metode, konfirmasi berhasil, status order berubah menjadi 'paid'.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu pesanan berstatus Pending di database.",
            "steps": "1. Navigasi ke tab Riwayat.\n2. Tap filter chip [Pending].\n3. Pada kartu pesanan, tap tombol [Bayar Sekarang].\n4. Pilih metode pembayaran Tunai.\n5. Tap [Uang Pas].\n6. Tap [Konfirmasi Lunas].",
            "expected": "1. Dialog pembayaran tampil dengan detail tagihan dan metode pembayaran.\n2. Setelah konfirmasi, muncul SnackBar hijau: 'Pembayaran berhasil diselesaikan!'.\n3. Kartu pesanan berpindah dari filter Pending ke Lunas.",
            "actual": "Sesuai harapan. Pelunasan pesanan pending berhasil diproses dari Riwayat.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot SnackBar konfirmasi lunas ]",
        },
        {
            "no": 7,
            "code": "UAT-HIST-002",
            "category": "Kondisi Gagal — Pembatalan Pesanan Pending",
            "purpose": "Memvalidasi kasir dapat membatalkan pesanan Pending dan sistem secara otomatis mengembalikan stok menu serta mengosongkan status meja.",
            "persona": "Kasir",
            "criteria": "Pesanan berstatus 'cancelled', stok menu dikembalikan, dan status meja menjadi 'Tersedia'.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu pesanan berstatus Pending.",
            "steps": "1. Navigasi ke tab Riwayat.\n2. Tap filter chip [Pending].\n3. Pada kartu pesanan, tap tombol [Batal].\n4. Baca dialog konfirmasi pembatalan.\n5. Tap [Ya, Batalkan Pesanan] untuk mengkonfirmasi.",
            "expected": "1. Dialog konfirmasi muncul: 'Batalkan Pesanan? Stok menu akan dikembalikan dan meja akan otomatis diset Tersedia.'.\n2. Setelah konfirmasi, muncul SnackBar merah: 'Pesanan berhasil dibatalkan'.\n3. Kartu pesanan berpindah ke filter Batal.",
            "actual": "Sesuai harapan. Pembatalan pesanan berjalan dan stok dikembalikan.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot dialog konfirmasi & kartu pesanan berstatus Batal ]",
        },
        {
            "no": 8,
            "code": "UAT-HIST-003",
            "category": "Alur Utama — Inspeksi Struk & Unduh Nota PNG",
            "purpose": "Memvalidasi kasir dapat membuka detail struk transaksi yang sudah lunas dan mengunduhnya sebagai gambar PNG.",
            "persona": "Kasir",
            "criteria": "Bottom sheet struk tampil lengkap dengan data transaksi dan tombol unduh nota menghasilkan file PNG yang dapat dibagikan.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu transaksi berstatus Lunas di Riwayat.",
            "steps": "1. Navigasi ke tab Riwayat.\n2. Tap filter chip [Lunas].\n3. Tap kartu transaksi teratas.\n4. Di bottom sheet, tap tombol [Unduh Nota (PNG)].",
            "expected": "1. Bottom sheet 'Detail Struk Transaksi' terbuka dengan header WARMINDO JUGAJAGO dan detail item pesanan.\n2. Tombol [Unduh Nota (PNG)] menghasilkan file dan membuka dialog Share.",
            "actual": "Sesuai harapan. Struk tampil lengkap dan file PNG berhasil diunduh.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot bottom sheet struk transaksi ]",
        },
        {
            "no": 9,
            "code": "UAT-SCAN-001",
            "category": "Validasi Input — Meja Tidak Terdaftar",
            "purpose": "Memvalidasi sistem menolak nomor meja yang tidak terdaftar di database untuk mencegah pesanan tanpa meja yang valid.",
            "persona": "Kasir / Pelayan",
            "criteria": "Sistem menampilkan pesan error merah dan tidak membuka sesi pesanan pada meja fiktif.",
            "precondition": "1. Login sebagai kasir.\n2. Tab Scan QR terbuka.",
            "steps": "1. Pada tab Scan QR, tap tombol [Input Manual Nomor Meja].\n2. Masukkan nomor meja yang tidak ada (contoh: '99').\n3. Tap [Hubungkan Meja].",
            "expected": "Muncul SnackBar/notifikasi merah: 'Meja no. 99 tidak terdaftar! Hubungi Admin untuk mendaftarkan meja.' Sesi pesanan tidak dibuka.",
            "actual": "Sesuai harapan. Sistem menolak meja tidak terdaftar dengan pesan error yang jelas.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot notifikasi penolakan meja tidak terdaftar ]",
        },
        {
            "no": 10,
            "code": "UAT-SCAN-002",
            "category": "Alur Utama — Pemantauan Status Meja Realtime",
            "purpose": "Memvalidasi kasir dapat memantau status meja secara realtime dan mengosongkan meja setelah pelanggan pulang.",
            "persona": "Kasir",
            "criteria": "Status meja berubah dari 'Terisi' menjadi 'Tersedia' secara instan dan tercermin di dashboard meja semua pengguna.",
            "precondition": "1. Login sebagai kasir.\n2. Terdapat minimal satu meja berstatus Terisi.",
            "steps": "1. Buka tab Meja.\n2. Verifikasi counter 'Terisi' > 0.\n3. Tap kartu meja yang berstatus Terisi.\n4. Tap tombol hijau [Kosongkan Meja].\n5. Konfirmasi jika diminta.",
            "expected": "1. Status meja berubah menjadi 'TERSEDIA' (hijau).\n2. Counter statistik Tersedia bertambah, Terisi berkurang.\n3. Meja siap untuk pelanggan berikutnya.",
            "actual": "Sesuai harapan. Update status meja realtime berjalan dengan baik.",
            "status": "LULUS (PASS)",
            "evidence": "[ Tempel screenshot dashboard meja sebelum & sesudah dikosongkan ]",
        },
    ]


# ─── SCENARIO BLOCK ───────────────────────────────────────────────────────────
def build_scenario_block(sc, st, idx):
    """Build a full UAT scenario block as a list of flowables."""
    story = []

    # -- scenario header --
    is_pass = "LULUS" in sc["status"]
    hdr_bg = GREEN if is_pass else RED
    hdr_data = [[
        p(f"<b>#{sc['no']}  {sc['code']}</b>", ParagraphStyle("sh",
            fontName="Helvetica-Bold", fontSize=10, textColor=WHITE, leading=14)),
        p(f"<b>{sc['category']}</b>", ParagraphStyle("sc",
            fontName="Helvetica", fontSize=9, textColor=WHITE,
            alignment=TA_LEFT, leading=13)),
        p(f"<b>{sc['status']}</b>", ParagraphStyle("ss",
            fontName="Helvetica-Bold", fontSize=9,
            textColor=colors.HexColor("#FFFFFF"),
            alignment=TA_CENTER, leading=13)),
    ]]
    hdr_t = Table(hdr_data, colWidths=[4.5*cm, 9.5*cm, 3.5*cm])
    hdr_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), hdr_bg),
        ("VALIGN",     (0,0), (-1,-1), "MIDDLE"),
        ("LEFTPADDING",(0,0),(-1,-1), 8),
        ("RIGHTPADDING",(0,0),(-1,-1), 8),
        ("TOPPADDING", (0,0),(-1,-1), 6),
        ("BOTTOMPADDING",(0,0),(-1,-1), 6),
    ]))
    story.append(hdr_t)

    # -- detail table --
    fields = [
        ("Tujuan Pengujian", sc["purpose"]),
        ("Persona / Peran",  sc["persona"]),
        ("Kriteria Penerimaan", sc["criteria"]),
        ("Prasyarat",        sc["precondition"]),
        ("Langkah Pengujian", sc["steps"]),
        ("Hasil yang Diharapkan", sc["expected"]),
        ("Hasil Aktual",     sc["actual"]),
    ]
    rows = []
    for k, v in fields:
        rows.append([
            p(k, st["table_body_bold"]),
            p(v.replace("\n", "<br/>"), st["table_body"]),
        ])

    # evidence row
    rows.append([
        p("Bukti Pengujian", st["table_body_bold"]),
        p(f'<i>{sc["evidence"]}</i>', ParagraphStyle("ev",
            fontName="Helvetica-Oblique", fontSize=8, textColor=GREY_MD, leading=11)),
    ])
    # screenshot placeholder row
    rows.append([
        p("Screenshot", st["table_body_bold"]),
        p("[ Kosongkan untuk ditempelkan screenshot oleh penguji ]",
          ParagraphStyle("ph", fontName="Helvetica-Oblique", fontSize=8,
                         textColor=colors.HexColor("#BDBDBD"), leading=11)),
    ])

    # --- screenshot placeholder box ---
    ph_box = Table(
        [[p("", st["table_body"])]],
        colWidths=[12.5*cm],
        rowHeights=[5.5*cm]
    )
    ph_box.setStyle(TableStyle([
        ("BOX", (0,0),(-1,-1), 1, colors.HexColor("#BDBDBD")),
        ("BACKGROUND", (0,0),(-1,-1), GREY_LT),
    ]))

    detail_t = Table(rows, colWidths=[4.5*cm, 13*cm])
    detail_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (0,-1), GREY_LT),
        ("VALIGN",     (0,0), (-1,-1), "TOP"),
        ("GRID",       (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("LEFTPADDING",(0,0),(-1,-1), 6),
        ("RIGHTPADDING",(0,0),(-1,-1), 6),
        ("TOPPADDING", (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("ROWBACKGROUNDS", (0,0),(-1,-1), [WHITE, colors.HexColor("#FAFAFA")]),
        ("BACKGROUND", (0,0),(0,-1), GREY_LT),
    ]))
    story.append(detail_t)

    # screenshot placeholder
    story.append(spacer(4))
    ph_label = p("Area Screenshot Bukti Pengujian (tempel gambar di sini):", st["caption"])
    ph_data = [[ph_label], [ph_box]]
    ph_tbl = Table(ph_data, colWidths=[17.5*cm])
    ph_tbl.setStyle(TableStyle([
        ("ALIGN", (0,0),(-1,-1), "CENTER"),
        ("VALIGN",(0,0),(-1,-1), "MIDDLE"),
    ]))
    story.append(ph_tbl)
    story.append(spacer(10))
    story.append(hr())
    story.append(spacer(4))
    return story


# ─── SUMMARY TABLE ────────────────────────────────────────────────────────────
def build_summary_table(scenarios, st):
    headers = ["No.", "Kode UAT", "Skenario", "Kategori", "Persona", "Status"]
    rows = [headers]
    for sc in scenarios:
        is_pass = "LULUS" in sc["status"]
        rows.append([
            str(sc["no"]),
            sc["code"],
            sc["purpose"][:60] + ("..." if len(sc["purpose"]) > 60 else ""),
            sc["category"],
            sc["persona"],
            sc["status"],
        ])
    t = Table(rows, colWidths=[1*cm, 3*cm, 5*cm, 4*cm, 2*cm, 2.5*cm])
    style = [
        ("BACKGROUND", (0,0), (-1,0), RED),
        ("TEXTCOLOR",  (0,0), (-1,0), WHITE),
        ("FONTNAME",   (0,0), (-1,0), "Helvetica-Bold"),
        ("FONTSIZE",   (0,0), (-1,-1), 7.5),
        ("GRID",       (0,0), (-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("VALIGN",     (0,0), (-1,-1), "MIDDLE"),
        ("ALIGN",      (0,0), (0,-1), "CENTER"),
        ("ALIGN",      (5,0), (5,-1), "CENTER"),
        ("LEFTPADDING",(0,0),(-1,-1), 5),
        ("RIGHTPADDING",(0,0),(-1,-1), 5),
        ("TOPPADDING", (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("ROWBACKGROUNDS", (0,1),(-1,-1), [WHITE, GREY_LT]),
    ]
    for i, sc in enumerate(scenarios, start=1):
        is_pass = "LULUS" in sc["status"]
        style.append(("TEXTCOLOR", (5,i), (5,i), GREEN if is_pass else RED))
        style.append(("FONTNAME",  (5,i), (5,i), "Helvetica-Bold"))
        if is_pass:
            style.append(("BACKGROUND", (5,i), (5,i), GREEN_LT))
        else:
            style.append(("BACKGROUND", (5,i), (5,i), RED_LIGHT))
    t.setStyle(TableStyle(style))
    return t


# ─── MAIN BUILD ───────────────────────────────────────────────────────────────
def build_pdf():
    st = build_styles()
    scenarios = build_scenarios()

    doc = SimpleDocTemplate(
        OUT_PATH, pagesize=A4,
        leftMargin=40, rightMargin=40, topMargin=55, bottomMargin=50,
    )
    story = []

    # ══════════════════════════════════════════════════════════════════════════
    # PAGE 1 — COVER
    # ══════════════════════════════════════════════════════════════════════════
    cover_data = [[
        Paragraph(
            "<b>LAPORAN<br/>USER ACCEPTANCE TESTING (UAT)</b>",
            ParagraphStyle("cov_hdr", fontName="Helvetica-Bold", fontSize=24,
                           textColor=WHITE, alignment=TA_CENTER, leading=30, spaceAfter=10)
        ),
    ]]
    cover_tbl = Table(cover_data, colWidths=[17.5*cm], rowHeights=[5*cm])
    cover_tbl.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), RED),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("ALIGN",      (0,0),(-1,-1), "CENTER"),
        ("LEFTPADDING",(0,0),(-1,-1), 20),
        ("RIGHTPADDING",(0,0),(-1,-1), 20),
        ("TOPPADDING", (0,0),(-1,-1), 20),
        ("BOTTOMPADDING",(0,0),(-1,-1), 20),
    ]))
    story.append(cover_tbl)
    story.append(spacer(16))

    # App name & badge
    sub_data = [
        [p("<b>Warmindo JugaJago</b>", ParagraphStyle("an",
            fontName="Helvetica-Bold", fontSize=18, textColor=RED,
            alignment=TA_CENTER, leading=22))],
        [p("POS &amp; Table Management System", ParagraphStyle("as",
            fontName="Helvetica", fontSize=12, textColor=GREY_MD,
            alignment=TA_CENTER, leading=16))],
        [spacer(8)],
        [p("Platform: Flutter (Android) &nbsp;|&nbsp; Backend: Supabase Cloud", ParagraphStyle("ap",
            fontName="Helvetica", fontSize=10, textColor=GREY_MD,
            alignment=TA_CENTER, leading=14))],
        [p("Versi Dokumen: v1.0.0 &nbsp;|&nbsp; Tanggal: November 2026", ParagraphStyle("av",
            fontName="Helvetica", fontSize=10, textColor=GREY_MD,
            alignment=TA_CENTER, leading=14))],
    ]
    sub_t = Table(sub_data, colWidths=[17.5*cm])
    sub_t.setStyle(TableStyle([
        ("ALIGN",  (0,0),(-1,-1), "CENTER"),
        ("VALIGN", (0,0),(-1,-1), "MIDDLE"),
    ]))
    story.append(sub_t)
    story.append(spacer(20))

    # Approval table on cover
    story.append(hr())
    story.append(p("<b>Persetujuan &amp; Pengesahan</b>", ParagraphStyle("apt",
        fontName="Helvetica-Bold", fontSize=11, textColor=GREY_DK,
        alignment=TA_CENTER, spaceAfter=8)))
    approval_data = [
        [p("<b>Peran</b>", st["table_hdr"]),
         p("<b>Nama</b>", st["table_hdr"]),
         p("<b>Jabatan</b>", st["table_hdr"]),
         p("<b>Tanggal</b>", st["table_hdr"]),
         p("<b>Status</b>", st["table_hdr"])],
        [p("Lead Developer", st["table_body"]),
         p("Hisyam", st["table_body"]),
         p("Mobile Engineer", st["table_body"]),
         p("November 2026", st["table_body"]),
         p("<b>DISETUJUI</b>", ParagraphStyle("ap2", fontName="Helvetica-Bold",
             fontSize=8, textColor=GREEN, alignment=TA_CENTER))],
        [p("Dosen Penguji", st["table_body"]),
         p("—", st["table_body"]),
         p("Dosen Pengampu", st["table_body"]),
         p("——————", st["table_body"]),
         p("MENUNGGU EVALUASI", ParagraphStyle("ap3", fontName="Helvetica",
             fontSize=8, textColor=YELLOW, alignment=TA_CENTER))],
    ]
    app_t = Table(approval_data, colWidths=[3.5*cm, 3.5*cm, 3.5*cm, 3.5*cm, 3.5*cm])
    app_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,0), RED),
        ("BACKGROUND", (0,2),(-1,2), YELLOW_LT),
        ("GRID",       (0,0),(-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("ALIGN",      (0,0),(-1,-1), "CENTER"),
        ("LEFTPADDING",(0,0),(-1,-1), 5),
        ("RIGHTPADDING",(0,0),(-1,-1), 5),
        ("TOPPADDING", (0,0),(-1,-1), 5),
        ("BOTTOMPADDING",(0,0),(-1,-1), 5),
    ]))
    story.append(app_t)
    story.append(spacer(16))

    # Disclaimer on cover
    story.append(hr())
    story.append(p(
        "<i>Dokumen ini dibuat khusus untuk keperluan evaluasi akademik mata kuliah "
        "Rekayasa Perangkat Lunak / Pengembangan Aplikasi Mobile. "
        "Seluruh data akun, transaksi, dan skenario bersifat simulasi pengujian.</i>",
        ParagraphStyle("disc", fontName="Helvetica-Oblique", fontSize=8,
                       textColor=GREY_MD, alignment=TA_CENTER, leading=12)))

    story.append(PageBreak())

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 1 — INFORMASI UMUM UAT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section_heading("BAGIAN 1 — INFORMASI UMUM UAT", st))
    story.append(spacer(6))

    story.append(kv_table([
        ("Nama Aplikasi",    "Warmindo JugaJago POS &amp; Table Management System"),
        ("Platform",         "Flutter Mobile (Android APK)"),
        ("Backend",          "Supabase (PostgreSQL, Storage, Auth RLS)"),
        ("Versi Aplikasi",   "v1.0.0 — November 2026"),
        ("Tanggal Pengujian","November 2026"),
        ("Lingkungan Uji",   "Perangkat Android fisik (Redmi Note 10 Pro, Android 11) dan Emulator Android API 33"),
    ], st))
    story.append(spacer(10))

    story.append(p("<b>Tujuan Pengujian</b>", st["h2"]))
    story.append(p(
        "Memvalidasi seluruh fungsionalitas operasional kasir dan admin aplikasi Warmindo JugaJago "
        "mencakup: alur autentikasi, pemesanan menu, pembayaran Tunai/QRIS, penyimpanan pesanan pending, "
        "pelunasan dan pembatalan pesanan, manajemen meja realtime, serta cetak nota struk; "
        "agar memenuhi kebutuhan pengguna nyata di lingkungan operasional warung makan.",
    st["body"]))
    story.append(spacer(6))

    story.append(p("<b>Persona / Peran Pengguna</b>", st["h2"]))
    personas = [
        ["Peran", "Deskripsi"],
        ["Kasir",    "Melayani transaksi harian, memilih menu, memproses pembayaran Tunai/QRIS, mencetak nota struk, dan memperbarui status meja."],
        ["Admin",    "Mengelola katalog menu (tambah, edit, hapus + foto), memantau seluruh riwayat transaksi, dan mendaftarkan meja baru via QR Generator."],
        ["Pelanggan","Memesan dengan scan QR stiker meja (dine-in) atau takeaway tanpa meja terdaftar."],
    ]
    pa_t = Table(personas, colWidths=[3*cm, 14.5*cm])
    pa_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,0), RED),
        ("TEXTCOLOR",  (0,0),(-1,0), WHITE),
        ("FONTNAME",   (0,0),(-1,0), "Helvetica-Bold"),
        ("FONTSIZE",   (0,0),(-1,-1), 8.5),
        ("GRID",       (0,0),(-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("LEFTPADDING",(0,0),(-1,-1), 6),
        ("RIGHTPADDING",(0,0),(-1,-1), 6),
        ("TOPPADDING", (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("ROWBACKGROUNDS", (0,1),(-1,-1), [WHITE, GREY_LT]),
    ]))
    story.append(pa_t)
    story.append(spacer(10))

    story.append(p("<b>Kriteria Penerimaan (Acceptance Criteria)</b>", st["h2"]))
    criteria_text = (
        "1. Seluruh alur utama (Login, Katalog, Scan Meja, Checkout Tunai/QRIS, Riwayat, Cetak Nota) "
        "berjalan tanpa kendala dan berstatus LULUS (PASS).<br/>"
        "2. Seluruh validasi input (form login kosong, format email salah, nominal pembayaran kurang, "
        "meja tidak terdaftar) menampilkan feedback error yang jelas dan spesifik.<br/>"
        "3. Kondisi gagal (meja fiktif, pembatalan pesanan, stok produk dikembalikan) tertangani "
        "secara aman tanpa aplikasi crash.<br/>"
        "4. Bukti pengujian disertakan berupa screenshot layar yang sesuai dengan hasil aktual setiap skenario."
    )
    story.append(p(criteria_text, st["body"]))
    story.append(spacer(10))

    story.append(p("<b>Prasyarat Pengujian Umum</b>", st["h2"]))
    pre_text = (
        "1. Perangkat Android (fisik/emulator) telah terinstal APK Warmindo JugaJago v1.0.0.<br/>"
        "2. Koneksi internet aktif menuju server Supabase Cloud.<br/>"
        "3. Akun Admin (admin@warmindo.com) dan Akun Kasir (sudahmalam@gmail.com) siap digunakan.<br/>"
        "4. Minimal satu menu aktif tersedia di katalog dan minimal satu meja terdaftar di database."
    )
    story.append(p(pre_text, st["body"]))

    story.append(PageBreak())

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 2 — RINGKASAN TEMUAN UAT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section_heading("BAGIAN 2 — RINGKASAN TEMUAN PENGUJIAN", st))
    story.append(spacer(6))

    # summary stats
    total = len(scenarios)
    lulus = sum(1 for s in scenarios if "LULUS" in s["status"])
    gagal = total - lulus
    pct   = int(lulus / total * 100)

    stats_data = [
        [p("Total Skenario", st["table_body_bold"]),
         p("Lulus (PASS)", st["table_body_bold"]),
         p("Gagal (FAIL)", st["table_body_bold"]),
         p("Persentase Kelulusan", st["table_body_bold"])],
        [p(str(total), ParagraphStyle("sv", fontName="Helvetica-Bold", fontSize=18,
            textColor=BLUE, alignment=TA_CENTER)),
         p(str(lulus), ParagraphStyle("sv2", fontName="Helvetica-Bold", fontSize=18,
            textColor=GREEN, alignment=TA_CENTER)),
         p(str(gagal), ParagraphStyle("sv3", fontName="Helvetica-Bold", fontSize=18,
            textColor=RED if gagal > 0 else GREY_MD, alignment=TA_CENTER)),
         p(f"{pct}%", ParagraphStyle("sv4", fontName="Helvetica-Bold", fontSize=18,
            textColor=GREEN if pct >= 80 else RED, alignment=TA_CENTER))],
    ]
    stats_t = Table(stats_data, colWidths=[4.375*cm]*4)
    stats_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,0), GREY_LT),
        ("BACKGROUND", (0,1),(-1,1), WHITE),
        ("BACKGROUND", (1,1),(1,1), GREEN_LT),
        ("BACKGROUND", (3,1),(3,1), GREEN_LT if pct >= 80 else RED_LIGHT),
        ("GRID",       (0,0),(-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("ALIGN",      (0,0),(-1,-1), "CENTER"),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("TOPPADDING", (0,0),(-1,-1), 8),
        ("BOTTOMPADDING",(0,0),(-1,-1), 8),
    ]))
    story.append(stats_t)
    story.append(spacer(12))

    # Category breakdown
    story.append(p("<b>Rincian per Kategori Skenario</b>", st["h2"]))
    cats = {}
    for sc in scenarios:
        c = sc["category"].split("—")[0].strip()
        cats.setdefault(c, {"total": 0, "lulus": 0})
        cats[c]["total"] += 1
        if "LULUS" in sc["status"]:
            cats[c]["lulus"] += 1
    cat_rows = [[p("Kategori", st["table_body_bold"]),
                 p("Jumlah", st["table_body_bold"]),
                 p("Lulus", st["table_body_bold"]),
                 p("Gagal", st["table_body_bold"]),
                 p("Kesimpulan", st["table_body_bold"])]]
    for cat, v in cats.items():
        g = v["total"] - v["lulus"]
        cat_rows.append([
            p(cat, st["table_body"]),
            p(str(v["total"]), ParagraphStyle("cc", fontSize=8, alignment=TA_CENTER)),
            p(str(v["lulus"]), ParagraphStyle("cl", fontName="Helvetica-Bold",
                fontSize=8, textColor=GREEN, alignment=TA_CENTER)),
            p(str(g), ParagraphStyle("cg", fontName="Helvetica-Bold",
                fontSize=8, textColor=RED if g > 0 else GREY_MD, alignment=TA_CENTER)),
            p("LULUS SEMUA" if g == 0 else f"{g} GAGAL",
              ParagraphStyle("ccs", fontName="Helvetica-Bold", fontSize=8,
                textColor=GREEN if g == 0 else RED, alignment=TA_CENTER)),
        ])
    cat_t = Table(cat_rows, colWidths=[7*cm, 2*cm, 2*cm, 2*cm, 4.5*cm])
    cat_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,0), GREY_LT),
        ("GRID",       (0,0),(-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("VALIGN",     (0,0),(-1,-1), "MIDDLE"),
        ("LEFTPADDING",(0,0),(-1,-1), 6),
        ("RIGHTPADDING",(0,0),(-1,-1), 6),
        ("TOPPADDING", (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("ROWBACKGROUNDS", (0,1),(-1,-1), [WHITE, GREY_LT]),
    ]))
    story.append(cat_t)
    story.append(spacer(10))

    story.append(p("<b>Kesimpulan Umum</b>", st["h2"]))
    story.append(p(
        f"Berdasarkan hasil User Acceptance Testing yang dilakukan terhadap {total} skenario "
        f"pengujian, sebanyak <b>{lulus} skenario ({pct}%) dinyatakan LULUS (PASS)</b> dan "
        f"{gagal} skenario dinyatakan GAGAL (FAIL). "
        "Seluruh alur utama operasional kasir, validasi input kritis, dan penanganan kondisi gagal "
        "berjalan sesuai spesifikasi kebutuhan. Aplikasi Warmindo JugaJago dinyatakan <b>SIAP "
        "untuk penggunaan operasional</b> berdasarkan hasil UAT ini.",
    st["body"]))

    story.append(PageBreak())

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 3 — TABEL REKAPITULASI SKENARIO
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section_heading("BAGIAN 3 — REKAPITULASI SKENARIO PENGUJIAN", st))
    story.append(spacer(6))
    story.append(build_summary_table(scenarios, st))

    story.append(PageBreak())

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 4 — DETAIL SKENARIO UAT
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section_heading("BAGIAN 4 — DETAIL SKENARIO UAT & BUKTI PENGUJIAN", st))
    story.append(spacer(6))

    for idx, sc in enumerate(scenarios):
        block = build_scenario_block(sc, st, idx)
        story.extend(block)

    story.append(PageBreak())

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 5 — CATATAN & REKOMENDASI
    # ══════════════════════════════════════════════════════════════════════════
    story.append(section_heading("BAGIAN 5 — CATATAN, TEMUAN, & REKOMENDASI", st))
    story.append(spacer(6))

    story.append(p("<b>Temuan Penting Selama Pengujian</b>", st["h2"]))
    findings = [
        ["No.", "Deskripsi Temuan", "Dampak", "Tindakan"],
        ["1", "Chip teks (Tunai, QRIS, Uang Pas, +10k, +50k) pada dialog "
              "pembayaran pending awalnya tidak terlihat karena warna putih pada latar terang.",
         "Minor — UI tidak nyaman namun fungsi berjalan", "Diperbaiki: teks diubah menjadi warna gelap dengan font bold."],
        ["2", "Pengujian Maestro CLI gagal pada perangkat TECNO CM7 (Android 16) "
              "akibat restriksi SELinux port gRPC.",
         "Minor — Hanya mempengaruhi otomasi, bukan fungsional app",
         "Diakomodasi: pengujian dilanjutkan pada emulator dan perangkat Redmi Note 10 Pro."],
        ["3", "Ikon launcher aplikasi default Flutter (cupcake biru) kurang mencerminkan identitas merek.",
         "Minor — Branding", "Diperbaiki: ikon launcher diperbarui ke logo Warmindo JugaJago transparan."],
    ]
    f_t = Table(findings, colWidths=[1*cm, 6*cm, 4.5*cm, 6*cm])
    f_t.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,0), RED),
        ("TEXTCOLOR",  (0,0),(-1,0), WHITE),
        ("FONTNAME",   (0,0),(-1,0), "Helvetica-Bold"),
        ("FONTSIZE",   (0,0),(-1,-1), 8),
        ("GRID",       (0,0),(-1,-1), 0.4, colors.HexColor("#CCCCCC")),
        ("VALIGN",     (0,0),(-1,-1), "TOP"),
        ("LEFTPADDING",(0,0),(-1,-1), 5),
        ("RIGHTPADDING",(0,0),(-1,-1), 5),
        ("TOPPADDING", (0,0),(-1,-1), 4),
        ("BOTTOMPADDING",(0,0),(-1,-1), 4),
        ("ROWBACKGROUNDS", (0,1),(-1,-1), [WHITE, GREY_LT]),
    ]))
    story.append(f_t)
    story.append(spacer(10))

    story.append(p("<b>Rekomendasi Pengembangan Selanjutnya</b>", st["h2"]))
    recs = [
        "1. <b>Dukungan Offline Mode</b>: Implementasi local cache (Hive/SQLite) agar kasir dapat "
        "mencatat pesanan saat koneksi internet terputus dan sinkronisasi otomatis saat kembali online.",
        "2. <b>Notifikasi Push</b>: Tambahkan notifikasi FCM agar admin mendapatkan alert realtime "
        "ketika ada pesanan baru atau stok menu mendekati habis.",
        "3. <b>Laporan Penjualan Harian</b>: Halaman analitik kasir dengan grafik pendapatan harian, "
        "menu terlaris, dan ekspor CSV langsung dari aplikasi.",
        "4. <b>Mode Tablet / Kasir Deskop</b>: Optimasi layout responsive untuk layar tablet 10 inci "
        "yang umum digunakan sebagai terminal kasir tetap.",
    ]
    for rec in recs:
        story.append(p(rec, st["body"]))
    story.append(spacer(10))

    story.append(p("<b>Batasan Pengujian</b>", st["h2"]))
    limits = (
        "1. Verifikasi pembayaran QRIS dilakukan secara simulasi konfirmasi kasir tanpa memotong saldo "
        "e-wallet perbankan riil (QRIS merchant internal).<br/>"
        "2. Kamera fisik pada emulator tidak mendukung scan QR nyata; alur ini diuji dengan fitur "
        "input manual nomor meja.<br/>"
        "3. Pengujian otomatis Maestro dibatasi oleh restriksi SELinux pada Android 16; "
        "pengujian dilaksanakan pada emulator API 33 dan perangkat Redmi Note 10 Pro (Android 11).<br/>"
        "4. Seluruh data pengguna dan transaksi bersifat data uji (test data) dalam lingkungan Supabase "
        "project khusus pengembangan."
    )
    story.append(p(limits, st["body"]))

    story.append(spacer(16))
    story.append(hr())
    story.append(spacer(6))
    story.append(p(
        "<i>Dokumen UAT ini disusun oleh Tim Pengembang Warmindo JugaJago untuk keperluan evaluasi "
        "akademik. Seluruh skenario pengujian divalidasi menggunakan perangkat fisik Android dan "
        "suite pengujian otomatis Maestro E2E v2.x.</i>",
    ParagraphStyle("closing", fontName="Helvetica-Oblique", fontSize=8,
                   textColor=GREY_MD, alignment=TA_CENTER, leading=12)))

    # BUILD
    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"PDF berhasil dibuat: {OUT_PATH}")


if __name__ == "__main__":
    build_pdf()
