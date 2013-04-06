-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 17 "Adaptive Techniques" (page 441)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);
    indicator:setTag("group", "Trend");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", resources:get("R_number_of_periods_name"), resources:get("R_number_of_periods_desciption"), 14, 2, 1000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrMD", resources:get("R_line_color_name"),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_MD_line_name")), core.rgb(0, 255, 255));
    indicator.parameters:addInteger("widthMD", resources:get("R_line_width_name"),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_MD_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleMD", resources:get("R_line_style_name"),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_MD_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleMD", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local n;

local first;
local source = nil;

-- Streams block
local MD = nil;

-- Routine
function Prepare()
    n = instance.parameters.N;
    source = instance.source;
    first = source:first() + 1;

    local name = profile:id() .. "(" .. source:name() .. ", " .. n .. ")";
    instance:name(name);
    MD = instance:addStream("MD", core.Line, name, "MD", instance.parameters.clrMD, first)
    MD:setWidth(instance.parameters.widthMD);
    MD:setStyle(instance.parameters.styleMD);
end

-- Indicator calculation routine
function Update(period)
    if period >= first then
	        local value = 0;
        local closePeriod = source.close[period];
        if (period == first) then
            value = closePeriod;
        else
            value = MD[period - 1];
        end
        --MD[period] = value + (closePeriod - value) / (0.6 * n * math.pow((closePeriod / value), 4));
        MD[period] = value + (closePeriod - value) / (0.6 * n * ((closePeriod / value)^4));
    end
end





