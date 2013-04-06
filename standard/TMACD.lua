-- TMACD
-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 8 "Cycle Analysis" (page 193-194)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Tick);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Oscillators");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("SN", resources:get("param_SN_name"), resources:get("param_SN_description"), 7, 2, 1000);
    indicator.parameters:addInteger("LN", resources:get("param_LN_name"), resources:get("param_LN_description"), 14, 2, 1000);

    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrTMACD", resources:get("R_line_color_name"), 
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_TMACD_line_name")), core.rgb(255, 0, 0));
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local SN;
local LN;


local first;
local source = nil;
local SN = nil;
local LN = nil;

-- Streams block
local TMACD = nil;

-- Routine
function Prepare()
    SN = instance.parameters.SN;
    LN = instance.parameters.LN;
    source = instance.source;

    -- Check parameters
    if (LN <= SN) then
       error("The short TMA period must be smaller than long TMA period");
    end

    -- Create short and long TMAs for the source
    TMAS = core.indicators:create("TMA", source, SN);
    TMAL = core.indicators:create("TMA", source, LN);
    first = source:first() + math.max(TMAS.DATA:first(), TMAL.DATA:first());

    -- Base name of the indicator.
    local name = profile:id() .. "(" .. source:name() .. ", " .. SN .. ", " .. LN .. ")";
    instance:name(name);

    TMACD = instance:addStream("TMACD", core.Bar, name, "TMACD", instance.parameters.clrTMACD, first);
    local precision = math.max(2, source:getPrecision());
    TMACD:setPrecision(precision);
end

-- Indicator calculation routine
function Update(period, mode)
    TMAS:update(mode);
    TMAL:update(mode);
    if period >= first then
        TMACD[period] = TMAS.DATA[period] - TMAL.DATA[period];
    end
end


