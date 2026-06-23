import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'stock_stream_service.dart'; // import model candlenya

class StockStreamService {
  final StreamController<List<CandleModel>> _controller = StreamController<List<CandleModel>>.broadcast();
  Timer? _timer;

  Stream<List<CandleModel>> get chartStream => _controller.stream;

  void startStreaming(String ticker) {
    _timer?.cancel();

    // Jalankan pemanggilan data pertama kali, lalu ulangi setiap 10 detik (biar hemat kuota & gak di-ban Yahoo)
    _fetchRealData(ticker);
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchRealData(ticker);
    });
  }

  Future<void> _fetchRealData(String ticker) async {
    String cleanTicker = ticker.toUpperCase().trim();
    // Tambahkan .JK jika belum ada untuk menandakan bursa Indonesia IDX
    String yahooTicker = cleanTicker.endsWith('.JK') ? cleanTicker : '$cleanTicker.JK';

    // Link API Publik Yahoo Finance untuk mengambil data chart intraday (interval 1 menit, range 1 hari)
    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$yahooTicker?interval=1m&range=1d');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['chart']['result'][0];
        final indicators = result['indicators']['quote'][0];
        final timestamps = result['timestamp'] as List<dynamic>;

        final List<double> opens = List<double>.from(indicators['open']);
        final List<double> highs = List<double>.from(indicators['high']);
        final List<double> lows = List<double>.from(indicators['low']);
        final List<double> closes = List<double>.from(indicators['close']);
        final List<double> volumes = List<double>.from(indicators['volume']);

        List<CandleModel> loadedCandles = [];

        // Konversi data dari Yahoo menjadi bentuk CandleModel milikmu
        for (int i = 0; i < timestamps.length; i++) {
          // Skip data jika ada komponen yang null dari server
          if (opens[i] == null || closes[i] == null) continue; 

          loadedCandles.add(CandleModel(
            open: opens[i],
            high: highs[i],
            low: lows[i],
            close: closes[i],
            volume: volumes[i],
          ));
        }

        // Ambil maksimal 30 candle terakhir agar pas dengan ukuran chart HP kamu
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