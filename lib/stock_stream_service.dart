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

  void startStreaming(String ticker) {
    _timer?.cancel();
    _history.clear();

    final random = Random();
    String cleanTicker = ticker.toUpperCase().trim();
    
    // ALGORITMA PINTAR: Bikin harga awal otomatis berdasarkan text kode saham
    // Jadi kalau ketik BMRI harganya akan selalu berkisar di area yang sama
    int codeSum = cleanTicker.runes.fold(0, (sum, rune) => sum + rune);
    double lastClose = ((codeSum * 7) % 8000) + 50.0; // Rentang Rp50 s/d Rp8050

    // Override khusus untuk saham-saham jangkar biar presisi
    if (cleanTicker == 'BBRI') lastClose = 5200.0;
    if (cleanTicker == 'GOTO') lastClose = 65.0;
    if (cleanTicker == 'BBCA') lastClose = 10100.0;

    // Buat 20 candle awal secara dinamis
    for (int i = 0; i < 20; i++) {
      double open = lastClose + (random.nextDouble() - 0.5) * (lastClose * 0.01);
      double close = open + (random.nextDouble() - 0.48) * (lastClose * 0.012);
      double high = max(open, close) + random.nextDouble() * (lastClose * 0.005);
      double low = min(open, close) - random.nextDouble() * (lastClose * 0.005);
      lastClose = close;

      _history.add(CandleModel(open: open, high: high, low: low, close: close, volume: 500));
    }
    _controller.add(_history);

    // Loop Running Trade
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_history.isEmpty) return;
      
      CandleModel lastCandle = _history.last;
      double volatility = lastCandle.close * 0.004; 
      double newClose = lastCandle.close + (random.nextDouble() - 0.48) * volatility;
      
      // Batasi agar harga tidak minus/gocap bawah jika sahamnya ambles
      if (newClose < 50) newClose = 50; 

      _history[_history.length - 1] = CandleModel(
        open: lastCandle.open,
        high: max(lastCandle.high, newClose),
        low: min(lastCandle.low, newClose),
        close: newClose,
        volume: lastCandle.volume + 15,
      );

      if (timer.tick % 10 == 0) {
        _history.add(CandleModel(open: newClose, high: newClose, low: newClose, close: newClose, volume: 0));
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