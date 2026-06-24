from flask import Flask, jsonify
import yfinance as yf

app = Flask(__name__)


@app.route("/v1/idx/<ticker>/candles", methods=["GET"])
def get_candles(ticker):
    try:
        # 1. Bersihkan input & paksa pakai akhiran .JK (Jakarta Market)
        symbol = ticker.strip().upper()
        if not symbol.endswith(".JK"):
            symbol = f"{symbol}.JK"

        # 2. Tarik data dari Yahoo Finance (3 bulan terakhir, interval harian)
        stock = yf.Ticker(symbol)
        df = stock.history(period="3mo", interval="1d")

        # Proteksi jika kode saham salah atau tidak ada datanya
        if df.empty:
            return (
                jsonify(
                    {
                        "error": f"Saham {ticker} tidak ditemukan di bursa IDX."
                    }
                ),
                404,
            )

        # 3. Bongkar DataFrame Python dan rakit jadi JSON rapi untuk Flutter
        candles_list = []
        for index, row in df.iterrows():
            # Konversi timestamp ke format teks YYYY-MM-DD
            date_str = index.strftime("%Y-%m-%d")

            candles_list.append(
                {
                    "date": date_str,
                    "open": float(row["Open"]),
                    "high": float(row["High"]),
                    "low": float(row["Low"]),
                    "close": float(row["Close"]),
                    "volume": float(row["Volume"]),
                }
            )

        # Kirim balik ke Flutter
        return jsonify(candles_list)

    except Exception as e:
        return (
            jsonify({"error": f"Masalah internal server Python: {str(e)}"}),
            500,
        )


if __name__ == "__main__":
    # host='0.0.0.0' wajib dipasang agar server bisa diakses dari luar localhost (oleh HP/Flutter)
    app.run(host="0.0.0.0", port=5000, debug=True)