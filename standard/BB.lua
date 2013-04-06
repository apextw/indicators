-- The indicator corresponds to the Bollinger Bands indicator in MetaTrader.
-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 5 "Trend System" (page 91-94)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Tick);
    indicator:type(core.Indicator);
    indicator:setTag("group", "Bollinger");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", resources:get("R_number_of_periods_name"), resources:get("R_number_of_periods_desciption"), 20, 1, 10000);
    indicator.parameters:addDouble("Dev", resources:get("param_Dev_name"), resources:get("param_Dev_description"), 2.0, 0.0001, 1000.0);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrBBP", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_BBB_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_BBB_line_desc")), core.rgb(255, 0, 0));
    indicator.parameters:addInteger("widthBBB", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_BBB_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_BBB_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("styleBBB", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_BBB_line_name")),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_BBB_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleBBB", core.FLAG_LEVEL_STYLE);

    indicator.parameters:addBoolean("HideAve", resources:get("param_HideA_name"), resources:get("param_HideA_description"), false);
    indicator.parameters:addColor("clrBBA", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_BBA_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_BBA_line_desc")), core.rgb(0, 0, 255));
    indicator.parameters:addInteger("widthBBA", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_BBA_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_BBA_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("styleBBA", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_BBA_line_name")), 
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_BBA_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleBBA", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local N;
local D;

local firstPeriod;
local source = nil;

-- Streams block
local TL = nil;
local BL = nil;
local AL = nil;

-- Routine
function Prepare()
    N = instance.parameters.N;
    D = instance.parameters.Dev;
    source = instance.source;
    firstPeriod = source:first() + N - 1;

    local name = profile:id() .. "(" .. source:name() .. ", " .. N .. ", " .. D .. ")";
    instance:name(name);
    TL = instance:addStream("TL", core.Line, name .. ".TL", "TL", instance.parameters.clrBBP, firstPeriod)
    TL:setWidth(instance.parameters.widthBBB);
    TL:setStyle(instance.parameters.styleBBB);
    BL = instance:addStream("BL", core.Line, name .. ".BL", "BL", instance.parameters.clrBBP, firstPeriod)
    BL:setWidth(instance.parameters.widthBBB);
    BL:setStyle(instance.parameters.styleBBB);
    if not instance.parameters.HideAve then
        AL = instance:addStream("AL", core.Line, name .. ".AL", "AL", instance.parameters.clrBBA, firstPeriod)
        AL:setWidth(instance.parameters.widthBBA);
        AL:setStyle(instance.parameters.styleBBA);
    end
end

-- Indicator calculation routine
function Update(period)
    if period >= firstPeriod then
        local ml = mathex.avg(source, period - N + 1, period);
        local d = mathex.stdev(source, period - N + 1, period);
        local Dd = D * d;
        TL[period] = ml + Dd;
        BL[period] = ml - Dd;
        if AL ~= nil then
            AL[period] = ml;
        end
    end
end





