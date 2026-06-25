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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff161a25),
        primaryColor: const Color(0xff26a69a),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// =================================================================
// WIDGET SPLASH SCREEN
// =================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _alignmentAnimation;
  late AnimationController _rippleController;

  bool _isAtCenter = false; 
  bool _isClicked = false; 

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _alignmentAnimation = Tween<Alignment>(
      begin: const Alignment(2.2 , 3.2), 
      end: Alignment.center, 
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn, 
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAtCenter = true; 
            _isClicked = true; 
          });
          _rippleController.forward(); 
        }
      }
    });

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: const Color(0xFF7F00FF)),
          ),

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

class ShockwavePainter extends CustomPainter {
  final double progress;
  ShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint1 = Paint()
      ..color = const Color(0xff26a69a).withOpacity(1.0 - progress) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * (1.0 - progress); 

    double radius1 = progress * 130; 
    canvas.drawCircle(center, radius1, paint1);
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ====================================================================
// 📊 MASTER NAVIGASI (4 HALAMAN UTAMA)
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

  String _urlAktif = "";
  String _apiKeyAktif = "";
  bool _isEngineRunning = false;

  @override
  void dispose() {
    _urlInputController.dispose(); 
    _apiInputController.dispose();
    super.dispose();
  }

  void _hubungkanKeDashboard(String kodeSahamBaru) {
    setState(() {
      _activeTicker = kodeSahamBaru.toUpperCase(); 
      _currentIndex = 0; 
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
              // -------------------------------------------------------------
              // CARD 1: CONTROL PANEL SERVER (YANG SUDAH ADA)
              // -------------------------------------------------------------
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

              // -------------------------------------------------------------
              // 🔥 CARD 2: JEMBATAN INPUT DATA RTI PREMIUM (FITUR BARU)
              // -------------------------------------------------------------
              Card(
                color: const Color(0xff1c2030),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.amber, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "RTI PREMIUM DATA BRIDGING",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Salin data Net Foreign Flow atau RTI Valuation di sini untuk kalkulasi rotasi sektoral:",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: "Foreign Buy (Miliar)",
                                labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                                filled: true,
                                fillColor: const Color(0xff131722),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Data RTI Berhasil Disinkronisasi ke Dashboard!"),
                                  backgroundColor: Colors.amber,
                                ),
                              );
                            },
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text("SYNC DATA", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // CARD 3: LIVE VIEW ENGINE RADAR (YANG SUDAH ADA)
              // -------------------------------------------------------------
              _isEngineRunning
                  ? LiveTradingView(
                      apiKey: _apiKeyAktif, 
                      baseUrl: _urlAktif,
                      ticker: _activeTicker, 
                      onTickerSearched: (String tickerBaru) {
                        setState(() {
                          _activeTicker = tickerBaru; 
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
          StockScreenerScreen(onStockSelected: _hubungkanKeDashboard),  
          MarketRadarScreen(onStockSelected: _hubungkanKeDashboard), 
          const StockCalculatorProScreen(), // 🔥 HALAMAN 4 VERSI UPGRADE PRO
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

// =================================================================
// MODUL INDIKATOR JEMBATAN LIVE (MOCK ENGINE)
// =================================================================
class LiveTradingView extends StatefulWidget {
  final String apiKey; final String baseUrl; final String ticker; final ValueChanged<String> onTickerSearched; 
  const LiveTradingView({super.key, required this.apiKey, required this.baseUrl, required this.ticker, required this.onTickerSearched});
  @override
  State<LiveTradingView> createState() => _LiveTradingViewState();
}
class _LiveTradingViewState extends State<LiveTradingView> {
  final StockStreamService _streamService = StockStreamService();
  @override
  void initState() { super.initState(); _streamService.startStreaming(widget.ticker, widget.apiKey, widget.baseUrl); }
  @override
  void didUpdateWidget(covariant LiveTradingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ticker != widget.ticker) _streamService.startStreaming(widget.ticker, widget.apiKey, widget.baseUrl);
  }
  @override
  void dispose() { _streamService.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CandleModel>>(
      stream: _streamService.chartStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: CircularProgressIndicator());
        final lastCandle = snapshot.data!.last;
        return Card(
          color: const Color(0xff1c2030),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("KODE SAHAM LIVE: ${widget.ticker}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("HARGA TERAKHIR: Rp${lastCandle.close.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, color: Colors.greenAccent)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =================================================================
// SCREENER & RADAR (HALAMAN 2 & 3)
// =================================================================
class StockScreenerScreen extends StatelessWidget {
  final Function(String) onStockSelected;
  const StockScreenerScreen({super.key, required this.onStockSelected});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Filtered Stocks'), backgroundColor: const Color(0xff1c2030)),
      body: ListTile(
        title: const Text("BCIP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: const Text("Fast Trade / Scalping"),
        trailing: const Text("Rp84"),
        onTap: () => onStockSelected("BCIP"),
      ),
    );
  }
}
class MarketRadarScreen extends StatelessWidget {
  final Function(String) onStockSelected;
  const MarketRadarScreen({super.key, required this.onStockSelected});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IDX Market Radar'), backgroundColor: const Color(0xff1c2030)),
      body: ListTile(
        title: const Text("GOTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: const Text("Top Volume Leaders"),
        trailing: const Text("+9.5%"),
        onTap: () => onStockSelected("GOTO"),
      ),
    );
  }
}

// ====================================================================
// 🔥 HALAMAN 4: REKAYASA TOTAL KLONINGAN KALKULATOR SAHAM PRO BEI
// ====================================================================
class StockCalculatorProScreen extends StatefulWidget {
  const StockCalculatorProScreen({super.key});

  @override
  State<StockCalculatorProScreen> createState() => _StockCalculatorProScreenState();
}

class _StockCalculatorProScreenState extends State<StockCalculatorProScreen> {
  // Controller Global Fee Sekuritas
  final _feeBuyGlobalCtrl = TextEditingController(text: "0.15");
  final _feeSellGlobalCtrl = TextEditingController(text: "0.25");

  // Sub-Tab 1: Profit & Loss (Cuan Net)
  final _pnlBuyPriceCtrl = TextEditingController();
  final _pnlSellPriceCtrl = TextEditingController();
  final _pnlLotCtrl = TextEditingController();
  String _pnlResult = "Masukkan data transaksi untuk menghitung cuan bersih.";

  // Sub-Tab 2: Average Down / Up
  final _avgPrice1Ctrl = TextEditingController();
  final _avgLot1Ctrl = TextEditingController();
  final _avgPrice2Ctrl = TextEditingController();
  final _avgLot2Ctrl = TextEditingController();
  String _avgResult = "Masukkan riwayat jemputan muatan harga lama & baru.";

  // Sub-Tab 3: Target Trading Plan (TP / CL)
  final _planBuyPriceCtrl = TextEditingController();
  final _planTargetProfitCtrl = TextEditingController(text: "5.0");
  final _planCutLossCtrl = TextEditingController(text: "2.0");
  String _planResult = "Masukkan modal entrian untuk membuat peta trading plan.";

  // Sub-Tab 4: Hitung Daya Beli Dana Maksimal Lot
  final _cashAvailableCtrl = TextEditingController();
  final _cashStockPriceCtrl = TextEditingController();
  String _cashResult = "Masukkan nilai modal tunai untuk melihat batas lot belanja.";

  @override
  void dispose() {
    _feeBuyGlobalCtrl.dispose(); _feeSellGlobalCtrl.dispose();
    _pnlBuyPriceCtrl.dispose(); _pnlSellPriceCtrl.dispose(); _pnlLotCtrl.dispose();
    _avgPrice1Ctrl.dispose(); _avgLot1Ctrl.dispose(); _avgPrice2Ctrl.dispose(); _avgLot2Ctrl.dispose();
    _planBuyPriceCtrl.dispose(); _planTargetProfitCtrl.dispose(); _planCutLossCtrl.dispose();
    _cashAvailableCtrl.dispose(); _cashStockPriceCtrl.dispose();
    super.dispose();
  }

  // LOGIKA 1: UNTUNG / RUGI NET
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

  // LOGIKA 2: AVERAGE DOWN
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

  // LOGIKA 3: TRADING PLAN TARGET HARGA
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

  // LOGIKA 4: DAYA BELI MAKSIMAL LOT
  void _prosesHitungDayaBeli() {
    double cash = double.tryParse(_cashAvailableCtrl.text) ?? 0;
    double price = double.tryParse(_cashStockPriceCtrl.text) ?? 0;
    double fB = (double.tryParse(_feeBuyGlobalCtrl.text) ?? 0.15) / 100;

    if (cash == 0 || price == 0) return;

    // Rumus: Harga per lot termasuk fee sekuritas
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
            // BAR SETTING FEE SEKURITAS GLOBAL (Ciri Khas Aplikasi Pro)
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
            
            // MAIN CONTENT VIEW TAB
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

  // TAB VIEW 1: PROFIT LOSS
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

  // TAB VIEW 2: AVERAGE DOWN
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

  // TAB VIEW 3: TRADING PLAN
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

  // TAB VIEW 4: DAYA BELI LOT
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

  // UTILS WIDGET BUILDER UNTUK KESERAGAMAN TEMA UI DARK
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
        child: Text(
          content,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.6, color: Colors.greenAccent),
        ),
      ),
    );
  }
}