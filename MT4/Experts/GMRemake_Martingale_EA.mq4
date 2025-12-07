//+------------------------------------------------------------------+
//|                                      GMRemake_Martingale_EA.mq4 |
//|                        Copyright 2024, GMRemake Martingale EA    |
//|                      A Martingale Trading Strategy for MT4       |
//|                      Original idea from AlgoX GM                 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, GMRemake Martingale EA"
#property link      "https://github.com/yourusername/GMRemake"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

// Basic Settings
enum ENUM_ENTRY_MODE
{
   ENTRY_MODE_INSTANT = 0,    // Instant Breakout (Every Tick)
   ENTRY_MODE_CONFIRMED = 1   // Confirmed Breakout (New Bar)
};

input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;                    // Trading Timeframe
input ENUM_ENTRY_MODE EntryModeLevel1 = ENTRY_MODE_CONFIRMED;   // Level 1 Entry Mode
input int             BarsCountedBack = 3;                      // 超越多少Bars後入市, 若沒有倉位時參考這入市參數
input int             MaxBuyOrder = 5;                          // 最多的馬丁多倉層數, 0為不會開多倉, 若馬丁已經超出此層數即時平掉所有多倉
input int             MaxSellOrder = 5;                         // 最多的馬丁空倉層數, 0為不會開空倉, 若馬丁已經超出此層數即時平掉所有空倉

// Entry Distance Parameters (in points) - Optimized for BTCUSD
input int             EntryDistance1 = 100;                    // Entry Distance 1 (First Order) ~$1
input int             EntryDistance2 = 20000;                    // Entry Distance 2 (Second Order) ~$200
input int             EntryDistance3 = 20000;                   // Entry Distance 3 (Third Order) ~$200
input int             EntryDistance4 = 20000;                   // Entry Distance 4 (Fourth Order) ~$200
input int             EntryDistance5 = 20000;                   // Entry Distance 5 (Fifth Order) ~$200
input int             EntryDistance6 = 20000;                   // Entry Distance 6 (Sixth Order) ~$200
input int             EntryDistance7 = 25000;                   // Entry Distance 7 (Seventh Order) ~$250
input int             EntryDistance8 = 30000;                   // Entry Distance 8 (Eighth Order) ~$300

// Lot Size Parameters
input double          LotSize1 = 0.01;                          // Lot Size 1 (First Order)
input double          LotSize2 = 0.02;                          // Lot Size 2 (Second Order)
input double          LotSize3 = 0.04;                          // Lot Size 3 (Third Order)
input double          LotSize4 = 0.08;                          // Lot Size 4 (Fourth Order)
input double          LotSize5 = 0.16;                          // Lot Size 5 (Fifth Order)
input double          LotSize6 = 0.32;                          // Lot Size 6 (Sixth Order)
input double          LotSize7 = 0.64;                          // Lot Size 7 (Seventh Order)
input double          LotSize8 = 1.28;                          // Lot Size 8 (Eighth Order)

// Trend Protection Parameters
input bool            TrendProtection = true;                   // Trend Protection (Price Confirmation)
input bool            MACDTrendProtection = true;               // MACD Trend Protection

// EMA Trend Filter Parameters
enum ENUM_EMA_FILTER_MODE
{
   EMA_FILTER_DISABLED = 0,   // Disabled
   EMA_FILTER_ABOVE = 1,      // Price must be Above EMA
   EMA_FILTER_BELOW = 2       // Price must be Below EMA
};

input int             EMATrendPeriodL = 200;                    // EMA Trend Period (Long)
input ENUM_EMA_FILTER_MODE EMATrendFilterLModeBuy = EMA_FILTER_DISABLED; // EMA(L) Filter Mode for Buy
input double          EMATrendFilterLForBuy = 0;                // EMA(L) Distance for Buy (+/- points)
input ENUM_EMA_FILTER_MODE EMATrendFilterLModeSell = EMA_FILTER_DISABLED; // EMA(L) Filter Mode for Sell
input double          EMATrendFilterLForSell = 0;               // EMA(L) Distance for Sell (+/- points)

input int             EMATrendPeriodS = 50;                     // EMA Trend Period (Short)
input ENUM_EMA_FILTER_MODE EMATrendFilterSModeBuy = EMA_FILTER_DISABLED; // EMA(S) Filter Mode for Buy
input double          EMATrendFilterSForBuy = 0;                // EMA(S) Distance for Buy (+/- points)
input ENUM_EMA_FILTER_MODE EMATrendFilterSModeSell = EMA_FILTER_DISABLED; // EMA(S) Filter Mode for Sell
input double          EMATrendFilterSForSell = 0;               // EMA(S) Distance for Sell (+/- points)

// Trailing Stop Parameters
input int             TrailingPoints = 8000;                    // Trailing Start Points ~$80
input int             StopTrailingPoints = 1000;                // 在已超出Trailig Points 後, 回踩多少(points)後立即平倉 ~$10

// General Parameters
input int             SlippageInPoints = 30;                   // Slippage in Points 
input int             SpreadInPoints = 2000;                    // Maximum Spread in Points ~$20
input int             MagicNumber = 20251207;                   // Magic Number
input string          Comment = "GMRemake_Martingale";          // Order Comment

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
double EntryDistances[8];
double LotSizes[8];
int CurrentBuyOrders = 0;
int CurrentSellOrders = 0;
double LastBuyPrice = 0;
double LastSellPrice = 0;
double MaxBidPrice = 0; // Highest Bid price seen during active Buy orders
double MinAskPrice = 0; // Lowest Ask price seen during active Sell orders
datetime LastBarTime = 0; // Last bar time for New Bar Check

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize entry distances array
   EntryDistances[0] = EntryDistance1 * Point;
   EntryDistances[1] = EntryDistance2 * Point;
   EntryDistances[2] = EntryDistance3 * Point;
   EntryDistances[3] = EntryDistance4 * Point;
   EntryDistances[4] = EntryDistance5 * Point;
   EntryDistances[5] = EntryDistance6 * Point;
   EntryDistances[6] = EntryDistance7 * Point;
   EntryDistances[7] = EntryDistance8 * Point;
   
   // Initialize lot sizes array
   LotSizes[0] = LotSize1;
   LotSizes[1] = LotSize2;
   LotSizes[2] = LotSize3;
   LotSizes[3] = LotSize4;
   LotSizes[4] = LotSize5;
   LotSizes[5] = LotSize6;
   LotSizes[6] = LotSize7;
   LotSizes[7] = LotSize8;
   
   Print("GMRemake Martingale EA Initialized Successfully");
   Print("Max Buy Orders: ", MaxBuyOrder, " | Max Sell Orders: ", MaxSellOrder);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("GMRemake Martingale EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check spread
   double spread = (Ask - Bid) / Point;
   if(spread > SpreadInPoints)
   {
      return;
   }
   
   // Count current orders
   CountOrders();
   
   // Reset Virtual Trailing High/Low if no orders
   if(CurrentBuyOrders == 0) MaxBidPrice = 0;
   if(CurrentSellOrders == 0) MinAskPrice = 0;
   
   // Enforce Max Orders Limits
   if(CurrentBuyOrders > MaxBuyOrder)
   {
      CloseAllBuyOrders();
      return;
   }
   
   if(CurrentSellOrders > MaxSellOrder)
   {
      CloseAllSellOrders();
      return;
   }
   
   // Check for Stop Loss (Max Orders Reached + Next Level Distance)
   CheckStopLoss();
   
   // Check trailing stop for existing orders
   ManageTrailingStop();
   
   // Check for New Bar
   bool isNewBar = false;
   if(LastBarTime != iTime(Symbol(), Timeframe, 0))
   {
       isNewBar = true;
       LastBarTime = iTime(Symbol(), Timeframe, 0);
   }
   
   // Check for new entry signals (Level 1 - Breakout)
   if(CurrentBuyOrders == 0 && MaxBuyOrder > 0)
   {
      if(EntryModeLevel1 == ENTRY_MODE_INSTANT || (EntryModeLevel1 == ENTRY_MODE_CONFIRMED && isNewBar))
      {
         CheckBuyEntry(1);
      }
   }
   
   if(CurrentSellOrders == 0 && MaxSellOrder > 0)
   {
      if(EntryModeLevel1 == ENTRY_MODE_INSTANT || (EntryModeLevel1 == ENTRY_MODE_CONFIRMED && isNewBar))
      {
         CheckSellEntry(1);
      }
   }
   
   // Check for martingale entries (Level > 1)
   // Martingale entries can be checked once per bar (Trend Confirmation)
   if(isNewBar)
   {
       if(CurrentBuyOrders > 0 && CurrentBuyOrders < MaxBuyOrder)
       {
          CheckBuyEntry(CurrentBuyOrders + 1);
       }
       
       if(CurrentSellOrders > 0 && CurrentSellOrders < MaxSellOrder)
       {
          CheckSellEntry(CurrentSellOrders + 1);
       }
   }
}

//+------------------------------------------------------------------+
//| Count current orders                                             |
//+------------------------------------------------------------------+
void CountOrders()
{
   CurrentBuyOrders = 0;
   CurrentSellOrders = 0;
   LastBuyPrice = 0;
   LastSellPrice = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
         {
            if(OrderType() == OP_BUY)
            {
               CurrentBuyOrders++;
               if(LastBuyPrice == 0 || OrderOpenPrice() < LastBuyPrice)
               {
                  LastBuyPrice = OrderOpenPrice();
               }
            }
            else if(OrderType() == OP_SELL)
            {
               CurrentSellOrders++;
               if(LastSellPrice == 0 || OrderOpenPrice() > LastSellPrice)
               {
                  LastSellPrice = OrderOpenPrice();
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check for Buy Entry Signal                                       |
//+------------------------------------------------------------------+
void CheckBuyEntry(int orderLevel)
{
   if(orderLevel > MaxBuyOrder) return;
   if(orderLevel > 8) return;
   
   // Determine shift based on Entry Mode for Level 1
   int shift = 1;
   double checkPrice = Ask;
   double currentPrice = Ask;
   
   if(orderLevel == 1 && EntryModeLevel1 == ENTRY_MODE_CONFIRMED)
   {
      shift = 2; // Look back starting from Bar 2
      checkPrice = iClose(Symbol(), Timeframe, 1); // Check if Bar 1 Closed above threshold
   }

   // Get bars data
   double highestHigh = iHigh(Symbol(), Timeframe, iHighest(Symbol(), Timeframe, MODE_HIGH, BarsCountedBack, shift));
   
   bool canEnter = false;
   
   // First order logic
   if(orderLevel == 1)
   {
      double entryThreshold = highestHigh + EntryDistances[0];
      
      // Debug Print for Confirmed Mode
      if(EntryModeLevel1 == ENTRY_MODE_CONFIRMED)
      {
         // Print("Debug Confirmed Buy: Close[1]=", checkPrice, " Threshold=", entryThreshold, " (High[", shift, "] + ", EntryDistances[0], ")");
      }

      if(checkPrice >= entryThreshold)
      {
         canEnter = true;
      }
   }
   // Martingale orders (2nd to 8th)
   else if(orderLevel >= 2 && orderLevel <= 8)
   {
      if(LastBuyPrice > 0)
      {
         double requiredDistance = EntryDistances[orderLevel - 1];
         double currentLoss = LastBuyPrice - currentPrice;
         
         if(currentLoss >= requiredDistance)
         {
            canEnter = true;
            Print("Debug Buy Level ", orderLevel, ": Distance Reached. Loss: ", currentLoss, " Required: ", requiredDistance);
            
            // Trend Protection: Check if previous candle is Bullish (Green)
            if(TrendProtection && orderLevel >= 2)
            {
               double prevClose = iClose(Symbol(), Timeframe, 1);
               double prevOpen = iOpen(Symbol(), Timeframe, 1);
               
               // If previous candle is not Green (Close <= Open), don't enter
               if(prevClose <= prevOpen)
               {
                  canEnter = false;
                  Print("Debug Buy Level ", orderLevel, ": Blocked by Candle Color. Close: ", prevClose, " <= Open: ", prevOpen);
               }
            }
         }
      }
   }
   
   if(!canEnter) return;
   
   // MACD Trend Protection
   if(MACDTrendProtection && orderLevel >= 2)
   {
      if(!CheckMACDTrend(true))
      {
         Print("Debug Buy Level ", orderLevel, ": Blocked by MACD Protection");
         return;
      }
   }
   
   // EMA Trend Filter
   if(!CheckEMATrendFilter(true))
   {
      Print("Debug Buy Level ", orderLevel, ": Blocked by EMA Filter");
      return;
   }
   
   // Open Buy Order
   double lotSize = LotSizes[orderLevel - 1];
   Print("Debug: Attempting OrderSend. Level: ", orderLevel, " Lot: ", lotSize, " Ask: ", Ask, " Bid: ", Bid);
   
   int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, SlippageInPoints, 0, 0, Comment, MagicNumber, 0, clrBlue);
   
   if(ticket > 0)
   {
      Print("Buy Order Opened: Level ", orderLevel, " | Lot: ", lotSize, " | Price: ", Ask);
      // Reset MaxBidPrice to current price to avoid immediate trailing stop trigger from previous high
      MaxBidPrice = Ask; 
   }
   else
   {
      Print("Error opening Buy order: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Check for Sell Entry Signal                                      |
//+------------------------------------------------------------------+
void CheckSellEntry(int orderLevel)
{
   if(orderLevel > MaxSellOrder) return;
   if(orderLevel > 8) return;
   
   // Determine shift based on Entry Mode for Level 1
   int shift = 1;
   double checkPrice = Bid;
   double currentPrice = Bid;
   
   if(orderLevel == 1 && EntryModeLevel1 == ENTRY_MODE_CONFIRMED)
   {
      shift = 2; // Look back starting from Bar 2
      checkPrice = iClose(Symbol(), Timeframe, 1); // Check if Bar 1 Closed below threshold
   }
   
   // Get bars data
   double lowestLow = iLow(Symbol(), Timeframe, iLowest(Symbol(), Timeframe, MODE_LOW, BarsCountedBack, shift));
   
   bool canEnter = false;
   
   // First order logic
   if(orderLevel == 1)
   {
      double entryThreshold = lowestLow - EntryDistances[0];
      
      if(checkPrice <= entryThreshold)
      {
         canEnter = true;
      }
   }
   // Martingale orders (2nd to 8th)
   else if(orderLevel >= 2 && orderLevel <= 8)
   {
      if(LastSellPrice > 0)
      {
         double requiredDistance = EntryDistances[orderLevel - 1];
         double currentLoss = currentPrice - LastSellPrice;
         
         if(currentLoss >= requiredDistance)
         {
            canEnter = true;
            Print("Debug Sell Level ", orderLevel, ": Distance Reached. Loss: ", currentLoss, " Required: ", requiredDistance);
            
            // Trend Protection: Check if previous candle is Bearish (Red)
            if(TrendProtection && orderLevel >= 2)
            {
               double prevClose = iClose(Symbol(), Timeframe, 1);
               double prevOpen = iOpen(Symbol(), Timeframe, 1);
               
               // If previous candle is not Red (Close >= Open), don't enter
               if(prevClose >= prevOpen)
               {
                  canEnter = false;
                  Print("Debug Sell Level ", orderLevel, ": Blocked by Candle Color. Close: ", prevClose, " >= Open: ", prevOpen);
               }
            }
         }
      }
   }
   
   if(!canEnter) return;
   
   // MACD Trend Protection
   if(MACDTrendProtection && orderLevel >= 2)
   {
      if(!CheckMACDTrend(false))
      {
         Print("Debug Sell Level ", orderLevel, ": Blocked by MACD Protection");
         return;
      }
   }
   
   // EMA Trend Filter
   if(!CheckEMATrendFilter(false))
   {
      Print("Debug Sell Level ", orderLevel, ": Blocked by EMA Filter");
      return;
   }
   
   // Open Sell Order
   double lotSize = LotSizes[orderLevel - 1];
   Print("Debug: Attempting OrderSend. Level: ", orderLevel, " Lot: ", lotSize, " Ask: ", Ask, " Bid: ", Bid);

   int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, SlippageInPoints, 0, 0, Comment, MagicNumber, 0, clrRed);
   
   if(ticket > 0)
   {
      Print("Sell Order Opened: Level ", orderLevel, " | Lot: ", lotSize, " | Price: ", Bid);
      // Reset MinAskPrice to current price to avoid immediate trailing stop trigger from previous low
      MinAskPrice = Bid;
   }
   else
   {
      Print("Error opening Sell order: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Check MACD Trend                                                 |
//| Returns true if MACD is not showing 3 consecutive divergences   |
//+------------------------------------------------------------------+
bool CheckMACDTrend(bool isBuy)
{
   // MACD with period 14
   double macd1 = iMACD(Symbol(), Timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   double macd2 = iMACD(Symbol(), Timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 2);
   double macd3 = iMACD(Symbol(), Timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 3);
   
   if(isBuy)
   {
      // Check for bullish trend (MACD rising)
      if(macd1 < macd2 && macd2 < macd3)
      {
         // 3 consecutive bars showing bearish divergence - don't open buy
         return false;
      }
   }
   else
   {
      // Check for bearish trend (MACD falling)
      if(macd1 > macd2 && macd2 > macd3)
      {
         // 3 consecutive bars showing bullish divergence - don't open sell
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check EMA Trend Filter                                           |
//+------------------------------------------------------------------+
bool CheckEMATrendFilter(bool isBuy)
{
   double currentPrice = isBuy ? Ask : Bid;
   
   // --- Long EMA Check ---
   double emaL = iMA(Symbol(), Timeframe, EMATrendPeriodL, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   // Buy Side Long EMA
   if(isBuy && EMATrendFilterLModeBuy != EMA_FILTER_DISABLED)
   {
      double threshold = emaL + (EMATrendFilterLForBuy * Point);
      if(EMATrendFilterLModeBuy == EMA_FILTER_ABOVE && currentPrice <= threshold) return false;
      if(EMATrendFilterLModeBuy == EMA_FILTER_BELOW && currentPrice >= threshold) return false;
   }
   
   // Sell Side Long EMA
   if(!isBuy && EMATrendFilterLModeSell != EMA_FILTER_DISABLED)
   {
      double threshold = emaL + (EMATrendFilterLForSell * Point);
      if(EMATrendFilterLModeSell == EMA_FILTER_ABOVE && currentPrice <= threshold) return false;
      if(EMATrendFilterLModeSell == EMA_FILTER_BELOW && currentPrice >= threshold) return false;
   }

   // --- Short EMA Check ---
   double emaS = iMA(Symbol(), Timeframe, EMATrendPeriodS, 0, MODE_EMA, PRICE_CLOSE, 0);

   // Buy Side Short EMA
   if(isBuy && EMATrendFilterSModeBuy != EMA_FILTER_DISABLED)
   {
      double threshold = emaS + (EMATrendFilterSForBuy * Point);
      if(EMATrendFilterSModeBuy == EMA_FILTER_ABOVE && currentPrice <= threshold) return false;
      if(EMATrendFilterSModeBuy == EMA_FILTER_BELOW && currentPrice >= threshold) return false;
   }

   // Sell Side Short EMA
   if(!isBuy && EMATrendFilterSModeSell != EMA_FILTER_DISABLED)
   {
      double threshold = emaS + (EMATrendFilterSForSell * Point);
      if(EMATrendFilterSModeSell == EMA_FILTER_ABOVE && currentPrice <= threshold) return false;
      if(EMATrendFilterSModeSell == EMA_FILTER_BELOW && currentPrice >= threshold) return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Manage Trailing Stop (Basket Logic)                              |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   double trailingStart = TrailingPoints * Point;
   double trailingStop = StopTrailingPoints * Point;
   
   // --- Buy Basket Logic ---
   if(CurrentBuyOrders > 0)
   {
      // 1. Update High Watermark (MaxBidPrice)
      if(MaxBidPrice == 0 || Bid > MaxBidPrice) MaxBidPrice = Bid;
      
      // 2. Calculate Average Buy Price
      double totalLots = 0;
      double weightedPrice = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == OP_BUY)
            {
               weightedPrice += OrderOpenPrice() * OrderLots();
               totalLots += OrderLots();
            }
         }
      }
      
      if(totalLots > 0)
      {
         double avgPrice = weightedPrice / totalLots;
         
         // 3. Check if Basket is in Profit Zone (Above Average + Start Points)
         // We only trigger trailing if the HIGHEST price seen is comfortably above our average cost
         if(MaxBidPrice > avgPrice + trailingStart)
         {
            // 4. Check for Retracement (Price dropped from High)
            if(MaxBidPrice - Bid >= trailingStop)
            {
               Print("Basket Trailing Stop Triggered for BUY. AvgPrice: ", avgPrice, " High: ", MaxBidPrice, " Close: ", Bid);
               CloseAllBuyOrders();
            }
         }
      }
   }
   
   // --- Sell Basket Logic ---
   if(CurrentSellOrders > 0)
   {
      // 1. Update Low Watermark (MinAskPrice)
      if(MinAskPrice == 0 || Ask < MinAskPrice) MinAskPrice = Ask;
      
      // 2. Calculate Average Sell Price
      double totalLots = 0;
      double weightedPrice = 0;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == OP_SELL)
            {
               weightedPrice += OrderOpenPrice() * OrderLots();
               totalLots += OrderLots();
            }
         }
      }
      
      if(totalLots > 0)
      {
         double avgPrice = weightedPrice / totalLots;
         
         // 3. Check if Basket is in Profit Zone (Below Average - Start Points)
         if(MinAskPrice < avgPrice - trailingStart)
         {
            // 4. Check for Retracement (Price rose from Low)
            if(Ask - MinAskPrice >= trailingStop)
            {
               Print("Basket Trailing Stop Triggered for SELL. AvgPrice: ", avgPrice, " Low: ", MinAskPrice, " Close: ", Ask);
               CloseAllSellOrders();
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close All Buy Orders                                             |
//+------------------------------------------------------------------+
void CloseAllBuyOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == OP_BUY)
         {
            bool closed = OrderClose(OrderTicket(), OrderLots(), Bid, SlippageInPoints, clrRed);
            if(closed) 
               Print("Closed Buy Order #", OrderTicket(), " due to MaxBuyOrder exceeded");
            else 
               Print("Failed to close Buy Order #", OrderTicket(), " Error: ", GetLastError());
         }
      }
   }
   CurrentSellOrders = 0;
}

//+------------------------------------------------------------------+
//| Check Stop Loss (Max Orders Reached)                             |
//+------------------------------------------------------------------+
void CheckStopLoss()
{
   // Buy Side
   if(CurrentBuyOrders >= MaxBuyOrder && MaxBuyOrder > 0)
   {
      // Determine the distance for the stop loss
      // Rule: If MaxBuyOrder=6, use EntryDistance for level 7.
      // We use the distance of the "next" level that would have been opened.
      
      int distanceIndex = MaxBuyOrder; // For MaxBuyOrder=6, we want EntryDistances[6] (Level 7)
      
      // If the next level is beyond our defined distances (8 levels), use the last available distance
      if(distanceIndex >= 8) distanceIndex = 7; 
      
      double stopLossDistance = EntryDistances[distanceIndex];
      
      if(LastBuyPrice > 0)
      {
         double currentLoss = LastBuyPrice - Bid;
         if(currentLoss >= stopLossDistance)
         {
            Print("Stop Loss Triggered: Max Buy Orders (", MaxBuyOrder, ") reached and price moved ", currentLoss/Point, " points (Target: ", stopLossDistance/Point, ").");
            CloseAllBuyOrders();
         }
      }
   }

   // Sell Side
   if(CurrentSellOrders >= MaxSellOrder && MaxSellOrder > 0)
   {
      // Determine the distance for the stop loss
      int distanceIndex = MaxSellOrder; // For MaxSellOrder=6, we want EntryDistances[6] (Level 7)
      
      // If the next level is beyond our defined distances (8 levels), use the last available distance
      if(distanceIndex >= 8) distanceIndex = 7;
      
      double stopLossDistance = EntryDistances[distanceIndex];
      
      if(LastSellPrice > 0)
      {
         double currentLoss = Ask - LastSellPrice;
         if(currentLoss >= stopLossDistance)
         {
            Print("Stop Loss Triggered: Max Sell Orders (", MaxSellOrder, ") reached and price moved ", currentLoss/Point, " points (Target: ", stopLossDistance/Point, ").");
            CloseAllSellOrders();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Close All Sell Orders                                            |
//+------------------------------------------------------------------+
void CloseAllSellOrders()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() == OP_SELL)
         {
            bool closed = OrderClose(OrderTicket(), OrderLots(), Ask, SlippageInPoints, clrBlue);
            if(closed) 
               Print("Closed Sell Order #", OrderTicket(), " due to MaxSellOrder exceeded");
            else 
               Print("Failed to close Sell Order #", OrderTicket(), " Error: ", GetLastError());
         }
      }
   }
   CurrentSellOrders = 0;
}

