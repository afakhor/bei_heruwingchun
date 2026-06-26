import 'dart:async';
import 'dart:convert'; // Wajib untuk memproses data JSON dari server
import 'package:http/http.dart' as http; // Pipa koneksi internet kilat
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Wajib untuk fungsi compute
import 'stock_stream_service.dart';
import 'finance_engine_bridge.dart'; // Mengambil jembatan C++ asli
import 'candlestick_chart.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// =================================================================
// WIDGET SPLASH SCREEN MURNI OTOMATIS (EFEK RADAR SEPUSAT & PRESISI)
// =================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;

  // Mesin animasi untuk efek gelombang kejut otomatis
  late AnimationController _rippleController;

  bool _isAtCenter = false; 
  bool _isClicked = false; 

  @override
  void initState() {
    super.initState();

    // 1. Animasi pergerakan ikon mendarat (2 Detik)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 2. Animasi efek kejut/radar otomatis (700ms)
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // 🔥 KITA KUNCI: Titik akhir (end) wajib mendarat di Alignment.center (0.0, 0.0)
    _alignmentAnimation = Tween<Alignment>(
      begin: const Alignment(2.2 , 3.2), 
      end: Alignment.center, 
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn, 
    ));

    // Pemicu Otomatis saat gerakan mendarat selesai
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAtCenter = true; 
            _isClicked = true; 
          });
          _rippleController.forward(); // 💥 Jalankan radar otomatis
        }
      }
    });

    // Pindah halaman otomatis setelah efek radar selesai memudar
    _rippleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()), 
          );
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7F00FF), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F00FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'PORTO HERU WINGCHUN',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash.png', 
              fit: BoxFit.cover,       
            ),
          ),

          // LAPISAN EFEK: Menggambar garis radar melingkar otomatis di tengah-tengah
          if (_isClicked)
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                return Center(
                  child: CustomPaint(
                    painter: ShockwavePainter(progress: _rippleController.value),
                    size: const Size(200, 200),
                  ),
                );
              },
            ),

          // LAPISAN UTAMA: Pergerakan Icon Alat (Murni Visual Otomatis)
          AnimatedBuilder(
            animation: _alignmentAnimation,
            builder: (context, child) {
              return Align(
                alignment: _alignmentAnimation.value,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300), 
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _isAtCenter
                      ? AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          // 🔥 KUNCI KEDUA: Paksa transformasi Matrix skala menyusut tepat di as tengah teks
                          transformAlignment: Alignment.center, 
                          transform: Matrix4.identity()..scale(_isClicked ? 0.85 : 1.0),
                          child: const Text(
                            '👆',
                            key: ValueKey('finger_icon'),
                            style: TextStyle(fontSize: 60), 
                          ),
                        )
                      : const Text(
                          '🪂',
                          key: ValueKey('tools_icon'),
                          style: TextStyle(fontSize: 85), 
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =================================================================
// PELUKIS GELOMBANG KEJUT (SHOCKWAVE RADAR PAINTER)
// =================================================================
class ShockwavePainter extends CustomPainter {
  final double progress;
  ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ring 1: Gelombang Kejut Utama (Warna Hijau Trading)
    final paint1 = Paint()
      ..color = const Color(0xff26a69a).withOpacity(1.0 - progress) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1.0 - progress); 

    double radius1 = progress * 130; 
    canvas.drawCircle(center, radius1, paint1);

    // Ring 2: Gelombang Lapisan Kedua (Warna Cyan Listrik)
    if (progress > 0.2) {
      final progress2 = (progress - 0.2) / 0.8;
      final paint2 = Paint()
        ..color = Colors.cyanAccent.withOpacity(1.0 - progress2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - progress2);

      double radius2 = progress2 * 90;
      canvas.drawCircle(center, radius2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
// ====================================================================
// 📊 MASTER NAVIGASI UTAMA (PIPA DATA DIALIRKAN DARI SINI)
// ====================================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; 
  String _activeTicker = 'BCIP'; 

  final TextEditingController _urlInputController = 
      TextEditingController(text: 'https://heruwingchun.pythonanywhere.com/v1/idx'); 
  final TextEditingController _apiInputController = TextEditingController();

  String _urlAktif = "https://heruwingchun.pythonanywhere.com/v1/idx";
  String _apiKeyAktif = "";
  bool _isEngineRunning = false;

  // 🎯 LIFTING STATE: Pipa tunggal ditaruh di level master agar bisa dibagi ke semua halaman
  final StockStreamService _globalStreamService = StockStreamService();

  @override
  void dispose() {
    _urlInputController.dispose(); 
    _apiInputController.dispose();
    _globalStreamService.dispose(); // Amankan pipa bursa dari memory leak
    super.dispose();
  }

  void _hubungkanKeDashboard(String kodeSahamBaru) {
    setState(() {
      _activeTicker = kodeSahamBaru.toUpperCase(); 
      _currentIndex = 0; 
      if (_isEngineRunning) {
        _globalStreamService.startStreaming(_activeTicker, _apiKeyAktif, _urlAktif);
      }
    });
  }

  Widget _buildDashboardPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Sumur Abadi'),
        backgroundColor: const Color(0xff1c2030),
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PANEL 1: KONTROL SERVER
              Card(
                color: const Color(0xff1c2030),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CONTROL PANEL SERVER & API KEY",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff26a69a)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _urlInputController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Masukkan Base URL API...",
                          hintStyle: const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.language, color: Colors.grey, size: 20),
                          filled: true,
                          fillColor: const Color(0xff131722),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xff26a69a))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiInputController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Paste API Key (Boleh Kosong)...",
                                hintStyle: const TextStyle(color: Colors.white24),
                                prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey, size: 20),
                                filled: true,
                                fillColor: const Color(0xff131722),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xff26a69a))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff26a69a),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              String inputKey = _apiInputController.text.trim();
                              String inputUrl = _urlInputController.text.trim();
                              if (inputKey.isEmpty) inputKey = "1";
                              setState(() {
                                _apiKeyAktif = inputKey;
                                _urlAktif = inputUrl; 
                                _isEngineRunning = true;
                                _globalStreamService.startStreaming(_activeTicker, _apiKeyAktif, _urlAktif);
                              });
                            },
                            child: const Text("AKTIFKAN", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), 

              // PANEL 2: CHART REALSTREAM & SIGNAL ANALYST
              _isEngineRunning
                  ? LiveTradingView(
                      apiKey: _apiKeyAktif, 
                      baseUrl: _urlAktif,
                      ticker: _activeTicker, 
                      streamService: _globalStreamService,
                      onTickerSearched: (String tickerBaru) {
                        setState(() {
                          _activeTicker = tickerBaru; 
                          _globalStreamService.startStreaming(_activeTicker, _apiKeyAktif, _urlAktif);
                        });
                      },
                    ) 
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(color: const Color(0xff1c2030), borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waves_rounded, color: Colors.amberAccent, size: 50),
                            SizedBox(height: 10),
                            Text(
                              "Pipa data tersumbat.\nSilakan input URL & API Key di atas lalu klik AKTIFKAN.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.amberAccent, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardPage(),       
          StockScreenerScreen(
            onStockSelected: _hubungkanKeDashboard,
            streamService: _globalStreamService,
            activeTicker: _activeTicker,
            isEngineRunning: _isEngineRunning,
          ),  
          MarketRadarScreen(
            onStockSelected: _hubungkanKeDashboard,
            streamService: _globalStreamService,
            activeTicker: _activeTicker,
            isEngineRunning: _isEngineRunning,
          ), 
          StockCalculatorProScreen(baseUrl: _urlAktif),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff1c2030),
        selectedItemColor: const Color(0xff26a69a),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          setState(() {
            _currentIndex = index; 
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Screener'),
          BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: 'Radar'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate_rounded), label: 'Kalkulator Pro'),
        ],
      ),
    );
  }
}

// ====================================================================
// 📈 HALAMAN 1: LIVE VIEW & CANDLESTICK (MENGGUNAKAN ENGINE ASLI)
// ====================================================================
class LiveTradingView extends StatefulWidget {
  final String apiKey;
  final String baseUrl; 
  final String ticker; 
  final StockStreamService streamService;
  final ValueChanged<String> onTickerSearched; 

  const LiveTradingView({
    super.key, 
    required this.apiKey, 
    required this.baseUrl, 
    required this.ticker,
    required this.streamService,
    required this.onTickerSearched,
  });

  @override
  State<LiveTradingView> createState() => _LiveTradingViewState();
}

class _LiveTradingViewState extends State<LiveTradingView> {
  // Menggunakan jembatan mesin C++ asli hasil kompilasi .so kamu
  final FinanceEngineBridge _engine = FinanceEngineBridge();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _gantiSaham(String kodeBaru) {
    if (kodeBaru.trim().isNotEmpty) {
      widget.onTickerSearched(kodeBaru.toUpperCase().trim());
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xff1c2030),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Ketik kode saham... (Contoh: BCIP, BBRI)',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          onSubmitted: _gantiSaham,
                        )
                      : Text('Live Radar Engine: ${widget.ticker}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.greenAccent),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _searchController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        StreamBuilder<List<CandleModel>>(
          stream: widget.streamService.chartStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                height: 250,
                color: const Color(0xff1c2030),
                child: Center(child: Text("Gagal Memuat Data Chart:\n${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xff26a69a))));
            }

            final candleHistory = snapshot.data!;
            final lastCandle = candleHistory.last;

            // Memanggil fungsi perhitungan FFI C++ secara Real-time
            final analisa = _engine.checkStockSignal(
              close: lastCandle.close, 
              ema5: lastCandle.close * 0.992,
              ema20: lastCandle.close * 0.985, 
              ema200: lastCandle.close * 0.95, 
              rsi: 45.0, 
              vwap: lastCandle.close * 0.99, 
              adx: 30.0, 
              atr: lastCandle.close * 0.02, 
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(color: const Color(0xff1c2030), borderRadius: BorderRadius.circular(12)),
                  child: KeyedSubtree(
                    key: UniqueKey(),
                    child: CandlestickChart(candles: candleHistory),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TICK RUNNING (${widget.ticker})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        "Rp${lastCandle.close.toStringAsFixed(0)}",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lastCandle.close >= lastCandle.open ? const Color(0xff26a69a) : const Color(0xffef5350)),
                      ),
                    ],
                  ),
                ),
                Card(
                  color: analisa.action == 1 ? const Color(0xff1b3a32) : const Color(0xff1f222e),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(analisa.action == 1 ? "🟢 AUTO SIGNAL: BUY" : "⚪ AUTO SIGNAL: HOLD", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Skor Indikator: ${analisa.score} / 100", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        if (analisa.action == 1) ...[
                          const SizedBox(height: 4),
                          Text("TP: Rp${analisa.takeProfit.toStringAsFixed(0)} | CL: Rp${analisa.stopLoss.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ====================================================================
// 📊 HALAMAN 2: STOCK SCREENER DENGAN FILTER (TERKONEKSI ISOLATE C++)
// ====================================================================
class ScreenerStockModel {
  final String ticker;
  final double close;
  final double changePercent;
  final String signal;
  final int score;
  final double stopLoss;
  final double takeProfit;

  ScreenerStockModel({
    required this.ticker,
    required this.close,
    required this.changePercent,
    required this.signal,
    this.score = 0,
    this.stopLoss = 0.0,
    this.takeProfit = 0.0,
  });

  factory ScreenerStockModel.fromJson(Map<String, dynamic> json) {
    return ScreenerStockModel(
      ticker: json['ticker'] ?? '',
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0.0,
      signal: json['signal'] ?? 'Neutral',
      score: json['score'] ?? 0,
      stopLoss: (json['stop_loss'] as num?)?.toDouble() ?? 0.0,
      takeProfit: (json['take_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StockScreenerScreen extends StatefulWidget {
  final Function(String) onStockSelected;
  final StockStreamService streamService;
  final String activeTicker;
  final bool isEngineRunning;

  const StockScreenerScreen({
    super.key,
    required this.onStockSelected,
    required this.streamService,
    required this.activeTicker,
    required this.isEngineRunning,
  });

  @override
  State<StockScreenerScreen> createState() => _StockScreenerScreenState();
}

class _StockScreenerScreenState extends State<StockScreenerScreen> {
  List<ScreenerStockModel> _realtimeStocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchScreenerData(); 
  }

  // 🔥 TEMPAT EKSEKUSI COMPUTE() ISOLATE DI DALAM STATE
  void memprosesDataScreener(List<Map<String, dynamic>> dataDariPython) async {
    // Lempar data berat hasil API ke Isolate terpisah agar UI anti-lag
    List<Map<String, dynamic>> hasilLolosCPlusPlus = await compute(
      cPlusPlusBulkScreening, 
      dataDariPython
    );

    // Konversi hasil map dari background ke bentuk List Model agar bisa dibaca ListView
    setState(() {
      _realtimeStocks = hasilLolosCPlusPlus.map((json) => ScreenerStockModel.fromJson(json)).toList();
      _isLoading = false;
    });
  }

  Future<void> _fetchScreenerData() async {
    try {
      // Di sini nanti tempat http.get kamu ke PythonAnywhere
      await Future.delayed(const Duration(milliseconds: 600)); 

      final List<Map<String, dynamic>> dummyJsonResponse = [
        {'ticker': 'BCIP', 'close': 58.0, 'change_percent': -1.69, 'signal': '🔥 VOL SPIKE', 'ema5': 56.0, 'ema20': 54.0, 'ema200': 50.0, 'rsi': 55.0, 'vwap': 57.0, 'adx': 25.0, 'atr': 2.0},
        {'ticker': 'GOTO', 'close': 54.0, 'change_percent': 9.5, 'signal': '🚀 BREAKOUT', 'ema5': 50.0, 'ema20': 48.0, 'ema200': 60.0, 'rsi': 65.0, 'vwap': 52.0, 'adx': 35.0, 'atr': 3.0},
        {'ticker': 'BBCA', 'close': 10100.0, 'change_percent': 1.2, 'signal': '👑 LEADER', 'ema5': 10000.0, 'ema20': 9800.0, 'ema200': 9500.0, 'rsi': 50.0, 'vwap': 10050.0, 'adx': 20.0, 'atr': 150.0},
      ];

      // Kirim data mentah ke pipa pemrosesan C++ Isolate
      memprosesDataScreener(dummyJsonResponse);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xff26a69a))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast Trade Screener', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff1c2030),
        automaticallyImplyLeading: false,
      ),
      body: _realtimeStocks.isEmpty 
        ? const Center(child: Text("Tidak ada saham yang lolos kriteria BUY C++", style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _realtimeStocks.length,
            itemBuilder: (context, index) {
              final stock = _realtimeStocks[index];

              if (widget.isEngineRunning && stock.ticker == widget.activeTicker) {
                return StreamBuilder<List<CandleModel>>(
                  stream: widget.streamService.chartStream,
                  builder: (context, snapshot) {
                    double finalPrice = stock.close;
                    double finalChange = stock.changePercent;
                    bool isLivePipe = false;

                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      finalPrice = snapshot.data!.last.close;
                      finalChange = ((snapshot.data!.last.close - snapshot.data!.last.open) / snapshot.data!.last.open) * 100;
                      isLivePipe = true;
                    }

                    return _buildRowLayout(stock, finalPrice, finalChange, isLivePipe);
                  },
                );
              }

              return _buildRowLayout(stock, stock.close, stock.changePercent, false);
            },
          ),
    );
  }

  Widget _buildRowLayout(ScreenerStockModel stock, double price, double change, bool isLive) {
    return Card(
      color: const Color(0xff1f222e),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Row(
          children: [
            Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isLive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4)
              ),
              child: Text(
                isLive ? "LIVE STREAM" : "RADAR BACK", 
                style: TextStyle(color: isLive ? Colors.greenAccent : Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Text(
          "Score: ${stock.score} | TP: ${stock.takeProfit.toStringAsFixed(0)} | CL: ${stock.stopLoss.toStringAsFixed(0)}", 
          style: const TextStyle(fontSize: 11, color: Colors.amberAccent)
        ),
        trailing: Text(
          "Rp${price.toStringAsFixed(0)} (${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%)",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: change >= 0 ? Colors.greenAccent : Colors.redAccent, 
          ),
        ),
        onTap: () => widget.onStockSelected(stock.ticker),
      ),
    );
  }
}

// ====================================================================
// 📊 HALAMAN 3: IDX MARKET RADAR
// ====================================================================
class RadarStockModel {
  final String ticker;
  final double basePrice;
  final double baseChange;
  final Color alertColor;

  RadarStockModel({
    required this.ticker,
    required this.basePrice,
    required this.baseChange,
    required this.alertColor,
  });
}

class MarketRadarScreen extends StatelessWidget {
  final Function(String) onStockSelected;
  final StockStreamService streamService;
  final String activeTicker;
  final bool isEngineRunning;

  const MarketRadarScreen({
    super.key, 
    required this.onStockSelected,
    required this.streamService,
    required this.activeTicker,
    required this.isEngineRunning,
  });

  List<RadarStockModel> get _gainers => [
    RadarStockModel(ticker: 'BCIP', basePrice: 84, baseChange: 14.2, alertColor: Colors.greenAccent),
    RadarStockModel(ticker: 'GOTO', basePrice: 54, baseChange: 9.5, alertColor: Colors.greenAccent),
    RadarStockModel(ticker: 'BUMI', basePrice: 120, baseChange: 7.2, alertColor: Colors.greenAccent),
  ];

  List<RadarStockModel> get _losers => [
    RadarStockModel(ticker: 'ASII', basePrice: 4600, baseChange: -6.8, alertColor: Colors.redAccent),
    RadarStockModel(ticker: 'UNVR', basePrice: 2300, baseChange: -5.2, alertColor: Colors.redAccent),
  ];

  List<RadarStockModel> get _marketCaps => [
    RadarStockModel(ticker: 'BBCA', basePrice: 10100, baseChange: 1.2, alertColor: Colors.amber),
    RadarStockModel(ticker: 'BBRI', basePrice: 4400, baseChange: -0.8, alertColor: Colors.amber),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('IDX Market Radar', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xff1c2030),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Color(0xff26a69a),
            tabs: [
              Tab(text: 'Performance'),
              Tab(text: 'Capital & LQ45'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        body: StreamBuilder<List<CandleModel>>(
          stream: isEngineRunning ? streamService.chartStream : null,
          builder: (context, snapshot) {
            double livePrice = 0;
            double liveChange = 0;

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final lastCandle = snapshot.data!.last;
              livePrice = lastCandle.close;
              liveChange = ((lastCandle.close - lastCandle.open) / lastCandle.open) * 100;
            }

            return TabBarView(
              children: [
                _buildDynamicTab(_gainers, _losers, "🔥 TOP GAINERS", "❄️ TOP LOSERS", livePrice, liveChange),
                _buildDynamicTab(_marketCaps, [], "👑 TOP MARKET CAPS", "", livePrice, liveChange),
                _buildDynamicTab(_gainers, [], "📊 RANKING VOLUME TERAKTIF", "", livePrice, liveChange),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildDynamicTab(List<RadarStockModel> section1, List<RadarStockModel> section2, String title1, String title2, double livePrice, double liveChange) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionHeader(title1),
        ...section1.map((stock) => _buildStockDynamicRow(stock, livePrice, liveChange)),
        if (section2.isNotEmpty) ...[
          const SizedBox(height: 15),
          _buildSectionHeader(title2),
          ...section2.map((stock) => _buildStockDynamicRow(stock, livePrice, liveChange)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildStockDynamicRow(RadarStockModel stock, double livePrice, double liveChange) {
    double finalPrice = stock.basePrice;
    double finalChange = stock.baseChange;
    bool isRealtime = false;

    if (isEngineRunning && stock.ticker == activeTicker && livePrice > 0) {
      finalPrice = livePrice;
      finalChange = liveChange;
      isRealtime = true;
    }

    String trailingText = finalChange >= 0 
        ? "+${finalChange.toStringAsFixed(2)}%" 
        : "${finalChange.toStringAsFixed(2)}%";

    if (finalPrice > 0) {
      trailingText = "Rp${finalPrice.toStringAsFixed(0)} ($trailingText)";
    }

    return Card(
      color: const Color(0xff1f222e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        onTap: () => onStockSelected(stock.ticker),
        title: Row(
          children: [
            Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isRealtime ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isRealtime ? "LIVE" : "STATIC",
                style: TextStyle(
                  color: isRealtime ? Colors.greenAccent : Colors.amberAccent, 
                  fontSize: 9, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          trailingText, 
          style: TextStyle(fontWeight: FontWeight.bold, color: stock.alertColor, fontSize: 13)
        ),
      ),
    );
  }
}

// ====================================================================
// 🧮 HALAMAN 4: KALKULATOR SAHAM PRO (HYBRID HYPER HYDRATED ENGINE)
// ====================================================================
class StockCalculatorProScreen extends StatefulWidget {
  final String baseUrl; // Menerima pipa URL dari Master Navigasi

  const StockCalculatorProScreen({super.key, required this.baseUrl});

  @override
  State<StockCalculatorProScreen> createState() => _StockCalculatorProScreenState();
}

class _StockCalculatorProScreenState extends State<StockCalculatorProScreen> {
  // Kontrol Ticker & Status Pipa Pendek Online
  final _tickerSearchCtrl = TextEditingController();
  bool _isFetchingPrice = false;
  String _searchStatus = "Mode: Offline (Bisa ketik manual). Masukkan Ticker untuk Auto-Fill Online.";

  final _feeBuyGlobalCtrl = TextEditingController(text: "0.15");
  final _feeSellGlobalCtrl = TextEditingController(text: "0.25");

  final _pnlBuyPriceCtrl = TextEditingController();
  final _pnlSellPriceCtrl = TextEditingController();
  final _pnlLotCtrl = TextEditingController();
  String _pnlResult = "Masukkan data transaksi untuk menghitung cuan bersih.";

  final _avgPrice1Ctrl = TextEditingController();
  final _avgLot1Ctrl = TextEditingController();
  final _avgPrice2Ctrl = TextEditingController();
  final _avgLot2Ctrl = TextEditingController();
  String _avgResult = "Masukkan riwayat jemputan muatan harga lama & baru.";

  final _planBuyPriceCtrl = TextEditingController();
  final _planTargetProfitCtrl = TextEditingController(text: "5.0");
  final _planCutLossCtrl = TextEditingController(text: "2.0");
  String _planResult = "Masukkan modal entrian untuk membuat peta trading plan.";

  final _cashAvailableCtrl = TextEditingController();
  final _cashStockPriceCtrl = TextEditingController();
  String _cashResult = "Masukkan nilai modal tunai untuk melihat batas lot belanja.";

  @override
  void dispose() {
    _tickerSearchCtrl.dispose();
    _feeBuyGlobalCtrl.dispose(); _feeSellGlobalCtrl.dispose();
    _pnlBuyPriceCtrl.dispose(); _pnlSellPriceCtrl.dispose(); _pnlLotCtrl.dispose();
    _avgPrice1Ctrl.dispose(); _avgLot1Ctrl.dispose(); _avgPrice2Ctrl.dispose(); _avgLot2Ctrl.dispose();
    _planBuyPriceCtrl.dispose(); _planTargetProfitCtrl.dispose(); _planCutLossCtrl.dispose();
    _cashAvailableCtrl.dispose(); _cashStockPriceCtrl.dispose();
    super.dispose();
  }

  // 🚀 FUNGSI KILAT PENGAMBIL DATA 1 SAHAM (HYBRID AUTO-COMPLETE)
  Future<void> _fetchSingleStockPrice() async {
    String ticker = _tickerSearchCtrl.text.trim().toUpperCase();
    if (ticker.isEmpty) {
      setState(() => _searchStatus = "⚠️ Harap isi kode saham terlebih dahulu.");
      return;
    }

    setState(() {
      _isFetchingPrice = true;
      _searchStatus = "⚡ Sedang menarik data harga $ticker dari server...";
    });

    try {
      // Menembak endpoint kilat 1 saham dengan batas sabar (timeout) hanya 5 detik
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/price?ticker=$ticker'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double price = (data['price'] ?? data['close'] ?? 0.0).toDouble();

        if (price > 0) {
          setState(() {
            // 🔥 KUNCI UTAMA: Auto-Complete menyuntik semua kolom harga di seluruh Tab!
            _pnlBuyPriceCtrl.text = price.toStringAsFixed(0);
            _avgPrice2Ctrl.text = price.toStringAsFixed(0);
            _planBuyPriceCtrl.text = price.toStringAsFixed(0);
            _cashStockPriceCtrl.text = price.toStringAsFixed(0);
            _searchStatus = "🟢 Ticker $ticker Berhasil Masuk: Rp${price.toStringAsFixed(0)} (Semua Kolom Terisi!)";
          });
          // Picu ulang kalkulasi otomatis jika ada sisa muatan lot lama yang tertinggal
          _prosesHitungPnL();
          _prosesHitungAvg();
          _prosesHitungPlan();
          _prosesHitungDayaBeli();
        } else {
          setState(() => _searchStatus = "⚠️ Saham $ticker tidak ditemukan di bursa.");
        }
      } else {
        setState(() => _searchStatus = "❌ Server Python merespon eror (${response.statusCode}).");
      }
    } on TimeoutException catch (_) {
      setState(() => _searchStatus = "📴 Koneksi Server Timeout. Otomatis beralih ke Mode Offline.");
    } catch (e) {
      setState(() => _searchStatus = "📴 Gagal tersambung internet. Silakan ketik harga secara manual.");
    } finally {
      setState(() => _isFetchingPrice = false);
    }
  }

  void _prosesHitungPnL() {
    double buy = double.tryParse(_pnlBuyPriceCtrl.text) ?? 0;
    double sell = double.tryParse(_pnlSellPriceCtrl.text) ?? 0;
    double lot = double.tryParse(_pnlLotCtrl.text) ?? 0;
    double fB = (double.tryParse(_feeBuyGlobalCtrl.text) ?? 0.15) / 100;
    double fS = (double.tryParse(_feeSellGlobalCtrl.text) ?? 0.25) / 100;

    if (buy == 0 || sell == 0 || lot == 0) return;

    double grossBuy = buy * lot * 100;
    double feeBeli = grossBuy * fB;
    double totalModal = grossBuy + feeBeli;

    double grossSell = sell * lot * 100;
    double feeJual = grossSell * fS;
    double totalTerima = grossSell - feeJual;

    double netCuan = totalTerima - totalModal;
    double roi = (netCuan / totalModal) * 100;

    setState(() {
      _pnlResult = "💵 HASIL TRANSAKSI NET:\n"
          "• Nilai Bersih: Rp${netCuan.toStringAsFixed(0)} (${netCuan >= 0 ? 'CUAN' : 'LOSS'})\n"
          "• Persentase ROI: ${roi.toStringAsFixed(2)}%\n\n"
          "🏢 RINCIAN BIAYA BURSA:\n"
          "• Total Keluar Modal: Rp${totalModal.toStringAsFixed(0)}\n"
          "• Total Terima Dana Jual: Rp${totalTerima.toStringAsFixed(0)}\n"
          "• Fee Broker Beli: Rp${feeBeli.toStringAsFixed(0)}\n"
          "• Fee Broker Jual + PPh: Rp${feeJual.toStringAsFixed(0)}";
    });
  }

  void _prosesHitungAvg() {
    double p1 = double.tryParse(_avgPrice1Ctrl.text) ?? 0;
    double l1 = double.tryParse(_avgLot1Ctrl.text) ?? 0;
    double p2 = double.tryParse(_avgPrice2Ctrl.text) ?? 0;
    double l2 = double.tryParse(_avgLot2Ctrl.text) ?? 0;

    if (l1 + l2 == 0) return;

    double totalDana = (p1 * l1 * 100) + (p2 * l2 * 100);
    double totalLot = l1 + l2;
    double avgHarga = totalDana / (totalLot * 100);

    setState(() {
      _avgResult = "🎚️ KEPEMILIKAN BARU:\n"
          "• Harga Rata-Rata Baru: Rp${avgHarga.toStringAsFixed(1)}\n"
          "• Total Volume: ${totalLot.toStringAsFixed(0)} Lot\n"
          "• Total Modal Tertanam: Rp${totalDana.toStringAsFixed(0)}";
    });
  }

  void _prosesHitungPlan() {
    double buy = double.tryParse(_planBuyPriceCtrl.text) ?? 0;
    double tpPct = (double.tryParse(_planTargetProfitCtrl.text) ?? 5.0) / 100;
    double clPct = (double.tryParse(_planCutLossCtrl.text) ?? 2.0) / 100;

    if (buy == 0) return;

    double targetTP = buy * (1 + tpPct);
    double targetCL = buy * (1 - clPct);

    setState(() {
      _planResult = "🎯 PETA TRADING PLAN (ENTRY Rp${buy.toStringAsFixed(0)}):\n"
          "• Target Take Profit: Pasang Jual di Rp${targetTP.toStringAsFixed(0)}\n"
          "• Batas Stop Loss / CL: Buang di Rp${targetCL.toStringAsFixed(0)}\n"
          "• Risk/Reward Ratio: 1 : ${(tpPct/clPct).toStringAsFixed(1)}";
    });
  }

  void _prosesHitungDayaBeli() {
    double cash = double.tryParse(_cashAvailableCtrl.text) ?? 0;
    double price = double.tryParse(_cashStockPriceCtrl.text) ?? 0;
    double fB = (double.tryParse(_feeBuyGlobalCtrl.text) ?? 0.15) / 100;

    if (cash == 0 || price == 0) return;

    double hargaPerLotBersih = (price * 100) * (1 + fB);
    double maxLot = (cash / hargaPerLotBersih).floorToDouble();
    double totalBelanja = maxLot * hargaPerLotBersih;
    double sisaCash = cash - totalBelanja;

    setState(() {
      _cashResult = "🛍️ MAKSIMAL PEMBELIAN:\n"
          "• Bisa Borong: ${maxLot.toStringAsFixed(0)} Lot\n"
          "• Total Nota Belanja: Rp${totalBelanja.toStringAsFixed(0)}\n"
          "• Sisa Kembalian Tunai: Rp${sisaCash.toStringAsFixed(0)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kalkulator Saham Pro IDX', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xff1c2030),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xff26a69a),
            tabs: [
              Tab(icon: Icon(Icons.monetization_on_rounded), text: 'Cuan Net (P&L)'),
              Tab(icon: Icon(Icons.layers_rounded), text: 'Average Down'),
              Tab(icon: Icon(Icons.gps_fixed_rounded), text: 'Trading Plan'),
              Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Daya Beli Lot'),
            ],
          ),
        ),
        body: Column(
          children: [
            // PANEL 1: CONFIG BROKER FEE
            Container(
              color: const Color(0xff1f222e),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.settings_applications, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  const Text("Setting Broker Fee: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  SizedBox(
                    width: 70,
                    height: 30,
                    child: TextField(
                      controller: _feeBuyGlobalCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.zero, labelText: "Fee Beli %", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 70,
                    height: 30,
                    child: TextField(
                      controller: _feeSellGlobalCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.zero, labelText: "Fee Jual %", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 PANEL NEW GADGET: INTERFACE SCANNER PULL ONLINE HYBRID
            Container(
              color: const Color(0xff1c2030),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _tickerSearchCtrl,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: "Ketik Kode Saham Target (Contoh: BCIP)...",
                              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                              filled: true,
                              fillColor: const Color(0xff131722),
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xff26a69a))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff26a69a),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: _isFetchingPrice ? null : _fetchSingleStockPrice,
                          child: _isFetchingPrice 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("PULL ONLINE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchStatus,
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w500,
                      color: _searchStatus.contains("🟢") ? Colors.greenAccent : (_searchStatus.contains("❌") || _searchStatus.contains("⚠️") ? Colors.redAccent : Colors.grey)
                    ),
                  ),
                ],
              ),
            ),

            // TAMPILAN TAB-VIEW UTAMA
            Expanded(
              child: TabBarView(
                children: [
                  _buildPnlTab(),
                  _buildAverageDownTab(),
                  _buildTradingPlanTab(),
                  _buildDayaBeliTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPnlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputCard("KALKULATOR UNTUNG / RUGI BERSIH", [
            _buildTextField(_pnlBuyPriceCtrl, "Harga Beli Per Saham (Rp)"),
            const SizedBox(height: 10),
            _buildTextField(_pnlSellPriceCtrl, "Harga Jual Per Saham (Rp)"),
            const SizedBox(height: 10),
            _buildTextField(_pnlLotCtrl, "Jumlah Muatan Belanja (Lot)"),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26a69a), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _prosesHitungPnL,
            child: const Text("🔥 HITUNG HASIL BERSIH", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          _buildResultCard(_pnlResult),
        ],
      ),
    );
  }

  Widget _buildAverageDownTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputCard("NOTAL BELI PERTAMA (POSISI LAMA)", [
            _buildTextField(_avgPrice1Ctrl, "Harga Beli Pertama (Rp)"),
            const SizedBox(height: 8),
            _buildTextField(_avgLot1Ctrl, "Volume Lot Lama"),
          ]),
          const SizedBox(height: 12),
          _buildInputCard("NOTA BELI KEDUA (AVERAGE DOWN)", [
            _buildTextField(_avgPrice2Ctrl, "Harga Beli Kedua / Baru (Rp)"),
            const SizedBox(height: 8),
            _buildTextField(_avgLot2Ctrl, "Volume Lot Tambahan Baru"),
          ]),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26a69a), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _prosesHitungAvg,
            child: const Text("🎚️ SIMULASIKAN HARGA RATA-RATA", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          _buildResultCard(_avgResult),
        ],
      ),
    );
  }

  Widget _buildTradingPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputCard("TARGET PRICE MANAGEMENT", [
            _buildTextField(_planBuyPriceCtrl, "Harga Modal Pembelian Beli (Rp)"),
            const SizedBox(height: 10),
            _buildTextField(_planTargetProfitCtrl, "Target Take Profit (%)"),
            const SizedBox(height: 10),
            _buildTextField(_planCutLossCtrl, "Batas Toleransi Cut Loss (%)"),
          ]),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26a69a), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _prosesHitungPlan,
            child: const Text("🎯 CETAK AUTOMATIC TRADING PLAN", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          _buildResultCard(_planResult),
        ],
      ),
    );
  }

  Widget _buildDayaBeliTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputCard("MONEY MANAGEMENT (BUYING POWER)", [
            _buildTextField(_cashAvailableCtrl, "Sisa Uang Dingin Tunai di RDI (Rp)"),
            const SizedBox(height: 10),
            _buildTextField(_cashStockPriceCtrl, "Harga Emiten Saham Target (Rp)"),
          ]),
          const SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff26a69a), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _prosesHitungDayaBeli,
            child: const Text("🛍️ CEK MAKSIMAL LOT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          _buildResultCard(_cashResult),
        ],
      ),
    );
  }

  Widget _buildInputCard(String title, List<Widget> children) {
    return Card(
      color: const Color(0xff1f222e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            ...children
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        filled: true,
        fillColor: const Color(0xff131722),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildResultCard(String content) {
    return Card(
      color: const Color(0xff1c2030),
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xff26a69a), width: 1.2), borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(content, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.6, color: Colors.greenAccent)),
      ),
    );
  }
}