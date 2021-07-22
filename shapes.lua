--takes a table of strings and returns a table where those strings are keys and have incrementing values. So an Enum.
function Enum(tabl)
	local newTab = {}
	local incre = 1
	for k,v in pairs(tabl)
		newTab[v] = incre
		incre = incre + 1
	end
	return newTab
end
cmds = Enum {
	"circle",--x,y,radius
	"clear",--x,y In chunks
	"clientLoadRequest",--x,y in chunks
}


local function vec2(x,y)
	return setmetatable({x=x,y=y},{__add=function(lh,rh) return vec2(lh.x+rh.x,lh.y+rh.y) end})
end
local function distance(pos1,pos2)
	return math.sqrt(((pos1.x-pos2.x)^2)+(pos1.y-pos2.y)^2)
end
local function circleDist(pointPos,circlePos,radius)
	return distance(pointPos,circlePos)-radius
end
