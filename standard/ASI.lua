-- http://ta.mql4.com/indicators/trends/accumulation_swing

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Swing");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("T", resources:get("param_T_name"), resources:get("param_T_description"), 300, 2, 1000);

    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrASI", resources:get("R_line_color_name"),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_ASI_line_name")), core.rgb(255, 0, 0));
    indicator.parameters:addInteger("widthASI", resources:get("R_line_width_name"), 
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_ASI_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleASI", resources:get("R_line_style_name"), 
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_ASI_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleASI", core.FLAG_LEVEL_STYLE);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block

local first;
local source = nil;

-- Streams block
local SI = nil;
local ASI=nil;
local T = nil;

-- Routine
function Prepare()

    source = instance.source;
    first = source:first() + 1;

    local name = profile:id() .. "(" .. source:name() .. ")";
    instance:name(name);
    ASI = instance:addStream("ASI", core.Line, name, "ASI", instance.parameters.clrASI, first);
    ASI:setWidth(instance.parameters.widthASI);
    ASI:setStyle(instance.parameters.styleASI);
    local precision = math.max(2, source:getPrecision());
    ASI:setPrecision(precision);
    T = source:pipSize() * instance.parameters.T;
end

-- Indicator calculation routine
function Update(period)
    local open, close, abs;

    if period >= first then
        open = source.open;
        close = source.close;
        abs = math.abs

        local nom = close[period] - close[period - 1]
            + (0.5 * (close[period] - open[period]))
            + (0.25 * (close[period - 1] - open[period - 1]));


        local closePrev = close[period - 1];
        local highCurr = source.high[period];
        local lowCurr = source.low[period];
        local hc = abs(highCurr - closePrev);
        local lc = abs(lowCurr - closePrev);
        local hl = abs(highCurr - lowCurr);
        local co = abs(closePrev - open[period - 1]);

        local TR = math.max(hc, lc, hl);

        local ER = 0;

        if ((closePrev >= lowCurr) and (closePrev <= highCurr)) then
            ER = 0;
        else
            if (closePrev > highCurr) then
                ER = hc;
            elseif (closePrev < lowCurr) then
                ER = lc;
            end
        end

        local SH = co;
        local K = math.max(hc, lc);
        local R = TR - 0.5 * ER + 0.25 * SH;

        if (R == 0) then
            SI = 0;
        else
            SI = 50 * nom * (K / T) / R;
        end
        ASI[period] = ASI[period - 1] + SI;
    end
end



