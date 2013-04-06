-- The indicator corresponds to the Parabolic indicator in MetaTrader.
-- The formula is described in the Kaufman "Trading Systems and Methods" chapter 5 "Trend Systems" (page 98-99)

-- Indicator profile initialization routine
-- Defines indicator profile properties and indicator parameters
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);
    indicator:setTag("group", "Trend");

    indicator.parameters:addGroup("Calculation");
	indicator.parameters:addDouble("Step", resources:get("param_Step_name"), resources:get("param_Step_description"), 0.02, 0.001, 1);
    indicator.parameters:addDouble("Max", resources:get("param_Max_name"), resources:get("param_Max_description"), 0.2, 0.001, 10);
    
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrUp", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_UP_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_UP_line_desc")), core.rgb(255, 0, 0));
    indicator.parameters:addInteger("widthUP", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_UP_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_UP_line_desc")), 1, 1, 5);
    
    indicator.parameters:addColor("clrDown", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_DOWN_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_DOWN_line_desc")), core.rgb(0, 255, 0));
    indicator.parameters:addInteger("widthDOWN", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_DOWN_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_DOWN_line_desc")), 1, 1, 5);
end

-- Indicator instance initialization routine
-- Processes indicator parameters and creates output streams
-- Parameters block

local first;
local source = nil;
local tradeHigh = nil;
local tradeLow = nil;
local parOp = nil;
local position = nil;
local af = nil;
local Step;
local Max;

-- Streams block
local SAR = nil;
local UP = nil;
local DOWN = nil;

-- Routine
function Prepare()
    source = instance.source;
    first = source:first() + 1;

    Step = instance.parameters.Step;
    Max = instance.parameters.Max;

    local name = profile:id() .. "(" .. source:name() .. "," .. Step .. "," .. Max .. ")";
    instance:name(name);

    
    tradeHigh = instance:addInternalStream(0, 0);
    tradeLow = instance:addInternalStream(0, 0);
    parOp = instance:addInternalStream(0, 0);
    position = instance:addInternalStream(0, 0);
    af = instance:addInternalStream(0, 0);
    SAR = instance:addInternalStream(first, 0);
    UP = instance:addStream("UP", core.Dot, name .. ".Up", "UP", instance.parameters.clrUp, first)
    UP:setWidth(instance.parameters.widthUP);
    DOWN = instance:addStream("DN", core.Dot, name .. ".Dn", "DN", instance.parameters.clrDown, first)
    DOWN:setWidth(instance.parameters.widthDOWN);
end

-- Indicator calculation routine
function Update(period)
    local init = Step;
    local quant = Step;
    local maxVal = Max;
    local lastHighest = 0;
    local lastLowest = 0;
    local high = 0;
    local low = 0;
    local prevHigh = 0;
    local prevLow = 0;
    if period >= first then
        high = source.high[period];
        low = source.low[period];
        prevHigh = source.high[period - 1];
        prevLow = source.low[period - 1];
        if (period == first) then
            tradeHigh[period] = prevHigh;
            tradeLow[period] = prevLow;
            position[period] = -1;
            parOp[period] = prevHigh;
            af[period] = 0;
        else
            parOp[period] = parOp[period - 1];
            position[period] = position[period - 1];
            tradeHigh[period] = tradeHigh[period - 1];
            tradeLow[period] = tradeLow[period - 1];
            af[period] = af[period - 1];
        end
        lastHighest = tradeHigh[period];
        lastLowest = tradeLow[period];
        if high > lastHighest then
            tradeHigh[period] = high;
        end
        if low < lastLowest then
            tradeLow[period] = low;
        end
        if position[period] == 1 then
            if (low < parOp[period]) then
                position[period] = -1;
                SAR[period] = lastHighest;
                tradeHigh[period] = high;
                tradeLow[period] = low;
                af[period] = init;
                parOp[period] = SAR[period] + af[period] * (tradeLow[period] - SAR[period]);
                if (parOp[period] < high) then
                    parOp[period] = high;
                end
                if (parOp[period] < prevHigh) then
                    parOp[period] = prevHigh;
                end
            else
                SAR[period] = parOp[period];
                if (tradeHigh[period] > tradeHigh[period - 1] and af[period] < maxVal) then
                    af[period] = af[period] + quant;
                    if af[period] > maxVal then
                        af[period] = maxVal;
                    end
                end

                parOp[period] = SAR[period] + af[period] * (tradeHigh[period] - SAR[period]);
                if (parOp[period] > low) then
                    parOp[period] = low;
                end
                if (parOp[period] > prevLow) then
                    parOp[period] = prevLow;
                end
            end
        else
            if (high > parOp[period]) then
                position[period] = 1;
                SAR[period] = lastLowest;
                tradeHigh[period] = high;
                tradeLow[period] = low;
                af[period] = init;
                parOp[period] = SAR[period] + af[period] * (tradeHigh[period] - SAR[period]);
                if (parOp[period] > low) then
                    parOp[period] = low;
                end
                if (parOp[period] > prevLow) then
                    parOp[period] = prevLow;
                end
            else
                SAR[period] = parOp[period];
                if (tradeLow[period] < tradeLow[period - 1] and af[period] < maxVal) then
                    af[period] = af[period] + quant;
                    if af[period] > maxVal then
                        af[period] = maxVal;
                    end
                end

                parOp[period] = SAR[period] + af[period] * (tradeLow[period] - SAR[period]);
                if (parOp[period] < high) then
                    parOp[period] = high;
                end
                if (parOp[period] < prevHigh) then
                    parOp[period] = prevHigh;
                end
            end
        end

        if position[period] == 1 then
            DOWN[period] = SAR[period];
        else
            UP[period] = SAR[period];
        end
    end
end



