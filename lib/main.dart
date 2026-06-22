import 'package:flutter/material.dart';
import 'finance_engine_bridge.dart';
import 'stock_stream_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(), // Tema gelap ala TradingView biar mata ga rusak
      home: const LiveTradingScreen(),
    );
  }
}

class LiveTradingScreen extends StatefulWidget {
  const LiveTradingScreen({super.key});

  @override
  State<LiveTradingScreen> createState() => _LiveTradingScreenState();
}

class _LiveTradingScreenState extends State<LiveTradingScreen> {
  final FinanceEngineBridge _engine = FinanceEngineBridge();
  final StockStreamService _streamService = StockStreamService();

  @override
  void initState() {
    super.override.initState();
    // Jalankan stream (saat ini otomatis masuk mode simulasi dulu biar aman)
    _streamService.connectToExchange("wss://isi_url_jika_ada", {});
  }

  @override
  void dispose() {
    _streamService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mekanis Running Trade (C++ Powered)')),
      body: StreamBuilder<StockTick>(
        stream: _streamService.tickStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tick = snapshot.data!;

          // DI SINI KEAJAIBANNYA: Setiap ada tick baru dari websocket, 
          // data langsung dioper ke C++ untuk dihitung indikator & skornya secara instan.
          // (Di bawah ini adalah contoh angka kalkulasi indikator yang di-supply ke engine)
          final analisa = _engine.checkStockSignal(
            close: tick.close,
            ema5: tick.close * 0.99,  // Simulasi nilai terhitung
            ema20: tick.close * 0.97, // Simulasi
            ema200: 4800.0,           // Angka acuan uptrend besar
            rsi: 42.0,                // Posisi aman, bukan pucuk
            vwap: tick.close * 0.98,  // Di bawah harga running, bandar akumulasi
            adx: 28.0,                // Tren kuat
            atr: 75.0,                // Volatilitas saham
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Tampilan Harga Real-Time
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text("RUNNING TICK (BBRI)", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        Text(
                          "Rp${tick.close.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold,
                            color: analisa.action == 1 ? Colors.greenAccent : Colors.white
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Card Hasil Analisis Sang Penjaga Portofolio (C++)
                Card(
                  color: analisa.action == 1 ? Colors.green.withOpacity(0.2) : Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: analisa.action == 1 ? Colors.green : Colors.transparent),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          analisa.action == 1 ? "🟢 REKOMENDASI: BUY" : "⚪ REKOMENDASI: WAIT / HOLD",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 30, color: Colors.grey),
                        Text("Sistem Scoring Engine: ${analisa.score} / 100 Poin", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text("🛡️ STOP LOSS", style: TextStyle(color: Colors.redAccent)),
                                Text(analisa.stopLoss > 0 ? "Rp${analisa.stopLoss.toStringAsFixed(0)}" : "-", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text("🎯 TAKE PROFIT", style: TextStyle(color: Colors.greenAccent)),
                                Text(analisa.takeProfit > 0 ? "Rp${analisa.takeProfit.toStringAsFixed(0)}" : "-", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        )
                      ],
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
