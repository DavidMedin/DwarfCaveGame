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

--garbo code
function clamp(l,n,r)
	if type(n) == "table" then
		return vec2(clamp(l,n.x,r),clamp(l,n.y,r))
	end
	if n >= l and n <= r then return n end
	if n < l then return l end
	if n > r then return r end
end

function wrap(l,n,r)
	if type(n)=="table" then return vec2(wrap(l,n.x,r),wrap(l,n.y,r)) end
	if n >= l and n <= r then return n end--nothing to do
	--bounds contains both l and r. Their position is dependant on whether n
	-- is less than left.
	--if it is left of left, then bounds is {r,l}, otherwise {l,r}
	local bounds = {n < l and r or l,n < l and l or r}
	return n-bounds[2]+bounds[1]
end

local function vec2_eq(lh,rh)
	return lh.x==rh.x and lh.y==rh.y
end
function vec2(x,y)
	if type(x) == "table" then
		y = x[2]
		x = x[1]
	end
	return setmetatable({x=x,y=y},{
		__add=function(lh,rh) if type(rh) == "number" then
			return vec2(lh.x+rh,lh.y+rh)
		elseif type(rh) == "table" then
			return vec2(lh.x+rh.x,lh.y+rh.y)
		end end,
		__sub=function(lh,rh) if type(rh) == "number" then
			return vec2(lh.x-rh,lh.y-rh)
		elseif type(rh) == "table" then
			return vec2(lh.x-rh.x,lh.y-rh.y)
		end end,
		__div=function(lh,rh) if type(rh) == "number" then
			return vec2(lh.x/rh,lh.y/rh)
		elseif type(rh) == "table" then
			return vec2(lh.x/rh.x,lh.y/rh.y)
		end end,
		__mul=function(lh,rh) if type(rh) == "number" then
			return vec2(lh.x*rh,lh.y*rh)
		elseif type(rh) == "table" then
			return vec2(lh.x*rh.x,lh.y*rh.y)
		end end,
		__eq=vec2_eq,
		__index=function(t,k)
			if k == 1 then
				return t.x
			elseif k==2 then
				return t.y
			
			end
		end
		})
end
function distance(pos1,pos2)
	return math.sqrt(((pos1.x-pos2.x)^2)+(pos1.y-pos2.y)^2)
end
function circleDist(pointPos,circlePos,radius)
	return distance(pointPos,circlePos)-radius
end
function shapeBounding(circleX,circleY,chunkX,chunkY,chunkSize,half,func)
	for pixX=math.max(0,(circleX-(chunkX-1)*chunkSize)-half),math.min(chunkSize-1,circleX-(chunkX-1)*chunkSize+half) do
		for pixY=math.max(0,circleY-(chunkY-1)*chunkSize-half),math.min(chunkSize-1,circleY-(chunkY-1)*chunkSize+half) do
			func(pixX,pixY)
		end
	end
end

function applyShapes(circleX,circleY,chunkX,chunkY,chunk,chunkSize,half,distFunc,selectedMaterial,func)
	--circleX=circleX+1
	--circleY=circleY+1
	shapeBounding(circleX,circleY,chunkX,chunkY,chunkSize,half,function(pixX,pixY)
		--iterate throught the pixels in the image
		local dist = distFunc(vec2(pixX,pixY)+vec2((chunkX-1)*chunkSize,(chunkY-1)*chunkSize),vec2(circleX,circleY),half)
		--chunk:setPixel(pixX,pixY,3/255,0,0)--the Green and Blue components are thrown out because this is a r8 image
		if dist < 0 then
			--this pixel is in the circle
			chunk:setPixel(pixX,pixY,selectedMaterial/255,0,0)--the Green and Blue components are thrown out because this is a r8 image
		end
		--if dist > -1.5 and dist < 0 then
		--	chunk:setPixel(pixX-1,pixY-1,1/255,0,0)
		--end


	end)
	--shapeBounding(circleX,circleY,chunkX,chunkY,chunkSize,half,function(pixX,pixY)
	--	if func then
	--		debugFunc(func,pixX,pixY,chunkX,chunkY)
	--	end
	--end)
end