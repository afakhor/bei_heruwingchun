#include <cstdint>
#include <algorithm>

// Struct khusus untuk mengembalikan data matang ke Flutter via Dart FFI
struct SignalResult {
    int32_t score;       // Total skor akhir (0 - 100)
    int32_t action;      // 1 = BUY, 0 = HOLD/WAIT, -1 = AVOID/SELL
    double stop_loss;    // Batas Cut Loss otomatis berbasis ATR
    double take_profit;   // Target Take Profit otomatis berbasis ATR
};

extern "C" {
    // Fungsi utama penyaring saham yang akan dipanggil oleh Flutter secara real-time
    SignalResult evaluate_stock_signal(
        double close, 
        double ema5, 
        double ema20, 
        double ema200, 
        double rsi, 
        double vwap, 
        double adx, 
        double atr
    ) {
        SignalResult result = {0, 0, 0.0, 0.0};
        
        // =================================================================
        // PARAMETER 1: FILTER TREN UTAMA (EMA 200) - Penyelamat Porto
        // =================================================================
        // Aturan baku: Haram hukumnya beli saham yang harganya di bawah EMA 200.
        // Ini taktik nomor satu untuk menghindari "menangkap pisau jatuh".
        if (close <= ema200) {
            result.score = 0;
            result.action = -1; // Sinyal mutlak: BAHAYA / HINDARI
            return result;
        }
        result.score += 20; // Bonus 20 poin karena saham berada di jalur uptrend besar

        // =================================================================
        // PARAMETER 2: STRUKTUR DATA TRADING (EMA 5 & EMA 20)
        // =================================================================
        // Mendeteksi momentum jangka pendek (Golden Cross)
        if (ema5 > ema20) {
            result.score += 15;
        }

        // =================================================================
        // PARAMETER 3: VALIDASI AKUMULASI (VWAP)
        // =================================================================
        // Jika harga saat ini di atas VWAP, artinya market maker / institusi
        // sedang menjaga harga di atas harga rata-rata modal mereka hari ini.
        if (close > vwap) {
            result.score += 25;
        }

        // =================================================================
        // PARAMETER 4: ANTIDOTE FOMO (RSI 14)
        // =================================================================
        // Kita hanya mau beli di area tenang (30 - 60).
        // Jika RSI > 70, artinya pasar sudah terlalu serakah (Overbought). Jangan masuk!
        if (rsi >= 30 && rsi <= 60) {
            result.score += 20;
        } else if (rsi > 70) {
            result.score -= 15; // Potong poin secara agresif untuk mencegah kamu HAKA di pucuk
        }

        // =================================================================
        // PARAMETER 5: MESIN ACCELERATOR (ADX)
        // =================================================================
        // Memastikan saham beneran punya "tenaga" untuk naik (ADX > 25).
        // Kalau ADX kecil, artinya saham sideway. Duitmu bakal mandek lama di sana.
        if (adx > 25) {
            result.score += 20;
        }

        // =================================================================
        // KEPUTUSAN AKHIR & RUMUS THE RISK SHIELD
        // =================================================================
        // Saham wajib mengumpulkan minimal 70 poin untuk mendapatkan label "BUY"
        if (result.score >= 70) {
            result.action = 1; // SIGNED: REKOMENDASI BUY
            
            // Pasang tameng pengaman menggunakan indikator volatilitas ATR
            // Stop Loss (SL) diletakkan 2x dari nafas volatilitas normal agar tidak mudah terkena gocekan
            result.stop_loss = close - (2.0 * atr);
            
            // Take Profit (TP) dipasang rasional pada 3x nilai ATR (Risk to Reward Ratio 1 : 1.5)
            result.take_profit = close + (3.0 * atr);
        } else {
            result.action = 0; // SIGNED: HOLD / Pantau saja dulu di dalam watchlist
            result.stop_loss = 0.0;
            result.take_profit = 0.0;
        }

        return result;
    }
}
