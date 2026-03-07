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
      void UpdateExtPivots(PIVOT &extPivots[], PIVOT &pivots[], MqlRates &rates[]);
      void DrawExtPivots(PIVOT &extPivots[], MqlRates &rates[]);      
      
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

string lastPivot0Name = "", lastPivot1Name = "";
void MarketStructure::DrawPivots(PIVOT &pivots[], const MqlRates &rates[]) {
   deleteLineIfNotUsed(lastPivot0Name, 5, pivots);
   deleteLineIfNotUsed(lastPivot1Name, 5, pivots);
   drawPivots(pivots, rates);
   if (ArraySize(pivots) >= 2) {
      lastPivot0Name = LINE_PREFIX + IntegerToString(pivots[1].time);
      lastPivot1Name = LINE_PREFIX + IntegerToString(pivots[2].time);
   } else {
      lastPivot0Name = ""; lastPivot1Name = "";
   }
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

void MarketStructure::UpdateExtPivots(PIVOT &extPivots[], PIVOT &pivots[], MqlRates &rates[]) {
   int numPivot = ArraySize(pivots);
   
   if(numPivot<=3) return;
   
   ArrayResize(extPivots, numPivot);
   int numExtPivot = 2;
   
   extPivots[0] = pivots[numPivot-1];
   extPivots[1] = pivots[numPivot-2];
   
   PIVOT lastPivotHigh, lastPivotLow;
   if(extPivots[1].type == PIVOT_HIGH) {
      lastPivotHigh = extPivots[1];
      lastPivotLow = extPivots[0];
   } else {
      lastPivotHigh = extPivots[0];
      lastPivotLow = extPivots[1];
   }
   PIVOT internalLowest = pivots[numPivot-3], internalHighest = pivots[numPivot-3];
   
   for(int i = numPivot-3; i>0; i--) {
      PIVOT currentPivot = pivots[i];
      if (currentPivot.price < lastPivotLow.price) {  // BoS bear
         if (extPivots[numExtPivot-1].type == PIVOT_LOW) {  // lastExtPivot type ==> LOW
            extPivots[numExtPivot++] = internalHighest;     // insert internal highest
            extPivots[numExtPivot++] = currentPivot;        // insert external low
            lastPivotHigh = internalHighest;
         } else { // BoS
            extPivots[numExtPivot++] = currentPivot;
         }
         lastPivotLow = currentPivot;            
         internalLowest = pivots[i-1];
         internalHighest = pivots[i-1];
         continue;
      }
      if (currentPivot.price > lastPivotHigh.price) {  // BoS bull
         if (extPivots[numExtPivot-1].type == PIVOT_HIGH) { // lastExtPivot type ==> HIGH
            extPivots[numExtPivot++] = internalLowest;      // insert internal Lowest
            extPivots[numExtPivot++] = currentPivot;        // insert external High
            lastPivotLow = internalLowest;
         } else { // BoS
            extPivots[numExtPivot++] = currentPivot;
         }
         lastPivotHigh = currentPivot;            
         internalLowest = pivots[i-1];
         internalHighest = pivots[i-1];
         continue;
      }
      // Check internal pivot
      if (currentPivot.price < internalLowest.price) {
         internalLowest = currentPivot;
      } else if (currentPivot.price > internalHighest.price) {
            internalHighest = currentPivot;
      }
   }
   
   ArrayResize(extPivots, numExtPivot);
}

void MarketStructure::DrawExtPivots(PIVOT &extPivots[], MqlRates &rates[]) {
   int numPivot = ArraySize(extPivots);
   if (numPivot < 3) {
      if (numErrror < 3) PrintFormat("Draw ext pivot error, NUM PIVOT: %d", numPivot);
      numErrror++;
      return;
   }
   
   for(int i=1; i<numPivot-1; i++) {
      const string lineName = LINE_PREFIXEXT + IntegerToString(extPivots[i].time);
      DrawExtPivot(lineName, extPivots[i-1], extPivots[i], extPivots[i+1]);
   }
}

void MergePivots(PIVOT &dest[], PIVOT &src[])
{
   int destSize = ArraySize(dest);
   int srcSize  = ArraySize(src);

   if(destSize == 0 || srcSize == 0)
      return;

   datetime matchTime = src[srcSize-1].time;
   int matchIndex = -1;

   int maxSearch = MathMin(destSize, 20); // cukup scan depan saja

   for(int i=0; i<maxSearch; i++)
   {
      if(dest[i].time == matchTime)
      {
         matchIndex = i;
         break;
      }

      if(dest[i].time < matchTime)
      {
         // pivot extend scenario
         if(i > 0 && srcSize >= 2 && dest[i-1].time == src[srcSize-2].time)
         {
            srcSize--;          // drop pivot terakhir src
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
   for(int i=tailSize-1; i>=0; i--)
      dest[srcSize+i] = dest[matchIndex+1+i];

   // copy src
   for(int i=0;i<srcSize;i++)
      dest[i] = src[i];
}

void MergePivotsBackup(PIVOT &dest[], PIVOT &src[])
{
   int destSize = ArraySize(dest);
   int srcSize  = ArraySize(src);

   if(srcSize == 0)
      return;

   datetime matchTime = src[srcSize-1].time;   // pivot tertua di src

   int matchIndex = -1;

   // cari di dest
   for(int i=0; i<10; i++)
   {
      if(dest[i].time == matchTime)
      {
         matchIndex = i;
         break;
      }
      if(dest[i].time < matchTime)
      {
         if(dest[i-1].time == src[srcSize-2].time) {
            ArrayResize(src, --srcSize);
            matchIndex = i-1;
            break;
         } else {
            Print(dest[i-1].time, " compare ", src[srcSize-2].time, " before: ", matchTime); 
            Print(i, " DEST: ", dest[i].time, ", ", dest[i+1].time); 
            Print("SRC: ", src[0].time, ", ", src[1].time, ", ", src[2].time, ", ", src[3].time, ", ", src[4].time);
            break; 
         }
      }
   }

   if(matchIndex == -1)
      return;

   int newSize = srcSize + (destSize - matchIndex - 1);

   PIVOT tmp[];
   ArrayResize(tmp,newSize);

   // copy src (pivot terbaru)
   for(int i=0;i<srcSize;i++)
      tmp[i] = src[i];

   // copy sisa dest
   for(int i=matchIndex+1;i<destSize;i++)
      tmp[srcSize + (i-matchIndex-1)] = dest[i];

   // replace dest
   ArrayResize(dest,newSize);
   ArrayCopy(dest,tmp);
}