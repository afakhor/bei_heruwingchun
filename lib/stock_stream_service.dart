import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ✅ KEMBALI MENGGUNAKAN CANDLEDATA & TIMESTAMP BIAR KLOP SAMA MAIN.DART
class CandleData {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class StockStreamService {
  final StreamController<List<CandleData>> _chartStreamController = 
      StreamController<List<CandleData>>.broadcast();

  Stream<List<CandleData>> get chartStream => _chartStreamController.stream;

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
          
          List<CandleData> loadedCandles = [];

          for (var item in dataHasil) {
            loadedCandles.add(CandleData(
              timestamp: DateTime.parse(item['date'] ?? DateTime.now().toString()), // 👈 diubah ke timestamp
              open: (item['open'] as num).toDouble(),
              high: (item['high'] as num).toDouble(),
              low: (item['low'] as num).toDouble(),
              close: (item['close'] as num).toDouble(),
              volume: (item['volume'] as num).toDouble(),
            ));
          }

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