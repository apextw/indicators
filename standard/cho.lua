function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Volume Indicators");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("FastN", resources:get("param_FastN_name"), resources:get("param_FastN_description"), 3, 1, 1000);
    indicator.parameters:addInteger("SlowN", resources:get("param_SlowN_name"), resources:get("param_SlowN_description"), 10, 1, 1000);
    indicator.parameters:addString("Method", resources:get("param_Method_name"), resources:get("param_Method_description"), "MVA");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_MVA"), "", "MVA");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_EMA"), "", "EMA");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_LWMA"), "", "LWMA");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_LSMA"), "", "REGRESSION");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_SMMA"), "", "SMMA");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_Vidya1995"), "", "VIDYA");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_Vidya1992"), "", "VIDYA92");
    indicator.parameters:addStringAlternative("Method", resources:get("string_alternative_Method_Wilders"), "", "WMA");
    indicator.parameters:addString("ADMethod", resources:get("param_ADMethod_name"), resources:get("param_ADMethod_description"), "CI");
    indicator.parameters:addStringAlternative("ADMethod", resources:get("string_alternative_ADMethod_Classic"), "", "CS");
    indicator.parameters:addStringAlternative("ADMethod", resources:get("string_alternative_ADMethod_ClassicIncremental"), "", "CI");
    indicator.parameters:addStringAlternative("ADMethod", resources:get("string_alternative_ADMethod_TradeStation"), "", "TS");

    indicator.parameters:addGroup("Style");
    indicator.parameters:addString("Display", resources:get("param_Display_name"), resources:get("param_Display_description"), "L");
    indicator.parameters:addStringAlternative("Display", resources:get("string_alternative_Display_Line"), "", "L");
    indicator.parameters:addStringAlternative("Display", resources:get("string_alternative_Display_Histogram"), "", "H");

    indicator.parameters:addColor("clrCHO", resources:get("R_line_color_name"),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_CHO_line_desc")), core.rgb(128, 128, 128));
    indicator.parameters:addInteger("widthCHO", resources:get("R_line_width_name"),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_CHO_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("styleCHO", resources:get("R_line_style_name"), 
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_CHO_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("styleCHO", core.FLAG_LEVEL_STYLE);
    indicator.parameters:addColor("clrHU", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_HU_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_HU_line_desc")), core.rgb(0, 255, 0));
    indicator.parameters:addColor("clrHD", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_HD_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_HD_line_desc")), core.rgb(255, 0, 0));
end

local first;
local AD;
local FMA, SMA;
local line;
local CHO;
local U, D;

function Prepare()
    source = instance.source;

    assert(source:supportsVolume(), resources:get("assert_hasVolume"));

    assert(core.indicators:findIndicator(instance.parameters.Method) ~= nil, resources:get("assert_indicatorInstalled"));

    local name;
    name = profile:id() .. "(" .. source:name() .. "," .. instance.parameters.Method .. "," .. instance.parameters.FastN .. "," .. instance.parameters.SlowN;
    name = name .. ",A/D(" .. instance.parameters.ADMethod .. "))";
    instance:name(name);

    AD = core.indicators:create("AD", source, instance.parameters.ADMethod);
    FMA = core.indicators:create(instance.parameters.Method, AD.DATA, instance.parameters.FastN);
    SMA = core.indicators:create(instance.parameters.Method, AD.DATA, instance.parameters.SlowN);

    first = math.max(FMA.DATA:first(), SMA.DATA:first());
    local mode;
    if instance.parameters.Display == "L" then
        mode = core.Line;
        line = true;
    else
        mode = core.Bar;
        line = false;
    end

    U = instance.parameters.clrHU;
    D = instance.parameters.clrHD;

    CHO = instance:addStream("CHO", mode, name, "CHO", instance.parameters.clrCHO, first);
    CHO:setPrecision(2);
    CHO:setWidth(instance.parameters.widthCHO);
    CHO:setStyle(instance.parameters.styleCHO);
    CHO:addLevel(0);
end

function Update(period, mode)
    AD:update(mode);
    FMA:update(mode);
    SMA:update(mode);

    if period >= first then
        CHO[period] = FMA.DATA[period] - SMA.DATA[period];
        if not(line) then
            if CHO[period] > 0 then
                CHO:setColor(period, U);
            else
                CHO:setColor(period, D);
            end
        end
    end
end
