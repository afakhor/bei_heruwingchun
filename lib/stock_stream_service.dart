import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 📊 MODEL CANDLE UTAMA (Disamakan dengan kebutuhan candlestick_chart.dart)
class CandleModel {
  final DateTime timestamp; // Sesuai kebutuhan stream lama
  final DateTime date;      // Sesuai kebutuhan GoAPI
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

// 🛡️ ALIAS PELINDUNG: Jika ada file lain nyari CandleData, otomatis diarahkan ke CandleModel
typedef CandleData = CandleModel;

class StockStreamService {
  // Menggunakan CandleModel sesuai kemauan main.dart baris 450
  final StreamController<List<CandleModel>> _chartStreamController = 
      StreamController<List<CandleModel>>.broadcast();

  Stream<List<CandleModel>> get chartStream => _chartStreamController.stream;

  void startStreaming(String ticker, String apiKey) async {
    final url = Uri.parse(
      'https://api.goapi.id/v1/stock/idx/${ticker.toUpperCase()}/historical?api_key=$apiKey'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        if (jsonMap['status'] == 'success' && jsonMap['data'] != null) {
          final List<dynamic> dataHasil = jsonMap['data']['results'] ?? [];
          
          List<CandleModel> loadedCandles = [];

          for (var item in dataHasil) {
            DateTime parsedDate = DateTime.parse(item['date'] ?? DateTime.now().toString());
            
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

          // Urutkan data dari kiri ke kanan untuk grafik
          loadedCandles = loadedCandles.reversed.toList();

          if (!_chartStreamController.isClosed) {
            _chartStreamController.add(loadedCandles);
          }
        } else {
          _chartStreamController.addError(jsonMap['message'] ?? "Gagal memuat data dari GoAPI.");
        }
      } else {
        _chartStreamController.addError("Server GoAPI merespon error: ${response.statusCode}");
      }
    } catch (e) {
      _chartStreamController.addError("Gagal terhubung ke GoAPI: $e");
    }
  }

  void dispose() {
    _chartStreamController.close();
  }
}