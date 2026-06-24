import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 📊 MODEL CANDLE UTAMA (Wajib ada di sini agar main.dart & chart tidak eror)
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

  // 🚀 FUNGSI SUDAH DIUPGRADE: Menerima baseUrl dinamis dari inputan UI HP kamu
  void startStreaming(String ticker, String apiKey, String baseUrl) async {
    
    // Bersihkan spasi. Jika inputan di HP kosong, otomatis pakai default ohlc.dev
    String cleanUrl = baseUrl.trim();
    if (cleanUrl.isEmpty) {
      cleanUrl = 'https://api.ohlc.dev/v1/idx/stocks';
    }
    
    // Jalur endpoint gabungan dari inputan situs di layar HP kamu
    final url = Uri.parse('$cleanUrl/${ticker.toUpperCase()}/candles?api_key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> dataHasil = jsonDecode(response.body);
        List<CandleModel> loadedCandles = [];

        for (var item in dataHasil) {
          DateTime parsedDate = DateTime.parse(item['date'] ?? item['time'] ?? DateTime.now().toString());

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
        _chartStreamController.addError("Gagal memuat data. Status: ${response.statusCode}");
      }
    } catch (e) {
      _chartStreamController.addError("Eror koneksi ke server: $e");
    }
  }

  // 🏢 FUNGSI AMBIL DATA SEKTOR (Juga mendukung URL dinamis)
  static Future<Map<String, dynamic>> fetchStockSector(String ticker, String apiKey, String baseUrl) async {
    String cleanUrl = baseUrl.trim();
    if (cleanUrl.isEmpty) {
      cleanUrl = 'https://api.ohlc.dev/v1/idx/stocks';
    }
    final url = Uri.parse('$cleanUrl/${ticker.toUpperCase()}?api_key=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'sector': data['sector'] ?? 'Tidak Diketahui',
          'industry': data['industry'] ?? 'Tidak Diketahui',
          'name': data['name'] ?? 'Nama Perusahaan',
        };
      }
    } catch (e) {
      print("Gagal ambil data sektor: $e");
    }
    return {'sector': '-', 'industry': '-', 'name': '-'};
  }

  void dispose() {
    _chartStreamController.close();
  }
}