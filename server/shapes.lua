--takes a table of strings and returns a table where those strings are keys and have incrementing values. So an Enum.
function Enum(tabl)
	local newTab = {}
	local incre = 1
	for k,v in pairs(tabl) do
		newTab[v] = incre
		incre = incre + 1
	end
	return newTab
end
cmds = Enum {
	"circle",--x,y,radius,selectedMaterial
	--"clear",--x,y In chunks
	"clientLoadRequest",--x,y in chunks
}


local function vec2(x,y)
	return setmetatable({x=x,y=y},{__add=function(lh,rh) return vec2(lh.x+rh.x,lh.y+rh.y) end})
end
local function distance(pos1,pos2)
	return math.sqrt(((pos1.x-pos2.x)^2)+(pos1.y-pos2.y)^2)
end
function circleDist(pointPos,circlePos,radius)
	return distance(pointPos,circlePos)-radius
end
function shapeBounding(circleX,circleY,chunkX,chunkY,chunkSize,half,func)
	for pixX=math.max(1,(circleX-(chunkX-1)*chunkSize)-half),math.min(chunkSize,circleX-(chunkX-1)*chunkSize+half) do
		for pixY=math.max(1,circleY-(chunkY-1)*chunkSize-half),math.min(chunkSize,circleY-(chunkY-1)*chunkSize+half) do
			func(pixX,pixY)
		end
	end
end

function applyShapes(circleX,circleY,chunkX,chunkY,chunk,chunkSize,half,distFunc,selectedMaterial,edgeList)
	shapeBounding(circleX,circleY,chunkX,chunkY,chunkSize,half,function(pixX,pixY)
		--iterate throught the pixels in the image
		local dist = distFunc(vec2(pixX,pixY)+vec2((chunkX-1)*chunkSize,(chunkY-1)*chunkSize),vec2(circleX,circleY),half)
		if dist <= 0 then
			--this pixel is in the circle
			chunk:setPixel(pixX-1,pixY-1,selectedMaterial/255,0,0)--the Green and Blue components are thrown out because this is a r8 image
		end
	end)
end
