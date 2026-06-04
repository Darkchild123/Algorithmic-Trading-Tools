
// I do not own copyright to original source code. This version is for educational purposes only. 

#property copyright "EATA Pollan vers. Fixed" // repainting fixed by Cosmas [finecosmas@gmail.com]
#property link      "lg06@windowslive.com"

#property indicator_separate_window
// We increase the total buffers to 6 (2 for lines, 2 for calculations, 2 for arrows)
#property indicator_buffers 6
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color5 Lime
#property indicator_color6 Crimson // FIX 1: Changed CustomRed to Crimson (native MT4 color)

//---- input parameters
extern int       CCI_per=14;
extern int       RSI_per=14;
extern int       Ma_Period=2;
extern int       koef=8;
extern bool      arrows            = true;

//---- buffers
double ExtMapBuffer1[]; // Line 1
double ExtMapBuffer2[]; // Line 2
double ExtMapBuffer3[]; // Calculation Buffer 1
double ExtMapBuffer4[]; // Calculation Buffer 2
double ArrowUpBuffer[];  // Arrow Up Buffer
double ArrowDnBuffer[];  // Arrow Dn Buffer

string sPrefix;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- Mapping indicators to 6 distinct buffers
   IndicatorBuffers(6);
   
   // Line 1
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,2);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexLabel(0, "CCI-RSI");   
   
   // Line 2
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,2);
   SetIndexBuffer(1,ExtMapBuffer2);
   SetIndexLabel(1, "RSI-CCI");  
   
   // Hidden calculation buffers
   SetIndexBuffer(2,ExtMapBuffer3);
   SetIndexBuffer(3,ExtMapBuffer4); 
   
   // Native Arrow Up Buffer (Drawn on the main chart area cleanly)
   SetIndexBuffer(4,ArrowUpBuffer);
   SetIndexStyle(4,DRAW_ARROW,STYLE_SOLID,2);
   SetIndexArrow(4,225); // Wingdings up arrow
   SetIndexLabel(4,"EATA Buy Signal");
   
   // Native Arrow Down Buffer
   SetIndexBuffer(5,ArrowDnBuffer);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,2);
   SetIndexArrow(5,226); // Wingdings down arrow
   SetIndexLabel(5,"EATA Sell Signal");

   if (koef>8 || koef<0) koef=8;
   sPrefix ="EATA pollan vers 3 (" + CCI_per + ", " + RSI_per + ": " + koef +" )";
   IndicatorShortName(sPrefix) ;

   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{
   int counted_bars = IndicatorCounted();
   if(counted_bars < 0) return(-1);
   if(counted_bars > 0) counted_bars--; // Recalculate the last closed bar to finalize states
   
   int limit = Bars - counted_bars;
   
   // Ensure moving average data calculations have historical padding context
   if(limit < Ma_Period + 10) limit = Ma_Period + 10;
   if(limit > Bars) limit = Bars;
   
   // Math variables scoped strictly locally per execution loop to eliminate data leakage across ticks
   double a, a1, a2, a3, a4, a5, a6, a7, a8;
   double b, b1, b2, b3, b4, b5, b6, b7, b8;
   double tt1max, tt2min;
   int i = 0; // FIX 2: Declared 'i' once globally inside the start function scope

   // Loop 1: Core Mathematical Calculations
   for(i=limit-1; i>=0; i--) 
   {
      if(i + 8 >= Bars) continue; // Out-of-bounds structural array protection

      a  = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i)   - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i);
      a1 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+1) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+1);
      a2 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+2) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+2);
      a3 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+3) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+3);
      a4 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+4) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+4);
      a5 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+5) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+5);
      a6 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+6) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+6);
      a7 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+7) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+7);
      a8 = iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+8) - iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+8);
                   
      b  = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i)   - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i);
      b1 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+1) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+1);
      b2 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+2) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+2);
      b3 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+3) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+3);
      b4 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+4) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+4);
      b5 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+5) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+5);
      b6 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+6) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+6);
      b7 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+7) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+7);
      b8 = iRSI(NULL,0,RSI_per,PRICE_TYPICAL,i+8) - iCCI(NULL,0,CCI_per,PRICE_TYPICAL,i+8);
                   
      switch(koef)
      {
         case 0     : tt1max=a; tt2min=b; break;
         case 1     : tt1max=a+a1; tt2min=b+b1; break;
         case 2     : tt1max=a+a1+a2; tt2min=b+b1+b2; break;
         case 3     : tt1max=a+a1+a2+a3; tt2min=b+b1+b2+b3; break;
         case 4     : tt1max=a+a1+a2+a3+a4; tt2min=b+b1+b2+b3+b4; break;
         case 5     : tt1max=a+a1+a2+a3+a4+a5; tt2min=b+b1+b2+b3+b4+b5; break;
         case 6     : tt1max=a+a1+a2+a3+a4+a5+a6; tt2min=b+b1+b2+b3+b4+b5+b6; break;
         case 7     : tt1max=a+a1+a2+a3+a4+a5+a6+a7; tt2min=b+b1+b2+b3+b4+b5+b6+b7; break;
         case 8     : tt1max=a+a1+a2+a3+a4+a5+a6+a7+a8; tt2min=b+b1+b2+b3+b4+b5+b6+b7+b8; break;
         default    : tt1max=a+a1+a2+a3+a4+a5+a6+a7+a8; tt2min=b+b1+b2+b3+b4+b5+b6+b7+b8; 
      }
                   
      ExtMapBuffer3[i]=tt1max;
      ExtMapBuffer4[i]=tt2min;
   }
                       
   // Loop 2: Safe Moving Average Generation down to Bar 0 (Reusing 'i')
   for(i=limit-1; i>=0; i--)
   {   
      ExtMapBuffer1[i]=iMAOnArray(ExtMapBuffer3,Bars,Ma_Period,0,MODE_SMA,i);                  
      ExtMapBuffer2[i]=iMAOnArray(ExtMapBuffer4,Bars,Ma_Period,0,MODE_SMA,i);  
   }                  

   // Loop 3: Safe Signal Allocation via Native Indicator Buffers (Reusing 'i')
   for(i=limit-1; i>=0; i--)
   { 
      if(i >= Bars-1) continue; 
      
      // Initialize/Clear buffers for current index loop to avoid phantom signals carrying over
      ArrowUpBuffer[i] = EMPTY_VALUE;
      ArrowDnBuffer[i] = EMPTY_VALUE;

      if(arrows)
      {
         double gap = 3.0 * iATR(NULL, 0, 20, i) / 4.0;
         
         if(ExtMapBuffer1[i] >= ExtMapBuffer2[i] && ExtMapBuffer1[i+1] < ExtMapBuffer2[i+1])
         {
            ArrowUpBuffer[i] = Low[i] - gap; // Position arrow smoothly under the bar
         }
         else if(ExtMapBuffer1[i] <= ExtMapBuffer2[i] && ExtMapBuffer1[i+1] > ExtMapBuffer2[i+1])
         {
            ArrowDnBuffer[i] = High[i] + gap; // Position arrow smoothly above the bar
         }      
      }
   }      
   return(0);
}
