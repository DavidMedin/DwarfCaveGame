playerLocation = vec2(math.floor(loadX*chunkSize/2),math.floor(loadY*chunkSize/2))
playerVelocity = vec2(0,0)
playerSize = vec2(2,2)
function generateArray(tabl,...)
	--this function will generate each part with empty tables if it can
	local indicies = {...}
	local nextThing = tabl
	for k,v in pairs(indicies) do
		if nextThing[v] == nil then
			nextThing[v] = {}
		end
		nextThing = nextThing[v]
	end
end
function Edgy(pixX,pixY,chunkX,chunkY)--this time, the pix' are starting at 0, I think
	--this function is called for every pixel in the effective area of a distance function (like the bounding box of a circle)
	generateArray(chunkEdges,chunkX,chunkY,pixX)
	if chunkEdges[chunkX][chunkY][pixX][pixY] ~= nil then chunkEdges[chunkX][chunkY][pixX][pixY] =nil end
	if chunks[chunkX][chunkY]:getPixel(pixX,pixY) ~= 1/255 then--we don't care if the pixel in question is air
		local dirs = {vec2{1,0},vec2{1,1},vec2{0,1},vec2{-1,1},vec2{-1,0},vec2{-1,-1},vec2{0,-1},vec2{1,-1}}--will do this better with math :)
		for k,v in pairs(dirs) do
			local pixPlace = vec2(pixX,pixY)+v
			--local chunkPlace = Snap((vec2(chunkX,chunkY)-1)*chunkSize+pixPlace-1)
			local chunkPlace = ((vec2(chunkX,chunkY)-1)*chunkSize+pixPlace)/chunkSize+1
			chunkPlace = vec2(math.floor(chunkPlace.x),math.floor(chunkPlace.y))
			if chunks[chunkPlace.x] == nil or chunks[chunkPlace.x][chunkPlace.y] == nil then return end
			pixPlace = wrap(0,pixPlace,99)
			local neighbor = {chunks[chunkPlace.x][chunkPlace.y]:getPixel(pixPlace.x,pixPlace.y)}
			--neighbor should be every neighboring pixel
			if neighbor[1] == 1/255 then
				pixPlace = vec2(pixX,pixY)
				chunkPlace = vec2(chunkX,chunkY)
				--idk just put it in chunkEdges for now
				--this garbo below is to initialize chunkEdges in this pixel
				local indicies = {chunkPlace.x,chunkPlace.y,pixPlace.x}
				local nextThing = chunkEdges
				for k,v in pairs(indicies) do
					if nextThing[v] == nil then
						nextThing[v] = {}
					end
					nextThing = nextThing[v]
				end
				chunkEdges[chunkPlace.x][chunkPlace.y][pixPlace.x][pixPlace.y] = 1
				--chunks[chunkPlace.x][chunkPlace.y]:setPixel(pixPlace.x,pixPlace.y,2/255,0,0)
				--lg.setCanvas(chunkCanvas)
				--lg.setShader(chunkShader)
				--local k = chunkPlace.x
				--local q = chunkPlace.y
				--chunkImages[k][q]:release()
				--chunkImages[k][q] = lg.newImage(chunks[chunkPlace.x][chunkPlace.y])
				--lg.draw(chunkImages[k][q],(k-1)*chunkSize-chunkCanvasPos[1],(q-1)*chunkSize-chunkCanvasPos[2])
				--lg.setCanvas()
				--lg.setShader()
			end
		end
	end
end


function physicsUpdate(dt)
	playerVelocity = playerVelocity+vec2(0,9.8)*dt
	local tmp = playerLocation/chunkSize
	local playerChunk = vec2(math.floor(tmp.x),math.floor(tmp.y))+1
	local localPos = playerVelocity - playerChunk*chunkSize--the position in the chunk
	for x,_ in pairs(chunks) do
		for y,__ in pairs(_) do
			shapeBounding(localPos.x,localPos.y,playerChunk.x,playerChunk.y,chunkSize,10,function(pixX,pixY)
				
			end)
		end
	end
end