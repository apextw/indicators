function Init()
    indicator:name("Zero Lag Moving Average");
    indicator:description("Zero Lag Moving Average");
    indicator:requiredSource(core.Tick);
    indicator:type(core.Indicator);
    
    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addInteger("Length", "Length", "Length", 9);
    indicator.parameters:addInteger("Filter", "Filter", "Filter", 0);
    indicator.parameters:addInteger("ColorBarBack", "ColorBarBack", "ColorBarBack", 2);
    indicator.parameters:addDouble("Deviation", "Deviation", "Deviation", 0);

    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clrUP", "UP color", "UP color", core.rgb(0, 0, 255));
    indicator.parameters:addColor("clrDN", "DN color", "DN color", core.rgb(255, 0, 0));
    
    indicator.parameters:addInteger("widthLinReg", "Line width", "Line width", 1, 1, 5);
    indicator.parameters:addInteger("styleLinReg", "Line style", "Line style", core.LINE_SOLID);
    indicator.parameters:setFlag("styleLinReg", core.FLAG_LINE_STYLE);
end

local first;
local source = nil;
local Length;
local Filter;
local ColorBarBack;
local Deviation;
local buffUP=nil;
local buffDN=nil;
local trend;
local buff;
local Coeff;
local Phase;
local Len;

function Prepare()
    source = instance.source;
    Length=instance.parameters.Length;
    Filter=instance.parameters.Filter;
    ColorBarBack=instance.parameters.ColorBarBack;
    Deviation=instance.parameters.Deviation;
    trend = instance:addInternalStream(0, 0);
    buff = instance:addInternalStream(0, 0);
    first = source:first()+2;
    local name = profile:id() .. "(" .. source:name() .. ", " .. instance.parameters.Length .. ", " .. instance.parameters.Filter .. ", " .. instance.parameters.ColorBarBack .. ", " .. instance.parameters.Deviation .. ")";
    instance:name(name);
    buffUp = instance:addStream("buffUp", core.Line, name .. ".Up", "Up", instance.parameters.clrUP, first);
    buffDn = instance:addStream("buffDn", core.Line, name .. ".Dn", "Dn", instance.parameters.clrDN, first);
    buffUp:setWidth(instance.parameters.widthLinReg);
    buffUp:setStyle(instance.parameters.styleLinReg);
    buffDn:setWidth(instance.parameters.widthLinReg);
    buffDn:setStyle(instance.parameters.styleLinReg);
    Coeff=3.*math.pi;
    Phase=Length-1;
    Len=Length*4.+Phase;
end

function Update(period, mode)
    if (period>first+Len+2) then
     local Weight=0;
     local Sum=0;
     local t=0;
     for i=0,Len-1,1 do
      local g=1./(Coeff*t+1.);
      if t<=0.5 then
       g=1.;
      end
      local beta=math.cos(math.pi*t);
      local alpha=g*beta;
      Sum=Sum+alpha*source[period-i];
      Weight=Weight+alpha;
      if t<1. then
       t=t+1./(Phase-1.);
      elseif t<Len-1. then
       t=t+7./(4.*Length-1.);
      end
     end
     if Weight>0. then
      buff[period]=(1.+Deviation/100.)*Sum/Weight;
     end
     if Filter>0. then
      if math.abs(buff[period]-buff[period-1])<Filter*source:pipSize() then
       buff[period]=buff[period-1];
      end
     end
     trend[period]=trend[period-1];
     if buff[period]-buff[period-1]>Filter*source:pipSize() then
      trend[period]=1;
     end
     if buff[period-1]-buff[period]>Filter*source:pipSize() then
      trend[period]=-1;
     end
     if trend[period]>0 then
      buffUp[period]=buff[period];
      if trend[period-ColorBarBack]<0 then
       buffUp[period-ColorBarBack]=buff[period-ColorBarBack];
      end
     end
     if trend[period]<0 then
      buffDn[period]=buff[period];
      if trend[period-ColorBarBack]>0 then
       buffDn[period-ColorBarBack]=buff[period-ColorBarBack];
      end
     end

    end 
end
