template<typename T>
void PushArray(T &arr[], const T &value)
{
   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);

   // shift semua elemen ke kanan
   ArrayCopy(arr, arr, 1, 0, size);

   // insert di depan
   arr[0] = value;
}

void CreateButton(string name,int x,int y,string text)
{
   ObjectCreate(0,name,OBJ_BUTTON,0,0,0);

   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,200);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,50);

   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_ZORDER,1000);
}