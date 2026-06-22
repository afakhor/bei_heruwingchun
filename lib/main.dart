import 'package:flutter/material.dart';
import 'finance_engine_bridge.dart';
import 'stock_stream_service.dart';
import 'candlestick_chart.dart'; // Import chart kustom kita

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
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
    super.initState();
    _streamService.startStreaming(); // Mulai jalankan mesin simulasi data
  }

  @override
  void dispose() {
    _streamService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Signal & Candlestick'),
        backgroundColor: const Color(0xff1c2030),
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

          // Lempar data harga terupdate ke mesin C++ Cepat untuk dinilai status kelayakannya
          final analisa = _engine.checkStockSignal(
            close: lastCandle.close,
            ema5: lastCandle.close * 0.992,
            ema20: lastCandle.close * 0.985,
            ema200: 4900.0, // Batas aman uptrend besar
            rsi: 45.0,
            vwap: lastCandle.close * 0.99,
            adx: 30.0,
            atr: 65.0,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TAMPILAN GRAFIK CANDLESTICK KUSTOM
                CandlestickChart(candles: candleHistory),
                
                const SizedBox(height: 10),
                
                // Info Harga Berjalan di Bawah Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("BBRI REAL-TIME TICK", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        "Rp${lastCandle.close.toStringAsFixed(2)}",
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

                // 2. PANEL REKOMENDASI KEPUTUSAN C++ ENGINE
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
                          
                          // Tampilan Target Pengaman Portofolio
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
                                  const Text("🎯 TAGGET TAKE PROFIT", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
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
