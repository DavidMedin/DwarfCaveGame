function send(...)
	local parts = {...}
	local str = ""
	for k,v in pairs(parts) do
		str = str .. v..":"
	end
	client:send(str.."\n")
end

--takes message like (messageType:x:y:data) and returns messageType,x,y,data. Data can be nil
function parseMessage(message)
	local first = 0
	local firstStop = message:find(":")
	if firstStop == nil then print "this message didn't have any ':' in it"; return message end
	local parts = {}
	repeat
		table.insert(parts,message:sub(first+1,firstStop-1))
		first = firstStop
		firstStop = message:find(":",firstStop+1)
	until(firstStop==nil)
	table.insert(parts,message:sub(first+1,#message))
	return unpack(parts)
	--local firstNum = tonumber(message:sub(0,first-1))
	--local last = message:find(":",first+1)
	--local lastNum = tonumber(message:sub(first+1,last-1))
	--if #message == last then
	--	return mesa
	--else
	--return firstNum,lastNum,message:sub(last+1,#message)
	--end
end
print(parseMessage "1:hello:2:datadatadata")
