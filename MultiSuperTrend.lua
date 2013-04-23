-- similar to SuperTrend Heat Map, but it sums up multiple superTrend and output either 1, 0, or -1

function AddMvaParam(id, frame, FM, MP )
    indicator.parameters:addString("B" .. id, "Time frame for avegage " .. id, "", frame);
    indicator.parameters:setFlag("B" .. id, core.FLAG_PERIODS);
    indicator.parameters:addInteger("FM" .. id, "Line " .. id .. ". Period", "", FM);
    indicator.parameters:addDouble("MP" .. id, "Line " .. id .. ". Multiplier", "", MP);
end

function Init()
    indicator:name("Multi SuperTrend Indicator");
    indicator:description("Provide a single indicator value from multiple supertrend indicators");
    indicator:requiredSource(core.Bar);
    indicator:type(core.Oscillator);

    indicator.parameters:addInteger("MAX", "Max number of trends to consider", "Max trends", 3, 1, 5);
    
    indicator.parameters:addGroup("1.  Line" );
    AddMvaParam(1, "H4", 10, 1.5);
    indicator.parameters:addGroup("2.  Line" );
    AddMvaParam(2, "H8", 10, 1.5);
    indicator.parameters:addGroup("3. Line" );
    AddMvaParam(3, "D1", 10, 1.5);
    indicator.parameters:addGroup("4.  Line" );
    AddMvaParam(4, "W1",10, 1.5);
    indicator.parameters:addGroup("5.  Line" );
    AddMvaParam(5, "M1", 10, 1.5);
    
    indicator.parameters:addGroup("Style");
    indicator.parameters:addColor("clr", "Line color", "", core.rgb(0, 0, 255));
end

-- list of streams
local streams = {}
-- the indicator source
local source;
local day_offset, week_offset;
local dummy;
local host;
local Indicator = nil;
local PRICE={};

local MAX;
local MST;
local internal;
local first = 0;

function Prepare()

    assert(core.indicators:findIndicator("SUPERTREND") ~= nil, "Please, download and install SUPERTREND.LUA indicator");
    
    source = instance.source;
    host = core.host;

    day_offset = host:execute("getTradingDayOffset");
    week_offset = host:execute("getTradingWeekOffset");

    MAX = instance.parameters.MAX;
    for i = 1, MAX, 1 do
        CheckBarSize(i);
    end

    local i;
    local name = profile:id() .. "(" .. source:name() .. ",";
    for i = 1, MAX, 1 do
        name = name .. "(" .. instance.parameters:getString("B" .. i) .. ")";
    end
    name = name .. ")";
    instance:name(name);
    
    dummy = instance:addStream("D", core.Line, name .. "", "", instance.parameters.clr, 20);
    dummy:addLevel(0.9);
    dummy:addLevel(-0.9);
    
    -- request for data and create MVA's if they do not exist yet.
    if Indicator == nil then
        Indicator = {};
        for i = 1, MAX, 1 do
            PRICE[i] = registerStream(i, instance.parameters:getString("B" .. i), instance.parameters:getInteger("FM" .. i));
            Indicator[i] = core.indicators:create("SUPERTREND", PRICE[i], instance.parameters:getInteger("FM" .. i) , instance.parameters:getDouble("MP" .. i));
            if (Indicator[i].DATA:first() > first) then
                first = Indicator[i].DATA:first() + 1;
            end
        end
    end

    internal = instance:addInternalStream(0, 0);
    MST = instance:addStream("MST", core.Line, name, "MST", instance.parameters.clr, first);
    MST:addLevel(0.9);
    MST:addLevel(-0.9);
end

function CheckBarSize(id)
    local s, e, s1, e1;
    s, e = core.getcandle(source:barSize(), core.now(), 0, 0);
    s1, e1 = core.getcandle(instance.parameters:getString("B" .. id), core.now(), 0, 0);
    assert ((e - s) <= (e1 - s1), "The chosen time frame must be equal to or bigger than the chart time frame!");
end


function Update(period, mode)
    local i, p, loading;

    local upcount = 0;
    local downcount = 0;
    
    for i = 1, MAX, 1 do
        p, loading = getPeriod(i, period);
        if p ~= -1 then
            Indicator[i]:update(mode);
            if Indicator[i].DATA:hasData(p) then 
                if Indicator[i].DATA[p] < PRICE[i].close[p] then
                    upcount = upcount + 1;
                elseif Indicator[i].DATA[p] > PRICE[i].close[p] then
                    downcount = downcount + 1;
                end 
            end            
        end
    end

    if (period > first) then
        if (upcount == MAX) then
            MST[period] = 1;
            internal[period] = 1;
        elseif (downcount == MAX) then
            MST[period] = -1;
            internal[period] = -1;
        else
            -- no decision, keep any previous decision
            -- FIXME - get range bound exit rules here
            internal[period] = internal[period-1];
            MST[period] = internal[period-1];
        end
    end
end

function getPriceStream(stream)
    local s = instance.parameters.S;
    return stream;
end

-- register stream
-- @param barSize       Stream's bar size
-- @param extent        The size of the required exten
-- @return the stream reference
function registerStream(id, barSize, extent)
    local stream = {};
    local s1, e1, length;
    local from, to;

    s1, e1 = core.getcandle(barSize, core.now(), 0, 0);
    length = math.floor((e1 - s1) * 86400 + 0.5);

    -- the size of the source
    if barSize == source:barSize() then
        stream.data = source;
        stream.barSize = barSize;
        stream.external = false;
        stream.length = length;
        stream.loading = false;
        stream.extent = extent;
        stream.loading = false;
    else
        stream.data = nil;
        stream.barSize = barSize;
        stream.external = true;
        stream.length = length;
        stream.loading = false;
        stream.extent = extent;
        local from, dataFrom
        from, dataFrom = getFrom(barSize, length, extent);
        if (source:isAlive()) then
            to = 0;
        else
            t, to = core.getcandle(barSize, source:date(source:size() - 1), day_offset, week_offset);
        end
        stream.loading = true;
        stream.loadingFrom = from;
        stream.dataFrom = dataFrom;
        stream.data = host:execute("getHistory", id, source:instrument(), barSize, from, to, source:isBid());
        setBookmark(0);
    end
    streams[id] = stream;
    return stream.data;
end

function getPeriod(id, period)
    local stream = streams[id];
    assert(stream ~= nil, "Stream is not registered");
    local candle, from, dataFrom, to;
    if stream.external then
        candle = core.getcandle(stream.barSize, source:date(period), day_offset, week_offset);
        if candle < stream.dataFrom then
            setBookmark(period);
            if stream.loading then
                return -1, true;
            end
            from, dataFrom = getFrom(stream.barSize, stream.length, stream.extent);
            stream.loading = true;
            stream.loadingFrom = from;
            stream.dataFrom = dataFrom;
            host:execute("extendHistory", id, stream.data, from, stream.data:date(0));
            return -1, true;
        end

        if (not(source:isAlive()) and candle > stream.data:date(stream.data:size() - 1)) then
            setBookmark(period);
            if stream.loading then
                return -1, true;
            end
            stream.loading = true;
            from = bf_data:date(bf_data:size() - 1);
            to = candle;
            host:execute("extendHistory", id, stream.data, from, to);
        end

        local p;
        p = core.findDate (stream.data, candle, true);
        return p, stream.loading;
    else
        return period;
    end
end

function setBookmark(period)
    local bm;
    bm = dummy:getBookmark(1);
    if bm < 0 then
        bm = period;
    else
        bm = math.min(period, bm);
    end
    dummy:setBookmark(1, bm);

end

-- get the from date for the stream using bar size and extent and taking the non-trading periods
-- into account
function getFrom(barSize, length, extent)
    local from, loadFrom;
    local nontrading, nontradingend;

    from = core.getcandle(barSize, source:date(source:first()), day_offset, week_offset);
    loadFrom = math.floor(from * 86400 - length * extent + 0.5) / 86400;
    nontrading, nontradingend = core.isnontrading(from, day_offset);
    if nontrading then
        -- if it is non-trading, shift for two days to skip the non-trading periods
        loadFrom = math.floor((loadFrom - 2) * 86400 - length * extent + 0.5) / 86400;
    end
    return loadFrom, from;
end

-- the function is called when the async operation is finished
function AsyncOperationFinished(cookie)
    local period;
    local stream = streams[cookie];
    if stream == nil then
        return ;
    end
    stream.loading = false;
    period = dummy:getBookmark(1);
    if (period < 0) then
        period = 0;
    end
    loading = false;
    instance:updateFrom(period);
end