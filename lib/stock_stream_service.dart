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

  Stream<List<CandleModel>> get chartStream => _chartStreamController.stream;

  void startStreaming(String ticker, String apiKey, String baseUrl) async {
    String cleanUrl = baseUrl.trim();
    String targetTicker = ticker.trim().toUpperCase();

    // 🛡️ Proteksi awal jika inputan kosong
    if (targetTicker.isEmpty) targetTicker = 'BBRI';
    
    // Potong garis miring '/' di ujung URL jika ada, biar tidak double slash
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    try {
      // 🔗 Hubungkan ke Server Python Proxy milikmu
      // Jalur akhir akan menjadi: https://link-python-kamu.com/v1/idx/BBRI/candles
          final url = Uri.parse('$cleanUrl/$targetTicker/candles');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      // 🔥 UBAH DI SINI: Dekode sebagai Map dulu, lalu ambil isi kotak "candles"
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataHasil = jsonResponse['candles']; // 👈 Pipa data dialihkan ke sini
      
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
          _chartStreamController.add(loadedCandles);
        }
      } else {
        // Jika server Python mengirimkan eror (misal ticker salah)
        final errorJson = jsonDecode(response.body);
        _chartStreamController.addError("Server Python: ${errorJson['error'] ?? 'Gagal memuat data'}");
      }
    } catch (e) {
      _chartStreamController.addError("Gagal terhubung ke server Python: $e");
    }
  }

  void dispose() {
    _chartStreamController.close();
  }
}