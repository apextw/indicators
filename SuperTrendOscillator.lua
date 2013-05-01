-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name("SuperTrend Oscillator");
    indicator:description("Super trend oscillator");
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);

	indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", "Number of periods", "No description", 10);
    indicator.parameters:addDouble("M", "Multiplier", "No description", 1.5);
	indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("color", "Color of line", "Color of line", core.rgb(0, 255, 255));
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local N;
local M;

local first;
local source = nil;
local ATR = nil;

-- Streams block
local UP = nil;
local DN = nil;
local TR = nil;

-- Routine
function Prepare()
    N = instance.parameters.N;
    M = instance.parameters.M;
    source = instance.source;
    ATR = core.indicators:create("ATR", source, N);
    first = ATR.DATA:first();
    local name = profile:id() .. "(" .. source:name() .. ", " .. N .. ", " .. M .. ")";
    instance:name(name);
    UP = instance:addInternalStream(first, 0);
    DN = instance:addInternalStream(first, 0);
    TR = instance:addStream("STO", core.Line, name .. ".Super Trend", "Super Trend", instance.parameters.color, first);
end

-- Indicator calculation routine
function Update(period, mode)
    ATR:update(mode);
    TR[period] = 1;
    if period >= first then
        local  change;        
       
        UP[period] = source.median[period] + ATR.DATA[period] * M;
        DN[period] = source.median[period] - ATR.DATA[period] * M;

        if period >= first + 1 then
            change = false;
            if source.close[period] > UP[period - 1] then
                TR[period] = 1;
                if TR[period - 1] == -1 then
                    change = true;
                end
            elseif source.close[period] < DN[period - 1] then
                TR[period] = -1;
                if TR[period - 1] == 1 then
                    change = true;
                end
            else
                TR[period] = TR[period - 1];
            end

            local flag, flagh;

            if TR[period] < 0 and TR[period - 1] > 0 then
               flag = 1;
            else
               flag = 0;
            end

            if TR[period] > 0 and TR[period - 1] < 0 then
               flagh = 1;
            else
               flagh = 0;
            end

            if TR[period] > 0 and DN[period] < DN[period - 1] then
                DN[period] = DN[period - 1];
            end

            if TR[period] < 0 and UP[period] > UP[period - 1] then
                UP[period] = UP[period - 1];
            end

            if flag == 1 then
                UP[period] = source.median[period] + ATR.DATA[period] * M;
            end

            if flagh == 1 then
                DN[period] = source.median[period] - ATR.DATA[period] * M;
            end

        end
    end
end

