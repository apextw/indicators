function Init()
    indicator:name("DailyFX News");
    indicator:description("The indicator shows chosen dailyfx calendar events")
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);
    indicator.parameters:addGroup("Calculation");
    indicator.parameters:addBoolean("ALL", "All instruments", "Choose true to see all news and false to see the news which are related with the current currency pair only", false);
    indicator.parameters:addString("IMP", "Importance of the new to show", "", "ALL");
    indicator.parameters:addStringAlternative("IMP", "All news", "", "ALL");
    indicator.parameters:addStringAlternative("IMP", "Medium or above", "", "MED");
    indicator.parameters:addStringAlternative("IMP", "High only", "", "HIGH");
    indicator.parameters:addBoolean("REFRESH", "Refresh news automatically", "", false);
    indicator.parameters:addInteger("TIMEOUT", "Refresh news in the specified timeout (in minutes)", "", 5, 5, 60);
    indicator.parameters:addGroup("Style");
    indicator.parameters:addInteger("S", "Font size in points", "", 8, 6, 20);
    indicator.parameters:addColor("clrN", "Negative news color", "", core.rgb(255, 0, 0));
    indicator.parameters:addColor("clrP", "Positive/Neutral news color", "", core.rgb(0, 255, 0));
end

local source;
local newsN;
local newsP;
local http;
local loading;
local loadingWeek;
local loadingYear;
local barSize;
local offset;
local extent;
local instr;
local barSizeInDays;
local ALL;
local IMP;
local DUMMY;
local refresh = false;
local notBefore = 40325;        -- May, 26 2010, the oldest availabe news archive

function Prepare(onlyName)
    local name = profile:id();
    instance:name(name);
    if onlyName then
        return ;
    end

    source = instance.source;
    barSize = source:barSize();
    instr = source:instrument();
    offset = core.host:execute("getTradingDayOffset");
    ALL = instance.parameters.ALL;
    IMP = instance.parameters.IMP;

    -- calculate the size of the candle
    local s, e;
    s, e = core.getcandle(source:barSize(), core.now(), offset);
    s = e - s;  -- length of candle in days
    if s > 1 then
        assert(false, "1-day is the largest chart which can be used to get news");
    end
    barSizeInDays = s;
    -- number of candles to extent for 1 week.
    -- if source:isAlive() then
    if true then
        extent = math.floor(7 / s);
        if extent > 300 then
            extent = 300;
        end
    else
        extent = 0;
    end

    newsN = instance:createTextOutput("N", "N", "Arial", instance.parameters.S, core.H_Center, core.V_Bottom, instance.parameters.clrN, extent);
    newsP = instance:createTextOutput("P", "P", "Arial", instance.parameters.S, core.H_Center, core.V_Top, instance.parameters.clrP, extent);
    loading = false;
    DUMMY = instance:addInternalStream(0, 0);
    http = core.makeHttpLoader();
    core.host:execute("setTimer", 1, 1);
    core.host:execute("addCommand", 2, "Refresh News", "");
    if instance.parameters.REFRESH then
        core.host:execute("setTimer", 3, instance.parameters.TIMEOUT * 60);
    end
end

local gWeekData = {};

function getweek(date)
    -- gets a week for the specified date
    local t = core.dateToTable(date);
    date = math.floor(date) - (t.wday - 1);
    t = core.dateToTable(date);
    return string.format("%02i-%02i-%04i", t.month, t.day, t.year), t.year;
end

--              date    time    TZ      curr    desc    imp     act     fore    prev
local pline = "([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)%c()";
local pdate = "%a%a%a%s(%a%a%a)%s(%d%d?)";
local ptime = "(%d%d?):(%d%d)";

function parseCSV(response, year)
    local pos, date, time, tz, curr, desc, imp, act, fore, prev;
    local month, day, hour, minute, timemod
    local weekData = {};
    local idx = 1;
    pos = 1;
    while true do
        date, time, tz, curr, desc, imp, act, fore, prev, pos = string.match(response, pline, pos);
        if (date == nil) then
            break;
        end

        if IMP == "ALL" or
           (IMP == "MED" and imp == "Medium" or imp == "High") or
           (IMP == "HIGH" and imp == "High") then

            -- process only those news, which are related with the currencies of
            -- the current instrument
            if (string.find(instr, string.upper(curr), 1, true) ~= nil) or ALL then
                month, day = string.match(date, pdate);
                hour, minute = string.match(time, ptime);
                if month ~= nil and hour ~= nil then
                    local ttime = {};
                    local skip = false;
                    if month == "Jan" then
                        ttime.month = 1;
                    elseif month == "Feb" then
                        ttime.month = 2;
                    elseif month == "Feb" then
                        ttime.month = 2;
                    elseif month == "Mar" then
                        ttime.month = 3;
                    elseif month == "Apr" then
                        ttime.month = 4;
                    elseif month == "May" then
                        ttime.month = 5;
                    elseif month == "Jun" then
                        ttime.month = 6;
                    elseif month == "Jul" then
                        ttime.month = 7;
                    elseif month == "Aug" then
                        ttime.month = 8;
                    elseif month == "Sep" then
                        ttime.month = 9;
                    elseif month == "Oct" then
                        ttime.month = 10;
                    elseif month == "Nov" then
                        ttime.month = 11;
                    elseif month == "Dec" then
                        ttime.month = 12;
                    else
                        skip = true;
                    end

                    if not(skip) then
                        ttime.day = tonumber(day);
                        ttime.hour = tonumber(hour);
                        ttime.min = tonumber(minute);
                        ttime.sec = 0;
                    end
                    ttime.year = year;

                    local news = {};
                    news.instrument = curr;
                    news.orgtime = date .. " " .. time;
                    news.gmt_time = core.tableToDate(ttime);
                    news.est_time = core.host:execute("convertTime", 2, 1, news.gmt_time);
                    ttime = core.dateToTable(core.host:execute("convertTime", 2, 4, news.gmt_time));
                    news.sdate = string.format("%02i/%02i %02i:%02i", ttime.month, ttime.day, ttime.hour, ttime.min);
                    -- get new's candle
                    local s, e;
                    s, e = core.getcandle(barSize, news.est_time, offset);
                    local n, e1;
                    news.orgcandles = s;
                    news.orgcandlee = e;
                    -- check whether candle is a nontraing candle
                    n, e1 = core.isnontrading(s, offset);
                    if n then
                        -- put the news to the first after-nontrading candle (2 day after the begin of the
                        -- non-trading period)
                        s, e = core.getcandle(barSize, e1 + 2, offset);
                    end
                    news.candles = s;
                    news.candlee = e;
                    news.subject = desc;
                    local posneg = "";
                    if act ~= "" then
                        posneg = act;
                    elseif fore ~= "" then
                        posneg = fore;
                    end
                    news.neg = (string.find(posneg, "-", 1, true) ~= nil);
                    news.act = act;
                    news.fore = fore;
                    news.imp = imp;
                    weekData[idx] = news;
                    idx = idx + 1;
                end
            end
        end
    end
    weekData.last = idx - 1;
    return weekData;
end

function loadweek(week, year)
    local url;
    url = "/files/Calendar-" .. week .. ".csv";
    http:load("www.dailyfx.com", 80, url, true);
    loading = true;
    core.host:execute("setStatus", "loading " .. week .. "...");
    loadingWeek = week;
    loadingYear = year;
    return ;
end

function ProcessCandle(period, date)
    local week, weekData, year;
    week, year = getweek(date);
    if gWeekData[week] == nil then
        if date >= notBefore then
            if not(loading) then
                loadweek(week, year);
                DUMMY:setBookmark(1, period);
            end
            return ;
        else
            gWeekData[week] = {};
            weekData = gWeekData[week];
            weekData.last = 0;
        end
    else
        weekData = gWeekData[week];
    end

    if weekData ~= nil then
        local msgp = "";
        local cntp = 0;
        local msgn = "";
        local cntn = 0;
        for i = 1, weekData.last, 1 do
            local data = weekData[i];
            if (data.candles <= date and
                data.candlee > date) or
               (data.orgcandles <= date and
                data.orgcandlee > date)  then
                if data.neg then
                    if cntn > 0 then
                        msgn = msgn .. "\013\010";
                    end
                    msgn = msgn .. data.sdate .. " " .. data.subject .. "(" .. data.imp .. ")";
                    if data.act ~= "" then
                        msgn = msgn .. " Act=" .. data.act;
                    end
                    if data.fore ~= "" then
                        msgn = msgn .. " For=" .. data.fore;
                    end
                    cntn = cntn + 1;
                else
                    if cntp > 0 then
                        msgp = msgp .. "\013\010";
                    end
                    msgp = msgp .. data.sdate .. " " .. data.subject .. "(" .. data.imp .. ")";
                    if data.act ~= "" then
                        msgp = msgp .. " Act=" .. data.act;
                    end
                    if data.fore ~= "" then
                        msgp = msgp .. " For=" .. data.fore;
                    end
                    cntp = cntp + 1;
                end
            end
        end
        local pperiod;
        if period >= source:size() then
            pperiod = source:size() - 1;
        else
            pperiod = period;
        end
        if (cntn > 0) then
            newsN:set(period, source.low[pperiod], "(" .. cntn .. ")", msgn);
        end
        if (cntp > 0) then
            newsP:set(period, source.high[pperiod], "(" .. cntp .. ")", msgp);
        end
    end
end

function Update(period, mode)
    if not(source:hasData(period)) then
        return ;
    end
    ProcessCandle(period, source:date(period));

    if extent > 0 and period == source:size() - 1 then
        local i, ccandle;

        ccandle = source:date(period);
        for i = 1, extent - 1, 1 do
            ccandle = ccandle + barSizeInDays;
            ProcessCandle(period + i, ccandle);
        end
    end
end

function AsyncOperationFinished(cookie, success, message)
    if cookie == 1 then
        if loading then
            if not(http:loading()) then
                if http:successful() then
                    gWeekData[loadingWeek] = parseCSV(http:response(), loadingYear);
                else
                    gWeekData[loadingWeek] = nil;
                end
                loading = false;
                core.host:execute("setStatus", "");
                instance:updateFrom(math.max(0, DUMMY:getBookmark(1)));
                return core.ASYNC_REDRAW;
            end
        end
        return 0;
    elseif cookie == 2 then
        gWeekData = {};
        instance:updateFrom(0);
        return core.ASYNC_REDRAW;
    elseif cookie == 3 then
        if not(refresh) then
            -- skip the first refresh tick
            refresh = true;
            return 0;
        else
            gWeekData = {};
            instance:updateFrom(0);
            return core.ASYNC_REDRAW;
        end
    end
    return 0;
end

function ReleaseInstance()
    if loading then
        while (http:loading()) do
        end
    end
    core.host:execute("killTimer", 1);
    core.host:execute("killTimer", 3);
end
