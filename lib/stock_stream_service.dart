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

  Stream<List<CandleModel>> get chartStream => _controller.stream;

  // 💡 BARU: startStreaming sekarang menerima apiKey dinamis dari Control Panel UI-mu
  void startStreaming(String ticker, String apiKey) {
    _timer?.cancel();

    _fetchTwelveData(ticker, apiKey);
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchTwelveData(ticker, apiKey);
    });
  }

  Future<void> _fetchTwelveData(String ticker, String apiKey) async {
    String cleanTicker = ticker.toUpperCase().trim();

    // 🚨 PERBAIKAN 1: Gunakan ticker asli yang kamu ketik tanpa memaksa akhiran :IDX
    // (Biar kalau ketik AAPL tidak berubah jadi AAPL:IDX yang bikin server bingung)
    String symbol = cleanTicker; 

    final url = Uri.parse(
      'https://api.twelvedata.com/time_series?symbol=$symbol&interval=1min&outputsize=30&apikey=$apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🚨 PERBAIKAN 2: Jika API bermasalah, kirim pesan error-nya ke UI agar loading berhenti!
        if (data['status'] != 'ok') {
          print("Twelve Data Error: ${data['message']}");
          _controller.addError(data['message'] ?? "Terjadi kesalahan API Twelve Data.");
          return;
        }

        final List<dynamic> values = data['values'] ?? [];
        List<CandleModel> loadedCandles = [];

        for (var item in values.reversed) {
          loadedCandles.add(CandleModel(
            // Menggunakan double.tryParse agar super aman dari error tipe data String JSON
            open: double.tryParse(item['open'].toString()) ?? 0.0,
            high: double.tryParse(item['high'].toString()) ?? 0.0,
            low: double.tryParse(item['low'].toString()) ?? 0.0,
            close: double.tryParse(item['close'].toString()) ?? 0.0,
            volume: double.tryParse(item['volume'].toString()) ?? 0.0,
          ));
        }

        if (!_controller.isClosed && loadedCandles.isNotEmpty) {
          _controller.add(loadedCandles);
        }
      } else {
        _controller.addError("Server merespon dengan status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Koneksi Twelve Data Bermasalah: $e");
      // 🚨 PERBAIKAN 3: Kirim error crash/koneksi internet ke UI
      _controller.addError("Koneksi internet bermasalah atau API terblokir.");
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}