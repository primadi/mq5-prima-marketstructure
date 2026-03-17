void drawExtPivotsBackup(PIVOT &extPivots[], MqlRates &rates[]) {
   int numPivot = ArraySize(extPivots);
   if (numPivot < 3) {
      if (numErrror < 3) PrintFormat("Draw ext pivot error, NUM PIVOT: %d", numPivot);
      numErrror++;
      return;
   }
   
   // DRAW EXT PIVOTS
   for(int i=1; i<numPivot-1; i++) {
      const string lineName = LINE_PREFIXEXT + IntegerToString(extPivots[i].time);
      DrawExtPivot(lineName, extPivots[i-1], extPivots[i], extPivots[i+1]);
   }
}

void updateExtPivotsBackup(PIVOT &extPivots[], PIVOT &pivots[], MqlRates &rates[]) {
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

template<typename T>
void PushArrayBackup(T &arr[], const T &value)
{
   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);

   // geser ke kiri (index 0 paling kanan)
   for(int i = size; i > 0; i--)
      arr[i] = arr[i - 1];

   // insert di depan
   arr[0] = value;
}