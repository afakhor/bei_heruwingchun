from flask import Flask, jsonify
import sys
import requests
import pandas as pd
from datetime import datetime

app = Flask(__name__)

@app.route("/v1/idx/<ticker>/candles", methods=["GET"])
def get_candles(ticker):
    try:
        # 1. Bersihkan input & paksa pakai akhiran .JK (Jakarta Market)
        symbol = ticker.strip().upper()
        if not symbol.endswith(".JK"):
            symbol = f"{symbol}.JK"

        # 🔥 JALUR BELAKANG: Tembak langsung API Chart internal Yahoo tanpa lewat 'yfinance'
        url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?range=3mo&interval=1d"
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
        
        response = requests.get(url, headers=headers)
        data = response.json()

        # Proteksi jika kode saham tidak valid atau diblokir
        if not data.get('chart') or not data['chart'].get('result') or data['chart']['result'] is None:
            return jsonify({"error": f"Saham {ticker} tidak ditemukan di bursa IDX."}), 404

        # Ekstrak data mentah dari JSON Yahoo
        result = data['chart']['result'][0]
        timestamps = result.get('timestamp', [])
        quote = result.get('indicators', {}).get('quote', [{}])[0]

        if not timestamps or not quote.get('open'):
            return jsonify({"error": f"Data saham {ticker} kosong atau tidak tersedia."}), 404

        # 2. Bangun struktur data Candlestick secara manual agar aman
        df = pd.DataFrame({
            'Open': quote.get('open', []),
            'High': quote.get('high', []),
            'Low': quote.get('low', []),
            'Close': quote.get('close', []),
            'Volume': quote.get('volume', [])
        }, index=[datetime.fromtimestamp(t) for t in timestamps])

        # Bersihkan data baris kosong (jika ada hari libur bursa)
        df = df.dropna()

        # 3. Bongkar DataFrame Python dan rakit jadi JSON rapi untuk Flutter
        candles_list = []
        for index, row in df.iterrows():
            candles_list.append({
                "date": index.strftime('%Y-%m-%d'),
                "open": float(row['Open']),
                "high": float(row['High']),
                "low": float(row['Low']),
                "close": float(row['Close']),
                "volume": int(row['Volume'])
            })

        # Kirim data sukses balik ke Flutter
        return jsonify({
            "status": "success",
            "ticker": ticker.upper(),
            "candles": candles_list
        })

    except Exception as e:
        return jsonify({"error": f"Terjadi kesalahan sistem: {str(e)}"}), 500

if __name__ == "__main__":
    # Tetap pasang host 0.0.0.0 untuk keperluan pengujian lokal jika dibutuhkan
    app.run(host="0.0.0.0", port=5000, debug=True)