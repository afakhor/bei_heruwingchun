import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 🔥 KITA KEMBALIKAN KELAS INI YANG KEMARIN TERHAPUS!
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
  Timer? _timer;

  Stream<List<CandleModel>> get chartStream => _controller.stream;

  void startStreaming(String ticker) {
    _timer?.cancel();

    // Jalankan pemanggilan data pertama kali, lalu ulangi setiap 10 detik
    _fetchRealData(ticker);
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRealData(ticker);
    });
  }

  Future<void> _fetchRealData(String ticker) async {
    String cleanTicker = ticker.toUpperCase().trim();
    String yahooTicker = cleanTicker.endsWith('.JK') ? cleanTicker : '$cleanTicker.JK';

    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$yahooTicker?interval=1m&range=1d');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Proteksi jika data dari server Yahoo kosong
        if (data['chart']['result'] == null) return;

        final result = data['chart']['result'][0];
        final indicators = result['indicators']['quote'][0];
        final timestamps = result['timestamp'] as List<dynamic>?;

        if (timestamps == null) return;

        final List<dynamic> opens = indicators['open'] ?? [];
        final List<dynamic> highs = indicators['high'] ?? [];
        final List<dynamic> lows = indicators['low'] ?? [];
        final List<dynamic> closes = indicators['close'] ?? [];
        final List<dynamic> volumes = indicators['volume'] ?? [];

        List<CandleModel> loadedCandles = [];

        // Konversi data dari Yahoo menjadi bentuk CandleModel secara aman
        for (int i = 0; i < timestamps.length; i++) {
          if (opens[i] == null || highs[i] == null || lows[i] == null || closes[i] == null) {
            continue; 
          }

          loadedCandles.add(CandleModel(
            open: (opens[i] as num).toDouble(),
            high: (highs[i] as num).toDouble(),
            low: (lows[i] as num).toDouble(),
            close: (closes[i] as num).toDouble(),
            volume: volumes[i] != null ? (volumes[i] as num).toDouble() : 0.0,
          ));
        }

        // Ambil maksimal 30 candle terakhir agar pas dengan ukuran chart HP
        if (loadedCandles.length > 30) {
          loadedCandles = loadedCandles.sublist(loadedCandles.length - 30);
        }

        if (!_controller.isClosed) {
          _controller.add(loadedCandles);
        }
      }
    } catch (e) {
      print("Error ambil data bursa asli: $e");
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}