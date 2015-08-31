local fs = require("filesystem")
local unicode = require("unicode")
local gpu = require("component").gpu
local image = {}
local transparentSymbol = "#"
local ocif_signature1 = 0x896F6369
local ocif_signature2 = 0x00661A0A --7 bytes: 89 6F 63 69 66 1A 0A
local ocif_signature_expand = { string.char(0x89), string.char(0x6F), string.char(0x63), string.char(0x69), string.char(0x66), string.char(0x1A), string.char(0x0A) }
local BYTE = 8
local NULL_CHAR = 0
local imageAPI = {}

local function readBytes(file, bytes)
  local readedByte = 0
  local readedNumber = 0
  for i = bytes, 1, -1 do
    readedByte = string.byte( file:read(1) or NULL_CHAR )
    readedNumber = readedNumber + bit32.lshift(readedByte, i*8-8)
  end

  return readedNumber
end

local function HEXtoRGB(color)
  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)
 
  return rr, gg, bb
end

local function encodePixel(hexcolor_fg, hexcolor_bg, char)
	local rr_fg, gg_fg, bb_fg = HEXtoRGB( hexcolor_fg )
	local rr_bg, gg_bg, bb_bg = HEXtoRGB( hexcolor_bg )
	local ascii_char1, ascii_char2 = string.byte( char, 1, 2 )

	ascii_char1 = ascii_char1 or NULL_CHAR
	ascii_char2 = ascii_char2 or NULL_CHAR

	return rr_fg, gg_fg, bb_fg, rr_bg, gg_bg, bb_bg, ascii_char1, ascii_char2
end

local function decodeChar(char1, char2)
	if ( char1 ~= 0 and char2 ~= 0 ) then
		return string.char( char1, char2 )
	elseif ( char1 ~= 0) then
		return string.char( char1 )
	elseif ( char2 ~= 0 ) then
		return string.char( char2 )
	end
end

function image.convertImagetoGroupedImage(PNGMassiv)
	local newPNGMassiv = { ["backgrounds"] = {} }

	for j = 1, #PNGMassiv do
		for i = 1, #PNGMassiv[j] do
			local back = PNGMassiv[j][i][1]
			local fore = PNGMassiv[j][i][2]
			local symbol = PNGMassiv[j][i][3]

			newPNGMassiv["backgrounds"][back] = newPNGMassiv["backgrounds"][back] or {}
			newPNGMassiv["backgrounds"][back][fore] = newPNGMassiv["backgrounds"][back][fore] or {}

			table.insert(newPNGMassiv["backgrounds"][back][fore], {i, j, symbol} )

			back, fore, symbol = nil, nil, nil
		end
	end

	return newPNGMassiv
end

local function loadJPG(path)
	local image = {}
	local file = io.open(path, "rb")

	local signature1, signature2 = readBytes(file, 4), readBytes(file, 3)
	if ( signature1 ~= ocif_signature1 or signature2 ~= ocif_signature2 ) then
		file:close()
		return nil
	end

	image.width = readBytes(file, 1)
	image.height = readBytes(file, 1)
	image.depth = readBytes(file, 1)

	for y = 1, image.height, 1 do
		table.insert( image, {} )
		for x = 1, image.width, 1 do
			table.insert( image[y], {} )
			image[y][x][2] = readBytes(file, 3)
			image[y][x][1] = readBytes(file, 3)
			image[y][x][3] = decodeChar(readBytes(file, 1), readBytes(file, 1))
		end
	end

	file:close()

	return image
end

function image.drawJPG(x, y, image)
	x = x - 1
	y = y - 1

	local image2 = convertImagetoGroupedImage(image)

	for back, backValue in pairs(image2["backgrounds"]) do
		gpu.setBackground(back)
		for fore, foreValue in pairs(image2["backgrounds"][back]) do
			gpu.setForeground(fore)
			for pixel = 1, #image2["backgrounds"][back][fore] do
				if image2["backgrounds"][back][fore][pixel][3] ~= transparentSymbol then
					gpu.set(x + image2["backgrounds"][back][fore][pixel][1], y + image2["backgrounds"][back][fore][pixel][2], image2["backgrounds"][back][fore][pixel][3])
				end
			end
		end
	end
end
   
function image.saveJPG(path, image)

	fs.remove(path)
	fs.makeDirectory(fs.path(path))

	local file = io.open(path, "w")

	--print("width = ", image.width)

	file:write( table.unpack(ocif_signature_expand) )
	file:write( string.char( image.width ) )
	file:write( string.char( image.height ) )
	file:write( string.char( image.depth ) )

	for y = 1, image.height, 1 do
		for x = 1, image.width, 1 do
			local encodedPixel = { encodePixel( image[y][x][2], image[y][x][1], image[y][x][3] ) }
			for i = 1, #encodedPixel do
				file:write( string.char( encodedPixel[i] ) )
			end
		end
	end

	file:close()
end

local function HEXtoSTRING(color,withNull)
	local strng = string.format("%x",color)
	local Lstrng = unicode.len(strng)

	if Lstrng < 6 then
		strng = string.rep("0", 6 - Lstrng) .. strng
	end

	if withNull then return "0x"..strng else return strng end
end

--Загрузка ПНГ
local function loadPNG(path)
	local file = io.open(path, "r")
	local newPNGMassiv = { ["backgrounds"] = {} }

	local pixelCounter, lineCounter = 1, 1
	for line in file:lines() do
		local dlinaStroki = unicode.len(line)
		pixelCounter = 1

		for i = 1, dlinaStroki, 16 do
			local back = tonumber("0x"..unicode.sub(line, i, i + 5))
			local fore = tonumber("0x"..unicode.sub(line, i + 7, i + 12))
			local symbol = unicode.sub(line, i + 14, i + 14)

			newPNGMassiv["backgrounds"][back] = newPNGMassiv["backgrounds"][back] or {}
			newPNGMassiv["backgrounds"][back][fore] = newPNGMassiv["backgrounds"][back][fore] or {}

			table.insert(newPNGMassiv["backgrounds"][back][fore], {pixelCounter, lineCounter, symbol} )

			pixelCounter = pixelCounter + 1
			back, fore, symbol = nil, nil, nil
		end

		lineCounter = lineCounter + 1
	end

	file:close()
	pixelCounter, lineCounter = nil, nil

	return newPNGMassiv
end

function image.savePNG(path, MasterPixels)
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local f = io.open(path, "w")

	for j=1, #MasterPixels do
		for i=1,#MasterPixels[j] do
			f:write(HEXtoSTRING(MasterPixels[j][i][1])," ",HEXtoSTRING(MasterPixels[j][i][2])," ",MasterPixels[j][i][3]," ")
		end
		f:write("\n")
	end

	f:close()
end

function image.drawPNG(x, y, massivSudaPihay)
	x = x - 1
	y = y - 1

	for back, backValue in pairs(massivSudaPihay["backgrounds"]) do
		gpu.setBackground(back)
		for fore, foreValue in pairs(massivSudaPihay["backgrounds"][back]) do
			gpu.setForeground(fore)
			for pixel = 1, #massivSudaPihay["backgrounds"][back][fore] do
				if massivSudaPihay["backgrounds"][back][fore][pixel][3] ~= transparentSymbol then
					gpu.set(x + massivSudaPihay["backgrounds"][back][fore][pixel][1], y + massivSudaPihay["backgrounds"][back][fore][pixel][2], massivSudaPihay["backgrounds"][back][fore][pixel][3])
				end
			end
		end
	end
end

function image.PNGtoJPG(PNGMassiv)
	local JPGMassiv = {}
	local width, height = 0, 0

	for j = 1, #PNGMassiv do
		JPGMassiv[j] = {}
		width = 0
		for i = 1, #PNGMassiv[j] do
			JPGMassiv[j][i] = { table.unpack(PNGMassiv[j][i]) }
			width = width + 1
		end
		height = height + 1
	end

	JPGMassiv["width"] = width
	JPGMassiv["height"] = height
	JPGMassiv["depth"] = 8

	return JPGMassiv
end

function image.JPGtoPNG(JPGMassiv)
	local PNGMassiv = {}
	local width, height = 0, 0

	for j = 1, #JPGMassiv do
		PNGMassiv[j] = {}
		width = 0
		for i = 1, #JPGMassiv[j] do
			PNGMassiv[j][i] = { table.unpack(JPGMassiv[j][i]) }
			width = width + 1
		end
		height = height + 1
	end

	return PNGMassiv
end

function image.convertAllPNGtoJPG(path)
	local list = guiapi.getFileList(path)
	for key, file in pairs(list) do
		if fs.isDirectory(path.."/"..file) then
			image.convertAllPNGtoJPG(path.."/"..file)
		else
			if guiapi.getFileFormat(file) == ".png" or guiapi.getFileFormat(file) == ".PNG" then
				print("Найден .PNG в директории \""..path.."/"..file.."\"")
				print("Загружаю этот файл...")
				PNGFile = loadPNG(path.."/"..file)
				print("Загрузка завершена!")
				print("Конвертация в JPG начата...")
				JPGFile = image.PNGtoJPG(PNGFile)
				print("Ковертация завершена!")
				print("Сохраняю .JPG в той же папке...")
				image.saveJPG(path.."/"..guiapi.hideFileFormat(file)..".jpg", JPGFile)
				print("Сохранение завершено!")
				print(" ")
			end
		end
	end
end

function image.load(path)

	local imga = {}
	local fileFormat = guiapi.getFileFormat(path)

	if string.lower(fileFormat) == ".jpg" then
		imga["format"] = ".jpg"
		imga["image"] = loadJPG(path)
	elseif  string.lower(fileFormat) == ".png" then
		imga["format"] = ".png"
		imga["image"] = loadPNG(path)
	else
		guiapi.error("Wrong file format! (not .png or .jpg)")
	end

	return imga
end

--Отрисовка этого изображения
function image.draw(x, y, imga)
	if imga.format == ".jpg" then
		image.drawJPG(x, y, imga["image"])
	elseif imga.format == ".png" then
		image.drawPNG(x, y, imga["image"])
	end
end

return image






