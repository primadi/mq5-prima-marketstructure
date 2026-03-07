
void DrawLine(string name, datetime t0, double p0, datetime t1, double p1,
   color clr, int width, ENUM_LINE_STYLE lineStyle)
{
   ObjectCreateOrUpdate(0, name, OBJ_TREND, 0, t0, p0, t1, p1);

   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
}

void ObjectCreateOrUpdate(long chartId, const string name, ENUM_OBJECT object_type, int subWindow,
    datetime t0, double p0, datetime t1, double p1) {
   if(ObjectFind(0, name) < 0) 
      ObjectCreate(chartId, name, object_type, subWindow, t0, p0, t1, p1);
   else
   {
      ObjectMove(0, name, 0, t0, p0);
      ObjectMove(0, name, 1, t1, p1);
   }
}

void DrawPivot(const string lineName, const PIVOT &pivotLeft, const PIVOT &pivotCurrent, 
   const PIVOT &pivotRight, const bool drawFibo, ENUM_TREND_TYPE &lastTrend) {
   double leftLength = MathAbs(pivotLeft.price - pivotCurrent.price);
   double rightLength = MathAbs(pivotCurrent.price - pivotRight.price);
   ENUM_TREND_TYPE currentTrend = rightLength <= leftLength ? TREND_NONE :
      pivotCurrent.type == PIVOT_HIGH ? TREND_LOW : TREND_HIGH;
      
   color lineColor = inpNoneColor;
   ENUM_LINE_STYLE style = STYLE_DOT;
   
   if (currentTrend == TREND_LOW) {
      lineColor = (lastTrend != TREND_HIGH)  ? inpBearColor : inpChocBearColor;
      style = STYLE_SOLID;
      lastTrend = currentTrend;
   } else if (currentTrend == TREND_HIGH) {
      lineColor = (lastTrend != TREND_LOW)  ? inpBullColor : inpChocBullColor;
      style = STYLE_SOLID;
      lastTrend = currentTrend;
   }
   
   DrawLine(lineName, pivotCurrent.time, pivotCurrent.price, 
      pivotRight.time, pivotRight.price, lineColor, inpLineWidth, style);
   if(drawFibo && lineColor != inpNoneColor) {
      DrawFiboLevel(lineName, pivotCurrent.time, pivotCurrent.price,
         pivotRight.time, pivotRight.price, lineColor);
   }
}
//+------------------------------------------------------------------+
void DrawFiboLevel(string name, datetime t0, double p0, datetime t1, double p1, color clr)
{
   string fiboName = name + "_F1";
   double level = p1 + (p0 - p1) * inpFiboLevel1;
   
   ObjectCreateOrUpdate(0, fiboName, OBJ_TREND, 0, t0, level, t1, level);
   ObjectSetInteger(0, fiboName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, fiboName, OBJPROP_WIDTH, inpLineWidth);
   ObjectSetInteger(0, fiboName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, fiboName, OBJPROP_RAY_RIGHT, false); // only on range
   ObjectSetInteger(0, fiboName, OBJPROP_BACK, true);
   
   fiboName = name + "_F2";
   level = p1 + (p0 - p1) * inpFiboLevel2;
   
   ObjectCreateOrUpdate(0, fiboName, OBJ_TREND, 0, t0, level, t1, level);
   ObjectSetInteger(0, fiboName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, fiboName, OBJPROP_WIDTH, inpLineWidth);
   ObjectSetInteger(0, fiboName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, fiboName, OBJPROP_RAY_RIGHT, false); // only on range
   ObjectSetInteger(0, fiboName, OBJPROP_BACK, true);
}

void DrawExtPivot(const string lineName, const PIVOT &pivotLeft, const PIVOT &pivotCurrent, 
   const PIVOT &pivotRight) {
   double leftLength = MathAbs(pivotLeft.price - pivotCurrent.price);
   double rightLength = MathAbs(pivotCurrent.price - pivotRight.price);
   ENUM_TREND_TYPE currentTrend = rightLength <= leftLength ? TREND_NONE :
      pivotCurrent.type == PIVOT_HIGH ? TREND_LOW : TREND_HIGH;
      
   color lineColor = inpNoneColor;
   ENUM_LINE_STYLE style = STYLE_DOT;
   
   if (currentTrend == TREND_LOW) {
      lineColor = inpExtBearColor;
      style = STYLE_SOLID;
   } else if (currentTrend == TREND_HIGH) {
      lineColor = inpExtBullColor;
      style = STYLE_SOLID;
   }
   
   DrawLine(lineName, pivotCurrent.time, pivotCurrent.price, 
      pivotRight.time, pivotRight.price, lineColor, inpLineWidth+2, style);
}