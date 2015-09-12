#! /usr/bin/env lua5.3
local socket = require('socket')
local posix = require('posix')

-- The following copyright notice applies only to the CRC32 code

--Copyright (c) 2007-2008 Neil Richardson (nrich@iinet.net.au)
--
--Permission is hereby granted, free of charge, to any person obtaining a copy 
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights 
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
--copies of the Software, and to permit persons to whom the Software is 
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
--IN THE SOFTWARE.

--module('CRC32', package.seeall)

local max = 2^32 -1

local CRC32 = {
    0,79764919,159529838,222504665,319059676,
    398814059,445009330,507990021,638119352,
    583659535,797628118,726387553,890018660,
    835552979,1015980042,944750013,1276238704,
    1221641927,1167319070,1095957929,1595256236,
    1540665371,1452775106,1381403509,1780037320,
    1859660671,1671105958,1733955601,2031960084,
    2111593891,1889500026,1952343757,2552477408,
    2632100695,2443283854,2506133561,2334638140,
    2414271883,2191915858,2254759653,3190512472,
    3135915759,3081330742,3009969537,2905550212,
    2850959411,2762807018,2691435357,3560074640,
    3505614887,3719321342,3648080713,3342211916,
    3287746299,3467911202,3396681109,4063920168,
    4143685023,4223187782,4286162673,3779000052,
    3858754371,3904687514,3967668269,881225847,
    809987520,1023691545,969234094,662832811,
    591600412,771767749,717299826,311336399,
    374308984,453813921,533576470,25881363,
    88864420,134795389,214552010,2023205639,
    2086057648,1897238633,1976864222,1804852699,
    1867694188,1645340341,1724971778,1587496639,
    1516133128,1461550545,1406951526,1302016099,
    1230646740,1142491917,1087903418,2896545431,
    2825181984,2770861561,2716262478,3215044683,
    3143675388,3055782693,3001194130,2326604591,
    2389456536,2200899649,2280525302,2578013683,
    2640855108,2418763421,2498394922,3769900519,
    3832873040,3912640137,3992402750,4088425275,
    4151408268,4197601365,4277358050,3334271071,
    3263032808,3476998961,3422541446,3585640067,
    3514407732,3694837229,3640369242,1762451694,
    1842216281,1619975040,1682949687,2047383090,
    2127137669,1938468188,2001449195,1325665622,
    1271206113,1183200824,1111960463,1543535498,
    1489069629,1434599652,1363369299,622672798,
    568075817,748617968,677256519,907627842,
    853037301,1067152940,995781531,51762726,
    131386257,177728840,240578815,269590778,
    349224269,429104020,491947555,4046411278,
    4126034873,4172115296,4234965207,3794477266,
    3874110821,3953728444,4016571915,3609705398,
    3555108353,3735388376,3664026991,3290680682,
    3236090077,3449943556,3378572211,3174993278,
    3120533705,3032266256,2961025959,2923101090,
    2868635157,2813903052,2742672763,2604032198,
    2683796849,2461293480,2524268063,2284983834,
    2364738477,2175806836,2238787779,1569362073,
    1498123566,1409854455,1355396672,1317987909,
    1246755826,1192025387,1137557660,2072149281,
    2135122070,1912620623,1992383480,1753615357,
    1816598090,1627664531,1707420964,295390185,
    358241886,404320391,483945776,43990325,
    106832002,186451547,266083308,932423249,
    861060070,1041341759,986742920,613929101,
    542559546,756411363,701822548,3316196985,
    3244833742,3425377559,3370778784,3601682597,
    3530312978,3744426955,3689838204,3819031489,
    3881883254,3928223919,4007849240,4037393693,
    4100235434,4180117107,4259748804,2310601993,
    2373574846,2151335527,2231098320,2596047829,
    2659030626,2470359227,2550115596,2947551409,
    2876312838,2788305887,2733848168,3165939309,
    3094707162,3040238851,2985771188,
}

local function xor(a, b)
    local calc = 0    

    for i = 32, 0, -1 do
	local val = 2 ^ i
	local aa = false
	local bb = false

	if a == 0 then
	    calc = calc + b
	    break
	end

	if b == 0 then
	    calc = calc + a
	    break
	end

	if a >= val then
	    aa = true
	    a = a - val
	end

	if b >= val then
	    bb = true
	    b = b - val
	end

	if not (aa and bb) and (aa or bb) then
	    calc = calc + val
	end
    end

    return calc
end

local function lshift(num, left)
    local res = num * (2 ^ left)
    return res % (2 ^ 32)
end

local function rshift(num, right)
    local res = num / (2 ^ right)
    return math.floor(res)
end

function Hash(str)
    local count = string.len(tostring(str))
    local crc = max
    
    local i = 1
    while count > 0 do
	local byte = string.byte(str, i)

	crc = xor(lshift(crc, 8), CRC32[xor(rshift(crc, 24), byte) + 1])

	i = i + 1
	count = count - 1
    end

    return math.floor(crc)
end


--
-- CRC32.lua
--
-- A pure Lua implementation of a CRC32 hashing algorithm. Slower than using a C implemtation,
-- but useful having no other dependancies.
--
--
-- Synopsis
--
-- require('CRC32')
--
-- crchash = CRC32.Hash('a string')
--
-- Methods:
--
-- hashval = CRC32.Hash(val)
--    Calculates and returns (as an integer) the CRC32 hash of the parameter 'val'. 



local trim = function(s)
   return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

local countLines = function(s)
   local _,n = s:gsub(".-\n[^\n]*", "")
   return n
end

local sendFiles = function(s,t)
   s:send("SEND\n")
   local rs,err = s:receive()
   if err then
      return string.format('Error in transmission: %s',err)
   end
   if rs ~= 'OKAY' then
      return string.format('Received %s, expected OKAY',rs)
   end
   local ngets,err = s:receive()
   if err then
      return string.format('Error in transmission: %s',err)
   end
   ngets = tonumber(ngets)
   local rtabs = {}
   local rtab,ps
   for k=1,ngets do
      rtab,err = s:receive()
      if err then
	 return string.format('Error in transmission: %s',err)
      end
      if rtab:find(":") then
	 rtab = rtab:gsub(":","/",1)
	 if posix.stat(rtab) then
	    table.insert(rtabs,rtab)
	 end
      elseif rtab:find("/") then
	 if posix.stat(rtab) then
	    table.insert(rtabs,rtab)
	 end
      else
	 ps = posix.stat(rtab)
	 if ps.type == 'directory' then
	    for l,u in ipairs(posix.glob(rtab .. '/*')) do
	       table.insert(rtabs,tab)
	    end
	 end
      end
   end
   local tabs = {}
   if #t == 0 then
      for k,v in ipairs(posix.glob()) do
	 ps = posix.stat(v)
	 if ps then
	    if ps.type == 'directory' then
	       table.insert(t,v)
	    end
	 end
      end
   end
   local dir
   for k,v in ipairs(t) do
      ps = posix.stat(v)
      if ps then
	 if ps.type == 'directory' then
	    dir = posix.glob(v .. '/*')
	    if dir then
	       for l,u in ipairs(dir) do
		  table.insert(tabs,u)
	       end
	    end
	 else
	    table.insert(tabs,v)
	 end
      end
   end
   if ngets > 0 then
      for k,v in ipairs(rtabs) do
	 rtabs[v] = true
      end
      local ntabs = {}
      for k,v in ipairs(tabs) do
	 if rtabs[v] then
	    table.insert(ntabs,v)
	 end
      end
      tabs = ntabs
   end
   s:send("OKAY\n")
   local project,tab,contents,fh,hash,nlines
   for k,v in ipairs(tabs) do
      io.write(string.format('Considering %s ... ',v))
      fh = io.open(v,'r')
      if fh then
	 contents = fh:read('*all')
	 if contents:sub(-1) ~= "\n" then
	    contents = contents .. "\n"
	 end
	 hash = Hash(trim(contents))
	 project = v:sub(1,v:find('/')-1)
	 tab = v:sub(v:find('/')+1)
	 s:send(project .. "\n")
	 s:send(tab .. "\n")
	 s:send(hash .. "\n")
	 rs,err = s:receive()
	 if err then
	    return string.format('Error in updating %s: %s',v,err)
	 end
	 if rs == 'SEND' then
	    nlines = countLines(contents)
	    s:send(nlines .. "\n")
	    io.write('Sending ... ')
	    s:send(contents)
	    rs,err = s:receive()
	    if err then
	       return string.format('Error in sending %s: %s',v,err)
	    end
	    io.write("Sent.\n")
	 else
	    io.write("Skipped.\n")
	 end
      end
   end
   s:send("FINISH\n")
end

local getFiles = function(s,t,dryrun)
   local project,err,tab,hash,file,fh,ltab,nlines,lne
   s:send("GET\n")
   lne,err = s:receive()
   if err then
      print(string.format("Error in transmission: %s",err))
      return
   end
   s:send(#t .. "\n")
   for k,v in ipairs(t) do
      s:send(v .. "\n")
   end
   lne,err = s:receive()
   if err then
	 print(string.format("Error in transmission: %s",err))
	 return
   end      
   while 1 do
      project, err = s:receive()
      if err then
	 print(string.format("Error in transmission: %s",err))
	 return
      end
      if project == "FINISH" then
	 break
      end
      tab, err = s:receive()
      if err then
	 print(string.format("Error in transmission: %s",err))
	 return
      end
      io.write(string.format("Receiving %s/%s ... ",project,tab))
      hash, err = s:receive()
      if err then
	 print(string.format("Error in transmission: %s",err))
	 return
      end
      if not posix.stat(project) then
	 err = posix.mkdir(project)
	 if err ~= 0 then
	    print(string.format("Error in creating project directory for %s: %s",project,err))
	    return
	 end
      end
      file = string.format("%s/%s",project,tab)
      if posix.stat(file) then
	 fh = io.open(file,'r')
	 ltab = fh:read('*all')
	 if tonumber(hash) == Hash(trim(ltab)) then
	    s:send("SKIP\n")
	    save = false
	 else
	    s:send("SEND\n")
	    save = true
	 end
      else
	 s:send("SEND\n")
	 save = true
      end
      if save then
	 nlines,err = s:receive()
	 if err then
	    print(string.format("Error in transmission: %s",err))
	    return
	 end
	 contents = {}
	 for k=1,nlines do
	    lne,err = s:receive()
	    if err then
	       print(string.format("Error in transmission: %s",err))
	       return
	    end
	    table.insert(contents,lne)
	 end
	 io.write("saving\n")
	 if not dryrun then
	    fh,err = io.open(file,"w")
	    if fh then
	       fh:write(table.concat(contents, "\n") .. "\n")
	    else
	       print(string.format("Error in saving file %s:%s",file,err))
	    end
	 end
	 s:send("OKAY\n")
      else
	 io.write("skipping\n")
      end
   end
end

local doHelp = function()
   print(
      [[
Options:
     -help    Display this message
     -action  Action to take ("get" or "send")
     -ip      IP address of server
     -port    Port for connection
     -dryrun  Dry run

All options can be shortened to their initial letter.
	  
The IP address can include the port number in the usual fashion, eg 10.0.0.3:57482.

The "dryrun" feature means that nothing will actually be saved but this only applies when this program is the receiver.
       ]]
	)
end

local ip
local port
local action = getFiles
local dryrun

local short = "ha:s:i:p:d"

local long = {
   {"help", "none", 'h'},
   {"action", "required", 'a'},
   {"ip", "required", 'i'},
   {"port", "required", 'p'},
   {"dryrun","none",'d'}
}

local last_index = 1
for r, optarg, optind, li in posix.getopt(arg, short, long) do
   if r == '?' then
      return print 'unrecognised option'
   end
   last_index = optind
   if r == 'h' then
      doHelp()
      return
   elseif r == 'a' then
      if optarg == 'send' or optarg == 's' then
	 action = sendFiles
      end
   elseif r == 'i' then
      ip = optarg
   elseif r == 'p' then
      port = optarg
   elseif r == 'd' then
      dryrun = true
   end
end

if not ip then
   return print 'You must specify the remote ip'
end

if not port and ip:find(':') then
   port = ip:sub(ip:find(':')+1)
   ip = ip:sub(1,ip:find(':')-1)
end

if not port and not ip then
   return print 'You must specify the remote ip and port'
end

local tabs = {}
local ps
for i = last_index,#arg do
   table.insert(tabs,arg[i])
end

print 'Establishing connection ...'
local client = socket.connect(ip,port)
if not client then
   return print 'No connection made'
else
   print 'Connected'
end
client:setoption('keepalive',true)

action(client,tabs,dryrun)
