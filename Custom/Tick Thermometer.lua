function Init()
    indicator:name("Tick Thermometer");
    indicator:description("");
    indicator:requiredSource(core.Bar);
    indicator:type(core.Indicator);	   
	
	 indicator.parameters:addBoolean("Lock", "Lock", "", false);
	 
	 indicator.parameters:addString("Type", "Lock Type", "", "Frame");
    indicator.parameters:addStringAlternative("Type", "Time Frame", "", "Frame");
    indicator.parameters:addStringAlternative("Type", "Instrument", "", "Instrument");
   
	
	Parameters (1 , "H1");
	Parameters (2 , "H1" );
	Parameters (3 , "H1" );
	Parameters (4 , "H1" );
	Parameters (5 , "H1"  );
	

	
	indicator.parameters:addGroup("Calculation");
    indicator.parameters:addString("Mode", "Mode", "", "L");    
    indicator.parameters:addStringAlternative("Mode", "Live", "", "L");
    indicator.parameters:addStringAlternative("Mode", "End of Turn", "", "E");
	
    indicator.parameters:addGroup("Style");
   indicator.parameters:addInteger("HEIGHT", "Height", "", 200);
    
   	indicator.parameters:addString("Algo", "Absolute/Relative", "", "Absolute");    
    indicator.parameters:addStringAlternative("Algo", "Relative", "", "Relative");
    indicator.parameters:addStringAlternative("Algo", "Absolute", "", "Absolute");
	
    indicator.parameters:addBoolean("V", "Show Values", "", true);
    indicator.parameters:addBoolean("P", "Show Percentages", "", true);
    indicator.parameters:addColor("IN", "Indicator color", "", core.rgb(0, 255, 0));
    indicator.parameters:addColor("NE", "Neutral color", "", core.rgb(0, 0, 0));		
    indicator.parameters:addColor("LABEL", "Label color", "", core.COLOR_LABEL);
     indicator.parameters:addInteger("Size", "Font Size", "", 10, 1, 20);
	
end


function Parameters (id , FRAME , DEFAULT )
    indicator.parameters:addGroup(id ..". DMI Calculation");
	indicator.parameters:addBoolean("ON"..id, "Use This TimeFrame", "", true);
    indicator.parameters:addInteger("N"..id, "Periods", "", 14);
	
	indicator.parameters:addString("INSTRUMENT"..id, "Instrumet", "", "");
    indicator.parameters:setFlag("INSTRUMENT"..id, core.FLAG_INSTRUMENTS );
   
    indicator.parameters:addString("B"..id, "Time frame", "", FRAME);
    indicator.parameters:setFlag("B"..id, core.FLAG_PERIODS);
end

local Algo;
local Lock;
local Type;

local source;

local day_offset, week_offset;
local dummy;
local stream=nil;
local host;
local first;

local INSTRUMENT={};
local Label={};
local FRAME={};
local  FrameLabel={};
local ON={};


local COUNT=0;
local PERIOD={};

local HEIGHT;
local font1, font2;
local fisrt, source;
local IN, NE, LABEL;
--local Placement;
local Size;
local Mode;
local V, P;

local id;

function Prepare()       
    Algo=instance.parameters.Algo;
    Lock=instance.parameters.Lock;
	Type=instance.parameters.Type;
    source = instance.source;
	first= source:first();
    host = core.host;	
	
	stream=nil;
	
	--Placement= instance.parameters.Placement;
    V= instance.parameters.V;
    P= instance.parameters.P;
    Size= instance.parameters.Size; 
    HEIGHT= instance.parameters.HEIGHT;
    IN= instance.parameters.IN;
    NE= instance.parameters.NE;
    LABEL= instance.parameters.LABEL
     Mode= instance.parameters.Mode;
	 
    local name =  profile:id()  ;
	
	local i;
   
	
	for i = 1 , 5 , 1 do    
	
	
	   ON[i]=instance.parameters:getBoolean ("ON"..i)
	   
	   if ON[i] then
				   COUNT= COUNT+1;
				   
				   
				   PERIOD[COUNT]= instance.parameters:getInteger ("N"..i);
				   
					 if instance.parameters:getString ("INSTRUMENT"..i) == "" then
					  INSTRUMENT[COUNT]= source:instrument();
				  else
				  INSTRUMENT[COUNT] = instance.parameters:getString ("INSTRUMENT"..i);
				  end
				
				   if Lock and  Type=="Instrument" then
				   INSTRUMENT[COUNT] = INSTRUMENT[1];
				   else
				   INSTRUMENT[COUNT] = INSTRUMENT[COUNT];
				   end
				   
					if Lock and  Type=="Instrument" and i ~= 1 then
					Label[COUNT]="";		  
					else
					 Label[COUNT]=INSTRUMENT[COUNT];
					end

						
				  
				   FRAME[COUNT]=  instance.parameters:getString ("B"..i);
				  
				  if Lock and  Type=="Frame" then
				  FRAME[COUNT]	= FRAME[1];		   
				  end
				  
				   if Lock and  Type=="Frame" and i ~= 1 then
					FrameLabel[COUNT]="";		  
					else
					 FrameLabel[COUNT]=FRAME[COUNT];
					end 	
				 
	   
	   
	   
	   end
	
	 
	  
   
	end	
	
	instance:name(name);
	
	font1 = core.host:execute("createFont", "Arial", Size, false, false);
	font2= core.host:execute("createFont", "Wingdings", 9, false, false);

	
    day_offset = host:execute("getTradingDayOffset");
    week_offset = host:execute("getTradingWeekOffset"); 	

    dummy = instance:addInternalStream(0, 0);	
end


function Update(period, mode)


 if source:hasData(period) and period >= first then
 
	local i;
	
	if stream == nil then
	stream = {};		
		for i = 1, COUNT , 1 do	 
			stream[i] = registerStream(i, FRAME[i],  PERIOD[i]);
			
		end
	end
	    local min=nil;
		local max=nil;
	 id= 1;

	for i = 1, COUNT, 1  do

				
				if stream[i].volume:hasData(stream[i].volume:size()-1)  and stream[i].volume:hasData(stream[i].volume:size()-2)then					

					if  period == source:size() - 1 then		
                  													
						           
                    
						
                       --Absolute/Relative			
					   
						if Algo == "Relative" then
						min, max = mathex.minmax (stream[i].volume, stream[i].volume:first(), stream[i].volume:size()-1);
						
						 core.host:execute("drawLabel1", id, -75+(-200)*i , core.CR_RIGHT, -50 + 20  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "(".. FRAME[i]..  "," .. Label[i] ..")"  ) ;  
						id = id+1;	
						DRAW( period, max , min , stream[i].volume[stream[i].volume:size()-1], HEIGHT,  i*200 ,  50, "vertical" );			
					   
						end
					
					
					  
                           if Algo == "Absolute" then
								   
								   if min== nil or max == nil then
								   min= stream[i].volume[stream[i].volume:size()-1];
								   max=  stream[i].volume[stream[i].volume:size()-1]
								   end
						       
							     if  min >  stream[i].volume[stream[i].volume:size()-1] then
								 min  =  stream[i].volume[stream[i].volume:size()-1] 
								 end
								 
								 if  max <  stream[i].volume[stream[i].volume:size()-1] then
								 max  =  stream[i].volume[stream[i].volume:size()-1] 
								 end
							   
						   end
																 
							

				end
			end
		
	end
	
	if Algo == "Absolute" then
	
			for i = 1, COUNT, 1  do
			
			
			if stream[i].volume:hasData(stream[i].volume:size()-1)  and stream[i].volume:hasData(stream[i].volume:size()-2)then	
			 core.host:execute("drawLabel1", id, -75+(-200)*i , core.CR_RIGHT, -50 + 20  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "(".. FRAME[i]..  "," .. Label[i] ..")"  ) ;  
						id = id+1;	
			DRAW( period, max , min , stream[i].volume[stream[i].volume:size()-1], HEIGHT,  i*200 ,  50, "vertical" );			
			end
			
			end
	
	end
	 
	  
	end

end

local streams = {}

function getPriceStream(stream, i)
    local s = instance.parameters:getString ("S"..i);
    if s == "open" then
        return stream.open;
    elseif s == "high" then
        return stream.high;
    elseif s == "low" then
        return stream.low;
    elseif s == "close" then
        return stream.close;
    elseif s == "median" then
        return stream.median;
    elseif s == "typical" then
        return stream.typical;
    elseif s == "weighted" then
        return stream.weighted;
    else
        return source.close;
    end
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
	-- the size of the source
    if barSize == source:barSize() and  INSTRUMENT[id]== source:instrument()  then
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
        stream.data = host:execute("getHistory", id, INSTRUMENT[id], barSize, from, to, source:isBid());
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
        p = findDateFast(stream.data, candle, true);
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
    loadFrom = math.floor(from * 86400 - 2 * length * extent + 0.5) / 86400;
    nontrading, nontradingend = core.isnontrading(from, day_offset);
    if nontrading then
        -- if it is non-trading, shift for two days to skip the non-trading periods
        loadFrom = math.floor((loadFrom - 2) * 86400 - 2 * length * extent + 0.5) / 86400;
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


-- find the date in the stream using binary search algo.
function findDateFast(stream, date, precise)
    local datesec = nil;
    local periodsec = nil;
    local min, max, mid;

    datesec = math.floor(date * 86400 + 0.5)

    min = 0;
    max = stream:size() - 1;

    if max < 1 then
        return -1;
    end

    while true do
        mid = math.floor((min + max) / 2);
        periodsec = math.floor(stream:date(mid) * 86400 + 0.5);
        if datesec == periodsec then
            return mid;
        elseif datesec > periodsec then
            min = mid + 1;
        else
            max = mid - 1;
        end
        if min > max then
            if precise then
                return -1;
            else
                return min - 1;
            end
        end
    end
end


function DRAW (period, max, min, value , Height, X, Y, Z)

	if period == source:size()-1 
	and  Mode == "E"
        then	
	period= period-1;
        elseif  Mode == "E" then
        return;        
	end
				


	
	
	if period ~= source:size()-1  
	and Mode == "L"
	then		
	return;	
	end


--local id=1;
local i,j ;
local Range = max-min;
local Percentage=  Range / 100;  
local Value = (value -min ) /  Percentage;   
local Index =  100/Height ;
local Color= IN;


if Z == "horizontal" then

			--	id=0;  
				if V then
					 core.host:execute("drawLabel1", id, -Y -Height  + (Value /Index), core.CR_RIGHT,  -X  - 33 , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  string.format("%." .. 4 .. "f", (value))) ;  
								id = id +1;
								
					   core.host:execute("drawLabel1", id,-Y , core.CR_RIGHT,  -X  - 45  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  string.format("%." .. 4 .. "f", max ));
								id = id +1;
								
				  
				   
				core.host:execute("drawLabel1", id,-Y -Height , core.CR_RIGHT,  -X  - 45  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL, string.format("%." .. 4 .. "f", min)) ;  
								id = id +1;
								
				 


				  core.host:execute("drawLabel1", id, -Y -Height/2, core.CR_RIGHT,  -X  - 45 , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL, string.format("%." .. 4 .. "f", min+(max-min)/2)) ;  
								id = id +1;
								




				  core.host:execute("drawLabel1", id, -Y -(Height/4)*1  , core.CR_RIGHT,  -X  - 45  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,   string.format("%." .. 4 .. "f", (min+((max-min)/4)*3))) ;  
				  id = id +1;



				  core.host:execute("drawLabel1", id, -Y -(Height/4)*3  , core.CR_RIGHT,-X  - 45   , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  string.format("%." .. 4 .. "f", (min+((max-min)/4)*1))) ;  
								id = id +1;
											
								
								
				end				
				if P then	
					
				   core.host:execute("drawLabel1", id, -Y -Height  + ( Value /Index) , core.CR_RIGHT, -X-14 + 23   , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,   string.format("%." .. 2 .. "f", (Value)));
								id = id +1;	  				
							 

					 core.host:execute("drawLabel1", id,-Y , core.CR_RIGHT, -X + 20   , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "100");
								id = id +1;	

					
					 core.host:execute("drawLabel1", id, -Y -(Height/4)*1 , core.CR_RIGHT, -X + 20  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "75");
								id = id +1;
								
								
					core.host:execute("drawLabel1", id, -Y -Height/2 , core.CR_RIGHT,  -X + 20  , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "50");
								id = id +1;			
								
									
					 core.host:execute("drawLabel1", id,  -Y -(Height/4)*3 , core.CR_RIGHT, -X + 20 , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "25");
								id = id +1;	  			
								
					 core.host:execute("drawLabel1", id,   -Y -Height , core.CR_RIGHT, -X + 20 , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,  "0");
								id = id +1;					

					
				end	     

						for i =  1, Height , 10 do
							  Color= IN; 
							  
							  if Index *i >=  Value then
							  Color = NE;		      
							  end		      
						   
					
								  for j  = 1, 25 , 5 do		               
								   
								core.host:execute("drawLabel1", id,-Y - Height + i , core.CR_RIGHT,  -X - j , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font2, Color,  "\108");
								id = id +1;
							  end		
						end
		
	elseif Z == "vertical" then
	
	         	--	id=0;  		  
				if V then
					 core.host:execute("drawLabel1", id, -X  - 30, core.CR_RIGHT, -Y -Value /Index , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  string.format("%." .. 4 .. "f", (value))) ;  
								id = id +1;
								
					   core.host:execute("drawLabel1", id, -X  - 30, core.CR_RIGHT, -Y , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  string.format("%." .. 4 .. "f", min ));
								id = id +1;
								
				  
				   
				core.host:execute("drawLabel1", id, -X  - 30, core.CR_RIGHT, -Y -Height , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL, string.format("%." .. 4 .. "f", max)) ;  
								id = id +1;
								
				 


				  core.host:execute("drawLabel1", id, -X  - 30, core.CR_RIGHT, -Y -Height/2 , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL, string.format("%." .. 4 .. "f", min+(max-min)/2)) ;  
								id = id +1;
								




				  core.host:execute("drawLabel1", id, -X  - 30, core.CR_RIGHT, -Y -(Height/4)*3 , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,   string.format("%." .. 4 .. "f", (min+((max-min)/4)*3))) ;  
				  id = id +1;



				  core.host:execute("drawLabel1", id, -X  - 30, core.CR_RIGHT, -Y -(Height/4)*1 , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  string.format("%." .. 4 .. "f", (min+((max-min)/4)*1))) ;  
								id = id +1;
											
								
								
				end				
				if P then	
					if 	round(Value, 1) ~= 100 and round(Value, 1) ~= 75 and round(Value, 1) ~= 50 and round(Value, 1) ~= 25 and round(Value, 1) ~= 100  then
				   core.host:execute("drawLabel1", id, -X-14 + 20, core.CR_RIGHT, -Y - Value /Index , core.CR_BOTTOM, core.H_Right, core.V_Bottom, font1, LABEL,   string.format("%." .. 2 .. "f", (Value)));
								id = id +1;	  				
					end		 

					 core.host:execute("drawLabel1", id, -X + 20, core.CR_RIGHT, -Y , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  "0");
								id = id +1;	

					
					 core.host:execute("drawLabel1", id, -X + 20, core.CR_RIGHT, -Y -(Height/4)*1 , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  "25");
								id = id +1;
								
								
					core.host:execute("drawLabel1", id, -X + 20, core.CR_RIGHT, -Y -Height/2 , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  "50");
								id = id +1;			
								
									
					 core.host:execute("drawLabel1", id, -X + 20, core.CR_RIGHT, -Y -(Height/4)*3 , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  "75");
								id = id +1;	  			
								
					 core.host:execute("drawLabel1", id, -X + 20, core.CR_RIGHT, -Y -Height , core.CR_BOTTOM, core.H_Left, core.V_Bottom, font1, LABEL,  "100");
								id = id +1;					

					
				end	     

						for i =  1, Height , 10 do
							  Color= NE; 
							  
							  if Index *i <=  Value then
							  Color = IN;		      
							  end		      
						   
					
								  for j  = 1, 25 , 5 do		               
								   
								core.host:execute("drawLabel1", id, -X - j, core.CR_RIGHT, -Y-i, core.CR_BOTTOM, core.H_Left, core.V_Bottom, font2, Color,  "\108");
								id = id +1;
							  end		
						end

    end		

end	

function ReleaseInstance()
  core.host:execute("deleteFont", font1); 
  core.host:execute("deleteFont", font2);    
end

function round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end


