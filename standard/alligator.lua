-- initializes the indicator
function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"))
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);
    indicator:setTag("group", "Bill Williams");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("JawN", resources:get("param_JawN_name"), resources:get("param_JawN_description"), 13);
    indicator.parameters:addInteger("JawS", resources:get("param_JawS_name"), resources:get("param_JawS_description"), 8);

    indicator.parameters:addInteger("TeethN", resources:get("param_TeethN_name"), resources:get("param_TeethN_description"), 8);
    indicator.parameters:addInteger("TeethS", resources:get("param_TeethS_name"), resources:get("param_TeethS_description"), 5);

    indicator.parameters:addInteger("LipsN", resources:get("param_LipsN_name"), resources:get("param_LipsN_description"), 5);
    indicator.parameters:addInteger("LipsS", resources:get("param_LipsS_name"), resources:get("param_LipsS_description"), 3);

    indicator.parameters:addString("MTH", resources:get("param_MTH_name"), resources:get("param_MTH_description"), "SMMA");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_MVA"), "", "MVA");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_EMA"), "", "EMA");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_LWMA"), "", "LWMA");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_LSMA"), "", "REGRESSION");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_SMMA"), "", "SMMA");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_Vidya1995"), "", "VIDYA");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_Vidya1992"), "", "VIDYA92");
    indicator.parameters:addStringAlternative("MTH", resources:get("string_alternative_MTH_Wilders"), "", "WMA");

    indicator.parameters:addGroup("Style");

    indicator.parameters:addColor("JawC", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_Jaw_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_Jaw_line_desc")), core.rgb(0, 0, 255));
    indicator.parameters:addInteger("JawW", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_Jaw_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_Jaw_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("JawSt", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_Jaw_line_name")),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_Jaw_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("JawSt", core.FLAG_LEVEL_STYLE);

    indicator.parameters:addColor("TeethC", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_Teeth_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_Teeth_line_desc")), core.rgb(255, 0, 0));
    indicator.parameters:addInteger("TeethW", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_Teeth_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_Teeth_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("TeethSt", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_Teeth_line_name")),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_Teeth_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("TeethSt", core.FLAG_LEVEL_STYLE);

    indicator.parameters:addColor("LipsC", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_Lips_line_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_Lips_line_desc")), core.rgb(0, 255, 0));
    indicator.parameters:addInteger("LipsW", string.format(resources:get("R_width_of_PARAM_name"), resources:get("param_Lips_line_name")),
        string.format(resources:get("R_width_of_PARAM_description"), resources:get("param_Lips_line_desc")), 1, 1, 5);
    indicator.parameters:addInteger("LipsSt", string.format(resources:get("R_style_of_PARAM_name"), resources:get("param_Lips_line_name")),
        string.format(resources:get("R_style_of_PARAM_description"), resources:get("param_Lips_line_desc")), core.LINE_SOLID);
    indicator.parameters:setFlag("LipsSt", core.FLAG_LEVEL_STYLE);
end

-- lines parameters
local JawN, JawS;
local TeethN, TeethS;
local LipsN, LipsC;

-- indicator source
local source;

-- lines
local Jaw, Teeth, Lips;
-- lines sources
local JawSrc, TeethSrc, LipsSrc;

-- process parameters and prepare for calculations
function Prepare()
    assert(core.indicators:findIndicator(instance.parameters.MTH) ~= nil, resources:get("assert_MTHNotNull1") .. instance.parameters.MTH .. resources:get("assert_MTHNotNull2"));

    JawN = instance.parameters.JawN;
    JawS = instance.parameters.JawS;
    TeethN = instance.parameters.TeethN;
    TeethS = instance.parameters.TeethS;
    LipsN = instance.parameters.LipsN;
    LipsS = instance.parameters.LipsS;

    source = instance.source;
    JawSrc = core.indicators:create(instance.parameters.MTH, source.median, JawN, core.rgb(0, 0, 0));
    TeethSrc = core.indicators:create(instance.parameters.MTH, source.median, TeethN, core.rgb(0, 0, 0));
    LipsSrc = core.indicators:create(instance.parameters.MTH, source.median, LipsN, core.rgb(0, 0, 0));

    local name = profile:id() .. "(" .. source:name() .. ", " .. JawN .. "(" .. JawS .. ")," .. TeethN .. "(" .. TeethS .. ")," .. LipsN .. "(" .. LipsS .. "), " .. instance.parameters.MTH .. ")";
    instance:name(name);

    Jaw = instance:addStream("Jaw", core.Line, name .. ".Jaw", "Jaw", instance.parameters.JawC, JawSrc.DATA:first() + JawS, JawS);
    Jaw:setWidth(instance.parameters.JawW);
    Jaw:setStyle(instance.parameters.JawSt);
    Teeth = instance:addStream("Teeth", core.Line, name .. ".Teeth", "Teeth", instance.parameters.TeethC, TeethSrc.DATA:first() + TeethS, TeethS);
    Teeth:setWidth(instance.parameters.TeethW);
    Teeth:setStyle(instance.parameters.TeethSt);
    Lips = instance:addStream("Lips", core.Line, name .. ".Lips", "Lips", instance.parameters.LipsC, LipsSrc.DATA:first() + LipsS, LipsS);
    Lips:setWidth(instance.parameters.LipsW);
    Lips:setStyle(instance.parameters.LipsSt);
end

-- Indicator calculation routine
function Update(period, mode)
    JawSrc:update(mode);
    TeethSrc:update(mode);
    LipsSrc:update(mode);

    if (period + JawS >= 0 and period >= JawSrc.DATA:first()) then
        Jaw[period + JawS] = JawSrc.DATA[period];
    end

    if (period + TeethS >= 0 and period >= TeethSrc.DATA:first()) then
        Teeth[period + TeethS] = TeethSrc.DATA[period];
    end

    if (period + LipsS >= 0 and period >= LipsSrc.DATA:first()) then
        Lips[period + LipsS] = LipsSrc.DATA[period];
    end
end

