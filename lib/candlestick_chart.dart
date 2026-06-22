import 'package:flutter/material.dart';
import 'stock_stream_service.dart';
import 'dart:math';

class CandlestickChart extends StatelessWidget {
  final List<CandleModel> candles;

  const CandlestickChart({super.key, required this.candles});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Tinggi area grafik chart
      width: double.infinity,
      color: const Color(0xff131722), // Warna latar gelap khas TradingView
      child: CustomPaint(
        painter: _ChartPainter(candles: candles),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<CandleModel> candles;

  _ChartPainter({required this.candles});

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // 1. Cari Harga Tertinggi (Max) & Terendah (Min) dari histori untuk penentuan skala Y
    double maxPrice = candles.map((e) => e.high).reduce(max);
    double minPrice = candles.map((e) => e.low).reduce(min);
    
    // Beri sedikit ruang kosong (padding) di atas dan bawah grafik
    maxPrice += (maxPrice - minPrice) * 0.1;
    minPrice -= (maxPrice - minPrice) * 0.1;

    double priceRange = maxPrice - minPrice;
    if (priceRange == 0) priceRange = 1;

    // 2. Hitung dimensi ukuran per bar candle (Skala X)
    double widthPerCandle = size.width / candles.length;
    double candleWidth = widthPerCandle * 0.75; // Jarak antar lilin (lebar body 75%)

    final paintBullish = Paint()..color = const Color(0xff26a69a)..style = PaintingStyle.fill; // Hijau TradingView
    final paintBearish = Paint()..color = const Color(0xffef5350)..style = PaintingStyle.fill; // Merah TradingView
    final paintWick = Paint()..strokeWidth = 1.5;

    // 3. Mulai melukis lilin satu per satu
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];

      // Konversi koordinat matematika harga ke bentuk Koordinat Pixel Layar (Y Axis)
      double openY = size.height * (1 - (candle.open - minPrice) / priceRange);
      double closeY = size.height * (1 - (candle.close - minPrice) / priceRange);
      double highY = size.height * (1 - (candle.high - minPrice) / priceRange);
      double lowY = size.height * (1 - (candle.low - minPrice) / priceRange);

      // Hitung posisi horizontal (X Axis)
      double centerX = (i * widthPerCandle) + (widthPerCandle / 2);
      double leftX = centerX - (candleWidth / 2);
      double rightX = centerX + (candleWidth / 2);

      // Tentukan warna berdasarkan kondisi (Bullish atau Bearish)
      bool isBullish = candle.close >= candle.open;
      Paint currentPaint = isBullish ? paintBullish : paintBearish;
      paintWick.color = isBullish ? const Color(0xff26a69a) : const Color(0xffef5350);

      // A. Gambar Sumbu Lilin (Wick / High-Low Line)
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), paintWick);

      // B. Gambar Badan Lilin (Body Rect / Open-Close Box)
      double topY = min(openY, closeY);
      double bottomY = max(openY, closeY);
      
      // Jika harga doji (open == close), beri tebal minimal 1 pixel agar kelihatan
      if (topY == bottomY) bottomY += 1.0; 

      canvas.drawRect(Rect.fromLTRB(leftX, topY, rightX, bottomY), currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    // Repaint terus setiap ada perubahan data stream baru masuk
    return true;
  }
}
