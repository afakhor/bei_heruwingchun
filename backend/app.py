# ====================================================================
# 1. IMPORT SEMUA LIBRARY (Pastikan 'requests' sudah masuk)
# ====================================================================
from flask import Flask, jsonify, request
import requests
import yfinance as yf
import pandas as pd
import numpy as np
import time

app = Flask(__name__)

# ====================================================================
# 2. SETUP SESSION UNTUK MENGAKALI BLOKIR YAHOO FINANCE
# ====================================================================
custom_session = requests.Session()
custom_session.headers.update({
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
})

# ====================================================================
# 3. FUNGSI HITUNG INDIKATOR TEKNIKAL
# ====================================================================
def calculate_indicators(df):
    """Menghitung semua indikator teknikal menggunakan pure pandas/numpy"""
    if len(df) < 200:  # Pastikan data cukup untuk EMA 200
        return None

    # 1. EMA 5, 20, 200
    df['ema5'] = df['Close'].ewm(span=5, adjust=False).mean()
    df['ema20'] = df['Close'].ewm(span=20, adjust=False).mean()
    df['ema200'] = df['Close'].ewm(span=200, adjust=False).mean()

    # 2. RSI 14 (Wilder's Smoothing)
    delta = df['Close'].diff()
    gain = delta.clip(lower=0)
    loss = -delta.clip(upper=0)
    avg_gain = gain.ewm(com=13, adjust=False).mean()
    avg_loss = loss.ewm(com=13, adjust=False).mean()
    rs = avg_gain / (avg_loss + 1e-10)
    df['rsi'] = 100 - (100 / (1 + rs))

    # 3. VWAP (Pendekatan Rolling VWAP untuk data harian)
    typical_price = (df['High'] + df['Low'] + df['Close']) / 3
    df['vwap'] = (typical_price * df['Volume']).rolling(window=14).sum() / (df['Volume'].rolling(window=14).sum() + 1e-10)

    # 4. ATR 14
    high_low = df['High'] - df['Low']
    high_cp = (df['High'] - df['Close'].shift()).abs()
    low_cp = (df['Low'] - df['Close'].shift()).abs()
    tr = pd.concat([high_low, high_cp, low_cp], axis=1).max(axis=1)
    df['atr'] = tr.ewm(com=13, adjust=False).mean()

    # 5. ADX 14
    plus_dm = df['High'].diff()
    minus_dm = df['Low'].diff()

    plus_dm = np.where((plus_dm > minus_dm) & (plus_dm > 0), plus_dm, 0.0)
    minus_dm = np.where((minus_dm > plus_dm) & (minus_dm > 0), minus_dm, 0.0)

    plus_di = 100 * (pd.Series(plus_dm, index=df.index).ewm(com=13, adjust=False).mean() / (df['atr'] + 1e-10))
    minus_di = 100 * (pd.Series(minus_dm, index=df.index).ewm(com=13, adjust=False).mean() / (df['atr'] + 1e-10))

    dx = 100 * (plus_di - minus_di).abs() / ((plus_di + minus_di) + 1e-10)
    df['adx'] = dx.ewm(com=13, adjust=False).mean()

    return df

# ====================================================================
# 4. ENDPOINT SCREENER (Satu Tanda @ Sudah Diperbaiki)
# ====================================================================
@app.route('/v1/idx/api/screener', methods=['GET'])
def get_screener():
    try:
        # TOTAL 150 SAHAM PILIHAN TERBAIK UNTUK SCALPER & FAST TRADE
        active_tickers = [
            # --- 1. JANGKAR LIKUIDITAS & BLUE CHIP AKTIF (20 Saham) ---
            "BBCA.JK", "BBRI.JK", "BMRI.JK", "BBNI.JK", "BBTN.JK", "BRIS.JK", "ARTO.JK", "BBYB.JK", "ASII.JK", "TLKM.JK",
            "UNVR.JK", "KLBF.JK", "INDF.JK", "ICBP.JK", "AMMN.JK", "GOTO.JK", "BUKA.JK", "EMTK.JK", "ASHA.JK", "AUTO.JK",

            # --- 2. HIGH BETA, TEKNOLOGI & GRUP KONGROMERAT (25 Saham) ---
            "BREN.JK", "CUAN.JK", "TPIA.JK", "BRPT.JK", "WIRG.JK", "FILM.JK", "MLPL.JK", "MPPA.JK", "KPIG.JK", "LPKR.JK",
            "LPPF.JK", "MNCN.JK", "PWON.JK", "SCMA.JK", "SRTG.JK", "BMTR.JK", "BSDE.JK", "CTRA.JK", "DILD.JK", "JSMR.JK",
            "CENT.JK", "CFIN.JK", "PANS.JK", "GGRM.JK", "KAEF.JK",

            # --- 3. KOMODITAS: ENERGI, EMAS & MINERAL (35 Saham) ---
            "ADRO.JK", "PTBA.JK", "ITMG.JK", "HRUM.JK", "MEDC.JK", "ENRG.JK", "SGER.JK", "MBMA.JK", "NCKL.JK", "ANTM.JK",
            "BRMS.JK", "MDKA.JK", "TINS.JK", "DKFT.JK", "KKGI.JK", "BUMI.JK", "DEWA.JK", "DOID.JK", "ELSA.JK", "AKRA.JK",
            "PGAS.JK", "PGEO.JK", "COAL.JK", "ELPI.JK", "RMKO.JK", "RMKE.JK", "BIPI.JK", "WINS.JK", "SIDO.JK", "SMGR.JK",
            "LSIP.JK", "SSMS.JK", "TBLA.JK", "TKIM.JK", "TOWR.JK",

            # --- 4. FAVORIT SCALPER, LAPIS 3 & WILD CARD (70 Saham) ---
            "BCIP.JK", "BAJA.JK", "AADI.JK", "ACES.JK", "PANI.JK", "CHIP.JK", "RGAS.JK", "GULA.JK", "RAFI.JK", "NZIA.JK",
            "CAKK.JK", "YELO.JK", "KAYU.JK", "WIIM.JK", "PACK.JK", "VAST.JK", "HALO.JK", "FUTR.JK", "TRON.JK", "VKTR.JK",
            "INET.JK", "CYBR.JK", "MUTU.JK", "HUMI.JK", "STRK.JK", "SURI.JK", "LIVE.JK", "VISI.JK", "DATA.JK", "CARS.JK",
            "CLEO.JK", "ERAA.JK", "ESSA.JK", "EXCL.JK", "GJTL.JK", "HMSP.JK", "MAPI.JK", "MPMX.JK", "PNLF.JK", "PTPP.JK",
            "WIKA.JK", "SSIA.JK", "ADMR.JK", "HEAL.JK", "MDKI.JK", "SMLE.JK", "ACRO.JK", "CGAS.JK", "NICE.JK", "MSJA.JK",
            "RAJA.JK", "RALS.JK", "SMSM.JK", "TBIG.JK", "BIRD.JK", "BKSL.JK", "BWPT.JK", "TAYS.JK", "NATO.JK", "BULL.JK",
            "APIC.JK", "META.JK", "ASPI.JK", "AWAN.JK", "DOOH.JK", "LABA.JK", "GRPH.JK", "AREA.JK", "ATLA.JK", "SOLA.JK"
        ]

        screener_list = []
        chunk_size = 25 # Pas pas posisi RAM gratisan

        for i in range(0, len(active_tickers), chunk_size):
            chunk = active_tickers[i:i + chunk_size]

            try:
                # Ambil data massal per 25 saham
                df_bulk = yf.download(chunk, period="1y", interval="1d", group_by="ticker", progress=False, session=custom_session)
            except Exception:
                continue

            for ticker in chunk:
                try:
                    if isinstance(df_bulk.columns, pd.MultiIndex):
                        if ticker not in df_bulk.columns.levels[0]:
                            continue
                        df = df_bulk[ticker].dropna(subset=['Close'])
                    else:
                        df = df_bulk.dropna(subset=['Close'])

                    if df.empty or len(df) < 60:
                        continue

                    df_computed = calculate_indicators(df)
                    if df_computed is None:
                        continue

                    last_row = df_computed.iloc[-1]
                    ticker_clean = ticker.replace('.JK', '')

                    screener_list.append({
                        "ticker": ticker_clean,
                        "close": float(last_row['Close']),
                        "ema5": float(last_row['ema5']) if 'ema5' in last_row else 0.0,
                        "ema20": float(last_row['ema20']) if 'ema20' in last_row else 0.0,
                        "ema200": float(last_row['ema200']) if 'ema200' in last_row else 0.0,
                        "rsi": float(last_row['rsi']) if 'rsi' in last_row else 50.0,
                        "vwap": float(last_row['vwap']) if 'vwap' in last_row else float(last_row['Close']),
                        "adx": float(last_row['adx']) if 'adx' in last_row else 0.0,
                        "atr": float(last_row['atr']) if 'atr' in last_row else 0.0
                    })
                except Exception:
                    continue

            # Jeda dipercepat ke 0.6 detik agar total proses di bawah 25 detik (bebas timeout Flutter)
            time.sleep(0.6)

        return jsonify(screener_list)

    except Exception as e:
        return jsonify({"error": f"Gagal memuat screener: {str(e)}"}), 500


# ====================================================================
# 5. ENDPOINT CANDLESTICK
# ====================================================================
@app.route('/v1/idx/api/candles/<ticker>', methods=['GET'])
def get_ticker_candles(ticker):
    try:
        tf = request.args.get('tf', 'month').lower()

        if tf == 'intraday':
            period, interval = "1d", "5m"
        elif tf == 'week':
            period, interval = "5d", "15m"
        elif tf == 'month':
            period, interval = "1mo", "1d"
        elif tf == 'ytd':
            period, interval = "ytd", "1d"
        else:
            period, interval = "1mo", "1d"

        ticker_jk = f"{ticker.upper()}.JK"

        # Ditambahkan parameter session agar aman dari blokir Yahoo Finance
        df = yf.download(ticker_jk, period=period, interval=interval, progress=False, session=custom_session)

        if df.empty:
            return jsonify({"error": "Data tidak ditemukan"}), 404

        candles = []
        for index, row in df.iterrows():
            candles.append({
                "date": index.strftime('%Y-%m-%d %H:%M:%S'),
                "open": float(row['Open']),
                "high": float(row['High']),
                "low": float(row['Low']),
                "close": float(row['Close']),
                "volume": float(row['Volume'])
            })

        return jsonify({"candles": candles})

    except Exception as e:
        return jsonify({"error": str(e)}), 500
@app.route('/')
def cek_status():
    return {"status": "Server Python Hidup dan Lancar Jaya!", "code": 200}



if __name__ == '__main__':
    app.run(debug=True)