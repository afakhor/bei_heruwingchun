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
  Offset? _pointA;
  Offset? _pointB;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320, 
      width: double.infinity,
      color: const Color(0xff131722),
      child: GestureDetector(
        // 🚀 FITUR BARU: Ketuk 2 kali di layar grafik untuk menghapus garis Fibo / Gann
        onDoubleTap: () {
          setState(() {
            _pointA = null;
            _pointB = null;
          });
        },
        onPanStart: (details) {
          setState(() {
            _pointA = details.localPosition;
            _pointB = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          if (_pointA != null) {
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

    // 1. HITUNG SKALA GRAFIK CANDLESTICK
    double rawMaxPrice = candles.map((e) => e.high).reduce(max);
    double rawMinPrice = candles.map((e) => e.low).reduce(min);
    
    // ✅ PERBAIKAN 1: Hitung padding konstan dulu agar skala atas & bawah seimbang sempurna
    double paddingHarga = (rawMaxPrice - rawMinPrice) * 0.1;
    if (paddingHarga == 0) paddingHarga = 1.0;

    double maxPrice = rawMaxPrice + paddingHarga;
    double minPrice = rawMinPrice - paddingHarga;
    double priceRange = maxPrice - minPrice;

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
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), paintWick..color = isBullish ? const Color(0xff26a69a) : const Color(0xffef5350));
      canvas.drawRect(Rect.fromLTRB(leftX, openY < closeY ? openY : closeY, rightX, openY > closeY ? openY : closeY), isBullish ? paintBullish : paintBearish);
    }

    // JIKA ADA SENTUHAN JARI, LUKIS FIBO & GANN
    if (pointA != null && pointB != null) {
      // =================================================================
      // MODUL A: FIBONACCI RETRACEMENT (Garis Horizontal)
      // =================================================================
      double startY = pointA!.dy; 
      double endY = pointB!.dy;   
      double heightDelta = endY - startY;

      final fiboRatios = [0.0, 0.382, 0.5, 0.618, 1.0];
      for (var ratio in fiboRatios) {
        double currentLineY = startY + (heightDelta * ratio);
        final fiboPaint = Paint()
          ..color = Colors.blueAccent.withOpacity(0.4)
          ..strokeWidth = ratio == 0.618 ? 1.5 : 0.8;

        canvas.drawLine(Offset(0, currentLineY), Offset(size.width, currentLineY), fiboPaint);
      }

      // =================================================================
      // MODUL B: GANN FAN (Pancaran Sudut Geometri W.D. Gann)
      // =================================================================
      double diffX = pointB!.dx - pointA!.dx; 
      double diffY = pointB!.dy - pointA!.dy; 

      final gannRatios = [
        {'name': '1x4', 'multiplier': 4.0},
        {'name': '1x3', 'multiplier': 3.0},
        {'name': '1x2', 'multiplier': 2.0},
        {'name': '1x1', 'multiplier': 1.0}, 
        {'name': '2x1', 'multiplier': 0.5},
        {'name': '3x1', 'multiplier': 0.33},
        {'name': '4x1', 'multiplier': 0.25},
      ];

      for (var gann in gannRatios) {
        double m = gann['multiplier'] as double;

        double targetX = pointA!.dx + diffX; 
        double targetY = pointA!.dy + (diffY * m); 

        final gannPaint = Paint()
          ..color = gann['name'] == '1x1' ? Colors.redAccent : Colors.white24
          ..strokeWidth = gann['name'] == '1x1' ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(pointA!, Offset(targetX, targetY), gannPaint);

        if (targetX > 0 && targetX < size.width && targetY > 0 && targetY < size.height) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: " ${gann['name']}",
              style: TextStyle(color: gann['name'] == '1x1' ? Colors.redAccent : Colors.grey, fontSize: 9),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(targetX, targetY - 10));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}