-- The indicator is based on EWO.
-- The formula of EWO is described in the Kaufman "Trading Systems and Methods" chapter 14 "Behavioral techniques" (page 358-361)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Waves");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("Trigger", resources:get("param_Trigger_name"), resources:get("param_Trigger_description"), 70, 2, 1000);
    indicator.parameters:addInteger("Period", resources:get("R_number_of_periods_name"), resources:get("R_number_of_periods_desciption"), 20, 2, 1000);
    indicator.parameters:addInteger("FastN", resources:get("param_FN_name"), resources:get("param_FN_description"), 5, 2, 1000);
    indicator.parameters:addInteger("SlowN", resources:get("param_SN_name"), resources:get("param_SN_description"), 35, 2, 1000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrEW", resources:get("R_line_color_name"),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_EW_line_name")), core.rgb(0, 255, 255));
    indicator.parameters:addInteger("widthEW", resources:get("R_line_width_name"),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_EW_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleEW", resources:get("R_line_style_name"),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_EW_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleEW", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local Trigger;
local Period;

local first;
local source = nil;
local ewo = nil;

-- Streams block
local EW = nil;

-- Routine
function Prepare()
    Trigger = instance.parameters.Trigger;
    Period = instance.parameters.Period;
    source = instance.source;
    ewo = core.indicators:create("EWO", source, instance.parameters.FastN, instance.parameters.SlowN, "M2", "MVA", "No");
    first = ewo.DATA:first() + Period;
    local name = profile:id() .. "(" .. source:name() .. ", " .. Trigger .. ", " .. Period .. ", " .. instance.parameters.FastN .. ", " .. instance.parameters.SlowN .. ")";
    instance:name(name);
    EW = instance:addStream("EW", core.Line, name, "EW", instance.parameters.clrEW, first)
    EW:setWidth(instance.parameters.widthEW);
    EW:setStyle(instance.parameters.styleEW);
    EW:setPrecision(4);
    EW:addLevel(-1);
    EW:addLevel(0);
    EW:addLevel(1);
end

-- Indicator calculation routine
function Update(period, mode)
    ewo:update(mode);
    EW[period] = 0;
    if period >= first then
        local highest, lowest;
        lowest, highest = mathex.minmax(ewo.DATA,  period - Period + 1, period);
        local last = ewo.DATA[period];
        local trend = EW[period - 1];
        if trend == 0 then
            if last == highest then
                trend = 1;
            end
            if last == lowest then
                trend = -1
            end
        end
        if (lowest < 0 and trend == -1 and last > (-1 * (Trigger / 100) * lowest)) then
            trend = 1;
        end
        if (highest > 0 and trend == 1 and last < (-1 * (Trigger / 100) * highest)) then
            trend = -1;
        end
        EW[period] = trend;
    end
end



