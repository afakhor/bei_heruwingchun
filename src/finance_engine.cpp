#include <cstdint>
#include <algorithm>

// Struct bawaan aslimu, tetap menggunakan int32_t dan snake_case agar sinkron dengan Dart FFI
struct SignalResult {
    int32_t score;       // Total skor akhir (0 - 100)
    int32_t action;      // 1 = BUY, 0 = HOLD/WAIT, -1 = AVOID/SELL
    double stop_loss;    // Batas Cut Loss otomatis berbasis ATR
    double take_profit;  // Target Take Profit otomatis berbasis ATR
};

extern "C" {
    // Menjaga nama fungsi asli sesuai cetakan bridge Dart kamu
    __attribute__((visibility("default"))) __attribute__((used))
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
        if (close <= ema200) {
            result.score = 0;
            result.action = -1; // Sinyal mutlak: BAHAYA / HINDARI
            return result;
        }
        result.score += 20; // Bonus 20 poin karena berada di jalur uptrend besar

        // =================================================================
        // PARAMETER 2: MOMENTUM SHORT-TERM (EMA 5 & EMA 20)
        // =================================================================
        if (ema5 > ema20 && close > ema5) {
            result.score += 15;
        }

        // =================================================================
        // PARAMETER 3: VALIDASI AKUMULASI (VWAP)
        // =================================================================
        if (close > vwap) {
            result.score += 25;
        }

        // =================================================================
        // PARAMETER 4: RUMUS ADAPTIF SCALPING (RSI 14)
        // =================================================================
        if (rsi >= 30 && rsi <= 45) {
            result.score += 20; // Golden area untuk akumulasi scalping
        } else if (rsi > 45 && rsi <= 65) {
            result.score += 10; // Mengikuti momentum naik
        } else if (rsi > 70) {
            result.score -= 15; // Mencegah HAKA di pucuk jenuh beli
        }

        // =================================================================
        // PARAMETER 5: MESIN ACCELERATOR (ADX)
        // =================================================================
        if (adx > 25) {
            result.score += 20;
        }

        // =================================================================
        // KEPUTUSAN AKHIR & RUMUS VOLATILITAS ASLI (ATR)
        // =================================================================
        // Eksekusi BUY jika skor >= 70 dan tren ADX meyakinkan di atas 20
        if (result.score >= 70 && adx > 20.0) {
            result.action = 1; // 🟢 ACTION: BUY
            result.stop_loss = close - (2.0 * atr); // Stop Loss aman dari gocekan
            result.take_profit = close + (3.0 * atr); // Target TP rasional 1:1.5 dari nafas market
        } else {
            result.action = 0; // ⚪ ACTION: HOLD / WAIT
            result.stop_loss = 0.0;
            result.take_profit = 0.0;
        }

        return result;
    }
}