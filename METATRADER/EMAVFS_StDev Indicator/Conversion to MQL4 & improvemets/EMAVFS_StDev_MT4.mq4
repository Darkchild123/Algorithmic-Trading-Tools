//+------------------------------------------------------------------+
//|                                               EMAVFS_StDev.mq4   |
//|     Converted from MetaTrader 5 MQ5 to MQ4 by Cosmas Nwachukwu   |
//|                                           finecosmas@gmail.com   |
//|        Original link: http://stan.okis.ru/file/stan/EMAVFS.pdf   |
//|                             https://www.mql5.com/en/code/20720   |
//+------------------------------------------------------------------+


#property copyright "Copyright (c) 2026"
#property link      "http://stan.okis.ru/file/stan/EMAVFS.pdf"
#property strict

#property indicator_chart_window
#property indicator_buffers 8

#property indicator_color1  clrNONE
#property indicator_color2  clrMagenta
#property indicator_color3  clrGray
#property indicator_color4  clrDodgerBlue
#property indicator_color5  clrRed
#property indicator_color6  clrAqua
#property indicator_color7  clrRed
#property indicator_color8  clrAqua

#property indicator_width1  1
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_width7  4
#property indicator_width8  4

enum Applied_price_
  {
   PRICE_CLOSE_        = 0,  // Close price
   PRICE_OPEN_         = 1,  // Open price
   PRICE_HIGH_         = 2,  // High price
   PRICE_LOW_          = 3,  // Low price
   PRICE_MEDIAN_       = 4,  // Median price, (high + low) / 2
   PRICE_TYPICAL_      = 5,  // Typical price, (high + low + close) / 3
   PRICE_WEIGHTED_     = 6,  // Weighted price, (high + low + close + close) / 4
   PRICE_SIMPL_        = 7,  // Simple price, (open + close) / 2
   PRICE_QUARTER_      = 8,  // Quarter price, (open + close + high + low) / 4
   PRICE_TRENDFOLLOW0_ = 9,  // TrendFollow 1 price
   PRICE_TRENDFOLLOW1_ = 10, // TrendFollow 2 price
   PRICE_DEMARK_       = 11  // Demark price
  };

input double         Wmin       = 0.0;          // Minimum sensitivity
input double         Wmax       = 5.0;          // Maximum sensitivity
input double         Efactor    = 1.01;         // E coefficient
input double         Afactor    = 1.001;        // A power
input Applied_price_ IPC        = PRICE_CLOSE_; // Price constant
input int            PriceShift = 0;            // Vertical shift in points
input double         dK1        = 2.001;        // Filter coefficient 1
input double         dK2        = 4.001;        // Filter coefficient 2
input int            std_period = 9;            // Standard deviation period
input int            Shift      = 0;            // Horizontal shift in bars

double ExtLineBuffer[];
double LineDownBuffer[];
double LineFlatBuffer[];
double LineUpBuffer[];
double BearsBuffer1[];
double BullsBuffer1[];
double BearsBuffer2[];
double BullsBuffer2[];

double dEMAVFS[];

int    start;
double dPriceShift;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(dK1 >= dK2)
     {
      Print("Invalid inputs: dK1 must be less than dK2.");
      return(INIT_FAILED);
     }

   if(std_period < 1)
     {
      Print("Invalid input: std_period must be greater than zero.");
      return(INIT_FAILED);
     }

   start = 2 + std_period;
   ArrayResize(dEMAVFS, std_period);

   SetIndexBuffer(0, ExtLineBuffer);
   SetIndexStyle(0, DRAW_NONE);
   SetIndexLabel(0, "EMAVFS");
   SetIndexDrawBegin(0, start);
   SetIndexShift(0, Shift);
   SetIndexEmptyValue(0, EMPTY_VALUE);

   SetIndexBuffer(1, LineDownBuffer);
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2, clrMagenta);
   SetIndexLabel(1, NULL);
   SetIndexDrawBegin(1, start);
   SetIndexShift(1, Shift);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexBuffer(2, LineFlatBuffer);
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2, clrGray);
   SetIndexLabel(2, NULL);
   SetIndexDrawBegin(2, start);
   SetIndexShift(2, Shift);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexBuffer(3, LineUpBuffer);
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 2, clrDodgerBlue);
   SetIndexLabel(3, NULL);
   SetIndexDrawBegin(3, start);
   SetIndexShift(3, Shift);
   SetIndexEmptyValue(3, EMPTY_VALUE);

   SetIndexBuffer(4, BearsBuffer1);
   SetIndexStyle(4, DRAW_ARROW, STYLE_SOLID, 2, clrRed);
   SetIndexArrow(4, 159);
   SetIndexLabel(4, "Dn_Signal 1");
   SetIndexDrawBegin(4, start);
   SetIndexShift(4, Shift);
   SetIndexEmptyValue(4, EMPTY_VALUE);

   SetIndexBuffer(5, BullsBuffer1);
   SetIndexStyle(5, DRAW_ARROW, STYLE_SOLID, 2, clrAqua);
   SetIndexArrow(5, 159);
   SetIndexLabel(5, "Up_Signal 1");
   SetIndexDrawBegin(5, start);
   SetIndexShift(5, Shift);
   SetIndexEmptyValue(5, EMPTY_VALUE);

   SetIndexBuffer(6, BearsBuffer2);
   SetIndexStyle(6, DRAW_ARROW, STYLE_SOLID, 4, clrRed);
   SetIndexArrow(6, 159);
   SetIndexLabel(6, "Dn_Signal 2");
   SetIndexDrawBegin(6, start);
   SetIndexShift(6, Shift);
   SetIndexEmptyValue(6, EMPTY_VALUE);

   SetIndexBuffer(7, BullsBuffer2);
   SetIndexStyle(7, DRAW_ARROW, STYLE_SOLID, 4, clrAqua);
   SetIndexArrow(7, 159);
   SetIndexLabel(7, "Up_Signal 2");
   SetIndexDrawBegin(7, start);
   SetIndexShift(7, Shift);
   SetIndexEmptyValue(7, EMPTY_VALUE);

   ArraySetAsSeries(ExtLineBuffer, false);
   ArraySetAsSeries(LineDownBuffer, false);
   ArraySetAsSeries(LineFlatBuffer, false);
   ArraySetAsSeries(LineUpBuffer, false);
   ArraySetAsSeries(BearsBuffer1, false);
   ArraySetAsSeries(BullsBuffer1, false);
   ArraySetAsSeries(BearsBuffer2, false);
   ArraySetAsSeries(BullsBuffer2, false);

   IndicatorShortName("EMAVFS_StDev");
   IndicatorDigits(Digits + 1);

   dPriceShift = Point * PriceShift;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < start)
      return(0);

   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);

   ArraySetAsSeries(ExtLineBuffer, false);

   int first;
   double series;
   double wema;
   double w;
   static double wema_prev;

   if(prev_calculated > rates_total || prev_calculated <= 0)
     {
      first = 1;
      wema_prev = PriceSeries(IPC, first - 1, open, low, high, close);
      ExtLineBuffer[0] = wema_prev + dPriceShift;
     }
   else
      first = prev_calculated - 1;

   for(int bar = first; bar < rates_total && !IsStopped(); bar++)
     {
      series = PriceSeries(IPC, bar, open, low, high, close);
      w = Wmin + (Wmax - Wmin) *
          (1.0 - MathExp(-MathPow(MathAbs(series - wema_prev / Efactor), Afactor)));
      wema = wema_prev + w * (series - wema_prev);
      ExtLineBuffer[bar] = wema + dPriceShift;

      if(bar < rates_total - 1)
         wema_prev = wema;
     }

   int color_first = first;
   if(prev_calculated > rates_total || prev_calculated <= 0)
      color_first++;
   if(color_first < 1)
      color_first = 1;

   int clear_from = color_first - 1;
   if(clear_from < 0)
      clear_from = 0;
   ClearLineBuffers(clear_from, rates_total);
   for(int bar = color_first; bar < rates_total && !IsStopped(); bar++)
     {
      int clr = 1;
      if(ExtLineBuffer[bar - 1] < ExtLineBuffer[bar])
         clr = 2;
      if(ExtLineBuffer[bar - 1] > ExtLineBuffer[bar])
         clr = 0;

      PaintLineSegment(bar, clr);
     }

   int stdev_first = first;
   if(prev_calculated > rates_total || prev_calculated <= 0)
      stdev_first = start;
   if(stdev_first < start)
      stdev_first = start;

   for(int bar = stdev_first; bar < rates_total && !IsStopped(); bar++)
     {
      double sum = 0.0;

      for(int i = 0; i < std_period; i++)
        {
         dEMAVFS[i] = ExtLineBuffer[bar - i] - ExtLineBuffer[bar - i - 1];
         sum += dEMAVFS[i];
        }

      double sma_diff = sum / std_period;

      sum = 0.0;
      for(int i = 0; i < std_period; i++)
         sum += MathPow(dEMAVFS[i] - sma_diff, 2);

      double stdev = MathSqrt(sum / std_period);
      double dstd = NormalizeDouble(dEMAVFS[0], Digits + 2);
      double filter1 = NormalizeDouble(dK1 * stdev, Digits + 2);
      double filter2 = NormalizeDouble(dK2 * stdev, Digits + 2);
      wema = ExtLineBuffer[bar];

      BearsBuffer1[bar] = EMPTY_VALUE;
      BullsBuffer1[bar] = EMPTY_VALUE;
      BearsBuffer2[bar] = EMPTY_VALUE;
      BullsBuffer2[bar] = EMPTY_VALUE;

      if(dstd < -filter1 && dstd >= -filter2)
         BearsBuffer1[bar] = wema;
      if(dstd < -filter2)
         BearsBuffer2[bar] = wema;
      if(dstd > filter1 && dstd <= filter2)
         BullsBuffer1[bar] = wema;
      if(dstd > filter2)
         BullsBuffer2[bar] = wema;
     }

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Clear EMAVFS color-line buffers                                  |
//+------------------------------------------------------------------+
void ClearLineBuffers(const int from_bar, const int rates_total)
  {
   for(int bar = from_bar; bar < rates_total; bar++)
     {
      LineDownBuffer[bar] = EMPTY_VALUE;
      LineFlatBuffer[bar] = EMPTY_VALUE;
      LineUpBuffer[bar] = EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//| Paint one MT5-style DRAW_COLOR_LINE segment using MT4 buffers     |
//+------------------------------------------------------------------+
void PaintLineSegment(const int bar, const int color_index)
  {
   SetLineValue(bar - 1, color_index, ExtLineBuffer[bar - 1]);
   SetLineValue(bar, color_index, ExtLineBuffer[bar]);
  }

//+------------------------------------------------------------------+
//| Set one value in the selected color-line buffer                   |
//+------------------------------------------------------------------+
void SetLineValue(const int bar, const int color_index, const double value)
  {
   switch(color_index)
     {
      case 0:
         LineDownBuffer[bar] = value;
         break;
      case 2:
         LineUpBuffer[bar] = value;
         break;
      default:
         LineFlatBuffer[bar] = value;
         break;
     }
  }

//+------------------------------------------------------------------+
//| Get selected price value                                          |
//+------------------------------------------------------------------+
double PriceSeries(const Applied_price_ applied_price,
                   const int bar,
                   const double &dOpen[],
                   const double &dLow[],
                   const double &dHigh[],
                   const double &dClose[])
  {
   switch(applied_price)
     {
      case PRICE_CLOSE_:
         return(dClose[bar]);
      case PRICE_OPEN_:
         return(dOpen[bar]);
      case PRICE_HIGH_:
         return(dHigh[bar]);
      case PRICE_LOW_:
         return(dLow[bar]);
      case PRICE_MEDIAN_:
         return((dHigh[bar] + dLow[bar]) / 2.0);
      case PRICE_TYPICAL_:
         return((dClose[bar] + dHigh[bar] + dLow[bar]) / 3.0);
      case PRICE_WEIGHTED_:
         return((2.0 * dClose[bar] + dHigh[bar] + dLow[bar]) / 4.0);
      case PRICE_SIMPL_:
         return((dOpen[bar] + dClose[bar]) / 2.0);
      case PRICE_QUARTER_:
         return((dOpen[bar] + dClose[bar] + dHigh[bar] + dLow[bar]) / 4.0);
      case PRICE_TRENDFOLLOW0_:
         if(dClose[bar] > dOpen[bar])
            return(dHigh[bar]);
         if(dClose[bar] < dOpen[bar])
            return(dLow[bar]);
         return(dClose[bar]);
      case PRICE_TRENDFOLLOW1_:
         if(dClose[bar] > dOpen[bar])
            return((dHigh[bar] + dClose[bar]) / 2.0);
         if(dClose[bar] < dOpen[bar])
            return((dLow[bar] + dClose[bar]) / 2.0);
         return(dClose[bar]);
      case PRICE_DEMARK_:
        {
         double result = dHigh[bar] + dLow[bar] + dClose[bar];
         if(dClose[bar] < dOpen[bar])
            result = (result + dLow[bar]) / 2.0;
         if(dClose[bar] > dOpen[bar])
            result = (result + dHigh[bar]) / 2.0;
         if(dClose[bar] == dOpen[bar])
            result = (result + dClose[bar]) / 2.0;
         return(((result - dLow[bar]) + (result - dHigh[bar])) / 2.0);
        }
      default:
         return(dClose[bar]);
     }
  }
//+------------------------------------------------------------------+
