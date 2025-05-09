local StrokeFunctions = {}

local function convertColor(color:Color3)
	return {R = math.floor(color.R*255),G = math.floor(color.G*255),B = math.floor(color.B*255)}
end

function StrokeFunctions.addBevelStroke(imageBuffer: buffer, size:Vector2, strokeThickness: number, color:Color3): buffer
	local outputBuffer = buffer.create(buffer.len(imageBuffer))
	buffer.copy(outputBuffer, 0, imageBuffer)
	local convertedColor = convertColor(color or Color3.new(0, 0, 0))
	
	local width = size.X
	local height = size.Y
	
	local edgePixels = {} -- List of {x, y} coordinates
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local pixelIndex = (y * width + x) * 4
			local alpha = buffer.readu8(imageBuffer, pixelIndex + 3)

			if alpha > 0 then
				local isEdge = false
				for _, offset in {{0, -1}, {0, 1}, {-1, 0}, {1, 0}} do
					local dx, dy = offset[1], offset[2]
					local nx, ny = x + dx, y + dy
					if nx >= 0 and nx < width and ny >= 0 and ny < height then
						local neighborIndex = (ny * width + nx) * 4
						local neighborAlpha = buffer.readu8(imageBuffer, neighborIndex + 3)
						if neighborAlpha == 0 then
							isEdge = true
							break
						end
					end
				end
				if isEdge then
					table.insert(edgePixels, {x, y})
				end
			end
		end
	end

	for _, edgePixel in edgePixels do
		local x, y = edgePixel[1], edgePixel[2]
		for dy = -strokeThickness, strokeThickness do
			for dx = -strokeThickness, strokeThickness do
				if dx * dx + dy * dy <= strokeThickness * strokeThickness then

					local nx, ny = x + dx, y + dy
					if nx >= 0 and nx < width and ny >= 0 and ny < height then

						local pixelIndex = (ny * width + nx) * 4
						local alpha = buffer.readu8(imageBuffer, pixelIndex + 3)
						if alpha == 0 then
							-- RGBA color
							buffer.writeu8(outputBuffer, pixelIndex, convertedColor.R)
							buffer.writeu8(outputBuffer, pixelIndex + 1, convertedColor.G)
							buffer.writeu8(outputBuffer, pixelIndex + 2, convertedColor.B)
							buffer.writeu8(outputBuffer, pixelIndex + 3, 255)
						end
					end
				end
			end
		end
	end

	return outputBuffer
end

function StrokeFunctions.addLinearStroke(imageBuffer: buffer, size:Vector2, strokeThickness: number, color:Color3): buffer
	local outputBuffer = buffer.create(buffer.len(imageBuffer))
	buffer.copy(outputBuffer, 0, imageBuffer)
	
	local convertedColor = convertColor(color or Color3.new(0, 0, 0))

	local width = size.X
	local height = size.Y

	local edgePixels = {}
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local pixelIndex = (y * width + x) * 4
			local alpha = buffer.readu8(imageBuffer, pixelIndex + 3)
			
			if alpha > 0 then
				local isEdge = false
				
				for _, offset in {{0, -1}, {0, 1}, {-1, 0}, {1, 0}} do
					local dx, dy = offset[1], offset[2]
					local nx, ny = x + dx, y + dy
					if nx >= 0 and nx < width and ny >= 0 and ny < height then
						local neighborIndex = (ny * width + nx) * 4
						local neighborAlpha = buffer.readu8(imageBuffer, neighborIndex + 3)
						if neighborAlpha == 0 then
							isEdge = true
							break
						end
					end
				end
				if isEdge then
					table.insert(edgePixels, {x, y})
				end
			end
		end
	end

	for _, edgePixel in edgePixels do
		local x, y = edgePixel[1], edgePixel[2]
		
		for dy = -strokeThickness, strokeThickness do
			for dx = -strokeThickness, strokeThickness do
				local nx, ny = x + dx, y + dy
				if nx >= 0 and nx < width and ny >= 0 and ny < height then
					local pixelIndex = (ny * width + nx) * 4
					local alpha = buffer.readu8(imageBuffer, pixelIndex + 3)
					if alpha == 0 then
						-- RGBA color
						buffer.writeu8(outputBuffer, pixelIndex, convertedColor.R)
						buffer.writeu8(outputBuffer, pixelIndex + 1, convertedColor.G)
						buffer.writeu8(outputBuffer, pixelIndex + 2, convertedColor.B)
						buffer.writeu8(outputBuffer, pixelIndex + 3, 255)
					end
				end
			end
		end
	end

	return outputBuffer
end

local OSGL = require(script.OSGL)

-- extract ID for automatic sizing
local function extractID(url)
	local reversed = url:reverse()
	local reversedId = reversed:match("^(%d+)")
	return tonumber(reversedId:reverse())
end

return {
	ApplyStroke = function(image:ImageButton | ImageLabel, mode:"Linear" | "Bevel", strokeThickness:number?, color3 :Color3)
		
		local thickness = strokeThickness or 2
		
		local imageID = extractID(image.Image)
		local windowAsset = OSGL.Window.fromAssetId(imageID)
		
		if not windowAsset.isOk then
			local errorStr = windowAsset:UnwrapErr()
			warn("Error occured while creating -",errorStr)
			return errorStr
		end
		
		local loadedWindow = windowAsset:Unwrap()
		loadedWindow:AddRenderers(image)
		
		local loadBuffer:buffer
		if mode == "Linear" then
			loadBuffer = StrokeFunctions.addLinearStroke(loadedWindow.buffer,loadedWindow.size,thickness,color3)
		elseif mode == "Bevel" then
			loadBuffer = StrokeFunctions.addBevelStroke(loadedWindow.buffer,loadedWindow.size,thickness,color3)
		end
		loadedWindow:Buffer(loadBuffer,loadedWindow.width,loadedWindow.height,0,0)
		loadedWindow:Render()
		
	end,
	addLinearStrokeRaw = StrokeFunctions.addLinearStroke,
	addBevelStrokeRaw = StrokeFunctions.addBevelStroke,
}
