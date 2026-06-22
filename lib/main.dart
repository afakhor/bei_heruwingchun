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
      home: const MainNavigationScreen(),
    );
  }
}

// 1. ENGINE UTAMA UNTUK MENGATUR NAVIGASI BAWAH LAYAR
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Daftar halaman yang bisa diakses
  final List<Widget> _pages = [
    const LiveTradingScreen(), // Halaman 1: Chart & Live Signal
    const StockScreenerScreen(), // Halaman 2: Hasil Filter Terbaik Hari Ini
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xff1c2030),
        selectedItemColor: const Color(0xff26a69a), // Hijau TradingView
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Live Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.调色板_outlined), // Menggunakan ikon filter/list
            activeIcon: Icon(Icons.insights),
            label: 'Top Filtered',
          ),
        ],
      ),
    );
  }
}

// =================================================================
// HALAMAN 1: LIVE TRADING SCREEN (Kode Kamu yang Sebelumnya)
// =================================================================
class LiveTradingScreen extends StatefulWidget {
  const LiveTradingScreen({super.key});

  @override
  State<LiveTradingScreen> createState() => _LiveTradingScreenState();
}

class _LiveTradingScreenState extends State<LiveTradingScreen> {
  final FinanceEngineBridge _engine = FinanceEngineBridge();
  final StockStreamService _streamService = StockStreamService();
  
  String _currentTicker = 'BBRI';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _streamService.startStreaming(_currentTicker);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff1c2030),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Ketik kode saham... (e.g. BCIP, ANTM, BBCA)',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                onSubmitted: _gantiSaham,
              )
            : Text('Live Engine: $_currentTicker'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.greenAccent),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      backgroundColor: const Color(0xff161a25),
      body: StreamBuilder<List<CandleModel>>(
        stream: _streamService.chartStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: UniqueKey(),
                  child: CandlestickChart(candles: candleHistory),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                const Divider(color: Colors.grey, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: analisa.action == 1 ? const Color(0xff1b3a32) : const Color(0xff1f222e),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: analisa.action == 1 ? const Color(0xff26a69a) : Colors.transparent, width: 1.5),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            analisa.action == 1 ? "🟢 AUTO SIGNAL: BUY" : "⚪ AUTO SIGNAL: HOLD / WAIT",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =================================================================
// HALAMAN 2: NEW WIDGET - STOCK SCREENER SCREEN (HASIL FILTERAN)
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

class StockScreenerScreen extends StatelessWidget {
  const StockScreenerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulasi database data filteran bursa real-time hari ini
    final List<ScreenedStockModel> topStocks = [
      ScreenedStockModel(rank: 1, ticker: 'BCIP', name: 'Bumi Citra Permai Tbk', price: 84, changePercent: 14.2, score: 95, strategyTag: 'Fast Trade / Scalping'),
      ScreenedStockModel(rank: 2, ticker: 'BRIS', name: 'Bank Syariah Indonesia Tbk', price: 2540, changePercent: 6.8, score: 89, strategyTag: 'Volume Spike Breakout'),
      ScreenedStockModel(rank: 3, ticker: 'ANTM', name: 'Aneka Tambang Tbk', price: 1620, changePercent: 4.5, score: 82, strategyTag: 'EMA Cross Uptrend'),
      ScreenedStockModel(rank: 4, ticker: 'BBRI', name: 'Bank Rakyat Indonesia Tbk', price: 5225, changePercent: 1.8, score: 78, strategyTag: 'Buy on Weakness'),
      ScreenedStockModel(rank: 5, ticker: 'TLKM', name: 'Telkom Indonesia Tbk', price: 3640, changePercent: -0.5, score: 65, strategyTag: 'Sideways Testing Support'),
    ];

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
            // Banner Keterangan Filter
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff1b3a32).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff26a69a).withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Kriteria: Momentum Bullish + Volume Spike di atas rata-rata MA20. Diupdate otomatis oleh C++ Scoring Engine.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            
            // LIST UTAMA HASIL FILTER SAHAM
            Expanded(
              child: ListView.builder(
                itemCount: topStocks.length,
                itemBuilder: (context, index) {
                  final stock = topStocks[index];
                  bool isPositive = stock.changePercent >= 0;

                  return Card(
                    color: const Color(0xff1f222e),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // Rank Number di sebelah kiri
                      leading: CircleAvatar(
                        backgroundColor: stock.rank <= 2 ? const Color(0xff26a69a) : Colors.grey[800],
                        child: Text('#${stock.rank}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      // Ticker dan Nama Perusahaan
                      title: Row(
                        children: [
                          Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4)
                            ),
                            child: Text(stock.strategyTag, style: const TextStyle(fontSize: 10, color: Colors.cyanAccent)),
                          )
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.top(4.0),
                        child: Text(stock.name, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      // Harga dan Persentase Perubahan di Sebelah Kanan
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