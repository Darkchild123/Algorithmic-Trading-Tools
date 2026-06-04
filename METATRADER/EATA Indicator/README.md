
## Credits & Original Source

* **Original Concept:** Based on the legacy `EATA pollan vers mod 2` indicator originally shared by user **Pollan** on the MQL5 and Forex Factory trading forums circa 2012-2013.
* **Original Code Attribution:** Headcoded under the contact `lg06@windowslive.com`.
* **Modification Author:** 
  * *Note: The original open-source version was heavily flawed with hardcoded look-ahead (future bias) loops that caused severe signal repainting. This repository hosts the re-engineered, mathematically stabilized, and native-buffered version fit for live execution and algorithmic EAs.*



# Non-Repainting EATA Pollan Custom MT4 Indicator (Fixed Version)

A fully optimized, non-repainting version of the **EATA Pollan** custom indicator for MetaTrader 4 (MT4). This indicator calculates cross-momentum dynamics using an interconnected, smoothed framework built from the Commodity Channel Index (CCI) and the Relative Strength Index (RSI).

---

##  The Problems in the Original Code

The legacy version of this indicator suffered from several architectural flaws that made it unreliable for live trading and historical backtesting:

1. **Future Peak/Trough Bias (Repainting):** The original mathematical array loops read data using negative index offsets (`i-1`, `i-2`, etc.). Within MT4's time-series structure, searching elements lower than `i` forces historical bars to look into "future" bars that hadn't closed yet at that moment in history.
2. **`iMAOnArray` Context Collapses:** The original loop boundaries limited execution strictly to new incoming bars (`Bars - IndicatorCounted()`). When live ticks arrived, the window narrowed down to 1 or 2 bars, causing the Moving Average function to lose its historical calculation context. This caused closed historical lines to shift dynamically.
3. **Ghost Graphic Signals (Object Cache Bugs):** Signal arrows were rendered using manual graphic chart objects (`OBJ_ARROW`). On live, unclosed bars (Bar 0), a fluctuating crossover would trigger an arrow. If the market reversed before the bar closed, the code failed to cleanly purge the object, pinning "ghost signals" permanently to the chart history.

---

##  Enhancements & Architectural Changes

The code was completely rewritten to achieve structural optimization, data continuity, and zero signal lag:

* **Inverted Historical Shift Logic:** All negative calculations (`i-1`) were changed to forward-looking historical shifts (`i+1`, `i+2`, etc.). The indicator now looks strictly backward into completed historical data. **Closed bars will never alter their value or repaint.**
* **Transitioned to Native Indicator Buffers:** Replaced the fragile `OBJ_ARROW` rendering workflow entirely. The script now utilizes 6 native MT4 data streams—increasing memory mapping capability to assign dedicated native buffers (`ArrowUpBuffer` and `ArrowDnBuffer`) for signal arrows.
* **Dynamically Managed Unclosed Ticks:** By utilizing native buffers, MetaTrader natively recalculates and refreshes the state of the active open bar (Bar 0) on every tick. Signals fluctuate smoothly on the live open bar but instantly **lock permanently into place the exact second the bar closes.**
* **Stabilized Buffer Context:** Enforced a multi-bar buffer window safety mechanism (`limit = MathMax(limit, Ma_Period + 10)`). This provides `iMAOnArray` with structural data continuity during live data feeds.
* **Compiler Modernization:** Cleaned up code scoping warnings, properly restricted index loop counters (`int i`), fixed overlapping declarations, and replaced non-standard identifiers with native, high-contrast trading colors (`Crimson` and `Lime`).

---

##  Indicator Specifications

* **Platform:** MetaTrader 4 (MQL4)
* **Indicator Buffers:** 6 Buffers 
  * `Buffer 0 & 1`: Line Overlays (CCI-RSI & RSI-CCI)
  * `Buffer 2 & 3`: Sub-calculation arrays
  * `Buffer 4 & 5`: Native Wingdings Buy/Sell Arrows
* **Inputs:**
  * `CCI_per` (Default: 14) — Period for Commodity Channel Index.
  * `RSI_per` (Default: 14) — Period for Relative Strength Index.
  * `Ma_Period` (Default: 2) — Smoothing moving average parameter.
  * `koef` (Default: 8) — Factor coefficient bounding past bar calculations (0 to 8).
  * `arrows` (Default: true) — Toggle visual signals on/off.

---

##  Installation

1. Download or copy the code from `EATA_fixed.mq4`.
2. Open MetaTrader 4 and navigate to `File` -> `Open Data Folder`.
3. Go to `MQL4` -> `Indicators`.
4. Paste the `.mq4` file inside the folder.
5. Restart MT4 or refresh the **Indicators** list in the Navigator panel.
6. Compile the code in MetaEditor if needed; it compiles with 0 errors and 0 warnings.
