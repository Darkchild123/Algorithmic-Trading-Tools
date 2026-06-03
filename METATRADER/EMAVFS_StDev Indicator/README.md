
# EMAVFS StDev MT4 Conversion

This project is a MetaTrader 4 conversion of the original MetaTrader 5 `EMAVFS_StDev.mq5` indicator.

The goal of the project is to make the EMAVFS StDev indicator run on MetaTrader 4 by rewriting the MQL5-specific parts of the source code into MQL4-compatible code.

## Project Overview

The original indicator was written for MetaTrader 5. This repository contains the converted `.mq4` version so it can be compiled and used in MetaTrader 4.

The conversion keeps the original indicator logic as close as possible while adapting MT5-only features to MT4 equivalents.

## Main File

- `EMAVFS_StDev.mq4` - Converted MetaTrader 4 indicator source file.

## What Was Converted

- MT5 indicator initialization was adapted for MT4.
- MT5 plotting functions were replaced with MT4 `SetIndex...` functions.
- MT5 `DRAW_COLOR_LINE` behavior was emulated with separate MT4 line buffers.
- Indicator buffers were reorganized for MT4 compatibility.
- Price calculation logic and standard deviation signal logic were preserved.

## Features

- Variable-factor exponential moving average.
- Standard-deviation-based trend filtering.
- Colored EMAVFS line:
  - Magenta for falling movement.
  - Gray for flat or unchanged movement.
  - Dodger blue for rising movement.
- Two bearish signal levels.
- Two bullish signal levels.
- Configurable smoothing, sensitivity, price source, filter strength, and chart shift settings.

## Installation

1. Open MetaTrader 4.
2. Click `File > Open Data Folder`.
3. Go to `MQL4/Indicators`.
4. Copy `EMAVFS_StDev.mq4` into the `Indicators` folder.
5. Restart MetaTrader 4, or refresh the Navigator panel.
6. Attach `EMAVFS_StDev` to a chart.

## Inputs

| Input | Default | Description |
| --- | ---: | --- |
| `Wmin` | `0.0` | Minimum sensitivity. |
| `Wmax` | `5.0` | Maximum sensitivity. |
| `Efactor` | `1.01` | E coefficient used in the smoothing calculation. |
| `Afactor` | `1.001` | Power factor used in the smoothing calculation. |
| `IPC` | `PRICE_CLOSE_` | Price source used for calculation. |
| `PriceShift` | `0` | Vertical shift in points. |
| `dK1` | `2.001` | First standard deviation filter coefficient. |
| `dK2` | `4.001` | Second standard deviation filter coefficient. |
| `std_period` | `9` | Standard deviation period. |
| `Shift` | `0` | Horizontal shift in bars. |

## Indicator Buffers

MT4 does not support MT5's `DRAW_COLOR_LINE` drawing mode directly, so the converted version uses separate buffers to reproduce the visual behavior.

| Buffer | Description |
| ---: | --- |
| `0` | Hidden main EMAVFS value buffer, useful for `iCustom()` calls. |
| `1` | Falling EMAVFS line. |
| `2` | Flat EMAVFS line. |
| `3` | Rising EMAVFS line. |
| `4` | Bearish signal level 1. |
| `5` | Bullish signal level 1. |
| `6` | Bearish signal level 2. |
| `7` | Bullish signal level 2. |

## Using With `iCustom`

Example:

```mql4
double emavfs = iCustom(Symbol(), Period(), "EMAVFS_StDev", 0, 1);
double bearishSignal1 = iCustom(Symbol(), Period(), "EMAVFS_StDev", 4, 1);
double bullishSignal1 = iCustom(Symbol(), Period(), "EMAVFS_StDev", 5, 1);
```

When a signal buffer has no signal on a bar, it returns `EMPTY_VALUE`.

## Compilation

Open `EMAVFS_StDev.mq4` in MetaEditor 4 and compile it. After successful compilation, MetaTrader 4 will create the corresponding `.ex4` file.

## Notes

- This is a conversion project from MQL5 to MQL4.
- The indicator is intended for MetaTrader 4.
- Test the converted indicator on a demo chart before using it in live trading.

## Disclaimer

This project is for educational and technical analysis purposes only. It is not financial advice.

## Credits
Nikolay Kositsin
https://www.mql5.com/en/code/20720
Original indicator: `EMAVFS_StDev.mq5
Original reference: http://stan.okis.ru/file/stan/EMAVFS.pdf
18b350f ( port EMAVFS_StDev indicator from MQL5 to MQL4)
