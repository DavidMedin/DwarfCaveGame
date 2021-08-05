function debugFunc(func,...)
	local args = {...}
	if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
		require"lldebugger".call(function() func(unpack(args)) end)
	else
		func(unpack(args))
	end
end
local nuklear = require "nuklear"
require "server/networking"
require "server/shapes"
local lg = love.graphics
local lw = love.window
local lp = love.physics
local lf = love.font
local lm = love.mouse

--chunk stuff
lg.setDefaultFilter("nearest","nearest")
chunkSize=100
chunks = {}--2d array of image data
local chunkImages = {}
--loadX,loadY = 5,4 --how many chunks to load from the loadOrigin
local chunkCanvas = lg.newCanvas(chunkSize*loadX,chunkSize*loadY)
local chunkCanvasPos= {0,0}
local loadOrigin = vec2{0,0}
chunkEdges = {}
local chunkShader = lg.newShader "chunkShader.glsl"--program on the GPU that describes how to render the chunks

function Snap(vec)
	--plus one because the chunk at (1,1) would be (0,0) after chunk, where it should still be (1,1)
	return vec2{math.floor(vec[1]/chunkSize)+1,math.floor(vec[2]/chunkSize)+1}
end

--camera stuff
local screenWidth,screenHeight = lw.getMode()
local cameraX,cameraY = 0,0
local scale = 1
local cameraTransform = love.math.newTransform()

--ui stuff
local ui = nuklear.newUI()
local combo = {value=1,items={"Dig","Generate"}}
local brushSize = 10
local fontRaster = lf.newTrueTypeRasterizer("mini-wakuwaku.ttf",20)
lg.setNewFont(fontRaster)


--material stuff
local selectedMaterial = 1
local materials = {{color={1,1,1},name="Air"},{material=lg.newImage "gold.png",name="Gold"},{color={0,0,0},name="Stone"}}
for k,v in pairs(materials) do
	--generate images for materials like 'air' and 'stone' which don't have images (blank image filled with its color)
	if v.color then
		local newCanvas = lg.newCanvas(40,40)
		lg.setCanvas(newCanvas)
		lg.clear(v.color)
		lg.setCanvas()
		v.material=newCanvas
	end
end


--networking stuff
local socket = require "socket"
--local client = assert(socket.connect("192.168.1.9",20))
local client = assert(socket.connect("140.190.30.161",20))
print("connected")

--generate the chunks
require "server.physics"
local blankCanvas = lg.newCanvas(chunkSize,chunkSize,{format="r8"})
blankCanvas:renderTo(function()
	lg.clear(3/255,0,0)
end)
local loadCoro = coroutine.create(function() for x=1,loadX do
	for y=1,loadY do
		send(client,cmds.clientLoadRequest,x,y)
		coroutine.yield()
	end
end end)
coroutine.resume(loadCoro)
for x=1,loadX do
	chunks[x] = {}
	chunkImages[x] = {}
	chunkEdges[x] = {}
	for y=1,loadY do
		--create new imagedata
		coroutine.resume(loadCoro)
		local data,err = client:receive("*l")
		chunks[x][y] = love.image.newImageData(chunkSize,chunkSize,"r8",data)
		chunkImages[x][y] = lg.newImage(chunks[x][y])
		chunkEdges[x][y] = {}
		lg.setCanvas(chunkCanvas)
		lg.setShader(chunkShader)
		chunkShader:send("gold",materials[2].material)
		chunkShader:send("offset",chunkCanvasPos)
		lg.draw(chunkImages[x][y],(x-1)*chunkSize,(y-1)*chunkSize)
		lg.setShader()
		lg.setCanvas()
	end --im doin sum
end
for k,v in pairs(chunks) do
	for q,w in pairs(v) do
		for pixX=0,chunkSize-1 do
			for pixY=0,chunkSize-1 do
				--debugFunc(Edgy,pixX,pixY,k,q)
				Edgy(pixX,pixY,k,q)
			end
		end
	end
end
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  require("lldebugger").start()
end
--Convolution city Woot Woot!
function loadChunks(dx,dy)
	local trikl = {loadOrigin[1]+dx,loadOrigin[2]+dy}--sets the x, then on the second pass sets the y
	local loads = {loadX,loadY}
	local cumDiff = 0--just used to see if anything moved tiles
	for i=1,2 do
		local old = Snap(loadOrigin)
		loadOrigin[i] = trikl[i]
		local new = Snap(loadOrigin)
		local oldBasis=old[i]
		local oldCompliment = old[((i)%2)+1]
		local newBasis=new[i]
		local loadBasis = loads[i]
		local loadCompliment = loads[(i)%2+1]
		local basisDif = oldBasis-newBasis
		cumDiff = cumDiff + basisDif
		if basisDif ~= 0 then
			--removes chunks
			for x=basisDif>0 and math.max(oldBasis,oldBasis+loadBasis-basisDif) or oldBasis, basisDif>0 and oldBasis+loadBasis-1 or math.min(oldBasis+loadBasis-1,newBasis-1) do
				for y=oldCompliment,oldCompliment+loadCompliment-1  do
					local correctedY = i==1 and y or x--the upper for loop is changing x with y, so we need to index in the same way
					local correctedX = i==1 and x or y
					--client:send(correctedX..":"..correctedY..":"..chunks[correctedX][correctedY]:getString().."\n")
					chunks[correctedX][correctedY]:release()
					chunks[correctedX][correctedY] = nil
					chunkImages[correctedX][correctedY]:release()
					chunkImages[correctedX][correctedY] = nil
					chunkEdges[correctedX][correctedY] = nil
				end
			end
			--add chunks
			for x=basisDif>0 and newBasis or math.max(newBasis,oldBasis+loadBasis), basisDif>0 and math.min(oldBasis-1,newBasis+loadBasis-1) or oldBasis+loadBasis-basisDif-1 do
				for y=oldCompliment,oldCompliment+loadCompliment-1 do
					local correctedX = i==1 and x or y
					local correctedY = i==1 and y or x
					if chunks[correctedX] == nil then chunks[correctedX] = {};chunkImages[correctedX] = {} end
					--client:send(correctedX..":"..correctedY..":".."\n")
					send(client,cmds.clientLoadRequest,correctedX,correctedY)
					local data = client:receive("*l")
					if 0 == pcall(function() chunks[correctedX][correctedY] = love.image.newImageData(chunkSize,chunkSize,"r8",data) end) then
						print("oh no, data is weird!, it is #data bytes long")
					end
					chunkImages[correctedX][correctedY] = lg.newImage(chunks[correctedX][correctedY])
					generateArray(chunkEdges,correctedX,correctedY)
				end
			end
		end
	end
	--update the chunkCanvas (if needed!)
	if cumDiff ~= 0 then
		local new = Snap(loadOrigin)
		chunkCanvasPos = {(new[1]-1)*chunkSize,(new[2]-1)*chunkSize}
		lg.setCanvas(chunkCanvas)
		lg.setShader(chunkShader)
		chunkShader:send('gold',materials[2].material)
		chunkShader:send("offset",chunkCanvasPos)
		for x,q in pairs(chunkImages) do
			for y,w in pairs(q) do
				lg.draw(chunkImages[x][y],(x-1)*chunkSize-chunkCanvasPos[1],(y-1)*chunkSize-chunkCanvasPos[2])
			end
		end
		lg.setShader()
		lg.setCanvas()
	end
end

function ScreenToPixel(vec)
		local x,y = cameraTransform:inverseTransformPoint(vec.x,vec.y)
		x,y = math.floor(x),math.floor(y)
end

function love.mousemoved(x,y,dx,dy,istouch)
	if not ui:mousemoved(x, y, dx, dy, istouch) then
	if love.mouse.isDown(1) then
		if combo.items[combo.value]=="Dig" then

		lg.setCanvas(chunkCanvas)
		lg.setShader(chunkShader)
		lg.setColor(1,1,1)
		chunkShader:send('gold',materials[2].material)
		chunkShader:send("offset",chunkCanvasPos)
		lg.origin()
		--mouse/coords
		local scrX,scrY = love.mouse.getPosition()
		local x,y = cameraTransform:inverseTransformPoint(scrX,scrY)
		x,y = math.floor(x),math.floor(y)
		--iterate through chunks
		--translates screen space
		local radius = brushSize
		send(client,cmds.circle,x,y,radius,selectedMaterial)
		for k,v in pairs(chunks) do
			for q,w in pairs(v) do
				applyShapes(x,y,k,q,w,chunkSize,radius,circleDist,selectedMaterial,Edgy)
				chunkImages[k][q]:release()
				chunkImages[k][q] = lg.newImage(w)
				lg.draw(chunkImages[k][q],(k-1)*chunkSize-chunkCanvasPos[1],(q-1)*chunkSize-chunkCanvasPos[2])
			end
		end
		
		for k,v in pairs(chunks) do
			for q,w in pairs(v) do
				shapeBounding(x,y,k,q,chunkSize,radius,function(pixX,pixY)
					debugFunc(Edgy,pixX,pixY,k,q)
				end)
			end
		end
		lg.setShader()
		lg.setCanvas()
		elseif combo.items[combo.value]=="Generate" then
			loadChunks(dx/scale,dy/scale)
		end
	elseif love.mouse.isDown(3) then
		--middle mouse is pressed
		--pan the camera
		cameraX = cameraX + dx/scale
		cameraY = cameraY + dy/scale
	end
	end
end
function love.wheelmoved(x,y)
	if not ui:wheelmoved(x, y) then
		scale = scale + y*.1
	end
end

function love.update(dt)
	--try to get stuff from server
	client:settimeout(0)
	local data,err = client:receive()
	client:settimeout()
	if not err then
		lg.setCanvas(chunkCanvas)
		lg.setShader(chunkShader)
		local parts = {ParseMessage(data)}	
		for k,v in pairs(parts) do parts[k] = tonumber(v) end
		for x,q in pairs(chunks) do
			for y,w in pairs(q) do
				if parts[1] == cmds.circle then
					applyShapes(parts[2],parts[3],x,y,w,chunkSize,parts[4],circleDist,parts[5])
				end
				chunkImages[x][y]:release()
				chunkImages[x][y] = lg.newImage(w)
				lg.draw(chunkImages[x][y],(x-1)*chunkSize-chunkCanvasPos[1],(y-1)*chunkSize-chunkCanvasPos[2])
			end
		end
		for x,q in pairs(chunks) do
			for y,w in pairs(q) do
				shapeBounding(parts[2],parts[3],x,y,chunkSize,parts[4],function(pixX,pixY)
					Edgy(pixX,pixY,x,y)
				end)
			end
		end
		lg.setCanvas()
		lg.setShader()
	end

	ui:frameBegin()
	if ui:windowBegin('tools', 550, 100, 220, 200,
			'border', 'title', 'movable','scalable') then
		ui:layoutRow('static',30,100,2)
		ui:label "Draw Tools:"
		ui:combobox(combo,combo.items)
		ui:layoutRow("dynamic",30,1)
		if combo.items[combo.value] == "Dig" then
			if ui:comboboxBegin "Brush Material" then
				--go through the tables in 'materials' and create material options
				for k,v in pairs(materials) do
					ui:layoutRow("dynamic",60,1)
					if ui:comboboxItem(v.name,v.material) then--v.material can be nil
						--this is the material that is clicked
						selectedMaterial = k
						print("selected "..selectedMaterial)
					end
				end

				ui:comboboxEnd()
			end

			ui:layoutRow("dynamic",30,{.45,.1,.45})
			ui:label "Brush Size"
			ui:label(brushSize)
			brushSize = ui:slider(1,brushSize,100,1)
			if ui:button "Debug" then debug.debug() end
		end
	end
	ui:windowEnd()
	ui:frameEnd()
end
local old = {loadOrigin[1],loadOrigin[2]}
function love.draw()
	lg.clear(.1,.1,.1)
	lg.setLineWidth(6)
	lg.setColor(1,1,1)

	--translate (in reverse because dunmb)
	--translates and scales everything that will be drawn from screen space to camera space
	cameraTransform:reset()
	cameraTransform:translate(screenWidth/2,screenHeight/2)
	cameraTransform:scale(scale)
	cameraTransform:translate(-(screenWidth/2)+cameraX,-(screenHeight/2)+cameraY)

	lg.applyTransform(cameraTransform)
	lg.draw(chunkCanvas,chunkCanvasPos[1],chunkCanvasPos[2])

	--chunk lines

	--for x,_ in pairs(chunks) do
	--	for y,__ in pairs(_) do
	--		lg.rectangle("line",(x-1)*chunkSize,(y-1)*chunkSize,chunkSize,chunkSize)
	--	end
	--end
	lg.setPointSize(5)
	lg.setColor(1,0,0)
	for x=0, playerSize.x-1 do
		for y=0, playerSize.y-1 do
			local points = playerLocation+vec2(x,y)
			lg.points(points.x,points.y)
		end
	end

	lg.setPointSize(2)
	lg.setColor(0,0,1)
	for _,cx in pairs(chunkEdges) do
		for __,cy in pairs(cx) do
			for xPos,x in pairs(cy) do
				for yPos,y in pairs(x) do
					lg.points((_-1)*chunkSize+xPos+.5,(__-1)*chunkSize+yPos+.5)
				end
			end
		end
	end

	lg.setColor(1,0,0)
	lg.setPointSize(10)
	lg.points(0,0)
	lg.setColor(1,1,1)

	--draw the loadOrigin box
	lg.setColor(1,0,0)
	lg.rectangle("line",loadOrigin[1],loadOrigin[2],loadX*100,loadY*100)
	lg.setColor(1,1,1)

	ui:draw()
	
	lg.origin()
	lg.print("FPS: "..love.timer.getFPS(),0,0)
	lg.print(playerLocation.x.." "..playerLocation.y,0,20)

end

function love.keypressed(key, scancode, isrepeat)
	ui:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	ui:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
	if not ui:mousepressed(x, y, button, istouch, presses) then
		love.mousemoved(x,y,0,0,false)
	end
end

function love.mousereleased(x, y, button, istouch, presses)
	ui:mousereleased(x, y, button, istouch, presses)
end


function love.textinput(text)
	ui:textinput(text)
end

