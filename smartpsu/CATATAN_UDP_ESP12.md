# Catatan Evaluasi & Solusi: Masalah HP Panas (Koneksi UDP ke ESP12)

## 1. Analisis Akar Masalah (Mengapa HP Menjadi Panas)
Koneksi UDP sangat ringan dan stabil untuk ESP12 / ESP8266, namun membuat HP panas akibat:

1. **Flood Paket UDP (Streaming Tanpa Throttle)**
   - ESP12 mengirimkan paket telemetri (ADC voltase/arus) terlalu rapat (tiap 10–50 ms).
   - Flutter menerima puluhan hingga ratusan paket per detik secara non-stop.

2. **Over-Rebuild pada UI (Render Overhead)**
   - Setiap paket masuk langsung memicu `setState()`.
   - Layar dipaksa re-render berkali-kali per detik hingga GPU/CPU bekerja 100%, memicu lonjakan suhu baterai & SoC.

3. **Alokasi Memori & JSON Parsing Konstan**
   - Serialisasi string JSON ribuan kali per menit membebani memori dan membuat Android Garbage Collector (GC) terus bekerja.

---

## 2. Kebutuhan Khusus Servis HP (High-Frequency Sampling)
Untuk analisis servis HP (deteksi short circuit, leakage current, power sequence, clocking pulse), **kecepatan sampling arus (mA / uA) TIDAK BOLEH dikurangi**. Solusinya adalah mengubah cara pengolahan dan penggambaran di Flutter:

1. **Oscilloscope/Ring Buffer Architecture (Zero-Alloc Array)**
   - UDP socket membaca data masuk secepat mungkin (misal 50–200 Hz).
   - Data langsung dimasukkan ke `Float32List` (Ring Buffer / Circular Buffer) tanpa alokasi memori baru, sehingga Android Garbage Collector tidak pernah terpicu.

2. **CustomPainter + RepaintBoundary (Hardware Accelerated Canvas)**
   - Grafik arus digambar langsung menggunakan `CustomPainter` murni di atas layer GPU khusus (`RepaintBoundary`).
   - Widget teks angka dan tombol menu **terisolasi total**, tidak pernah me-render ulang saat grafik bergerak.

3. **Batching Paket UDP dari ESP12**
   - Di ESP12: Kumpulkan 5–10 sample pembacaan ADC ke dalam 1 paket UDP tunggal sebelum dikirim via WiFi.
   - Contoh: 1 paket UDP berisi array `[12.5, 12.8, 14.1, 13.9, 15.0]` alih-alih mengirim 5 kali paket UDP terpisah.
   - Dampak: Overhead header jaringan WiFi berkurang 80%, radio WiFi HP tidak bekerja 100% terus-menerus, suhu HP tetap dingin, namun detail gelombang arus tetap utuh dan sangat presisi.

---

## 3. Spesifikasi Sensor Hardware: INA3221 (Triple-Channel I2C Sensor)
- **Komponen**: INA3221 (3 Channel Current & Bus Voltage Monitor).
- **Keunggulan untuk Servis HP**:
  - Memiliki 3 Channel independen (Bisa untuk VBUS/VCC Utama, Jalur VDD/BATT, dan Jalur USB/Secondary).
  - Waktu konversi (Conversion Time) I2C bisa diatur hingga **140 µs** per channel untuk tangkapan pulsa arus super cepat (leakage / short pulse).
  - Pembacaan tegangan bus hingga 26V dengan resolusi shunt voltage yang sangat presisi untuk deteksi kebocoran arus skala mikro/miliampere.
- **Strategi Pengiriman Data dari ESP12 ke App**:
  - ESP12 membaca register Shunt Voltage & Bus Voltage via I2C (Wire library).
  - Format paket UDP dikirim dalam byte biner langsung (misal: 6 byte per pembacaan: 2 byte Ch1 Current, 2 byte Bus Voltage, 2 byte Status/Ch2) atau batch array biner untuk meminimalkan beban CPU ponsel.
