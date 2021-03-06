//+------------------------------------------------------------------+
//|                                                       NAS100.mq4 |
//|                                                                  |
//|This script could be used in the FXCM MT4 for NAS100.             |
//|Known issue: Program would halt when orders openning       |
//|continuously failed. This may happen when the server is busy.     |

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//#define EXPERT_MAGIC 223456
double   old_price, new_price, front_price, back_price, middle_price, gap, fluctuation, spread, retracement;
double   a, vol; 
double   StartFreeMargin, EndFreeMargin;
double   dHigh[], dLow[],dMiddle[];
int      n, back;
int      ticket;
datetime ordertime;
string   ordersymbol;      //default is NAS100
//MqlTradeRequest request={0};
//MqlTradeResult  result={0};


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   n=0;
   a=20;    //For NAS100, 20 shows the best result.
   vol=10;
   back=1;
   ordersymbol="NAS100";    //default is NAS100
   //a=(SymbolInfoDouble(ordersymbol,SYMBOL_LASTHIGH)-SymbolInfoDouble(ordersymbol,SYMBOL_LASTLOW))*2;   
   //if(a<0.6) a=0.6; 
   //Print("High = ", SymbolInfoDouble(ordersymbol,SYMBOL_LASTHIGH), "Low = ", SymbolInfoDouble(ordersymbol,SYMBOL_LASTLOW), "a= ", a);
   StartFreeMargin=AccountInfoDouble(ACCOUNT_EQUITY);
   //StartFreeMargin=AccountEquity();
   Print("Account Equity is ",StartFreeMargin);
   //double price=SymbolInfoDouble(ordersymbol,SYMBOL_ASK); 
   //double bid=SymbolInfoDouble(ordersymbol,SYMBOL_BID); 
   new_price=SymbolInfoDouble(ordersymbol,SYMBOL_ASK); 
   old_price=new_price;
   
   //int total=PositionsTotal();  
   int total=OrdersTotal();
   //Print("Order total = ",total);
   if(total<=0)    //No orders opened
   {
      back_price=old_price;
      middle_price=old_price;
      gap=0;
      spread=0;
      fluctuation=0;
      retracement=0;
      Print("No Orders");
   }
   else //total==1
   {
      //ulong  position_ticket=PositionGetTicket(0); 
      //back_price=PositionGetDouble(POSITION_PRICE_OPEN);
      //datetime opentime=PositionGetInteger(POSITION_TIME);
      //datetime currenttime=TimeCurrent();
      //ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      //double lasthigh=iHigh(ordersymbol, PERIOD_M1, opentime, currenttime);
      //double lastlow=iLow(ordersymbol, PERIOD_M1, opentime, currenttime);
      
      if(OrderSelect(0, SELECT_BY_POS)==true)
      {
          ticket=OrderTicket();
          back_price=OrderOpenPrice();            //Price when order opened
          datetime opentime=OrderOpenTime();      //Time when order opened
          datetime currenttime=TimeCurrent();     //Current time
          //Print("Open time is ", opentime, ", Open price is ", back_price);
          int type=OrderType();    //Ordertype: Buy or Sell
          //Print(type);
          double lasthigh=iHigh(ordersymbol, PERIOD_M1, opentime, currenttime);    //The highest price since opening
          double lastlow=iLow(ordersymbol, PERIOD_M1, opentime, currenttime);      //The lowest price since opening
      
      //if(type==POSITION_TYPE_BUY)
          if(type==OP_BUY)    //Buy already opened
          {
             //back_price=PositionGetDouble(POSITION_PRICE_OPEN);
             middle_price=lasthigh;
             gap=middle_price-back_price;
             spread=0;
             fluctuation=old_price-back_price;
             retracement=0;
             Print("Buy already Open at ", back_price, " Fluctuation= ", fluctuation);
             Print("Buy Time is ", opentime, " Current Time is ", currenttime);
             Print("Last High is ", middle_price, " gap= ", gap);
          }
          else if(type==OP_SELL)    //Sell already opened
          {
             back_price=back_price+1;
             middle_price=lastlow;
             gap=middle_price-back_price;
             spread=0;
             fluctuation=old_price-back_price;
             retracement=0;
             Print("Sell already Open at ", back_price, " Fluctuation= ", fluctuation);
             Print("Sell Time is ", opentime, " Current Time is ", currenttime);
             Print("Last Low is ", middle_price, " gap= ", gap);
          }
      }
   }
   
   //Print("Account Balance is ",AccountInfoDouble(ACCOUNT_BALANCE));
   //Print("Profit is ", AccountInfoDouble(ACCOUNT_EQUITY)-StartFreeMargin);
   //Print("Profit is ", AccountInfoDouble(ACCOUNT_PROFIT));
   Sleep(1000);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+


//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+


//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   new_price=Ask;
   spread=new_price-old_price;
   fluctuation=new_price-back_price;
   old_price=new_price;
   //Print("Fluctuation= ", fluctuation);
   if(AccountInfoDouble(ACCOUNT_FREEMARGIN)>0)
   {  
      int total=OrdersTotal(); //Total order numbers.    
      if(total<=0)
      {
         if(fluctuation>(1.5*a))    //open a new Open order.
         {
            CloseAll();
            Print("Close All For Initialization");
            ticket=OpenBuy();
            if(ticket)
            {
            Print("Start Buy at ", old_price);
            back_price=old_price;
            middle_price=old_price;
            gap=0;
            fluctuation=0;   
            spread=0;
            }
            else Print("Open Buy Error. Try Again Soon...");
         }
         else if (fluctuation<(-1.5*a))    //Open a new Sell order.
         {
            CloseAll();
            Print("Close All For Initialization");
            ticket=OpenSell();
            if(ticket)
            {
            Print("Start Sell at ", old_price);
            back_price=old_price;
            middle_price=old_price;
            gap=0;
            fluctuation=0;   
            spread=0;
            }
            else Print("Open Sell Error. Try Again Soon...");
         }
         //Sleep(1000);
      }
      else //total==1
      {
      for(int i=total-1; i>=0; i--)
      {
         OrderSelect(i, SELECT_BY_POS);
         ticket=OrderTicket();
         int type = OrderType();
         
         if(type==OP_BUY)
         {
            CheckBuy();
         }
         else if(type==OP_SELL)
         {
            CheckSell();
         }
         //type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         //Print("Order Type is ", type);
         //Print("Balance is ", (AccountInfoDouble(ACCOUNT_EQUITY)-StartFreeMargin));
         
         datetime currenttime=TimeCurrent();
         if((currenttime-ordertime)>6*3600)
         {
            double cs=CheckStable();
            if(cs>0 && fabs(fluctuation)>(1.0*a))    //fluctuation > 1.0*a shows the best result for NAS100.
            {
            bool bclose=CloseAll();
            if(bclose)
            {
               back_price=cs;
               middle_price=cs;
               gap=0;
               fluctuation=0;   
               spread=0;
               Print("Close order for stablization, ordertime = ",ordertime, " current time = ", currenttime);
            }
            else Print("Close Error. Try again soon...");
            }
         }
      }
      }      
   }  
   Sleep(1000);   
//---
   
  }
  
int OpenBuy()
{   
   ordertime=TimeCurrent();
   //ticket=OrderSend(ordersymbol,OP_BUY,vol,Ask,100,0,0,"My Buy",EXPERT_MAGIC,0,clrGreen);
   ticket=OrderSend(ordersymbol,OP_BUY,vol,Ask,100,0,0,"My Buy",0,clrGreen);
   if(ticket<0)
   {
      Print("Order Buy failed with error #",GetLastError());
   }
   else
   {
      Print("Order Buy placed successfully at time ", ordertime);
      return(ticket);
   }
}


int OpenSell()
{   
   ordertime=TimeCurrent();
   //ticket=OrderSend(ordersymbol,OP_SELL,vol,Bid,100,0,0,"My Sell",EXPERT_MAGIC,0,clrRed);
   ticket=OrderSend(ordersymbol,OP_SELL,vol,Bid,100,0,0,"My Sell",0,clrRed);
   if(ticket<0)
   {
      Print("Order Sell failed with error #",GetLastError());
   }
   else
   {
      Print("Order Sell placed successfully at time ", ordertime);
      return(ticket);
   }
}  

bool CloseAll()    //Close all orders.
{
   int total=OrdersTotal();
   bool bclose;
   //Print(total);   
   for(int i=total-1; i>=0; i--)
   {     
      OrderSelect(i, SELECT_BY_POS);
      int type=OrderType();

      if(type==OP_BUY)
      {
         //OrderSend(ordersymbol,OP_SELL,10,Bid,3,0,0,"My Order",EXPERT_MAGIC,0,clrRed);
         bclose=OrderClose(ticket,vol,Bid,100,clrRed);
      }
      else //type==OP_SELL
      {
         //OrderSend(ordersymbol,OP_BUY,10,Ask,3,0,0,"My Order",EXPERT_MAGIC,0,clrGreen);
         bclose=OrderClose(ticket,vol,Ask,100,clrGreen);
      }
   }
   return(bclose);
}

void CheckBuy()
{
   bool bclose;
   if(spread>0)
   {      
      if(new_price>middle_price)
      {
         middle_price=new_price;
         gap=middle_price-back_price;

      }
   }
   else if(spread<0)
   {
      retracement=new_price-middle_price;
      if(gap<(2*a))
      {
         if(fluctuation<(-1.5*a))
         {
            bclose=CloseAll();
            while(!bclose)    //May fail when the server is busy.
            {
               Print("Close Error. Try again soon...");
               Sleep(1000);
               bclose=CloseAll();
            }

            if(bclose)
            {
               Print("Close Buy");
               ticket=OpenSell();
               while(!ticket)    //May fail when the server is busy.
               {
                  Print("Change to Sell Error. Try Again Soon...");
                  Sleep(1000);
                  ticket=OpenSell();
               }
               if(ticket)
               {
                  Print("Change to Sell at ", old_price);
                  back_price=old_price;
                  middle_price=old_price;
                  gap=0;
                  fluctuation=0;   
                  spread=0; 
               }
            //else Print("Change to Sell Error. Try Again Soon..."); 
            }  
            //else Print("Close Error. Try Again Soon...");      
         }
      }
      else if(gap>=(2*a))
      {
         if(retracement<-(gap/2))
         {
            bclose=CloseAll();
            while(!bclose)    //May fail when the server is busy.
            {
               Print("Close Error. Try again soon...");
               Sleep(1000);
               bclose=CloseAll();
            }
            if(bclose)
            {
               Print("Close Buy");
               ticket=OpenSell();
               while(!ticket)    //May fail when the server is busy.
               {
                  Print("Change to Sell Error. Try Again Soon...");
                  Sleep(1000);
                  ticket=OpenSell();
               }
               if(ticket)
               {
                  Print("Change to Sell at ", old_price);
                  back_price=old_price;
                  middle_price=old_price;
                  gap=0;
                  fluctuation=0; 
                  spread=0;  
               }
            } 
         }
      }
   }

   if(gap>=(4*a))    //Update the back_price and middle_price
   {
      back_price=middle_price-back*a;
      gap=middle_price-back_price;
      fluctuation=new_price-back_price;
   }   
}

void CheckSell()
{
   bool bclose;
   if(spread<0)
   {      
      if(new_price<middle_price)
      {
         middle_price=new_price;
         gap=middle_price-back_price;

      }
   }
   else if(spread>0)
   {      
      retracement=new_price-middle_price;
      if(gap>(-2*a))
      {
         if(fluctuation>(1.5*a))
         {
            bclose=CloseAll();
            while(!bclose)    //May fail when the server is busy.
            {
               Print("Close Error. Try again soon...");
               Sleep(1000);
               bclose=CloseAll();
            }
            if(bclose)
            {
               Print("Close Sell");
               //double price=SymbolInfoDouble(ordersymbol,SYMBOL_ASK);
               ticket=OpenBuy();
               while(!ticket)    //May fail when the server is busy.
               {
                  Print("Change to Buy Error. Try Again Soon...");
                  Sleep(1000);
                  ticket=OpenBuy();
               }
               if(ticket)
               {
                  Print("Change to Buy at ", old_price);
                  //old_price=price;
                  back_price=old_price;
                  middle_price=old_price;
                  gap=0;
                  fluctuation=0;   
                  spread=0;  
               }
            }        
         }
      }
      else if(gap<=(-2*a))
      {
         if(retracement>-(gap/2))
         {
            bclose=CloseAll();
            while(!bclose)    //May fail when the server is busy.
            {
               Print("Close Error. Try again soon...");
               Sleep(1000);
               bclose=CloseAll();
            }
            if(bclose)
            {
               Print("Close Sell");
               ticket=OpenBuy();
               while(!ticket)    //May fail when the server is busy.
               {
                  Print("Change to Buy Error. Try Again Soon...");
                  Sleep(1000);
                  ticket=OpenBuy();
               }
               if(ticket)
               {
                  Print("Change to Buy at ", old_price);
                  back_price=old_price;
                  middle_price=old_price;
                  gap=0;
                  fluctuation=0;  
                  spread=0; 
               }
            }  
         }
      }
   }
   if(gap<=(-4*a))
   {
      back_price=middle_price+back*a;
      gap=middle_price-back_price;
      fluctuation=new_price-back_price;
   }
}   

//Get the highest value since opening
double iHigh(string symbol,ENUM_TIMEFRAMES timeframe,datetime opentime, datetime currenttime)
{
   ArraySetAsSeries(dHigh,true);
   int copied=CopyHigh(symbol,timeframe,0,Bars(symbol, timeframe, opentime, currenttime),dHigh);
   double high=dHigh[0];
   for (int i=1; i<copied; i++) 
   {
      if(high<dHigh[i]) high=dHigh[i];
   }
   return(high);
}
//***********************************************

//Get the lowest value since opening
double iLow(string symbol,ENUM_TIMEFRAMES timeframe, datetime opentime, datetime currenttime)
{
   ArraySetAsSeries(dLow,true);
   int copied=CopyLow(symbol,timeframe,0,Bars(symbol,timeframe, opentime, currenttime),dLow);
   double low=dLow[0];
   for (int i=1; i<copied; i++) 
   {
      if(low>dLow[i]) low=dLow[i];
   }
   return(low);
} 
//***********************************************

//Check stable status per hour and return flag cs
double CheckStable()
{
   int i;
   datetime currenttime=TimeCurrent();
   datetime previoustime=currenttime-6*3600;
   int copied=CopyHigh(ordersymbol,PERIOD_H1,0,Bars(ordersymbol, PERIOD_H1, previoustime, currenttime),dHigh);
   CopyLow(ordersymbol,PERIOD_H1,0,Bars(ordersymbol, PERIOD_H1, previoustime, currenttime),dLow);
   CopyLow(ordersymbol,PERIOD_H1,0,Bars(ordersymbol, PERIOD_H1, previoustime, currenttime),dMiddle);
   for (i=0; i<copied; i++) 
   {
      dMiddle[i]=(dHigh[i]+dLow[i])/2;
   }
   double cs=dMiddle[copied-1];
   //Check stable status
   for (i=1; i<copied; i++) 
   {
      if(fabs(dMiddle[i]-dMiddle[i-1])>13) 
      {
         cs=0;
         break;
      }
   }
   return(cs);
}
//*******************************************************************


//+------------------------------------------------------------------+
