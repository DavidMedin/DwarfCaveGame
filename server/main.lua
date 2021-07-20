love=love
local chunks = {}


local socket = require "socket"
local server = assert(socket.bind("*",20))
print "started up"
local client = server:accept()
print "found connection"
while true do
	local data,err = client:receive()
	if err then break; end
	local first = data:find(":")
	local firstNum = tonumber(data:sub(0,first-1))
	local last = data:find(":",first+1)
	local lastNum = tonumber(data:sub(first+1,last-1))
	if #data == last then
		--client requested data
		if chunks[firstNum] == nil or chunks[firstNum][lastNum] == nil then
			client:send("#\n")
		else
			client:send(chunks[firstNum][lastNum].."\n")
		end
	else
		--client wants to update us, I guess
		if chunks[firstNum] == nil then chunks[firstNum] = {} end
		chunks[firstNum][lastNum] = data:sub(last+1,#data)
	end

end

function Serialize()
	local file = io.open("map.cave","w")
	
	local currentChar = 0
	for x,q in pairs(chunks) do
		
		for y,w in pairs(q) do
			
		end
	end
	file:write(data)

	file:close()
end

print "done"
love.event.quit()
