import 'dart:ffi';
import 'dart:io';

// 1. Definisikan Struct di Dart yang strukturnya HARUS PERSIS sama dengan C++
final class SignalResult extends Struct {
  @Int32()
  external int score; // Total skor (0 - 100)

  @Int32()
  external int action; // 1 = BUY, 0 = HOLD, -1 = AVOID

  @Double()
  external double stopLoss; // Batas Cut Loss berbasis ATR

  @Double()
  external double takeProfit; // Target Profit berbasis ATR
}

// 2. Definisikan tipe fungsi (Signature) untuk kebutuhan FFI
// Tipe tanda tangan C++ (Menggunakan tipe data ffi Dart)
typedef EvaluateStockSignalC = SignalResult Function(
  Double close,
  Double ema5,
  Double ema20,
  Double ema200,
  Double rsi,
  Double vwap,
  Double adx,
  Double atr,
);

// Tipe tanda tangan Dart (Tipe data primitif Dart standar)
typedef EvaluateStockSignalDart = SignalResult Function(
  double close,
  double ema5,
  double ema20,
  double ema200,
  double rsi,
  double vwap,
  double adx,
  double atr,
);

class FinanceEngineBridge {
  late DynamicLibrary _nativeLib;
  late EvaluateStockSignalDart _evaluateStockSignal;

  FinanceEngineBridge() {
    // 3. Load Library C++ (.so) saat aplikasi berjalan di Android
    if (Platform.isAndroid) {
      // Nama 'libfinance_engine.so' otomatis digenerate oleh CMake yang kita daftarkan kemarin
      _nativeLib = DynamicLibrary.open('libfinance_engine.so');
    } else {
      // Fail-safe jika dicoba di platform lain saat development
      _nativeLib = DynamicLibrary.process();
    }

    // 4. Hubungkan fungsi Dart ke fungsi C++ asli
    _evaluateStockSignal = _nativeLib
        .lookup<NativeFunction<EvaluateStockSignalC>>('evaluate_stock_signal')
        .asFunction<EvaluateStockSignalDart>();
  }

  // 5. Fungsi bersih yang siap dipanggil dari UI Flutter kamu
  SignalResult checkStockSignal({
    required double close,
    required double ema5,
    required double ema20,
    required double ema200,
    required double rsi,
    required double vwap,
    required double adx,
    required double atr,
  }) {
    // Tinggal panggil, hitungan milidetik selesai di level C++
    return _evaluateStockSignal(close, ema5, ema20, ema200, rsi, vwap, adx, atr);
  }
}
