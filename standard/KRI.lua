-- There is no formula into Kaufman book and no analog in MetaTrader.
-- http://www.bull-n-bear.ru/technic/?t_analysis=kri
-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Oscillators");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", resources:get("R_number_of_periods_name"), resources:get("R_number_of_periods_desciption"), 14, 2, 1000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrKRI", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_KRI_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_KRI_line_name")), core.rgb(255, 255, 0));
    indicator.parameters:addInteger("widthKRI", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_KRI_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_KRI_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleKRI", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_KRI_line_name")), 
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_KRI_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleKRI", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local n;

local first;
local source = nil;

-- Streams block
local KRI = nil;

-- Routine
function Prepare()
    n = instance.parameters.N;
    source = instance.source;
    first = source:first() + n + 1;

    local name = profile:id() .. "(" .. source:name() .. ", " .. n .. ")";
    instance:name(name);
    KRI = instance:addStream("KRI", core.Line, name, "KRI", instance.parameters.clrKRI, first)
    KRI:setWidth(instance.parameters.widthKRI);
    KRI:setStyle(instance.parameters.styleKRI);
    local precision = math.max(2, source:getPrecision());
    KRI:setPrecision(precision);
end

-- Indicator calculation routine
function Update(period, mode)
    if period >= first then
        local mvaValue = mathex.avg(source.close,  period - n + 1, period);
        KRI[period] = 100 * (source.close[period] - mvaValue) / mvaValue;
    end
end




