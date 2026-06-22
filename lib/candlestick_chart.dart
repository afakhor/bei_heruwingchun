import 'package:flutter/material.dart';
import 'stock_stream_service.dart';
import 'dart:math';

class CandlestickChart extends StatefulWidget {
  final List<CandleModel> candles;

  const CandlestickChart({super.key, required this.candles});

  @override
  State<CandlestickChart> createState() => _CandlestickChartState();
}

class _CandlestickChartState extends State<CandlestickChart> {
  // Koordinat pixel untuk menarik garis Fibonacci manual
  Offset? _pointA;
  Offset? _pointB;
  bool _isDrawingFibo = true; // Mode aktif menggambar

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // Kita naikkan sedikit tingginya agar lebih lega untuk digambar
      width: double.infinity,
      color: const Color(0xff131722),
      child: GestureDetector(
        // Tangkap momen saat jari pertama kali menyentuh layar (Titik A)
        onPanStart: (details) {
          if (_isDrawingFibo) {
            setState(() {
              _pointA = details.localPosition;
              _pointB = details.localPosition; // Inisialisasi awal sama
            });
          }
        },
        // Tangkap pergerakan jari saat digeser/diseret (Update Titik B)
        onPanUpdate: (details) {
          if (_isDrawingFibo && _pointA != null) {
            setState(() {
              _pointB = details.localPosition;
            });
          }
        },
        child: CustomPaint(
          painter: _ChartPainter(
            candles: widget.candles,
            pointA: _pointA,
            pointB: _pointB,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<CandleModel> candles;
  final Offset? pointA;
  final Offset? pointB;

  _ChartPainter({required this.candles, this.pointA, this.pointB});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // =================================================================
    // 1. HITUNG SKALA GRAFIK CANDLESTICK (Sama seperti kemarin)
    // =================================================================
    double maxPrice = candles.map((e) => e.high).reduce(max);
    double minPrice = candles.map((e) => e.low).reduce(min);
    
    maxPrice += (maxPrice - minPrice) * 0.1;
    minPrice -= (maxPrice - minPrice) * 0.1;
    double priceRange = maxPrice - minPrice;
    if (priceRange == 0) priceRange = 1;

    double widthPerCandle = size.width / candles.length;
    double candleWidth = widthPerCandle * 0.75;

    final paintBullish = Paint()..color = const Color(0xff26a69a)..style = PaintingStyle.fill;
    final paintBearish = Paint()..color = const Color(0xffef5350)..style = PaintingStyle.fill;
    final paintWick = Paint()..strokeWidth = 1.5;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      double openY = size.height * (1 - (candle.open - minPrice) / priceRange);
      double closeY = size.height * (1 - (candle.close - minPrice) / priceRange);
      double highY = size.height * (1 - (candle.high - minPrice) / priceRange);
      double lowY = size.height * (1 - (candle.low - minPrice) / priceRange);

      double centerX = (i * widthPerCandle) + (widthPerCandle / 2);
      double leftX = centerX - (candleWidth / 2);
      double rightX = centerX + (candleWidth / 2);

      bool isBullish = candle.close >= candle.open;
      Paint currentPaint = isBullish ? paintBullish : paintBearish;
      paintWick.color = isBullish ? const Color(0xff26a69a) : const Color(0xffef5350);

      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), paintWick);
      canvas.drawRect(Rect.fromLTRB(leftX, topY(openY, closeY), rightX, bottomY(openY, closeY)), currentPaint);
    }

    // =================================================================
    // 2. MODUL MATEMATIKA: MENGGAMBAR FIBONACCI RETRACEMENT
    // =================================================================
    if (pointA != null && pointB != null) {
      double startY = pointA!.y;
      double endY = pointB!.y;
      double heightDelta = endY - startY;

      // Daftar rasio emas Fibonacci Retracement baku sesuai standar trading harian
      final fiboRatios = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];
      final fiboColors = [
        Colors.red,          // 0.0
        Colors.orange,       // 0.236
        Colors.yellow,       // 0.382
        Colors.green,        // 0.5 (Zonasi krusial psikologis)
        Colors.greenAccent,  // 0.618 (The Golden Ratio)
        Colors.blue,         // 0.786
        Colors.purple        // 1.0
      ];

      for (int i = 0; i < fiboRatios.length; i++) {
        double ratio = fiboRatios[i];
        // Hitung koordinat Y pixel berdasarkan rasio tarikan jari
        double currentLineY = startY + (heightDelta * ratio);

        // Konversi koordinat Y pixel kembali menjadi perkiraan Nilai Harga Saham asli
        double estimatedPrice = maxPrice - ((currentLineY / size.height) * priceRange);

        // Konfigurasi kuas untuk menggambar garis Fibo
        final fiboPaint = Paint()
          ..color = fiboColors[i].withOpacity(0.7)
          ..strokeWidth = (ratio == 0.618 || ratio == 0.5) ? 2.0 : 1.0 // Tebalkan Golden Ratio
          ..style = PaintingStyle.stroke;

        // A. Gambar garis horizontal dari ujung kiri layar ke ujung kanan layar
        canvas.drawLine(Offset(0, currentLineY), Offset(size.width, currentLineY), fiboPaint);

        // B. Cetak teks label harga Fibo di atas garisnya agar kelihatan jelas harganya berapa
        final textPainter = TextPainter(
          text: TextSpan(
            text: " Fibo ${ratio.toStringAsFixed(3)} (Rp${estimatedPrice.toStringAsFixed(0)})",
            style: TextStyle(color: fiboColors[i], fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        // Render teks sedikit di atas garis di sebelah kiri layar
        textPainter.paint(canvas, Offset(5, currentLineY - 12));
      }
    }
  }

  double topY(double o, double c) => o < c ? o : c;
  double bottomY(double o, double c) => o > c ? o : c;

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    // Selalu lukis ulang saat data candle berubah atau koordinat sentuhan jari bergeser
    return true;
  }
}
