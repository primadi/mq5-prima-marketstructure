const string LINE_PREFIX = "PMS_";
const string LINE_PREFIXEXT = "PME_";

enum ENUM_PIVOT_TYPE { PIVOT_NONE = 0, PIVOT_HIGH = 1, PIVOT_LOW = -1};
enum ENUM_TREND_TYPE { TREND_NONE = 0, TREND_HIGH = 1, TREND_LOW = -1};

#include  "utils.mqh";

bool neverPrint = true;

struct PIVOT {
   //int index;
   datetime time;
   ENUM_PIVOT_TYPE type;
   double price;
};

class MarketStructure {
   private:
      bool IsValidPivotHigh(const int idx, const int last_pivot_index, const int numRightBar, const MqlRates &rates[]);
      bool IsValidPivotLow(const int idx, const int last_pivot_index, const int numRightBar, const MqlRates &rates[]);
      PIVOT calcTempPivot(const PIVOT &pivots[], const MqlRates &rates[], const string symbol, const ENUM_TIMEFRAMES tf);
   public:
      void DrawPivots(PIVOT &pivots[], const MqlRates &rates[]);
      void UpdateExtPivots(PIVOT &extPivots[], PIVOT &pivots[]);
      void DrawExtPivots(PIVOT &extPivots[]);      
      
      void UpdateAllPivots(PIVOT &pivots[], const int numPivot, const int numRightBar,
         const MqlRates &rates[], const string symbol, const ENUM_TIMEFRAMES tf) {
         int pivotCount = 0;
         ArrayResize(pivots, numPivot);
   
         int numBars = ArraySize(rates);
         int idxBarLastHigh = -1, idxBarLastLow = -1;
         ENUM_PIVOT_TYPE lastType = PIVOT_NONE;

         for(int i=numRightBar; i<numBars; i++) {
            if (pivotCount >= numPivot) break;
            
            if (idxBarLastHigh>=0) {
               if (lastType == PIVOT_HIGH && rates[i].high >= rates[idxBarLastHigh].high) {
                  PIVOT pv = { rates[i].time, PIVOT_HIGH, rates[i].high };
                  pivots[pivotCount-1] = pv;
                  idxBarLastHigh = i;
                  continue;
               }
            }
            if (idxBarLastLow>=0) {
               if (lastType == PIVOT_LOW && rates[i].low <= rates[idxBarLastLow].low) {
                  PIVOT pv = { rates[i].time, PIVOT_LOW, rates[i].low };
                  pivots[pivotCount-1] = pv;
                  idxBarLastLow = i;
                  continue;
               }
            }
            
            bool isPivotHigh = IsValidPivotHigh(i, idxBarLastLow, numRightBar, rates);
            bool isPivotLow = IsValidPivotLow(i, idxBarLastHigh, numRightBar, rates);
               
            if(isPivotHigh && lastType != PIVOT_HIGH) {
               PIVOT pv = { rates[i].time, PIVOT_HIGH, rates[i].high };
               pivots[pivotCount++] = pv;
               idxBarLastHigh = i;
               lastType = PIVOT_HIGH;
               continue;
            }
            if(isPivotLow && lastType != PIVOT_LOW) {
               PIVOT pv = { rates[i].time, PIVOT_LOW, rates[i].low };
               pivots[pivotCount++] = pv;
               idxBarLastLow = i;
               lastType = PIVOT_LOW;
               continue;
            }
         }
         ArrayResize(pivots, pivotCount);
         PIVOT tempPivot = MarketStructure::calcTempPivot(pivots, rates, symbol, tf);
         if (tempPivot.time != 0) {   // merge temp pivot
            if (tempPivot.type == pivots[0].type)
               pivots[0] = tempPivot;
            else
               PushArray(pivots, tempPivot);
         }
     }
};

bool MarketStructure::IsValidPivotHigh(const int idx, const int last_pivot_index, const int numRightBar, const MqlRates &rates[]) {
   int bearCount = 0;
   double lastBearClose = rates[idx].low;
   int start = idx - 1;
   int end = (last_pivot_index >= 0) ? last_pivot_index : 0;
   for(int k = start; k > end; k--)
   {
      if(rates[k].close < rates[k].open && rates[k].close < lastBearClose) // bear bar && close lower
      {
         bearCount++;
         lastBearClose = rates[k].close;
         if(bearCount >= numRightBar) break;
      }
   }
   return bearCount >= numRightBar;
}

bool MarketStructure::IsValidPivotLow(const int idx, const int last_pivot_index, const int numRightBar, const MqlRates &rates[]) {
   int bullCount = 0;
   double lastBullClose = rates[idx].high;
   int start = idx - 1;
   int end = (last_pivot_index >= 0) ? last_pivot_index : 0;
   for(int k = start; k > end; k--)
   {
      if(rates[k].close > rates[k].open && rates[k].close > lastBullClose) // bull bar && close higher
      {
         bullCount++;
         lastBullClose = rates[k].close;
         if(bullCount >= numRightBar) break;
      }
   }
   return bullCount >= numRightBar;
}

PIVOT MarketStructure::calcTempPivot(const PIVOT &pivots[], const MqlRates &rates[], const string symbol, const ENUM_TIMEFRAMES tf) {
   if (ArraySize(pivots) <= 0) {
      PIVOT pv = { 0, PIVOT_NONE, 0};    // time 0 remove temp pivot
      return pv;
   }
   
   PIVOT lastPivot = pivots[0];
   int lastPivotIndex = iBarShift(symbol, tf, lastPivot.time, true);
   if (lastPivotIndex-2<0) {
      PIVOT pv = { 0, PIVOT_NONE, 0};    // time 0 remove temp pivot
      return pv;
   }
   
   int idxLowestPivot = lastPivotIndex-1, idxHighestPivot = lastPivotIndex-1;
   for(int i=lastPivotIndex-2; i>=0; i--) {
      if(rates[i].low < rates[idxLowestPivot].low) idxLowestPivot = i;
      if(rates[i].high > rates[idxHighestPivot].high) idxHighestPivot = i;
   }
   
   if (lastPivot.type == PIVOT_HIGH) {
      if(rates[idxHighestPivot].high > lastPivot.price) {
         PIVOT pv = { rates[idxHighestPivot].time, PIVOT_HIGH, rates[idxHighestPivot].high};
         return pv;
      }
      PIVOT pv = { rates[idxLowestPivot].time, PIVOT_LOW, rates[idxLowestPivot].low}; // create new temp pivot
      return pv;
   }
   // lastPivot.type == PIVOT_LOW
   if(rates[idxLowestPivot].low < lastPivot.price) {
      PIVOT pv = { rates[idxLowestPivot].time, PIVOT_LOW, rates[idxLowestPivot].low};
      return pv;
   }
   PIVOT pv = { rates[idxHighestPivot].time, PIVOT_HIGH, rates[idxHighestPivot].high};  // create new temp pivot
   return pv;   
}

string lastPivotNames[3];
void MarketStructure::DrawPivots(PIVOT &pivots[], const MqlRates &rates[]) {
   for(int i=0; i<3; i++) deleteLineIfNotUsed(lastPivotNames[i], 5, pivots);
   drawPivots(pivots, rates);
   
   int numPivots = MathMin(3, ArraySize(pivots)-1);
   for(int i=0; i<numPivots; i++) lastPivotNames[i] = LINE_PREFIX + IntegerToString(pivots[i+1].time);
   for(int i=numPivots; i<3; i++) lastPivotNames[i] = "";
}

int numErrror = 0;
void drawPivots(PIVOT &pivots[], const MqlRates &rates[]) {
   int numPivot = ArraySize(pivots);
   if (numPivot < 3) {
      if (numErrror < 3) PrintFormat("Draw pivot error, NUM PIVOT: %d", numPivot);
      numErrror++;
      return;
   }
   
   ENUM_TREND_TYPE lastTrend = TREND_NONE;
   for(int i=numPivot-2; i>0; i--) {
      const string lineName = LINE_PREFIX + IntegerToString(pivots[i].time);
      DrawPivot(lineName, pivots[i+1], pivots[i], pivots[i-1], inpDrawFibo, lastTrend);
   }
}

void deleteLineIfNotUsed(string lineName, int maxSearch, PIVOT &pivots[]) {
   if (lineName == "") return;
   
   bool nameFound = false;
   int maxCount = MathMin(maxSearch, ArraySize(pivots));
   for(int i=1;i<maxCount-1; i++) {
      if (lineName == LINE_PREFIX + IntegerToString(pivots[i].time)) {
         nameFound = true;
         break;
      }
   }
   if (!nameFound) {
      ObjectDelete(0, lineName);
      ObjectDelete(0, lineName + "_F1");
      ObjectDelete(0, lineName + "_F2");
   }
}

void MarketStructure::UpdateExtPivots(PIVOT &extPivots[], PIVOT &pivots[])
{
   int numPivot = ArraySize(pivots);
   if(numPivot < 3)
      return;

   int numExt = ArraySize(extPivots);
   int extCapacity = numExt;
   int lastIdxBar = -1;

   if(numExt>0) {
      // remove last 2 pivot
      if (numExt>=2) numExt -= 2;
      datetime pivotTime = extPivots[numExt-1].time;
      
      // find lastIdxBar
      for (int i=numPivot-1; i>=0; i--)
         if (pivots[i].time == pivotTime) {
            lastIdxBar = i;
            break;
         }

      if (lastIdxBar == -1) {
         Print("IdxBarNotFound, resetted");
         numExt = 0;
      }
   }

   // init first 2 pivots
   if(numExt == 0)
   {
      extCapacity = 10;
      ArrayResize(extPivots, extCapacity);
      extPivots[0] = pivots[numPivot-1];
      extPivots[1] = pivots[numPivot-2];
      numExt = 2;
      lastIdxBar = numPivot-2;
   }

   // determine last structure pivots
   PIVOT lastHigh, lastLow;

   if(extPivots[numExt-1].type == PIVOT_HIGH)
   {
      lastHigh = extPivots[numExt-1];
      lastLow  = extPivots[numExt-2];
   }
   else
   {
      lastHigh = extPivots[numExt-2];
      lastLow  = extPivots[numExt-1];
   }
   
   if(lastIdxBar < 1) return;
   
   PIVOT internalLow  = pivots[lastIdxBar-1];
   PIVOT internalHigh = internalLow;

   for(int i = lastIdxBar-1; i >= 0; i--)
   {
      PIVOT p = pivots[i];

      // bearish BOS
      if(p.price < lastLow.price)
      {
         if(extPivots[numExt-1].type == PIVOT_LOW)
         {
            if(extCapacity < numExt+2) {
               extCapacity+=10;
               ArrayResize(extPivots, extCapacity);
            }
            extPivots[numExt++] = internalHigh;
            extPivots[numExt++] = p;
            lastHigh = internalHigh;
            lastIdxBar = i;
         }
         else
         {
            if(extCapacity < numExt+1) {
               extCapacity+=10;
               ArrayResize(extPivots, extCapacity);
            }         
            extPivots[numExt++] = p;
            lastIdxBar = i;
         }

         lastLow = p;

         if(i>0)
         {
            internalLow  = pivots[i-1];
            internalHigh = internalLow;
         }

         continue;
      }

      // bullish BOS
      if(p.price > lastHigh.price)
      {
         if(extPivots[numExt-1].type == PIVOT_HIGH)
         {
            if(extCapacity < numExt+2) {
               extCapacity+=10;
               ArrayResize(extPivots, extCapacity);
            }         
            extPivots[numExt++] = internalLow;
            extPivots[numExt++] = p;
            lastLow = internalLow;
            lastIdxBar = i;            
         }
         else
         {
            if(extCapacity < numExt+1) {
               extCapacity+=10;
               ArrayResize(extPivots, extCapacity);
            }         
            extPivots[numExt++] = p;
            lastIdxBar = i;            
         }

         lastHigh = p;

         if(i>0)
         {
            internalLow  = pivots[i-1];
            internalHigh = internalLow;
         }

         continue;
      }

      // update internal pivots
      if(p.price < internalLow.price)
         internalLow = p;
      else
      if(p.price > internalHigh.price)
         internalHigh = p;
   }

   ArrayResize(extPivots, numExt);
}

string lastExtPivotNames[3];
void MarketStructure::DrawExtPivots(PIVOT &pivots[]) {
   for(int i=0; i<3; i++) deleteLineIfNotUsed(lastExtPivotNames[i], 5, pivots);
   
   // DRAW EXT PIVOTS
   int numPivots = ArraySize(pivots);
   for(int i=1; i<numPivots-1; i++) {
      const string lineName = LINE_PREFIXEXT + IntegerToString(pivots[i].time);
      DrawExtPivot(lineName, pivots[i-1], pivots[i], pivots[i+1]);
   }
   numPivots = MathMin(3,numPivots);
   for(int i=0; i<numPivots; i++) lastExtPivotNames[i] = LINE_PREFIXEXT + IntegerToString(pivots[i+1].time);
   for(int i=numPivots; i<3; i++) lastExtPivotNames[i] = "";
}

void MergePivots(PIVOT &dest[], PIVOT &src[])
{
   int destSize = ArraySize(dest);
   int srcSize  = ArraySize(src);

   if(destSize == 0 || srcSize == 0)
      return;

   datetime matchTime = src[srcSize-1].time;
   int matchIndex = -1;

   int maxSearch = MathMin(destSize, 20);

   for(int i=0;i<maxSearch;i++)
   {
      if(dest[i].time == matchTime)
      {
         matchIndex = i;
         break;
      }

      if(dest[i].time < matchTime)
      {
         if(i>0 && srcSize>=2 && dest[i-1].time == src[srcSize-2].time)
         {
            srcSize--;
            matchIndex = i-1;
         }
         break;
      }
   }

   if(matchIndex < 0)
      return;

   int tailSize = destSize - matchIndex - 1;

   ArrayResize(dest, srcSize + tailSize);

   // shift tail
   ArrayCopy(dest, dest, srcSize, matchIndex+1, tailSize);

   // copy src
   ArrayCopy(dest, src, 0, 0, srcSize);
}
