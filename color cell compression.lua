-- This is an implementation of the "cell" part of colour cell compression
-- https://en.wikipedia.org/wiki/Color_Cell_Compression
--
-- This basically renders every 4x4 cell as a 1-bit bitmap
--
-- Usage (first time):
--   1) Open Aseprite
--   2) Go to File > Scripts > Open scripts folder
--   3) Copy this file to the scripts folder
--   4) In Aseprite, go to File > Scripts > Rescan scripts folder
--   5) Run the script: File > Scripts > palettize
--
-- Usage:
--   1) File > Scripts > palettize
--
-- Made by MiiFox
local sprite = app.activeSprite
if sprite == nil then
    return app.alert("ERROR: There is no active sprite")
end
if sprite.colorMode == ColorMode.Tilemap then
    return app.alert("ERROR: Tilemap color mode not supported")
end
--if sprite.colorMode ~= ColorMode.RGB then
--    app.command.ChangePixelFormat{ format="rgb" }
--end
if not (sprite.width&3) == 0 then
    return app.alert("ERROR: Sprite's width is not divideable by 4")
end
if not (sprite.height&3) == 0 then
    return app.alert("ERROR: Sprite's height is not divideable by 4")
end

function color_cell_compression()
    -- step 1: iterate over all the cells, gather all distinct colours per cell
    for u,cell in ipairs(sprite.cels) do
        local data = {}
        local count = {}
        local image = cell.image
        local w = image.width >> 2
        for it in image:pixels() do
            local pixelValue = it() -- get pixel
            local cell_x = it.x >> 2
            local cell_y = it.y >> 2
            if (it.x&3) == 0 and (it.y&3) == 0 then
                data[cell_x + cell_y*w] = {}
                count[cell_x + cell_y*w] = 0
            end
            local found = false
            for v,col in ipairs(data[cell_x + cell_y*w]) do
                if col == pixelValue then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(data[cell_x + cell_y*w], pixelValue)
                count[cell_x + cell_y*w] = count[cell_x + cell_y*w] + 1
            end
        end

        -- step 2: determine the palette per cell
        local dark_cell = {}
        local light_cell = {}
        for j,p in pairs(data) do
            -- order from dark to light
            table.sort(p, function (c1, c2) return app.pixelColor.rgbaR(c1)*.299 + app.pixelColor.rgbaG(c1)*.587 + app.pixelColor.rgbaB(c1)*.114 < app.pixelColor.rgbaR(c2)*.299 + app.pixelColor.rgbaG(c2)*.587 + app.pixelColor.rgbaB(c2)*.114 end )
            local size = count[j]
            local mid_loc = (size >> 1) + 1
            local dark_red = 0
            local dark_green = 0
            local dark_blue = 0
            local dark_count = 0
            local light_red = 0
            local light_green = 0
            local light_blue = 0
            local light_count = 0
            -- determine which two colours to use for dark and for light
            -- area for improvement: right now we calculate the mean of the two color segments. the median looks better, though it is more processor-intensive
            for i,v in pairs(p) do
                if i < mid_loc then
                    dark_red = dark_red + app.pixelColor.rgbaR(v)
                    dark_green = dark_green + app.pixelColor.rgbaG(v)
                    dark_blue = dark_blue + app.pixelColor.rgbaB(v)
                    dark_count = dark_count + 1
                else
                    light_red = light_red + app.pixelColor.rgbaR(v)
                    light_green = light_green + app.pixelColor.rgbaG(v)
                    light_blue = light_blue + app.pixelColor.rgbaB(v)
                    light_count = light_count + 1
                end
            end
            local score_dark = 99999
            local score_light = 99999
            for i,v in pairs(p) do
                if i < mid_loc then
                    local score = math.abs(app.pixelColor.rgbaR(v)-(dark_red/dark_count))*.299
                                + math.abs(app.pixelColor.rgbaG(v)-(dark_green/dark_count))*.587
                                + math.abs(app.pixelColor.rgbaB(v)-(dark_blue/dark_count))*.114
                    if score < score_dark then
                        score_dark = score
                        dark_cell[j] = v
                    end
                else
                    local score = math.abs(app.pixelColor.rgbaR(v)-(light_red/light_count))*.299
                                + math.abs(app.pixelColor.rgbaG(v)-(light_green/light_count))*.587
                                + math.abs(app.pixelColor.rgbaB(v)-(light_blue/light_count))*.114
                    if score < score_light then
                        score_light = score
                        light_cell[j] = v
                    end
                end
            end
        end
        -- apply per-cell colour palette
        for it in image:pixels() do
            local pixelValue = it()
            local cell_x = it.x >> 2
            local cell_y = it.y >> 2
            local dark = dark_cell[cell_x + cell_y*w]
            local light = light_cell[cell_x + cell_y*w]
            local red = app.pixelColor.rgbaR(pixelValue)
            local green = app.pixelColor.rgbaG(pixelValue)
            local blue = app.pixelColor.rgbaB(pixelValue)
            if math.abs(red-app.pixelColor.rgbaR(dark))*.299 + math.abs(green-app.pixelColor.rgbaG(dark))*.587 + math.abs(blue-app.pixelColor.rgbaB(dark))*.114 < math.abs(red-app.pixelColor.rgbaR(light))*.299 + math.abs(green-app.pixelColor.rgbaG(light))*.587 + math.abs(blue-app.pixelColor.rgbaB(light))*.114 then
                it(dark)
            else
                it(light)
            end
        end
    end
    -- bonus: set grid to cell width
    sprite.gridBounds = Rectangle(0,0,4,4)
end

app.transaction("color cell compression", color_cell_compression)
