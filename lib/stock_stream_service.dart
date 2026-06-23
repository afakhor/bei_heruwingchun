import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // 🔥 TARUH API KEY TWELVE DATA MU DI SINI (Ganti teks di bawah ini)
  final String _apiKey = "6640daaab69d434abf1fc39469834748";

  Stream<List<CandleModel>> get chartStream => _controller.stream;

  void startStreaming(String ticker) {
    _timer?.cancel();

    // Ambil data pertama kali, lalu refresh setiap 15 detik biar aman dari kuota gratisan
    _fetchTwelveData(ticker);
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchTwelveData(ticker);
    });
  }

  Future<void> _fetchTwelveData(String ticker) async {
    String cleanTicker = ticker.toUpperCase().trim();
    
    // Format Twelve Data untuk Bursa Efek Indonesia wajib pakai akhiran :IDX
    String symbol = cleanTicker.endsWith(':IDX') ? cleanTicker : '$cleanTicker:IDX';

    // Ambil interval 1 menit dengan total 30 candle terakhir
    final url = Uri.parse(
      'https://api.twelvedata.com/time_series?symbol=$symbol&interval=1min&outputsize=30&apikey=$_apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Proteksi jika API Key salah atau limit habis
        if (data['status'] != 'ok') {
          print("Twelve Data Error: ${data['message']}");
          return;
        }

        final List<dynamic> values = data['values'] ?? [];
        List<CandleModel> loadedCandles = [];

        // ⚠️ PENTING: Twelve Data mengirim data terbaru di indeks 0 (terbalik).
        // Kita balik (.reversed) supaya urutannya pas di chart dari kiri (lampau) ke kanan (terbaru).
        for (var item in values.reversed) {
          loadedCandles.add(CandleModel(
            open: double.parse(item['open'].toString()),
            high: double.parse(item['high'].toString()),
            low: double.parse(item['low'].toString()),
            close: double.parse(item['close'].toString()),
            volume: double.parse(item['volume'].toString()),
          ));
        }

        if (!_controller.isClosed && loadedCandles.isNotEmpty) {
          _controller.add(loadedCandles);
        }
      }
    } catch (e) {
      print("Koneksi Twelve Data Bermasalah: $e");
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
