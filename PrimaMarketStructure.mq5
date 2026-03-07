//+------------------------------------------------------------------+
//|                                        PrimaMarketStructure V2.0 |
//|                                 Copyright 2026, Primadi Setiawan |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0
#property indicator_buffers 0

#include "PrimaMarketStructure.mqh";
#include "DrawUtils.mqh";

input int inpMaxPivot = 100;               // Number of pivot
input int inpNumRightBar = 2;             // Number of right leg bar
input color inpBullColor = clrGreen;      // Bull leg color
input color inpChocBullColor = clrCyan;   // ChoCh bull color
input color inpBearColor = clrRed;        // Bear leg color
input color inpChocBearColor = clrMagenta;// ChoCh bear color
input color inpNoneColor = clrGray;       // None leg color
input int   inpLineWidth = 3;             // Line leg width
input bool  inpDrawFibo = true;           // Draw fibo level
input double inpFiboLevel1 = 0.382;       // Fibo level 1
input double inpFiboLevel2 = 0.618;       // Fibo level 2
input bool  inpDrawInternalPivot = true;  // Draw internal pivot
input bool  inpDrawExternalPivot = true;  // Draw external pivot
input color inpExtBullColor = clrYellow;  // Ext Bull Color
input color inpExtBearColor = clrOrange;  // Ext Bear Color

const int REFRESH_COUNT = 5000;
int tickCount = REFRESH_COUNT;
MarketStructure ms;

bool pvVisible, extVisible;
string keyShowPV, keyShowExtPV;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   keyShowPV = "PV_" + _Symbol + "_" + IntegerToString(_Period);
   if(GlobalVariableCheck(keyShowPV))
      pvVisible = GlobalVariableGet(keyShowPV);
   else
      pvVisible = inpDrawInternalPivot;

   keyShowExtPV = "EV_" + _Symbol + "_" + IntegerToString(_Period);
   if(GlobalVariableCheck(keyShowExtPV))
      extVisible = GlobalVariableGet(keyShowExtPV);
   else
      extVisible = inpDrawExternalPivot;

         
   CreateButton("btnPV", 20,50, pvVisible ? "PV: SHOW": "PV: HIDE");
   ObjectSetInteger(0,"btnPV",OBJPROP_BGCOLOR,clrGreen);
   ObjectSetInteger(0,"btnPV",OBJPROP_COLOR,clrWhite);
      
   CreateButton("btnEXT",230,50, extVisible ? "EXT: SHOW": "EXT: HIDE");
   ObjectSetInteger(0,"btnEXT",OBJPROP_BGCOLOR,clrDodgerBlue);
   ObjectSetInteger(0,"btnEXT",OBJPROP_COLOR,clrWhite);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) 
{ 
   ObjectsDeleteAll(0, LINE_PREFIX);
   ObjectsDeleteAll(0, LINE_PREFIXEXT);
   
   //--- Hapus tombol saat indikator di-remove
   ObjectDelete(0, "btnPV");
   ObjectDelete(0, "btnEXT");
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id!=CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam=="btnPV")
   {
      pvVisible = !pvVisible;
      GlobalVariableSet(keyShowPV, pvVisible);
      
      if(pvVisible)
         ObjectSetString(0,"btnPV",OBJPROP_TEXT,"PV: SHOW");
      else
         ObjectSetString(0,"btnPV",OBJPROP_TEXT,"PV: HIDE");
   }

   if(sparam=="btnEXT")
   {
      extVisible = !extVisible;
      GlobalVariableSet(keyShowExtPV, extVisible);

      if(extVisible)
         ObjectSetString(0,"btnEXT",OBJPROP_TEXT,"EXT: SHOW");
      else
         ObjectSetString(0,"btnEXT",OBJPROP_TEXT,"EXT: HIDE");
   }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
PIVOT globalPivots[];
int OnCalculate(const int32_t rates_total,
                const int32_t prev_calculated, 
                const int32_t begin, 
                const double &price[]) {

   if(rates_total < inpNumRightBar) return(0);
   
   // reset objects every 1000 ticks
   if (tickCount++>=REFRESH_COUNT) { ObjectsDeleteAll(0, LINE_PREFIX); tickCount = 0; ArrayResize(globalPivots, 0); }
   bool needRefresh = tickCount == 0;
   MqlRates rates[];
   int bars_to_copy = needRefresh ? MathMin(rates_total, inpMaxPivot * 20) : 4 * 20;
   
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, bars_to_copy, rates);
   if(copied <= 0) return 0;
   ArraySetAsSeries(rates, true);

   if (needRefresh)
      ms.UpdateAllPivots(globalPivots, inpMaxPivot, inpNumRightBar , rates, _Symbol, PERIOD_CURRENT);
   else {
      PIVOT tempPivots[];
      ms.UpdateAllPivots(tempPivots, 4, inpNumRightBar , rates, _Symbol, PERIOD_CURRENT);
      MergePivots(globalPivots, tempPivots);
   }
   
   if (pvVisible) 
      ms.DrawPivots(globalPivots, rates);
   else
      ObjectsDeleteAll(0, LINE_PREFIX);
      
   if (extVisible) {
      PIVOT extPivots[];
      ms.UpdateExtPivots(extPivots, globalPivots, rates);
      
      /*if (neverPrint) {
         for(int i=0; i<ArraySize(extPivots); i++) {
            PrintFormat("ExtPV[%d] Price %f, Type %s", i, 
               extPivots[i].price, extPivots[i].type == PIVOT_HIGH ? "High" : "Low");
         }
      }*/
      
      ms.DrawExtPivots(extPivots, rates);
   } else ObjectsDeleteAll(0, LINE_PREFIXEXT);      

   neverPrint = false;
   return rates_total;         
}
