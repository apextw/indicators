function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);
    indicator:setTag("group", "Trend");
    indicator:setTag("replaceSource", "t");
end

local source = nil;

local open = nil;
local high = nil;
local low = nil;
local close = nil;

local first = 0;

-- Routine
function Prepare()
    source = instance.source;
    first = source:first() + 1;

    local name = profile:id() .. "(" .. source:name() .. ")";

    instance:name(name);
    open = instance:addStream("open", core.Line, name .. ".open", "open", core.rgb(0, 0, 0), first)
    high = instance:addStream("high", core.Line, name .. ".high", "high", core.rgb(0, 0, 0), first)
    low = instance:addStream("low", core.Line, name, "low" .. ".low", core.rgb(0, 0, 0), first)
    close = instance:addStream("close", core.Line, name .. ".close", "close", core.rgb(0, 0, 0), first)
    instance:createCandleGroup(name, "HA", open, high, low, close);
end

-- Indicator calculation routine
function Update(period, mode)
    if period >= first then
        if (period == first) then
            open[period] = (source.open[period - 1] + source.close[period - 1]) / 2;
        else
            open[period] = (open[period - 1] + close[period - 1]) / 2;
        end
        close[period] = (source.open[period] + source.high[period] + source.low[period] + source.close[period]) / 4;
        high[period] = math.max(open[period], close[period], source.high[period]);
        low[period] = math.min(open[period], close[period], source.low[period]);
    end
end



