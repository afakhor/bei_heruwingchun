import 'dart:ffi';
import 'dart:io';

// 1. Definisikan Struct FFI (Urutan wajib sama persis dengan struct di C++)
final class SignalResult extends Struct {
  @Int32()
  external int score; // Menghubungkan ke int32_t score

  @Int32()
  external int action; // Menghubungkan ke int32_t action

  @Double()
  external double stopLoss; // OTOMATIS membaca memory stop_loss milik C++

  @Double()
  external double takeProfit; // OTOMATIS membaca memory take_profit milik C++
}

// 2. Tanda tangan fungsi untuk sisi Native C++
typedef EvaluateStockSignalNative = SignalResult Function(
  Double close,
  Double ema5,
  Double ema20,
  Double ema200,
  Double rsi,
  Double vwap,
  Double adx,
  Double atr,
);

// 3. Tanda tangan fungsi untuk sisi Dart
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
  late final DynamicLibrary _dylib;
  late final EvaluateStockSignalDart _evaluateStockSignal;

  FinanceEngineBridge() {
    // Membuka library binary C++ di Android (.so)
    if (Platform.isAndroid) {
      _dylib = DynamicLibrary.open('libfinance_engine.so');
    } else {
      _dylib = DynamicLibrary.process();
    }

    // 4. Hubungkan ke nama fungsi asli C++ kamu: 'evaluate_stock_signal'
    _evaluateStockSignal = _dylib
        .lookupFunction<EvaluateStockSignalNative, EvaluateStockSignalDart>(
          'evaluate_stock_signal',
        );
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
    // Mengembalikan data matang hasil kalkulasi C++ langsung ke UI
    return _evaluateStockSignal(close, ema5, ema20, ema200, rsi, vwap, adx, atr);
  }
}

// ====================================================================
// 🔥 TARUH DI SINI, BOSSKU! (Fungsi luar Class / Top-Level Function)
// ====================================================================
/// Fungsi ini dirancang khusus untuk berjalan di Isolate terpisah via `compute()`.
/// Menerima List Map mentah dari server, memfilternya pakai C++, dan mengembalikan data yang lolos screening.
List<Map<String, dynamic>> cPlusPlusBulkScreening(List<Map<String, dynamic>> rawStocks) {
  // Inisialisasi bridge baru di dalam Isolate ini
  final bridge = FinanceEngineBridge();
  List<Map<String, dynamic>> buySignals = [];

  for (var stock in rawStocks) {
    try {
      // Hitung sinyal via FFI C++ secara estafet
      final result = bridge.checkStockSignal(
        close: (stock['close'] as num).toDouble(),
        ema5: (stock['ema5'] as num).toDouble(),
        ema20: (stock['ema20'] as num).toDouble(),
        ema200: (stock['ema200'] as num).toDouble(),
        rsi: (stock['rsi'] as num).toDouble(),
        vwap: (stock['vwap'] as num).toDouble(),
        adx: (stock['adx'] as num).toDouble(),
        atr: (stock['atr'] as num).toDouble(),
      );

      // Hanya masukkan saham yang menghasilkan sinyal BUY (1) menurut C++
      if (result.action == 1) {
        // Gandakan map asli dan suntikkan data kalkulasi dari mesin C++
        final Map<String, dynamic> verifiedStock = Map.from(stock);
        verifiedStock['score'] = result.score;
        verifiedStock['action'] = result.action;
        verifiedStock['stop_loss'] = result.stopLoss;
        verifiedStock['take_profit'] = result.takeProfit;

        buySignals.add(verifiedStock);
      }
    } catch (e) {
      // Jika ada satu emiten bermasalah datanya, skip ke saham berikutnya
      continue;
    }
  }

  return buySignals;
}