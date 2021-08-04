love=love
require "networking"
require "shapes"
local chunks = {}
local connections = {}
local socket = require "socket"
local server = assert(socket.bind("*",20))
local chunkSize = 100
--test = love.image.newImageData(100,100,"r8")

server:settimeout(0)
print "started up"
while true do
	local client,err = server:accept()
	if client == nil and err ~= "timeout" then
		--do weird error
		print(err)
	elseif client ~= nil then
		table.insert(connections,client)
		client:settimeout(0)
		print "found connection"
	end
	--try to recieve
	for k,v in pairs(connections) do
		local data,err = v:receive("*l")
		if err then goto continue end
		local parts = {ParseMessage(data)}
		local messageType = tonumber(parts[1])
		if messageType == cmds.circle then
			for q,w in pairs(parts) do parts[q] = tonumber(w) end
			for x,q in pairs(chunks) do
				for y,r in pairs(q) do
					applyShapes(parts[2],parts[3],x,y,r,chunkSize,parts[4],circleDist,parts[5])
				end
			end
			for r,t in pairs(connections) do
				if t ~= v then
					--update the others as well
					t:send(data.."\n")
				end
			end
		elseif messageType == cmds.clientLoadRequest then
			--the client wants a chunk
			for q,w in pairs(parts) do parts[q] = tonumber(w) end
			if chunks[parts[2]] == nil then chunks[parts[2]] = {} end
			if chunks[parts[2]][parts[3]] == nil then
				--create new chunk
				chunks[parts[2]][parts[3]] = love.image.newImageData(chunkSize,chunkSize,"r8")
				chunks[parts[2]][parts[3]]:mapPixel(function(x,y,r,g,b,a) return 3/255,3/255,3/255,1 end)
			end
			v:send(chunks[parts[2]][parts[3]]:getString().."\n")
		end
		::continue::
	end
	--print "done with clients"
end

print "done"
love.event.quit()
