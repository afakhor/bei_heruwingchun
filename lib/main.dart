import 'package:flutter/material.dart';
import 'finance_engine_bridge.dart'; // Import jembatan kita

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('BEI Real-Time Engine')),
        body: const SignalTesterWidget(),
      ),
    );
  }
}

class SignalTesterWidget extends StatefulWidget {
  const SignalTesterWidget({super.key});

  @override
  State<SignalTesterWidget> createState() => _SignalTesterWidgetState();
}

class _SignalTesterWidgetState extends State<SignalTesterWidget> {
  // Inisialisasi engine bridge
  final FinanceEngineBridge _engine = FinanceEngineBridge();
  String _resultDisplay = "Belum ada analisis";

  void _runTestAnalysis() {
    // Simulasi data saham yang BAGUS (Uptrend, akumulasi, momentum pas)
    final hasilAnalisis = _engine.checkStockSignal(
      close: 5200.0,  // Harga BBRI misal Rp5.200
      ema5: 5150.0,
      ema20: 5100.0,  // Golden Cross (EMA 5 > EMA 20)
      ema200: 4800.0, // Harga jauh di atas EMA 200 (Uptrend besar)
      rsi: 45.0,      // RSI aman, tidak overbought / bukan di pucuk
      vwap: 5180.0,   // Harga di atas modal bandar hari ini
      adx: 30.0,      // Tren dikonfirmasi kuat (ADX > 25)
      atr: 80.0,      // Volatilitas normal harian Rp80
    );

    setState(() {
      _resultDisplay = "SKOR: ${hasilAnalisis.score}\n"
          "AKSI: ${hasilAnalisis.action == 1 ? '🟢 BUY' : '⚪ HOLD'}\n"
          "STOP LOSS: Rp${hasilAnalisis.stopLoss.toStringAsFixed(0)}\n"
          "TAKE PROFIT: Rp${hasilAnalisis.takeProfit.toStringAsFixed(0)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _resultDisplay,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _runTestAnalysis,
              child: const Text('Jalankan Test C++ Engine'),
            ),
          ],
        ),
      ),
    );
  }
}
