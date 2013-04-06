function Init()
    indicator:name(resources:get("name"));
    indicator:description(resources:get("description"));
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);
    indicator:setTag("group", "Bill Williams");

    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("FM", resources:get("param_FM_name"), resources:get("param_FM_description"), 5, 2, 10000);
    indicator.parameters:addInteger("SM", resources:get("param_SM_name"), resources:get("param_SM_description"), 35, 2, 10000);
    indicator.parameters:addInteger("M", resources:get("param_M_name"), resources:get("param_M_description"), 5, 2, 10000);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("GO_color", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_GO_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_GO_desc")), core.rgb(0, 255, 0));
    indicator.parameters:addColor("RO_color", string.format(resources:get("R_color_of_PARAM_name"), resources:get("param_RO_name")),
        string.format(resources:get("R_color_of_PARAM_description"), resources:get("param_RO_desc")), core.rgb(255, 0, 0));
end

local FM;
local SM;
local M;

local first;
local source = nil;

-- Streams block
local CL = nil;
local GO = nil;
local RO = nil;

local AO = nil;
local MVA = nil;

function Prepare()
    FM = instance.parameters.FM;
    SM = instance.parameters.SM;
    M = instance.parameters.M;

    source = instance.source;

    AO = core.indicators:create("AO", source, FM, SM);
    MVA = core.indicators:create("MVA", AO.DATA, M);
    first = MVA.DATA:first();

    local name = profile:id() .. "(" .. source:name() .. ", " .. FM .. ", " .. SM .. ", " .. M .. ")";
    instance:name(name);
    CL = instance:addStream("AC", core.Bar, name .. ".AC", "AC", instance.parameters.GO_color, first);
    CL:addLevel(0);
    GO = instance.parameters.GO_color;
    RO = instance.parameters.RO_color;
end

function Update(period, mode)
    AO:update(mode);
    MVA:update(mode);

    if (period >= first) then
        CL[period] = AO.DATA[period] - MVA.DATA[period];
    end
    
    if (period >= first + 1) then
        local curr, prev;
        curr = CL[period];
        prev = CL[period - 1];
        if (curr > prev) then
            CL:setColor(period, GO);
        elseif (curr < prev) then
            CL:setColor(period, RO);
        else
            CL:setColor(period, CL:colorI(period - 1));
        end
    end
end

