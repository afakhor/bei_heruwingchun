import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class StockTick {
  final double close;
  final double volume;

  StockTick({required this.close, required this.volume});
}

class StockStreamService {
  WebSocket? _webSocket;
  StreamController<StockTick> _controller = StreamController<StockTick>.broadcast();
  Timer? _mockTimer;
  bool _isMockMode = true; // Ubah ke false jika nanti sudah punya URL asli

  Stream<StockTick> get tickStream => _controller.stream;

  // Fungsi untuk mulai mendengarkan data bursa
  void connectToExchange(String url, Map<String, String> headers) async {
    if (_isMockMode) {
      _startMockDataStream();
    } else {
      _connectRealWebSocket(url, headers);
    }
  }

  // JALAN TIKUS: Simulasi data bergerak tiap 500ms biar kodingan UI bisa ditest langsung
  void _startMockDataStream() {
    double currentPrice = 5200.0; // Harga awal BBRI misal
    final random = Random();

    _mockTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Bikin harga naik turun tipis ala running trade asli
      double change = (random.nextDouble() - 0.48) * 30; 
      currentPrice += change;
      double vol = (random.nextInt(500) + 100).toDouble();

      if (!_controller.isClosed) {
        _controller.add(StockTick(close: currentPrice, volume: vol));
      }
    });
  }

  // JALAN ASLI: Menembak WebSocket Broker (Ajaib/TradingView)
  void _connectRealWebSocket(String url, Map<String, String> headers) async {
    try {
      _webSocket = await WebSocket.connect(url, headers: headers);
      
      _webSocket!.listen((message) {
        // TODO: Parsing format unik TradingView (~m~...~m~) di sini sebelum dikirim ke C++
        // Sementara ini contoh strukturnya jika formatnya JSON standar:
        final data = jsonDecode(message);
        
        _controller.add(StockTick(
          close: double.parse(data['price'].toString()),
          volume: double.parse(data['volume'].toString()),
        ));
      }, onError: (error) {
        print("WebSocket Error: $error");
        _reconnect(url, headers);
      }, onDone: () {
        print("Koneksi WebSocket Terputus.");
        _reconnect(url, headers);
      });
    } catch (e) {
      print("Gagal tersambung ke server: $e");
      _reconnect(url, headers);
    }
  }

  void _reconnect(String url, Map<String, String> headers) {
    Future.delayed(const Duration(seconds: 5), () => _connectRealWebSocket(url, headers));
  }

  void dispose() {
    _mockTimer?.cancel();
    _webSocket?.close();
    _controller.close();
  }
}
