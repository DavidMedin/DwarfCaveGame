love=love
require "../networking"
local chunks = {}
local connections = {}
local socket = require "socket"
local server = assert(socket.bind("*",20))

test = love.image.newImageData(100,100,"r8")

server:settimeout(0)
print "started up"
while true do
	local client,err = server:accept()
	if client == nil and err ~= "timeout" then
		--do weird error
		print(err)
	elseif client ~= nil then
		table.insert(connections,client)
		print "found connection"
	end
	--try to recieve
	for k,v in pairs(connections) do
		v:settimeout(1)
		local data,err = v:receive()
		if err then goto continue end
		print(data)
		if #data == last then
			--client requested data
			if chunks[firstNum] == nil or chunks[firstNum][lastNum] == nil then
				v:send("#\n")
			else
				v:send(chunks[firstNum][lastNum].."\n")
			end
		else
			--client wants to update us, I guess
			if chunks[firstNum] == nil then chunks[firstNum] = {} end
			chunks[firstNum][lastNum] = data:sub(last+1,#data)
		end
		::continue::
	end
end

print "done"
love.event.quit()
