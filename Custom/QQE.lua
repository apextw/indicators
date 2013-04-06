-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
-- TODO: Add minimal and maximal value of numeric parameters and default color of the streams
function Init()
    indicator:name("Qualitative Quantitative Estimation");
    indicator:description("Qualitative Quantitative Estimation");
    indicator:requiredSource(core.Tick);
    indicator:type(core.Oscillator);

    indicator.parameters:addInteger("RF", "RSI Period", "RSI Period", 14);
    indicator.parameters:addInteger("RSP", "RSI  Smoothing Period", "RSI  Smoothing Period", 5);
    indicator.parameters:addInteger("AP", " ATR Period", " ATR Period", 14);
    indicator.parameters:addDouble("F", "Fast ATR Multipliers", "Fast ATR Multipliers", 2.618 );
	indicator.parameters:addDouble("S", "Slow ATR Multipliers", "Slow ATR Multipliers", 4.236);
	indicator.parameters:addBoolean("T", "Show Slow trailing stop", "", false);
	indicator.parameters:addColor("Q", "Color of QQE", "Color of QQE", core.rgb(255, 0, 0));
    indicator.parameters:addColor("T1", "Color of Fast trailing stop", "Color of Fast trailing stop", core.rgb(0, 255, 0));
	indicator.parameters:addColor("T2", "Color of Slow trailing stop", "Color of Slow trailing stop", core.rgb(0, 0, 255));
	
	
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- TODO: Refine the first period calculation for each of the output streams.
-- TODO: Calculate all constants, create instances all subsequent indicators and load all required libraries
-- Parameters block
local RF;
local RS;
local AP;
local FM;
local SM;
local Slow;

local first;
local source = nil;

-- Streams block
local RSI=nil;
local EMA=nil;
local TR=nil;
local ATR=nil;

local Stop1=nil;
local Stop2=nil;

local QQE = nil;
local TS1 = nil;
local TS2 = nil;

local WildersPeriod=nil

-- Routine
function Prepare()
    RF = instance.parameters.RF;
    RS = instance.parameters.RSP;
    AP = instance.parameters.AP;
    FM = instance.parameters.F;
    SM = instance.parameters.S;
	Slow = instance.parameters.T;
    source = instance.source;
    first = source:first();
	
	WildersPeriod=RF * 2 - 1;
	
	RSI = core.indicators:create("RSI", source, RF);
	EMA = core.indicators:create("EMA", RSI.DATA, RS);
	TR =  instance:addInternalStream(0, 0);
	ATR = core.indicators:create("EMA", TR, AP);
	DELTA = core.indicators:create("EMA", ATR.DATA, WildersPeriod);
	

    local name = profile:id() .. "(" .. source:name() .. ", " .. RF .. ", " .. RS .. ", " .. AP .. ", "  .. FM .. ", " .. SM .. ")";
    instance:name(name);
    QQE = instance:addStream("QQE", core.Line, name .. ".QQE", "QQE", instance.parameters.Q, first);
	
	TS1 = instance:addStream("TS1", core.Line, name .. ".TS", "TS Fast", instance.parameters.T1, first);
	if Slow then
	TS2 = instance:addStream("TS2", core.Line, name .. ".TS", "TS Slow", instance.parameters.T2, first);
	end

end

-- Indicator calculation routine
-- TODO: Add your code for calculation output values
function Update(period,mode)

		 if period >= RF and source:hasData(period) then

				 RSI:update(mode);
				 
					 if period >= RF + RS then
					 
						 EMA:update(mode);
						 
						 QQE[period] = EMA.DATA[period];
						 
							  if period >= RF + RS +1 then
							 TR[period] = math.abs(EMA.DATA[period] - EMA.DATA[period-1]);
							 
							       if period >= RF + RS +1  + AP then
									 ATR:update(mode);
									 
									 									 
                                          if period >=  RF + RS +1  + AP + WildersPeriod	 then 
										  
													    DELTA:update(mode);															
												
														if EMA.DATA[period] < TS1[period-1] then														
														
														 Stop1=EMA.DATA[period] + DELTA.DATA[period]*FM;
														 
															 if Stop1 > TS1[period-1] then
															         
															 	   if EMA.DATA[period-1] <  TS1[period-1]  then 														     
															       Stop1 = TS1[period-1];
																   end
															     
															 end									
																
														elseif  EMA.DATA[period] > TS1[period-1] then
														
                                                         Stop1=EMA.DATA[period] - DELTA.DATA[period]*FM;
														 
															 if Stop1 < TS1[period-1] then
															        
															        if EMA.DATA[period-1] >  TS1[period-1]  then 														     
															       Stop1 = TS1[period-1];
																   end
															       
															 end
															 
													    end	
														
														TS1[period]=Stop1;
														
														if Slow then
														
																	if EMA.DATA[period] < TS2[period-1] then														
																
																 Stop2=EMA.DATA[period] + DELTA.DATA[period]*SM;
																 
																	 if Stop2 > TS2[period-1] then
																			 
																			 if EMA.DATA[period-1] <  TS2[period-1]  then 	
																			 Stop2 = TS2[period-1];
																			 end
																	 end									
																		
																elseif  EMA.DATA[period] > TS2[period-1] then
																
																 Stop2=EMA.DATA[period] - DELTA.DATA[period]*SM;
																 
																	 if Stop2 < TS2[period-1] then
																			 
																			 if EMA.DATA[period-1] >  TS2[period-1]  then 
																			 Stop2 = TS2[period-1];
																			 end
																	 end
																	 
																end		
																
																TS2[period]=Stop2;
														end
														
														
														
														
														
											end
									end
							end
					end
			end
end

