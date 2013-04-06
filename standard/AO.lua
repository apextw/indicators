function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Bill Williams");

    indicator.parameters:addInteger("FM", resources:get("param_FM_name"), resources:get("param_FM_description"), 5, 2, 10000);
    indicator.parameters:addInteger("SM", resources:get("param_SM_name"), resources:get("param_SM_description"), 35, 2, 10000);
    indicator.parameters:addColor("GO_color", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_GO_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_GO_desc")), core.rgb(0, 255, 0));
    indicator.parameters:addColor("RO_color", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_RO_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_RO_desc")), core.rgb(255, 0, 0));
end

local FM;
local SM;
local SC;

local first;
local source = nil;

-- Streams block
local CL = nil;

local FMVA = nil;
local SMVA = nil;
local GO, RO;

function Prepare()
    FM = instance.parameters.FM;
    SM = instance.parameters.SM;
    SC = instance.parameters.SC;

    assert(FM < SM, resources:get("assert_FMLessSM"));

    source = instance.source;
    first = source:first() + SM;

    -- Create the median stream
    FMVA = core.indicators:create("MVA", source.median, FM);
    SMVA = core.indicators:create("MVA", source.median, SM);

    local name = profile:id() .. "(" .. source:name() .. ", " .. FM .. ", " .. SM .. ")";
    instance:name(name);
    CL = instance:addStream("AO", core.Bar, name .. ".AO", "AO", instance.parameters.GO_color, first);
    CL:addLevel(0);
    GO = instance.parameters.GO_color;
    RO = instance.parameters.RO_color;
end

function Update(period, mode)
    FMVA:update(mode);
    SMVA:update(mode);

    if (period >= first) then
        CL[period] = FMVA.DATA[period] - SMVA.DATA[period];
    end

    if (period >= first + 1) then
        if (CL[period] > CL[period - 1]) then
            CL:setColor(period, GO);
        elseif (CL[period] < CL[period - 1]) then
            CL:setColor(period, RO);
        else
            CL:setColor(period, CL:colorI(period - 1));
        end
    end
end

