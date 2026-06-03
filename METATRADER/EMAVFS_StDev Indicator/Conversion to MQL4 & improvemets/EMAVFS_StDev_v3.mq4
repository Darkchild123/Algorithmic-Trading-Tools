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
#property indicator_color2  clrNONE
#property indicator_color3  clrNONE
#property indicator_color4  clrNONE
#property indicator_color5  clrRed
#property indicator_color6  clrAqua
#property indicator_color7  clrRed
#property indicator_color8  clrAqua

#property indicator_width1  1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
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

input double         Wmin          = 0.0;          // Minimum sensitivity
input double         Wmax          = 5.0;          // Maximum sensitivity
input double         Efactor       = 1.01;         // E coefficient
input double         Afactor       = 1.001;        // A power
input Applied_price_ IPC           = PRICE_CLOSE_; // Price constant
input int            PriceShift    = 0;            // Vertical shift in points
input double         dK1           = 2.001;        // Filter coefficient 1
input double         dK2           = 4.001;        // Filter coefficient 2
input int            std_period    = 9;            // Standard deviation period
input int            Shift         = 0;            // Horizontal shift in bars
input bool           DrawLiveLine  = true;         // Draw the still-forming candle line segment
input int            MaxObjectBars = 3000;         // Maximum colored line object segments, 0 = all bars
input string         InstanceId    = "A";          // Unique id if several copies run on one chart

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
string object_prefix = "";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   object_prefix = "EMAVFS_StDev_v3_" + Symbol() + "_" +
                   IntegerToString(Period()) + "_" + InstanceId + "_";

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
   SetIndexStyle(1, DRAW_NONE);
   SetIndexLabel(1, NULL);
   SetIndexEmptyValue(1, EMPTY_VALUE);

   SetIndexBuffer(2, LineFlatBuffer);
   SetIndexStyle(2, DRAW_NONE);
   SetIndexLabel(2, NULL);
   SetIndexEmptyValue(2, EMPTY_VALUE);

   SetIndexBuffer(3, LineUpBuffer);
   SetIndexStyle(3, DRAW_NONE);
   SetIndexLabel(3, NULL);
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

   IndicatorShortName("EMAVFS_StDev_v3");
   IndicatorDigits(Digits + 1);

   dPriceShift = Point * PriceShift;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteLineObjects();
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

   bool full_recalc = (prev_calculated > rates_total || prev_calculated <= 0);

   if(full_recalc)
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

   ClearHiddenLineBuffers(first, rates_total);

   int stdev_first = first;
   if(full_recalc)
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

   DrawColorLineObjects(rates_total, full_recalc, time);

   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Clear hidden compatibility line buffers                          |
//+------------------------------------------------------------------+
void ClearHiddenLineBuffers(const int from_bar, const int rates_total)
  {
   int clear_from = from_bar;
   if(clear_from < 0)
      clear_from = 0;

   for(int bar = clear_from; bar < rates_total; bar++)
     {
      LineDownBuffer[bar] = EMPTY_VALUE;
      LineFlatBuffer[bar] = EMPTY_VALUE;
      LineUpBuffer[bar] = EMPTY_VALUE;
     }
  }

//+------------------------------------------------------------------+
//| Draw colored EMAVFS as chart objects to avoid buffer endpoint repaint |
//+------------------------------------------------------------------+
void DrawColorLineObjects(const int rates_total,
                          const bool full_recalc,
                          const datetime &time[])
  {
   if(full_recalc)
      DeleteLineObjects();

   int last_closed = rates_total - 2;
   int current_bar = rates_total - 1;

   if(full_recalc)
     {
      int first_segment = start;
      if(MaxObjectBars > 0 && current_bar - first_segment + 1 > MaxObjectBars)
         first_segment = current_bar - MaxObjectBars + 1;
      if(first_segment < start)
         first_segment = start;

      for(int bar = first_segment; bar <= last_closed && !IsStopped(); bar++)
         DrawSegmentObject(bar, false, time);
     }
   else
     {
      if(MaxObjectBars > 0)
        {
         int old_bar = current_bar - MaxObjectBars;
         if(old_bar >= start)
            ObjectDelete(SegmentObjectName(old_bar, time));
        }

      if(last_closed >= start)
         DrawSegmentObject(last_closed, false, time);
     }

   if(DrawLiveLine && current_bar >= start)
      DrawSegmentObject(current_bar, true, time);
   else
      ObjectDelete(object_prefix + "LIVE");
  }

//+------------------------------------------------------------------+
//| Draw or update one colored line segment                          |
//+------------------------------------------------------------------+
void DrawSegmentObject(const int bar,
                       const bool live_segment,
                       const datetime &time[])
  {
   if(bar < start || bar < 1)
      return;

   int color_index = SegmentColorIndex(bar);
   int previous_color_index = SegmentColorIndex(bar - 1);

   int seconds = Period() * 60;
   if(seconds <= 0)
      seconds = 60;

   int transition_offset = 0;
   if(color_index != previous_color_index && bar > start)
     {
      transition_offset = seconds / 100;
      if(transition_offset < 1)
         transition_offset = 1;
     }

   datetime time1 = time[bar - 1] + Shift * seconds + transition_offset;
   datetime time2 = time[bar] + Shift * seconds;

   if(time1 >= time2)
      time1 = time[bar - 1] + Shift * seconds;

   string name = object_prefix;
   if(live_segment)
      name += "LIVE";
   else
      name = SegmentObjectName(bar, time);

   if(ObjectFind(name) < 0)
      ObjectCreate(name, OBJ_TREND, 0, time1, ExtLineBuffer[bar - 1], time2, ExtLineBuffer[bar]);
   else
     {
      ObjectMove(name, 0, time1, ExtLineBuffer[bar - 1]);
      ObjectMove(name, 1, time2, ExtLineBuffer[bar]);
     }

   ObjectSet(name, OBJPROP_COLOR, SegmentColor(color_index));
   ObjectSet(name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(name, OBJPROP_WIDTH, 2);
   ObjectSet(name, OBJPROP_RAY, false);
   ObjectSet(name, OBJPROP_BACK, false);
  }

//+------------------------------------------------------------------+
//| Build stable object name for a closed segment                    |
//+------------------------------------------------------------------+
string SegmentObjectName(const int bar, const datetime &time[])
  {
   return(object_prefix + IntegerToString((int)time[bar]));
  }

//+------------------------------------------------------------------+
//| Get segment color index from EMAVFS slope                        |
//+------------------------------------------------------------------+
int SegmentColorIndex(const int bar)
  {
   if(bar < 1)
      return(1);

   if(ExtLineBuffer[bar - 1] < ExtLineBuffer[bar])
      return(2);
   if(ExtLineBuffer[bar - 1] > ExtLineBuffer[bar])
      return(0);

   return(1);
  }

//+------------------------------------------------------------------+
//| Convert segment color index to chart color                       |
//+------------------------------------------------------------------+
color SegmentColor(const int color_index)
  {
   switch(color_index)
     {
      case 0:
         return(clrMagenta);
      case 2:
         return(clrDodgerBlue);
      default:
         return(clrGray);
     }
  }

//+------------------------------------------------------------------+
//| Delete chart objects created by this indicator instance           |
//+------------------------------------------------------------------+
void DeleteLineObjects()
  {
   if(object_prefix == "")
      return;

   for(int i = ObjectsTotal() - 1; i >= 0; i--)
     {
      string name = ObjectName(i);
      if(StringFind(name, object_prefix, 0) == 0)
         ObjectDelete(name);
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
