# ImageStroke
ImageStroke is library that gives ability to create strokes on images using editable images.

[**Roblox Marketplace Asset**](https://create.roblox.com/store/asset/112604070431989/ImageStroke)

# Usage example
```Lua
local ImageStroke = require(script.ImageStroke)
local Image = script.Parent

-- create image stroke with thickness of 5 and color of Color3.fromRGB(50, 151, 218).
-- currently there's two stroke types: Linear and Bevel
ImageStroke.ApplyStroke(Image,"Linear",5,Color3.fromRGB(50, 151, 218))
```
