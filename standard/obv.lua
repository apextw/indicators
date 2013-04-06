function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Volume Indicators");

    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrV", resources:get("R_line_color_name"),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_V_line_name")), core.rgb(65, 105, 225));
    indicator.parameters:addInteger("widthV", resources:get("R_line_width_name"),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_V_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleV", resources:get("R_line_style_name"),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_V_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleV", core.FLAG_LEVEL_STYLE);
end

local close;
local volume;
local first;
local V;

function Prepare()

    assert(instance.source:supportsVolume(), resources:get("assert_hasVolume"));

    close = instance.source.close;
    volume = instance.source.volume;
    first = instance.source:first();


    local name;
    name = profile:id() .. "(" .. instance.source:name() .. ")";
    instance:name(name);

    V = instance:addStream("OBV", core.Line, name, "OBV", instance.parameters.clrV, first);
    V:setWidth(instance.parameters.widthV);
    V:setStyle(instance.parameters.styleV);
    V:setPrecision(0);
end

function Update(period, mode)
    if period == first then
        V[period] = volume[period];
    elseif period > first then
        if close[period] > close[period - 1] then
            V[period] = V[period - 1] + volume[period];
        elseif close[period] < close[period - 1] then
            V[period] = V[period - 1] - volume[period];
        else
            V[period] = V[period - 1];
        end
    end
end

