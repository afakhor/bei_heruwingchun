import 'package:flutter/material.dart';
import 'finance_engine_bridge.dart';
import 'stock_stream_service.dart';
import 'candlestick_chart.dart';

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

// ===========================================
// 📊 1. HALAMAN UTAMA / DASHBOARD (INPUTAN LANGSUNG NEMPEL)
// ============================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final TextEditingController _apiInputController = TextEditingController();
  String _apiKeyAktif = "";
  bool _isEngineRunning = false;

  @override
  void dispose() {
    _apiInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Sumur Abadi'),
        backgroundColor: const Color(0xff1c2030),
        automaticallyImplyLeading: false, 
      ),
      // Kita biarkan SingleChildScrollView di luar agar layar bisa di-scroll sampai ke bawah panel analisa
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📥 KOTAK FORM INPUTAN YANG NEMPEL DI HALAMAN UTAMA
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
                        "CONTROL PANEL API KEY",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff26a69a)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiInputController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Paste Twelve Data Key...",
                                hintStyle: const TextStyle(color: Colors.white24),
                                prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey, size: 20),
                                filled: true,
                                fillColor: const Color(0xff131722),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xff26a69a)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
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
                              if (inputKey.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("API Key kosong, Bossku!")),
                                );
                                return;
                              }
                              
                              setState(() {
                                _apiKeyAktif = inputKey;
                                _isEngineRunning = true;
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
              const SizedBox(height: 20),
              
              // 📊 LOGIKA EKSEKUSI JALUR PIPA DATA
              _isEngineRunning
                  ? LiveTradingView(apiKey: _apiKeyAktif) // 🔥 JALANKAN ENGINE GRAFIK SEBENARNYA
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xff1c2030),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.waves_rounded, color: Colors.amberAccent, size: 50),
                            SizedBox(height: 10),
                            Text(
                              "Pipa data tersumbat.\nSilakan input API Key di atas lalu klik AKTIFKAN.",
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
}

// =================================================================
// 📈 2. MODUL LIVE VIEW & PROSES ANALISA ENGINE (VERSI AMAN BUILD)
// =================================================================
class LiveTradingView extends StatefulWidget {
  final String apiKey;
  const LiveTradingView({super.key, required this.apiKey});

  @override
  State<LiveTradingView> createState() => _LiveTradingViewState();
}

class _LiveTradingViewState extends State<LiveTradingView> {
  final FinanceEngineBridge _engine = FinanceEngineBridge();
  final StockStreamService _streamService = StockStreamService();

  String _currentTicker = 'BBRI';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 📡 Menggunakan fungsi standar bawaanmu tanpa parameter apiKey dulu
    _streamService.startStreaming(_currentTicker);
  }

  @override
  void didUpdateWidget(covariant LiveTradingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiKey != widget.apiKey) {
      _streamService.startStreaming(_currentTicker);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _streamService.dispose();
    super.dispose();
  }

  void _gantiSaham(String kodeBaru) {
    if (kodeBaru.trim().isNotEmpty) {
      setState(() {
        _currentTicker = kodeBaru.toUpperCase().trim();
        _isSearching = false;
        _searchController.clear();
        _streamService.startStreaming(_currentTicker);
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
                            hintText: 'Ketik kode saham... (e.g. BCIP, BBRI)',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          onSubmitted: _gantiSaham,
                        )
                      : Text('Live Radar Engine: $_currentTicker', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          stream: _streamService.chartStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: Color(0xff26a69a)),
                ),
              );
            }

            final candleHistory = snapshot.data!;
            final lastCandle = candleHistory.last;

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
                  decoration: BoxDecoration(
                    color: const Color(0xff1c2030),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: KeyedSubtree(
                    key: UniqueKey(),
                    child: CandlestickChart(candles: candleHistory),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TICK RUNNING ($_currentTicker)", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        "Rp${lastCandle.close.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          color: lastCandle.close >= lastCandle.open ? const Color(0xff26a69a) : const Color(0xffef5350)
                        ),
                      ),
                    ],
                  ),
                ),
                Card(
                  color: analisa.action == 1 
                      ? const Color(0xff1b3a32) 
                      : (analisa.action == -1 ? const Color(0xff3a1b1b) : const Color(0xff1f222e)),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: analisa.action == 1 
                          ? const Color(0xff26a69a) 
                          : (analisa.action == -1 ? const Color(0xffef5350) : Colors.transparent), 
                      width: 1.5
                    ),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          analisa.action == 1 
                              ? "🟢 AUTO SIGNAL: BUY" 
                              : (analisa.action == -1 ? "🔴 AUTO SIGNAL: AVOID / SELL" : "⚪ AUTO SIGNAL: HOLD / WAIT"),
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Skor Indikator Gabungan: ${analisa.score} / 100", style: const TextStyle(color: Colors.grey)),
                        const Divider(height: 30, color: Colors.grey),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text("🛡️ AMANKAN STOP LOSS", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                const SizedBox(height: 5),
                                Text(analisa.stopLoss > 0 ? "Rp${analisa.stopLoss.toStringAsFixed(0)}" : "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text("🎯 TARGET TAKE PROFIT", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                const SizedBox(height: 5),
                                Text(analisa.takeProfit > 0 ? "Rp${analisa.takeProfit.toStringAsFixed(0)}" : "-", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
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

// ===========================
// 📱 3. FITUR RADAR SCREENER DATA SAHAM (VERSI LENGKAP & FIX)
// ==================================
class ScreenedStockModel {
  final int rank;
  final String ticker;
  final String name;
  final double price; // Menggunakan double agar sinkron dengan toStringAsFixed(0)
  final double changePercent;
  final int score;
  final String strategyTag;

  ScreenedStockModel({
    required this.rank,
    required this.ticker,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.score,
    required this.strategyTag,
  });
}

class StockScreenerScreen extends StatefulWidget {
  const StockScreenerScreen({super.key});

  @override
  State<StockScreenerScreen> createState() => _StockScreenerScreenState();
}

class _StockScreenerScreenState extends State<StockScreenerScreen> {
  // 5 Data saham aslimu sudah aman kembali di sini, Bossku
  final List<ScreenedStockModel> _allStocks = [
    ScreenedStockModel(rank: 1, ticker: 'BCIP', name: 'Bumi Citra Permai Tbk', price: 84, changePercent: 14.2, score: 95, strategyTag: 'Fast Trade / Scalping'),
    ScreenedStockModel(rank: 2, ticker: 'BRIS', name: 'Bank Syariah Indonesia Tbk', price: 2540, changePercent: 6.8, score: 89, strategyTag: 'Volume Spike Breakout'),
    ScreenedStockModel(rank: 3, ticker: 'ANTM', name: 'Aneka Tambang Tbk', price: 1620, changePercent: 4.5, score: 82, strategyTag: 'EMA Cross Uptrend'),
    ScreenedStockModel(rank: 4, ticker: 'BBRI', name: 'Bank Rakyat Indonesia Tbk', price: 5225, changePercent: 1.8, score: 78, strategyTag: 'Buy on Weakness'),
    ScreenedStockModel(rank: 5, ticker: 'TLKM', name: 'Telkom Indonesia Tbk', price: 3640, changePercent: -0.5, score: 65, strategyTag: 'Sideways Testing Support'),
  ];

  List<ScreenedStockModel> _filteredStocks = [];
  final TextEditingController _screenerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredStocks = _allStocks; 
  }

  @override
  void dispose() {
    _screenerSearchController.dispose();
    super.dispose();
  }

  // Fungsi filter andalanmu dikembalikan tanpa error tipe data
  void _runFilter(String keyword) {
    List<ScreenedStockModel> results = [];
    if (keyword.isEmpty) {
      results = _allStocks;
    } else {
      results = _allStocks
          .where((stock) => stock.ticker.toLowerCase().contains(keyword.toLowerCase()) || 
                            stock.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredStocks = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff161a25),
      appBar: AppBar(
        title: const Text('Top Filtered Stocks Today', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff1c2030),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _screenerSearchController,
              onChanged: _runFilter, 
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Cari hasil filteran harian...',
                labelStyle: const TextStyle(color: Colors.grey),
                suffixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xff1f222e),
              ),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: _filteredStocks.isEmpty
                  ? const Center(child: Text('Saham tidak ditemukan dalam radar hari ini.', style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      itemCount: _filteredStocks.length,
                      itemBuilder: (context, index) {
                        final stock = _filteredStocks[index];
                        bool isPositive = stock.changePercent >= 0;

                        return Card(
                          color: const Color(0xff1f222e),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: stock.rank <= 2 ? const Color(0xff26a69a) : Colors.grey[800],
                              child: Text('#${stock.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            title: Row(
                              children: [
                                Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: Text(stock.strategyTag, style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0), 
                              child: Text(stock.name, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                            trailing: Column(
                              mainAxisAlignment: Main====
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Rp${stock.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                  "${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isPositive ? const Color(0xff26a69a) : const Color(0xffef5350),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
} // 🔑 CODINGAN KAMU SELESAI DAN TERKUNCI RAPAT DI SINI.
// =================================================================
// RADAR SCREENER DATA SAHAM
// =================================================================
class ScreenedStockModel {
  final int rank;
  final String ticker;
  final String name;
  final double price;
  final double changePercent;
  final int score;
  final String strategyTag;

  ScreenedStockModel({
    required this.rank,
    required this.ticker,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.score,
    required this.strategyTag,
  });
}

class StockScreenerScreen extends StatefulWidget {
  const StockScreenerScreen({super.key});

  @override
  State<StockScreenerScreen> createState() => _StockScreenerScreenState();
}

class _StockScreenerScreenState extends State<StockScreenerScreen> {
  final List<ScreenedStockModel> _allStocks = [
    ScreenedStockModel(rank: 1, ticker: 'BCIP', name: 'Bumi Citra Permai Tbk', price: 84, changePercent: 14.2, score: 95, strategyTag: 'Fast Trade / Scalping'),
    ScreenedStockModel(rank: 2, ticker: 'BRIS', name: 'Bank Syariah Indonesia Tbk', price: 2540, changePercent: 6.8, score: 89, strategyTag: 'Volume Spike Breakout'),
    ScreenedStockModel(rank: 3, ticker: 'ANTM', name: 'Aneka Tambang Tbk', price: 1620, changePercent: 4.5, score: 82, strategyTag: 'EMA Cross Uptrend'),
    ScreenedStockModel(rank: 4, ticker: 'BBRI', name: 'Bank Rakyat Indonesia Tbk', price: 5225, changePercent: 1.8, score: 78, strategyTag: 'Buy on Weakness'),
    ScreenedStockModel(rank: 5, ticker: 'TLKM', name: 'Telkom Indonesia Tbk', price: 3640, changePercent: -0.5, score: 65, strategyTag: 'Sideways Testing Support'),
  ];

  List<ScreenedStockModel> _filteredStocks = [];
  final TextEditingController _screenerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredStocks = _allStocks; 
  }

  void _runFilter(String keyword) {
    List<ScreenedStockModel> results = [];
    if (keyword.isEmpty) {
      results = _allStocks;
    } else {
      results = _allStocks
          .where((stock) => stock.ticker.toLowerCase().contains(keyword.toLowerCase()) || 
                            stock.name.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredStocks = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff161a25),
      appBar: AppBar(
        title: const Text('Top Filtered Stocks Today'),
        backgroundColor: const Color(0xff1c2030),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _screenerSearchController,
              onChanged: _runFilter, 
              decoration: InputDecoration(
                labelText: 'Cari hasil filteran harian...',
                suffixIcon: const Icon(Icons.search, color: Colors.greenAccent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xff1f222e),
              ),
            ),
            const SizedBox(height: 15),

            Expanded(
              child: _filteredStocks.isEmpty
                  ? const Center(child: Text('Saham tidak ditemukan dalam radar hari ini.'))
                  : ListView.builder(
                      itemCount: _filteredStocks.length,
                      itemBuilder: (context, index) {
                        final stock = _filteredStocks[index];
                        bool isPositive = stock.changePercent >= 0;

                        return Card(
                          color: const Color(0xff1f222e),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: stock.rank <= 2 ? const Color(0xff26a69a) : Colors.grey[800],
                              child: Text('#${stock.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            title: Row(
                              children: [
                                Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(4)
                                      ),
                                      child: Text(stock.strategyTag, style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0), 
                              child: Text(stock.name, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Rp${stock.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  "${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isPositive ? const Color(0xff26a69a) : const Color(0xffef5350),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}