-- check for RSI divergence
-- 1 for bullish divergence, -1 for bearish divergence
function Init()
    indicator:name("RSIDivergence");
    indicator:description("RSI Divergence");
    indicator:requiredSource(core.Tick);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Classic Oscillators");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("rsiN", "Number of RSI periods", "Number of RSI periods", 14, 2, 1000);
    indicator.parameters:addInteger("bbN", "Number of BB periods", "Number of BB periods", 20, 2, 1000);
    indicator.parameters:addInteger("bbDiv", "BB Divs", "BB Divs", 2, 1, 10);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("rsid", "Line color", "Line color", core.rgb(255, 0, 0));
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local rsiN;
local bbN;
local bbDiv;

local first;
local source = nil;

-- Streams block
local RSI = nil;
local BB = nil;
local RSID = nil;

-- Routine
function Prepare()

    rsiN = instance.parameters.rsiN;
    bbN = instance.parameters.bbN;
    bbDiv = instance.parameters.bbDiv;
    
    source = instance.source;

    local name = profile:id() .. "(" .. source:name() .. ", " .. rsiN .. ")";
    instance:name(name);

	RSI = core.indicators:create("RSI", source, rsiN);
    BB = core.indicators:create("BB", source, bbN, bbDiv);
    first = math.max(RSI.DATA:first(), BB.DATA:first()) + 1;
    RSID = instance:addStream("RSID", core.Line, name, "RSID", instance.parameters.rsid, first);

    require("RSIDState");
    
    RSID:addLevel(-0.9);
    RSID:addLevel(0);
    RSID:addLevel(0.9);
    
    RSIDState.init(source, RSI, BB);
    --Thisinit(source, RSI, BB);
end

-- Indicator calculation routine
function Update(period, mode)
	RSI:update(mode);
    BB:update(mode);
    RSID[period] = RSIDState.update(period);
    --RSID[period] = Thisupdate(period);
    
end

--

