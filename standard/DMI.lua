-- The indicator corresponds to the ADX indicator in MetaTrader.
-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 23 "Risk Control" (page 609-611)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Trend Strength");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("N", resources:get("R_number_of_periods_name"), resources:get("R_number_of_periods_desciption"), 14, 1, 1000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrDIP", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_DIP_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_DIP_line_desc")), core.rgb(0, 255, 0));
    indicator.parameters:addInteger("widthDIP", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_DIP_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_DIP_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("styleDIP", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_DIP_line_name")),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_DIP_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleDIP", core.FLAG_LEVEL_STYLE);

    indicator.parameters:addColor("clrDIM", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_DIM_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_DIM_line_desc")), core.rgb(255, 0, 0));
    indicator.parameters:addInteger("widthDIM", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_DIM_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_DIM_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("styleDIM", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_DIM_line_name")),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_DIM_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleDIM", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block
local n;

local first;
local source = nil;
local avgPlusDM = nil;
local avgMinusDM = nil;
local tAbs = math.abs;

-- Streams block
local DIP = nil;
local DIM = nil;
local emaDIP = nil;
local emaDIM = nil;
local sfirst;

-- Routine
function Prepare(onlyName)
    n = instance.parameters.N;
    source = instance.source;
    local name = profile:id() .. "(" .. source:name() .. ", " .. n .. ")";
    instance:name(name);
    if onlyName then
        return ;
    end
        

    sfirst = source:first() + 1;

    avgPlusDM = instance:addInternalStream(sfirst, 0);
    avgMinusDM = instance:addInternalStream(sfirst, 0);
    emaDIP = core.indicators:create("EMA", avgPlusDM, n);
    emaDIM = core.indicators:create("EMA", avgMinusDM, n);
    first = math.max(emaDIP.DATA:first(), emaDIM.DATA:first());

    DIP = instance:addStream("DIP", core.Line, name .. ".DIP", "DI+", instance.parameters.clrDIP, first)
    DIP:setWidth(instance.parameters.widthDIP);
    DIP:setStyle(instance.parameters.styleDIP);
    DIP:setPrecision(4);
    DIM = instance:addStream("DIM", core.Line, name .. ".DIM", "DI-", instance.parameters.clrDIM, first)
    DIM:setWidth(instance.parameters.widthDIM);
    DIM:setStyle(instance.parameters.styleDIM);
    DIM:setPrecision(4);
end

function TrueRangeCustom(period)
    local num1 = tAbs(source.high[period] - source.low[period]);
    local num2 = tAbs(source.high[period] - source.close[period - 1]);
    local num3 = tAbs(source.close[period - 1] - source.low[period]);
    return math.max(num1, num2, num3);
end

-- Indicator calculation routine
function Update(period, mode)
    avgPlusDM[period] = 0;
    avgMinusDM[period] = 0;

    if period >= sfirst then
        local upperMove = 0;
        local lowerMove = 0;
        local TR = 0;

        upperMove = source.high[period] - source.high[period - 1];
        lowerMove = source.low[period - 1] - source.low[period];
        if (upperMove < 0) then upperMove = 0 end
        if (lowerMove < 0) then lowerMove = 0 end
        if (upperMove == lowerMove) then
            upperMove = 0;
            lowerMove = 0;
        elseif (upperMove < lowerMove) then
            upperMove = 0;
        elseif (lowerMove < upperMove) then
            lowerMove = 0;
        end

        TR = TrueRangeCustom(period);
        if (TR == 0) then
            avgPlusDM[period] = 0;
            avgMinusDM[period] = 0;
        else
            avgPlusDM[period] = 100 * upperMove / TR;
            avgMinusDM[period] = 100 * lowerMove / TR;
        end
    end

    if period >= first then
        emaDIP:update(mode);
        emaDIM:update(mode);

        DIP[period] = emaDIP.DATA[period];
        DIM[period] = emaDIM.DATA[period];
    end
end








