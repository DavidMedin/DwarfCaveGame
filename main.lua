local nuklear = require "nuklear"
love=love
local lg = love.graphics
local lw = love.window
local lp = love.physics

--chunk stuff
lg.setDefaultFilter("nearest","nearest")
local chunkSize=100
local chunks = {}--2d array of textures
local chunkImages = {}
local chunkCanvas = lg.newCanvas(chunkSize*5,chunkSize*5)
local chunkEdges = {}
local chunkShader = lg.newShader "chunkShader.glsl"

--camera stuff
local screenWidth,screenHeight = lw.getMode()
local cameraX,cameraY = 0,0
local scale = 1
local cameraTransform = love.math.newTransform()

--ui stuff
local ui = nuklear.newUI()
local combo = {value=1,items={"Dig","Generate"}}
local brushSize = 20

--generate the chunks
local blankCanvas = lg.newCanvas(chunkSize,chunkSize,{format="r8"})
blankCanvas:renderTo(function()
	lg.clear(0,0,0)
end)
for x=1,5 do
	chunks[x] = {}
	chunkImages[x] = {}
	for y=1,5 do
		--create new imagedata
		chunks[x][y] = blankCanvas:newImageData()
		chunkImages[x][y] = lg.newImage(chunks[x][y])
		lg.setCanvas(chunkCanvas)
		lg.setShader(chunkShader)
		lg.draw(chunkImages[x][y],(x-1)*chunkSize,(y-1)*chunkSize)
		lg.setShader()
		lg.setCanvas()
	end
end
local function vec2(x,y)
	return setmetatable({x=x,y=y},{__add=function(lh,rh) return vec2(lh.x+rh.x,lh.y+rh.y) end})
end
local function distance(pos1,pos2)
	return math.sqrt(((pos1.x-pos2.x)^2)+(pos1.y-pos2.y)^2)
end
local function circleDist(pointPos,circlePos,radius)
	return distance(pointPos,circlePos)-radius
end


--uses cameraX,cameraY, and scale Attempt to set out-of-range pixel!
function GetCanvasPos(k,q,mult)
	mult = mult or 1
	return ((k-1)*chunkSize)*mult,((q-1)*chunkSize)*mult
end
function love.mousemoved(x,y,dx,dy,istouch)
	if not ui:mousemoved(x, y, dx, dy, istouch) then
	if love.mouse.isDown(1) then
		if combo.items[combo.value]=="Dig" then

		lg.setCanvas(chunkCanvas)
		lg.setShader(chunkShader)
		lg.origin()
		--mouse/coords
		local scrX,scrY = love.mouse.getPosition()
		local x,y = cameraTransform:inverseTransformPoint(scrX,scrY)
		x,y = math.floor(x),math.floor(y)
		--iterate through chunks
		--translates screen space
		for k,v in pairs(chunks) do
			for q,w in pairs(v) do
				--w is the 'image'
				local radius = brushSize
				--might be slow
				for pixX=math.max(1,(x-(k-1)*chunkSize)-radius),math.min(chunkSize,x-(k-1)*chunkSize+radius) do
					for pixY=math.max(1,y-(q-1)*chunkSize-radius),math.min(chunkSize,y-(q-1)*chunkSize+radius) do
						--iterate throught the pixels in the image
						local dist = circleDist(vec2(pixX,pixY)+vec2((k-1)*chunkSize,(q-1)*chunkSize),vec2(x,y),radius)
						if dist <= 0 then
							--this pixel is in the circle
								w:setPixel(pixX-1,pixY-1,1,0,0)--the Green and Blue components are thrown out because this is a r8 image
						end
					end
				end
				chunkImages[k][q]:release()
				chunkImages[k][q] = lg.newImage(w)
				lg.draw(chunkImages[k][q],(k-1)*chunkSize,(q-1)*chunkSize)
			end
		end
		lg.setShader()
		lg.setCanvas()
		elseif combo.items[combo.value]=="Generate" then
			--if the Generate tool is selected, then we can paint chunks into existence.
			--Get the real-space position of the cursor,
			--then find the chunk it is in.
			local x,y = cameraTransform:inverseTransformPoint(love.mouse.getPosition())
			--find the chunk
			--lg.rectangle("fill",x%100,y%100,100,100)
			local ix,iy = math.floor(x/chunkSize)+1,math.floor(y/chunkSize)+1
			if chunks[ix] == nil or chunks[ix][iy] == nil then
				--lets write chunk
				if chunks[ix] == nil then chunks[ix] = {} end
				chunks[ix][iy] = lg.newCanvas(chunkSize,chunkSize)
				lg.setCanvas(chunks[ix][iy])
				lg.clear(0,0,0)
				lg.setCanvas()
			end
			
		end
	elseif love.mouse.isDown(3) then
		--middle mouse is pressed
		--pan the camera
		cameraX = cameraX + dx
		cameraY = cameraY + dy
	end
	end
end
function love.wheelmoved(x,y)
	if not ui:wheelmoved(x, y) then
		scale = scale + y*.1
	end
end
function love.update(dt)
	ui:frameBegin()
	if ui:windowBegin('tools', 100, 100, 200, 160,
			'border', 'title', 'movable','scalable') then
		ui:layoutRow('dynamic',30,2)
		ui:label "Draw Tools:"
		ui:combobox(combo,combo.items)
		if combo.items[combo.value] == "Dig" then
			ui:layoutRow("dynamic",60,2)
			ui:label "Brush Size"
			brushSize = ui:slider(1,brushSize,100,1)
		end
		--ui:layoutRow('dynamic', 30, 1)
		--ui:label('Hello, world!')
		--ui:layoutRow('dynamic', 30, 2)
		--ui:label('Hello, world!')
		--ui:label('Combo box:')
		--if ui:combobox(combo, combo.items) then
		--	print('Combo!', combo.items[combo.value])
		--end
		--ui:layoutRow('dynamic', 30, 3)
		--ui:label('Buttons:')
		--if ui:button('Sample') then
		--	print('Sample!')
		--end
		--if ui:button('Button') then
		--	print('Button!')
		--end
	end
	ui:windowEnd()
	ui:frameEnd()
end
function love.draw()
	lg.clear(.1,.1,.1)
	lg.setLineWidth(6)

	--translate (in reverse because dunmb)
	--translates and scales everything that will be drawn from screen space to camera space
	cameraTransform:reset()
	cameraTransform:translate(screenWidth/2,screenHeight/2)
	cameraTransform:scale(scale)
	cameraTransform:translate(-(screenWidth/2)+cameraX,-(screenHeight/2)+cameraY)

	lg.applyTransform(cameraTransform)
	--for k,v in pairs(chunks) do
	--	for q,w in pairs(v) do
	--		--lg.draw(w,GetCanvasPos(k,q))
	--	end
	--end
	lg.draw(chunkCanvas)	
	lg.setColor(1,0,0)
	lg.setPointSize(10)
	lg.points(0,0)
	lg.setColor(1,1,1)
	ui:draw()
	

end

function love.keypressed(key, scancode, isrepeat)
	ui:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	ui:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
	ui:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	ui:mousereleased(x, y, button, istouch, presses)
end


function love.textinput(text)
	ui:textinput(text)
end

