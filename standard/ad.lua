function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Volume Indicators");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addString("Method", resources:get("param_Method_name"), resources:get("param_Method_description"), "CI");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_Classic"), "", "CS");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_ClassicIncremental"), "", "CI");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_TradeStation"), "", "TS");
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrAD", resources:get("R_line_color_name"), 
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_AD_line_name")), core.rgb(255, 83, 83));
    indicator.parameters:addInteger("widthAD", resources:get("R_line_width_name"),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_AD_line_name")), 1, 1, 5);
    indicator.parameters:addInteger("styleAD", resources:get("R_line_style_name"),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_AD_line_name")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleAD", core.FLAG_LEVEL_STYLE);
end

local source;
local o, h, l, c, v;
local first;
local AD;
local Method;

function Prepare()
    source = instance.source;
    o = source.open;
    h = source.high;
    l = source.low;
    c = source.close;
    v = source.volume;
    first = source:first();

    if instance.parameters.Method == "CS" then
        Method = 1;
    elseif instance.parameters.Method == "CI" then
        Method = 2;
    elseif instance.parameters.Method == "TS" then
        Method = 3;
    else
        Method = 2;
    end


    assert(source:supportsVolume(), resources:get("assert_supportsVolume"));

    local name;
    name = profile:id() .. "(" .. source:name() .. "," .. instance.parameters.Method .. ")";
    instance:name(name);

    AD = instance:addStream("AD", core.Line, name, "AD", instance.parameters.clrAD, first);
    AD:setPrecision(2);
    AD:setWidth(instance.parameters.widthAD);
    AD:setStyle(instance.parameters.styleAD);
    AD:addLevel(0);
end

function Update(period, mode)
    if period >= first then
        if Method == 1 or Method == 2 then
            -- classic
            if h[period] - l[period] == 0 then
                AD[period] = 0;
            else
                AD[period] = ((c[period] - l[period]) - (h[period] - c[period])) / (h[period] - l[period]) * v[period];
            end
        else
            -- TS (method == 3)
            AD[period] = (c[period] - o[period]) / (h[period] - l[period]) * v[period];
        end

        if period >= first + 1 and Method == 2 or Method == 3 then
            AD[period] = AD[period] + AD[period - 1];
        end
    end
end
