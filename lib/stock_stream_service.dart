import 'dart:async';
import 'dart:math';

class CandleModel {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleModel({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockStreamService {
  final StreamController<List<CandleModel>> _controller = StreamController<List<CandleModel>>.broadcast();
  List<CandleModel> _history = [];
  Timer? _timer;

  Stream<List<CandleModel>> get chartStream => _controller.stream;

  void startStreaming() {
    final random = Random();
    double lastClose = 5200.0;

    // 1. Buat 20 candle pertama sebagai data awal (Pre-load)
    for (int i = 0; i < 20; i++) {
      double open = lastClose + (random.nextDouble() - 0.5) * 40;
      double close = open + (random.nextDouble() - 0.48) * 50;
      double high = max(open, close) + random.nextDouble() * 20;
      double low = min(open, close) - random.nextDouble() * 20;
      lastClose = close;

      _history.add(CandleModel(open: open, high: high, low: low, close: close, volume: 500));
    }
    _controller.add(_history);

    // 2. Setiap 1 detik, update candle terakhir atau buat candle baru
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Ambil candle paling ujung
      CandleModel lastCandle = _history.last;
      
      // Simulasikan harga bergerak (update harga close, high, dan low)
      double newClose = lastCandle.close + (random.nextDouble() - 0.48) * 30;
      double newHigh = max(lastCandle.high, newClose);
      double newLow = min(lastCandle.low, newClose);

      // Update candle terakhir di dalam list
      _history[_history.length - 1] = CandleModel(
        open: lastCandle.open,
        high: newHigh,
        low: newLow,
        close: newClose,
        volume: lastCandle.volume + 10,
      );

      // Setiap 10 detik, kunci candle tersebut dan buat lilin baru (Bar baru terbentuk)
      if (timer.tick % 10 == 0) {
        _history.add(CandleModel(
          open: newClose,
          high: newClose,
          low: newClose,
          close: newClose,
          volume: 0,
        ));
        // Batasi histori hanya 30 candle di layar biar HP ramah memori
        if (_history.length > 30) _history.removeAt(0);
      }

      if (!_controller.isClosed) {
        _controller.add(List.from(_history));
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
