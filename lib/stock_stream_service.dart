import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CandleModel {
  final DateTime timestamp;
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleModel({
    required this.timestamp,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockStreamService {
  final StreamController<List<CandleModel>> _chartStreamController = 
      StreamController<List<CandleModel>>.broadcast();

  Timer? _pollingTimer; // Mesin penggerak live update (polling)

  Stream<List<CandleModel>> get chartStream => _chartStreamController.stream;

  void startStreaming(String ticker, String apiKey, String baseUrl, {String timeframe = 'month'}) async {
    // 🛡️ Bersihkan timer lama jika user mengganti emiten (pindah saham)
    _pollingTimer?.cancel();

    String cleanUrl = baseUrl.trim();
    String targetTicker = ticker.trim().toUpperCase();

    if (targetTicker.isEmpty) targetTicker = 'BBRI';

    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    // 📥 FUNGSI INTERNAL UNTUK TEMBAK API
    Future<void> fetchCandlesCore() async {
      try {
        final url = Uri.parse('$cleanUrl/api/candles/$targetTicker?tf=$timeframe');

        // 🔥 OPSI A: Mengirim API Key secara aman via HTTP Headers
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey', // Standar token Bearer
            // Jika di Flask kamu memakai custom header, bisa ganti jadi: 'X-API-KEY': apiKey
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          final List<dynamic> dataHasil = jsonResponse['candles'];

          List<CandleModel> loadedCandles = [];

          for (var item in dataHasil) {
            DateTime parsedDate = DateTime.parse(item['date']);

            loadedCandles.add(CandleModel(
              timestamp: parsedDate,
              date: parsedDate,
              open: (item['open'] as num).toDouble(),
              high: (item['high'] as num).toDouble(),
              low: (item['low'] as num).toDouble(),
              close: (item['close'] as num).toDouble(),
              volume: (item['volume'] as num).toDouble(),
            ));
          }

          if (!_chartStreamController.isClosed) {
            _chartStreamController.add(loadedCandles); // Alirkan data baru ke UI
          }
        } else {
          final errorJson = jsonDecode(response.body);
          _chartStreamController.addError("Server Python: ${errorJson['error'] ?? 'Gagal memuat data'}");
        }
      } catch (e) {
        _chartStreamController.addError("Gagal terhubung ke server Python: $e");
      }
    }

    // 1. Jalankan tembakan pertama langsung saat fungsi dipanggil
    await fetchCandlesCore();

    // 2. NYALAKAN POMPA DATA: Ambil data otomatis setiap 3 detik
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await fetchCandlesCore();
    });
  }

  // Fungsi untuk mematikan pompa data saat user keluar dari mode live trading
  void stopStreaming() {
    _pollingTimer?.cancel();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _chartStreamController.close();
  }
}