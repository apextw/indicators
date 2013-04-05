-- The indicator corresponds to the Relative Strength Index indicator in MetaTrader.
-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 6 "Momentum and Oscillators" (page 133-134)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name("AccumRSI");
    indicator:description("Accumulated RSI");
    indicator:requiredSource(core.Tick);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Classic Oscillators");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", "Number of periods", "Number of periods", 14, 2, 1000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrRSI", "Line color", "Line color", core.rgb(255, 0, 0));
    
    indicator.parameters:addGroup("Levels");
    -- Overbought/oversold level
    indicator.parameters:addInteger("overbought", "Over bought level", "Over bought level", 70, 0, 100);
    indicator.parameters:addInteger("oversold", "Over sold level", "Over sold level", 30, 0, 100);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local n;

local first;
local source = nil;

-- Streams block
local RSI = nil;
local ARSI = nil;

-- Routine
function Prepare()

    n = instance.parameters.N;
    source = instance.source;
    first = source:first() + n + 1;

    local name = profile:id() .. "(" .. source:name() .. ", " .. n .. ")";
    instance:name(name);

	RSI = core.indicators:create("RSI", source, N);
    ARSI = instance:addStream("ARSI", core.Line, name, "ARSI", instance.parameters.clrRSI, first);
    ARSI:setPrecision(2);
    
    ARSI:addLevel(instance.parameters.oversold);
    ARSI:addLevel(50);
    ARSI:addLevel(instance.parameters.overbought);
end

-- Indicator calculation routine
function Update(period, mode)
	RSI:update(mode);
    if period >= first then
        ARSI[period] = (RSI.DATA[period - 1] + RSI.DATA[period]) / 2;
    end
end