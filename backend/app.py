import flask
# 🔥 PERBAIKAN: Menambahkan Flask dan request ke dalam import
from flask import Flask, jsonify, request 
import yfinance as yf
import pandas as pd
import numpy as np

# 🔥 PERBAIKAN: Menggunakan Flask yang sudah di-import langsung
app = Flask(__name__)

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
    rs = avg_gain / (avg_loss + 1e-10) # hindari pembagian dengan nol
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

@app.route('/api/screener', methods=['GET'])
def get_screener():
    try:
        active_tickers = [
            "AALI.JK", "ABBA.JK", "ABDA.JK", 
"ABMM.JK", "ACES.JK", "ACST.JK", "ADES.JK", 
"ADHI.JK", "AISA.JK", "AKKU.JK", "AKPI.JK", 
"AKRA.JK", "AKSI.JK", "ALDO.JK", "ALKA.JK", 
"ALMI.JK", "ALTO.JK", "AMAG.JK", "AMFG.JK", 
"AMIN.JK", "AMRT.JK", "ANJT.JK", "ANTM.JK", 
"APEX.JK", "APIC.JK", "APII.JK", "APLI.JK", 
"APLN.JK", "ARGO.JK", "ARII.JK", "ARNA.JK", 
"ARTA.JK", "ARTI.JK", "ARTO.JK", "ASBI.JK", 
"ASDM.JK", "ASGR.JK", "ASII.JK", "ASJT.JK", 
"ASMI.JK", "ASRI.JK", "ASRM.JK", "ASSA.JK", 
"ATIC.JK", "AUTO.JK", "BABP.JK", "BACA.JK", 
"BAJA.JK", "BALI.JK", "BAPA.JK", "BATA.JK", 
"BAYU.JK", "BBCA.JK", "BBHI.JK", "BBKP.JK", 
"BBLD.JK", "BBMD.JK", "BBNI.JK", "BBRI.JK", 
"BBRM.JK", "BBTN.JK", "BBYB.JK", "BCAP.JK", 
"BCIC.JK", "BCIP.JK", "BDMN.JK", "BEKS.JK", 
"BEST.JK", "BFIN.JK", "BGTG.JK", "BHIT.JK", 
"BIKA.JK", "BIMA.JK", "BINA.JK", "BIPI.JK", 
"BIPP.JK", "BIRD.JK", "BISI.JK", "BJBR.JK", 
"BJTM.JK", "BKDP.JK", "BKSL.JK", "BKSW.JK", 
"BLTA.JK", "BLTZ.JK", "BMAS.JK", "BMRI.JK", 
"BMSR.JK", "BMTR.JK", "BNBA.JK", "BNBR.JK", 
"BNGA.JK", "BNII.JK", "BNLI.JK", "BOLT.JK", 
"BPFI.JK", "BPII.JK", "BRAM.JK", "BRMS.JK", 
"BRNA.JK", "BRPT.JK", "BSDE.JK", "BSIM.JK", 
"BSSR.JK", "BSWD.JK", "BTEK.JK", "BTEL.JK", 
"BTON.JK", "BTPN.JK", "BUDI.JK", "BUKK.JK", 
"BULL.JK", "BUMI.JK", "BUVA.JK", "BVIC.JK", 
"BWPT.JK", "BYAN.JK", "CANI.JK", "CASS.JK", 
"CEKA.JK", "CENT.JK", "CFIN.JK", "CINT.JK", 
"CITA.JK", "CLPI.JK", "CMNP.JK", "CMPP.JK", 
"CNKO.JK", "CNTX.JK", "COWL.JK", "CPIN.JK", 
"CPRO.JK", "CSAP.JK", "CTBN.JK", "CTRA.JK", 
"CTTH.JK", "DART.JK", "DEFI.JK", "DEWA.JK", 
"DGIK.JK", "DILD.JK", "DKFT.JK", "DLTA.JK", 
"DMAS.JK", "DNAR.JK", "DNET.JK", "DOID.JK", 
"DPNS.JK", "DSFI.JK", "DSNG.JK", "DSSA.JK", 
"DUTI.JK", "DVLA.JK", "DYAN.JK", "ECII.JK", 
"EKAD.JK", "ELSA.JK", "ELTY.JK", "EMDE.JK", 
"EMTK.JK", "ENRG.JK", "EPMT.JK", "ERAA.JK", 
"ERTX.JK", "ESSA.JK", "ESTI.JK", "ETWA.JK", 
"EXCL.JK", "FAST.JK", "FASW.JK", "FISH.JK", 
"FMII.JK", "FORU.JK", "FPNI.JK", "GAMA.JK", 
"GDST.JK", "GDYR.JK", "GEMA.JK", "GEMS.JK", 
"GGRM.JK", "GIAA.JK", "GJTL.JK", "GLOB.JK", 
"GMTD.JK", "GOLD.JK", "GOLL.JK", "GPRA.JK", 
"GSMF.JK", "GTBO.JK", "GWSA.JK", "GZCO.JK", 
"HADE.JK", "HDFA.JK", "HERO.JK", "HEXA.JK", 
"HITS.JK", "HMSP.JK", "HOME.JK", "HOTL.JK", 
"HRUM.JK", "IATA.JK", "IBFN.JK", "IBST.JK", 
"ICBP.JK", "ICON.JK", "IGAR.JK", "IIKP.JK", 
"IKAI.JK", "IKBI.JK", "IMAS.JK", "IMJS.JK", 
"IMPC.JK", "INAF.JK", "INAI.JK", "INCI.JK", 
"INCO.JK", "INDF.JK", "INDR.JK", "INDS.JK", 
"INDX.JK", "INDY.JK", "INKP.JK", "INPC.JK", 
"INPP.JK", "INRU.JK", "INTA.JK", "INTD.JK", 
"INTP.JK", "IPOL.JK", "ISAT.JK", "ISSP.JK", 
"ITMA.JK", "ITMG.JK", "JAWA.JK", "JECC.JK", 
"JIHD.JK", "JKON.JK", "JPFA.JK", "JRPT.JK", 
"JSMR.JK", "JSPT.JK", "JTPE.JK", "KAEF.JK", 
"KARW.JK", "KBLI.JK", "KBLM.JK", "KBLV.JK", 
"KBRI.JK", "KDSI.JK", "KIAS.JK", "KICI.JK", 
"KIJA.JK", "KKGI.JK", "KLBF.JK", "KOBX.JK", 
"KOIN.JK", "KONI.JK", "KOPI.JK", "KPIG.JK", 
"KRAS.JK", "KREN.JK", "LAPD.JK", "LCGP.JK", 
"LEAD.JK", "LINK.JK", "LION.JK", "LMAS.JK", 
"LMPI.JK", "LMSH.JK", "LPCK.JK", "LPGI.JK", 
"LPIN.JK", "LPKR.JK", "LPLI.JK", "LPPF.JK", 
"LPPS.JK", "LRNA.JK", "LSIP.JK", "LTLS.JK", 
"MAGP.JK", "MAIN.JK", "MAPI.JK", "MAYA.JK", 
"MBAP.JK", "MBSS.JK", "MBTO.JK", "MCOR.JK", 
"MDIA.JK", "MDKA.JK", "MDLN.JK", "MDRN.JK", 
"MEDC.JK", "MEGA.JK", "MERK.JK", "META.JK", 
"MFMI.JK", "MGNA.JK", "MICE.JK", "MIDI.JK", 
"MIKA.JK", "MIRA.JK", "MITI.JK", "MKPI.JK", 
"MLBI.JK", "MLIA.JK", "MLPL.JK", "MLPT.JK", 
"MMLP.JK", "MNCN.JK", "MPMX.JK", "MPPA.JK", 
"MRAT.JK", "MREI.JK", "MSKY.JK", "MTDL.JK", 
"MTFN.JK", "MTLA.JK", "MTSM.JK", "MYOH.JK", 
"MYOR.JK", "MYTX.JK", "NELY.JK", "NIKL.JK", 
"NIRO.JK", "NISP.JK", "NOBU.JK", "NRCA.JK", 
"OCAP.JK", "OKAS.JK", "OMRE.JK", "PADI.JK", 
"PALM.JK", "PANR.JK", "PANS.JK", "PBRX.JK", 
"PDES.JK", "PEGE.JK", "PGAS.JK", "PGLI.JK", 
"PICO.JK", "PJAA.JK", "PKPK.JK", "PLAS.JK", 
"PLIN.JK", "PNBN.JK", "PNBS.JK", "PNIN.JK", 
"PNLF.JK", "PSAB.JK", "PSDN.JK", "PSKT.JK", 
"PTBA.JK", "PTIS.JK", "PTPP.JK", "PTRO.JK", 
"PTSN.JK", "PTSP.JK", "PUDP.JK", "PWON.JK", 
"PYFA.JK", "RAJA.JK", "RALS.JK", "RANC.JK", 
"RBMS.JK", "RDTX.JK", "RELI.JK", "RICY.JK", 
"RIGS.JK", "RIMO.JK", "RODA.JK", "ROTI.JK", 
"RUIS.JK", "SAFE.JK", "SAME.JK", "SCCO.JK", 
"SCMA.JK", "SCPI.JK", "SDMU.JK", "SDPC.JK", 
"SDRA.JK", "SGRO.JK", "SHID.JK", "SIDO.JK", 
"SILO.JK", "SIMA.JK", "SIMP.JK", "SIPD.JK", 
"SKBM.JK", "SKLT.JK", "SKYB.JK", "SMAR.JK", 
"SMBR.JK", "SMCB.JK", "SMDM.JK", "SMDR.JK", 
"SMGR.JK", "SMMA.JK", "SMMT.JK", "SMRA.JK", 
"SMRU.JK", "SMSM.JK", "SOCI.JK", "SONA.JK", 
"SPMA.JK", "SQMI.JK", "SRAJ.JK", "SRIL.JK", 
"SRSN.JK", "SRTG.JK", "SSIA.JK", "SSMS.JK", 
"SSTM.JK", "STAR.JK", "STTP.JK", "SUGI.JK", 
"SULI.JK", "SUPR.JK", "TALF.JK", "TARA.JK", 
"TAXI.JK", "TBIG.JK", "TBLA.JK", "TBMS.JK", 
"TCID.JK", "TELE.JK", "TFCO.JK", "TGKA.JK", 
"TIFA.JK", "TINS.JK", "TIRA.JK", "TIRT.JK", 
"TKIM.JK", "TLKM.JK", "TMAS.JK", "TMPO.JK", 
"TOBA.JK", "TOTL.JK", "TOTO.JK", "TOWR.JK", 
"TPIA.JK", "TPMA.JK", "TRAM.JK", "TRIL.JK", 
"TRIM.JK", "TRIO.JK", "TRIS.JK", "TRST.JK", 
"TRUS.JK", "TSPC.JK", "ULTJ.JK", "UNIC.JK", 
"UNIT.JK", "UNSP.JK", "UNTR.JK", "UNVR.JK", 
"VICO.JK", "VINS.JK", "VIVA.JK", "VOKS.JK", 
"VRNA.JK", "WAPO.JK", "WEHA.JK", "WICO.JK", 
"WIIM.JK", "WIKA.JK", "WINS.JK", "WOMF.JK", 
"WSKT.JK", "WTON.JK", "YPAS.JK", "YULE.JK", 
"ZBRA.JK", "SHIP.JK", "CASA.JK", "DAYA.JK", 
"DPUM.JK", "IDPR.JK", "JGLE.JK", "KINO.JK", 
"MARI.JK", "MKNT.JK", "MTRA.JK", "OASA.JK", 
"POWR.JK", "INCF.JK", "WSBP.JK", "PBSA.JK", 
"PRDA.JK", "BOGA.JK", "BRIS.JK", "PORT.JK", 
"CARS.JK", "MINA.JK", "CLEO.JK", "TAMU.JK", 
"CSIS.JK", "TGRA.JK", "FIRE.JK", "TOPS.JK", 
"KMTR.JK", "ARMY.JK", "MAPB.JK", "WOOD.JK", 
"HRTA.JK", "MABA.JK", "HOKI.JK", "MPOW.JK", 
"MARK.JK", "NASA.JK", "MDKI.JK", "BELL.JK", 
"KIOS.JK", "GMFI.JK", "MTWI.JK", "ZINC.JK", 
"MCAS.JK", "PPRE.JK", "WEGE.JK", "PSSI.JK", 
"MORA.JK", "DWGL.JK", "PBID.JK", "JMAS.JK", 
"CAMP.JK", "IPCM.JK", "PCAR.JK", "LCKM.JK", 
"BOSS.JK", "HELI.JK", "JSKY.JK", "INPS.JK", 
"GHON.JK", "TDPM.JK", "DFAM.JK", "NICK.JK", 
"BTPS.JK", "SPTO.JK", "PRIM.JK", "HEAL.JK", 
"TRUK.JK", "PZZA.JK", "TUGU.JK", "MSIN.JK", 
"SWAT.JK", "TNCA.JK", "MAPA.JK", "TCPI.JK", 
"IPCC.JK", "RISE.JK", "BPTR.JK", "POLL.JK", 
"NFCX.JK", "MGRO.JK", "NUSA.JK", "FILM.JK", 
"ANDI.JK", "LAND.JK", "MOLI.JK", "PANI.JK", 
"DIGI.JK", "CITY.JK", "SAPX.JK", "SURE.JK", 
"HKMU.JK", "MPRO.JK", "DUCK.JK", "GOOD.JK", 
"SKRN.JK", "YELO.JK", "CAKK.JK", "SATU.JK", 
"SOSS.JK", "DEAL.JK", "POLA.JK", "DIVA.JK", 
"LUCK.JK", "URBN.JK", "SOTS.JK", "ZONE.JK", 
"PEHA.JK", "FOOD.JK", "BEEF.JK", "POLI.JK", 
"CLAY.JK", "NATO.JK", "JAYA.JK", "COCO.JK", 
"MTPS.JK", "CPRI.JK", "HRME.JK", "POSA.JK", 
"JAST.JK", "FITT.JK", "BOLA.JK", "CCSI.JK", 
"SFAN.JK", "POLU.JK", "KJEN.JK", "KAYU.JK", 
"ITIC.JK", "PAMG.JK", "IPTV.JK", "BLUE.JK", 
"ENVY.JK", "EAST.JK", "LIFE.JK", "FUJI.JK", 
"KOTA.JK", "INOV.JK", "ARKA.JK", "SMKL.JK", 
"HDIT.JK", "KEEN.JK", "BAPI.JK", "TFAS.JK", 
"GGRP.JK", "OPMS.JK", "NZIA.JK", "SLIS.JK", 
"PURE.JK", "IRRA.JK", "DMMX.JK", "SINI.JK", 
"WOWS.JK", "ESIP.JK", "TEBE.JK", "KEJU.JK", 
"PSGO.JK", "AGAR.JK", "IFSH.JK", "REAL.JK", 
"IFII.JK", "PMJS.JK", "UCID.JK", "GLVA.JK", 
"PGJO.JK", "AMAR.JK", "CSRA.JK", "INDO.JK", 
"AMOR.JK", "TRIN.JK", "DMND.JK", "PURA.JK", 
"PTPW.JK", "TAMA.JK", "IKAN.JK", "SAMF.JK", 
"SBAT.JK", "KBAG.JK", "CBMF.JK", "RONY.JK", 
"CSMI.JK", "BBSS.JK", "BHAT.JK", "CASH.JK", 
"TECH.JK", "EPAC.JK", "UANG.JK", "PGUN.JK", 
"SOFA.JK", "PPGL.JK", "TOYS.JK", "SGER.JK", 
"TRJA.JK", "PNGO.JK", "SCNP.JK", "BBSI.JK", 
"KMDS.JK", "PURI.JK", "SOHO.JK", "HOMI.JK", 
"ROCK.JK", "ENZO.JK", "PLAN.JK", "PTDU.JK", 
"ATAP.JK", "VICI.JK", "PMMP.JK", "BANK.JK", 
"WMUU.JK", "EDGE.JK", "UNIQ.JK", "BEBS.JK", 
"SNLK.JK", "ZYRX.JK", "LFLO.JK", "FIMP.JK", 
"TAPG.JK", "NPGF.JK", "LUCY.JK", "ADCP.JK", 
"HOPE.JK", "MGLV.JK", "TRUE.JK", "LABA.JK", 
"ARCI.JK", "IPAC.JK", "MASB.JK", "BMHS.JK", 
"FLMC.JK", "NICL.JK", "UVCR.JK", "BUKA.JK", 
"HAIS.JK", "OILS.JK", "GPSO.JK", "MCOL.JK", 
"RSGK.JK", "RUNS.JK", "SBMA.JK", "CMNT.JK", 
"GTSI.JK", "IDEA.JK", "KUAS.JK", "BOBA.JK", 
"MTEL.JK", "DEPO.JK", "BINO.JK", "CMRY.JK", 
"WGSH.JK", "TAYS.JK", "WMPP.JK", "RMKE.JK", 
"OBMD.JK", "AVIA.JK", "IPPE.JK", "NASI.JK", 
"BSML.JK", "DRMA.JK", "ADMR.JK", "SEMA.JK", 
"ASLC.JK", "NETV.JK", "BAUT.JK", "ENAK.JK", 
"NTBK.JK", "SMKM.JK", "STAA.JK", "NANO.JK", 
"BIKE.JK", "WIRG.JK", "SICO.JK", "GOTO.JK", 
"TLDN.JK", "MTMH.JK", "WINR.JK", "IBOS.JK", 
"OLIV.JK", "ASHA.JK", "SWID.JK", "TRGU.JK", 
"ARKO.JK", "CHEM.JK", "DEWI.JK", "AXIO.JK", 
"KRYA.JK", "HATM.JK", "RCCC.JK", "GULA.JK", 
"JARR.JK", "AMMS.JK", "RAFI.JK", "KKES.JK", 
"ELPI.JK", "EURO.JK", "KLIN.JK", "TOOL.JK", 
"BUAH.JK", "CRAB.JK", "MEDS.JK", "COAL.JK", 
"PRAY.JK", "CBUT.JK", "BELI.JK", "MKTR.JK", 
"OMED.JK", "BSBK.JK", "PDPP.JK", "KDTN.JK", 
"ZATA.JK", "NINE.JK", "MMIX.JK", "PADA.JK", 
"ISAP.JK", "VTNY.JK", "SOUL.JK", "ELIT.JK", 
"BEER.JK", "CBPE.JK", "SUNI.JK", "CBRE.JK", 
"WINE.JK", "BMBL.JK", "PEVE.JK", "LAJU.JK", 
"FWCT.JK", "NAYZ.JK", "IRSX.JK", "PACK.JK", 
"VAST.JK", "CHIP.JK", "HALO.JK", "KING.JK", 
"PGEO.JK", "FUTR.JK", "HILL.JK", "BDKR.JK", 
"PTMP.JK", "SAGE.JK", "TRON.JK", "CUAN.JK", 
"NSSS.JK", "GTRA.JK", "HAJJ.JK", "JATI.JK", 
"TYRE.JK", "MPXL.JK", "SMIL.JK", "KLAS.JK", 
"MAXI.JK", "VKTR.JK", "RELF.JK", "AMMN.JK", 
"CRSN.JK", "GRPM.JK", "WIDI.JK", "TGUK.JK", 
"INET.JK", "MAHA.JK", "RMKO.JK", "CNMA.JK", 
"FOLK.JK", "HBAT.JK", "GRIA.JK", "PPRI.JK", 
"ERAL.JK", "CYBR.JK", "MUTU.JK", "LMAX.JK", 
"HUMI.JK", "MSIE.JK", "RSCH.JK", "BABY.JK", 
"AEGS.JK", "IOTF.JK", "KOCI.JK", "PTPS.JK", 
"BREN.JK", "STRK.JK", "KOKA.JK", "LOPI.JK", 
"UDNG.JK", "RGAS.JK", "MSTI.JK", "IKPM.JK", 
"AYAM.JK", "SURI.JK", "ASLI.JK", "GRPH.JK", 
"SMGA.JK", "UNTD.JK", "TOSK.JK", "MPIX.JK", 
"ALII.JK", "MKAP.JK", "MEJA.JK", "LIVE.JK", 
"HYGN.JK", "BAIK.JK", "VISI.JK", "AREA.JK", 
"MHKI.JK", "ATLA.JK", "DATA.JK", "SOLA.JK", 
"BATR.JK", "SPRE.JK", "PART.JK", "GOLF.JK", 
"ISEA.JK", "BLES.JK", "GUNA.JK", "LABS.JK", 
"DOSS.JK", "NEST.JK", "PTMR.JK", "VERN.JK", 
"DAAZ.JK", "BOAT.JK", "NAIK.JK", "AADI.JK", 
"MDIY.JK", "KSIX.JK", "RATU.JK", "YOII.JK", 
"HGII.JK", "BRRC.JK", "DGWG.JK", "CBDK.JK", 
"OBAT.JK", "MINE.JK", "ASPR.JK", "PSAT.JK", 
"COIN.JK", "CDIA.JK", "BLOG.JK", "MERI.JK", 
"KAQI.JK", "YUPI.JK", "FORE.JK", "MDLA.JK", 
"DKHH.JK", "AYLS.JK", "DADA.JK", "ASPI.JK", 
"ESTA.JK", "BESS.JK", "AMAN.JK", "CARE.JK", 
"PIPA.JK", "NCKL.JK", "MENN.JK", "AWAN.JK", 
"MBMA.JK", "RAAM.JK", "DOOH.JK", "CGAS.JK", 
"NICE.JK", "MSJA.JK", "SMLE.JK", "ACRO.JK", 
"MANG.JK", "WIFI.JK", "FAPA.JK", "DCII.JK", 
"KETR.JK", "DGNS.JK", "UFOE.JK", "CHEK.JK", 
"PMUI.JK", "EMAS.JK", "PJHB.JK", "RLCO.JK", 
"SUPA.JK", "WBSA.JK", "ADMF.JK", "ADMG.JK", 
"ADRO.JK", "AGII.JK", "AGRO.JK", "AGRS.JK", 
"AHAP.JK", "AIMS.JK", "PNSE.JK", "POLY.JK", 
"POOL.JK", "PPRO.JK"
        ]
        
        screener_list = []
        chunk_size = 150 

        for i in range(0, len(active_tickers), chunk_size):
            chunk = active_tickers[i:i + chunk_size]
            df_bulk = yf.download(chunk, period="1y", interval="1d", group_by="ticker", progress=False)

            for ticker in chunk:
                try:
                    if ticker in df_bulk.columns.levels[0]:
                        df = df_bulk[ticker].dropna(subset=['Close'])
                        if df.empty or len(df) < 200:
                            continue

                        df_computed = calculate_indicators(df)
                        if df_computed is None:
                            continue

                        last_row = df_computed.iloc[-1]
                        ticker_clean = ticker.replace('.JK', '')

                        screener_list.append({
                          "ticker": ticker_clean,
                          "close": float(last_row['Close']),
                          "ema5": float(last_row['ema5']),
                          "ema20": float(last_row['ema20']),
                          "ema200": float(last_row['ema200']),
                          "rsi": float(last_row['rsi']),
                          "vwap": float(last_row['vwap']),
                          "adx": float(last_row['adx']),
                          "atr": float(last_row['atr'])
                        })
                except Exception:
                    continue

        return jsonify(screener_list)

    except Exception as e:
        return jsonify({"error": f"Gagal memuat radar pasar: {str(e)}"}), 500


# ====================================================================
# 2. ENDPOINT CANDLESTICK (Sudah Sinkron dengan Request Flutter)
# ====================================================================
@app.route('/api/candles/<ticker>', methods=['GET'])
def get_ticker_candles(ticker):
    try:
        # Ambil parameter 'tf' dari Flutter, jika kosong default ke 'month'
        tf = request.args.get('tf', 'month').lower()
        
        # 🎯 Pemetaan 4 Opsi Timeframe sesuai spek yfinance
        if tf == 'intraday':
            period, interval = "1d", "5m"   # 1 Hari penuh, candle per 5 menit
        elif tf == 'week':
            period, interval = "5d", "15m"  # 1 Minggu ke belakang, candle per 15 menit
        elif tf == 'month':
            period, interval = "1mo", "1d"  # 1 Bulan ke belakang, candle harian
        elif tf == 'ytd':
            period, interval = "ytd", "1d"  # Dari awal tahun sampai hari ini, candle harian
        else:
            period, interval = "1mo", "1d"

        ticker_jk = f"{ticker.upper()}.JK"
        df = yf.download(ticker_jk, period=period, interval=interval, progress=False)
        
        if df.empty:
            return jsonify({"error": "Data tidak ditemukan"}), 404
            
        candles = []
        for index, row in df.iterrows():
            candles.append({
                # Jika intraday/week pakai format lengkap jam, jika daily cukup tanggalnya
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

if __name__ == '__main__':
    app.run(debug=True)