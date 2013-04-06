-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 17 "Adaptive Techniques" (page 436-438)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Tick);
    indicator:type(core.Indicator);
    indicator:setTag("group", "Moving Averages");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", resources:get("R_number_of_periods_name"), resources:get("R_number_of_periods_desciption"), 14, 2, 1000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrKAMA", resources:get("R_line_color_name"),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_KAMA_line_name")), core.rgb(0, 255, 255));
    indicator.parameters:addInteger("widthKAMA", resources:get("R_line_width_name"),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_KAMA_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleKAMA", resources:get("R_line_style_name"),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_KAMA_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleKAMA", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local n;

local first;
local first1;
local source = nil;

-- Streams block
local KAMA = nil;
local INT = nil;

-- Routine
function Prepare()
    n = instance.parameters.N;
    source = instance.source;
    first1 = source:first() + 1;
    first = first1 + n - 1;

    local name = profile:id() .. "(" .. source:name() .. ", " .. n .. ")";
    instance:name(name);
    INT = instance:addInternalStream(first1, 0);
    KAMA = instance:addStream("KAMA", core.Line, name, "KAMA", instance.parameters.clrKAMA, first)
    KAMA:setWidth(instance.parameters.widthKAMA);
    KAMA:setStyle(instance.parameters.styleKAMA);
end

local fastend = 0.666;
local slowend = 0.0645;


-- Indicator calculation routine
function Update(period)
    if period >= first1 then
        INT[period] = math.abs(source[period] - source[period - 1]);
    end
    if period >= first then
        local value = 0;
        if (period == first) then
            value = source[period];
        else
            value = KAMA[period - 1];
        end
        local i = 0;
        local er = 0;
        er = core.sum(INT, period - n + 1, period);
        if er ~= 0 then
            er = math.abs(source[period] - source[period - n + 1]) / er;
        end
        local sc = er * (fastend - slowend) + slowend;
        sc = sc * sc;
        KAMA[period] = value + sc * (source[period] - value);
    end
end





