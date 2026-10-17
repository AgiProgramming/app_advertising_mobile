---
version: alpha
name: Mann Plus Payroll
description: >-
  Aplikasi mobile penggajian karyawan Bengkel Mann Plus Advertising. Turunan
  langsung dari design language aplikasi web Laravel yang sudah dipakai
  (indigo-600 + slate, kartu putih ber-border, label uppercase kecil, slip
  bergaya struk). Padat, tenang, dan angka-sentris — bukan dekoratif.
colors:
  primary: "#4F46E5"
  primary-pressed: "#4338CA"
  primary-soft: "#EEF2FF"
  ink: "#0F172A"
  ink-muted: "#475569"
  muted: "#64748B"
  border: "#E2E8F0"
  border-strong: "#CBD5E1"
  surface: "#FFFFFF"
  surface-sunken: "#F8FAFC"
  canvas: "#F1F5F9"
  shell: "#0F172A"
  success: "#059669"
  success-soft: "#D1FAE5"
  warning: "#B45309"
  warning-soft: "#FEF3C7"
  danger: "#BE123C"
  danger-soft: "#FFE4E6"
typography:
  display:
    fontFamily: Instrument Sans
    fontSize: 28px
    fontWeight: 800
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  title:
    fontFamily: Instrument Sans
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "-0.01em"
  subtitle:
    fontFamily: Instrument Sans
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.35
  body:
    fontFamily: Instrument Sans
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  body-strong:
    fontFamily: Instrument Sans
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.45
  label:
    fontFamily: Instrument Sans
    fontSize: 11px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "0.06em"
  caption:
    fontFamily: Instrument Sans
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.4
  money-lg:
    fontFamily: Instrument Sans
    fontSize: 26px
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  money-md:
    fontFamily: Instrument Sans
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.2
  mono:
    fontFamily: Roboto Mono
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.6
rounded:
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  pill: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  xxl: 24px
  gutter: 16px
components:
  app-bar:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    height: 56px
  bottom-nav:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.muted}"
    height: 64px
  bottom-nav-active:
    textColor: "{colors.primary}"
    backgroundColor: "{colors.primary-soft}"
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: 16px
  stat-tile:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: 12px
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    height: 48px
    typography: "{typography.body-strong}"
  button-primary-pressed:
    backgroundColor: "{colors.primary-pressed}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    height: 48px
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    height: 44px
  input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    height: 48px
  badge-paid:
    backgroundColor: "{colors.success-soft}"
    textColor: "{colors.success}"
    rounded: "{rounded.pill}"
    padding: 4px
  badge-unpaid:
    backgroundColor: "{colors.warning-soft}"
    textColor: "{colors.warning}"
    rounded: "{rounded.pill}"
    padding: 4px
  slip-paper:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: 20px
  list-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    height: 64px
---

## Overview

Aplikasi ini dipakai **sambil berdiri di bengkel**, sering dengan satu tangan dan
sarung tangan kerja. Konsekuensinya bukan "desain yang cantik", tapi **hierarki
yang bisa dibaca dalam 2 detik**: berapa gaji bersih, sudah dibayar atau belum,
berapa sisa kasbon.

Design language diambil langsung dari aplikasi web Laravel yang sudah berjalan
(`resources/views/app.blade.php`): indigo-600 sebagai satu-satunya aksen, palet
slate untuk netral, kartu putih ber-border 1px, label kecil uppercase dengan
tracking lebar, dan slip gaji bergaya struk dengan angka monospace.

Tiga aturan yang menentukan seluruh tampilan:

1. **Indigo hanya untuk aksi dan status aktif.** Bukan untuk dekorasi, bukan
   untuk background, bukan gradien.
2. **Angka adalah tokoh utama.** Semua nominal rata kanan, memakai angka
   tabular supaya digit tidak bergeser antar baris.
3. **Satu layar, satu pertanyaan.** Beranda menjawab "gaji saya bulan ini
   berapa", daftar slip menjawab "periode mana yang belum dibayar", detail slip
   menjawab "rinciannya dari mana".

## Colors

- **Primary `#4F46E5`** — tombol utama, tab aktif, tautan. Satu-satunya warna
  yang boleh "berteriak".
- **Ink `#0F172A` / ink-muted `#475569` / muted `#64748B`** — tiga tingkat teks.
  Jangan pakai abu-abu di luar tiga ini.
- **Canvas `#F1F5F9`** — latar halaman; kartu selalu putih di atasnya, sehingga
  batas antar blok terbentuk dari kontras 1 tingkat, bukan dari bayangan tebal.
- **Shell `#0F172A`** — hanya untuk layar login dan panel gelap.
- **Success `#059669`** — "Sudah Dibayar". **Warning `#B45309`** — "Belum
  Dibayar". **Danger `#BE123C`** — hapus / gagal. Ketiganya selalu dipasangkan
  dengan latar lembutnya (`*-soft`) di dalam badge, tidak pernah sebagai teks
  polos di atas putih.

## Typography

Satu keluarga: **Instrument Sans** (sama dengan `@theme` di web). Skala kecil
dan disiplin — 11/12/14/15/20/26/28 saja.

- **label** (11px, 700, uppercase, tracking 0.06em) untuk judul kolom dan
  keterangan di atas nilai. Ini yang membuat tabel terasa "sistem", bukan app
  kasual.
- **money-lg** (26px, 800, tabular) hanya untuk gaji bersih di beranda dan
  detail slip. Nominal lain memakai **money-md**.
- **mono** (Roboto Mono 12px) khusus isi slip gaji — meniru struk, dan membuat
  kolom rupiah rata sempurna.
- Tidak ada font dekoratif, tidak ada teks gradien.

## Layout

- Grid 4pt; gutter layar **16px**; padding kartu **16px**; jarak antar kartu
  **12px**.
- Lebar konten maksimum mengikuti lebar HP (target 360–430dp), tanpa layout
  dua kolom kecuali grid statistik 2×2 di beranda Admin.
- Struktur halaman: **app bar 56px** (judul kiri, aksi kanan) → konten scroll →
  **bottom nav 64px**. Tidak ada floating action button besar; aksi utama
  diletakkan di bottom bar halaman detail.
- Tinggi target sentuh minimum **44px**; baris list **64px**.

## Elevation & Depth

Hampir tanpa bayangan. Kedalaman dibentuk oleh tiga hal, berurutan:

1. border 1px `#E2E8F0` pada setiap kartu;
2. perbedaan latar (canvas → surface);
3. satu bayangan lembut `0 1px 2px rgba(15,23,42,.06)` hanya untuk app bar dan
   bottom nav yang menempel (sticky).

Kartu tidak boleh punya bayangan besar + border sekaligus. Tidak ada
glassmorphism, tidak ada blur dekoratif.

## Shapes

- Radius: **12px** untuk input/tombol/tile, **16px** untuk kartu, **8px** untuk
  kertas slip (terasa seperti kertas, bukan gelembung), **pill** untuk badge.
- Ikon di dalam kontainer kecil bersudut 10–12px, ukuran 20px, satu warna
  (muted atau primary) — tidak ada ikon berwarna-warni.

## Components

- **app-bar** — putih, border bawah 1px, judul 20px/700, maksimal satu aksi
  teks/ikon di kanan.
- **bottom-nav** — 4 tab; tab aktif = ikon + label indigo dengan pil
  `primary-soft` di belakang ikon; tab pasif = ikon garis, label muted.
- **card** — putih, border 1px, radius 16px, padding 16px, judul 15px/600 di
  kiri atas, aksi teks 12px/600 indigo di kanan atas bila perlu.
- **stat-tile** — label 11px uppercase + nilai 16px/700 tabular; tanpa ikon
  besar, tanpa ilustrasi.
- **list-row** — 64px, judul 14px/600, subjudul 12px muted, nilai rata kanan
  16px/700 tabular, badge di bawah nilai. Dipisah garis 1px, bukan kartu
  bertumpuk.
- **badge** — pill, teks 11px/700, latar lembut. Hanya tiga varian: dibayar,
  belum dibayar, dan netral. **Dua sumbu status tidak boleh dicampur:**
  `payment_status` (uang) memakai hijau/kuning, `job_status` (pekerjaan) selalu
  netral abu-abu. Alasannya: "Selesai" bukan berarti "Sudah Dibayar", dan
  sebaliknya — kalau keduanya hijau, karyawan akan salah baca.
- **slip-paper** — putih, border 1px, radius 8px, isi mono 12px, garis putus-
  putus antar blok, total dipisah garis ganda seperti struk, QR di kanan bawah.
- **input** — 48px, radius 12px, border 1px, fokus = border indigo + ring
  `primary-soft` 3px. Label uppercase 11px di atas, bukan placeholder.
- **empty-state** — satu ikon garis 32px, satu kalimat 14px muted, satu tombol
  sekunder. Tanpa ilustrasi.

## Screens

Enam layar pertama yang akan dibangun, masing-masing dengan satu pertanyaan yang
harus terjawab dalam sekali lihat.

1. **Login** — layar gelap `shell` penuh, monogram di kiri atas, judul besar di
   bawah, form sebagai *sheet* putih dengan sudut atas 24px. Satu tombol
   indigo. Tidak ada kartu mengambang di tengah gradien.
2. **Beranda Karyawan** (*Monitor*) — sapaan + periode aktif, kartu "Gaji bersih
   bulan ini" (money-lg + badge status), tiga stat-tile (diterima / tertunda /
   sisa kasbon), lalu "Tugas aktif" dan "Slip terbaru" sebagai baris list.
3. **Daftar Slip** (*Compare*) — chip filter (Semua / Belum / Sudah), lalu baris
   per periode: bulan+tahun di kiri, nominal di kanan, badge status di bawah
   nominal. Dikelompokkan per tahun.
4. **Detail Slip** (*Inspect*) — kertas slip: identitas bengkel, nomor slip,
   periode, blok karyawan, rincian (nilai SPK → PPN 3% → nilai bersih → komisi
   → tunjangan → potongan kasbon), total gaji bersih, status, QR verifikasi, dan
   bottom bar berisi Share + PDF.
5. **Notifikasi** (*Operate*) — feed berkelompok Hari ini / Minggu ini; titik
   indigo untuk yang belum dibaca; ikon kategori dalam kotak 32px; waktu rata
   kanan. Tap → membuka slip terkait.
6. **Beranda Admin** (*Monitor*) — 4 stat-tile 2×2 (SPK, karyawan aktif, kasbon
   berjalan, slip belum dibayar), "Perlu tindakan" (slip belum dibayar, SPK
   selesai tanpa slip), dan baris aksi cepat ke form input.

## Do's and Don'ts

**Do**

- Pakai tabular numbers untuk semua nominal dan rata kanan.
- Tulis nominal lengkap `Rp 212.367,02` di slip; di kartu ringkas boleh
  `Rp 212.367` dengan keterangan "dibulatkan".
- Tampilkan status sebagai badge di dekat nominal, bukan di kolom terpisah.
- Sediakan state loading (skeleton baris), kosong, dan gagal-di-fetch di setiap
  layar list.
- Pertahankan satu aksen: indigo.

**Don't**

- Jangan pakai gradien ungu-biru, glassmorphism, atau bayangan besar.
- Jangan taruh ikon berwarna di setiap judul kartu.
- Jangan pakai hero + tiga kartu fitur di layar mana pun (ini aplikasi kerja,
  bukan landing page).
- Jangan tampilkan grafik yang tidak dipakai untuk mengambil keputusan.
- Jangan pakai emoji di UI.
- Jangan menaruh lebih dari satu tombol indigo dalam satu layar.
