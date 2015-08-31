local component = require("component")
local term = require("term")
local unicode = require("unicode")
local event = require("event")
local fs = require("filesystem")
local shell = require("shell")
local keyboard = require("keyboard")
local computer = require("computer")
local fs = require("filesystem")
local gpu = component.gpu
local screen = component.screen

local OS = {}

----------------------------------------------------------------------------------------------------

OS.windowColors = {
	background = 0xeeeeee,
	usualText = 0x444444,
	subText = 0x888888,
	tab = 0xaaaaaa,
	title = 0xffffff,
	shadow = 0x444444,
}

OS.colors = {
	white = 0xF0F0F0,
	orange = 0xF2B233,
	magenta = 0xE57FD8,
	lightBlue = 0x99B2F2,
	yellow = 0xDEDE6C,
	lime = 0x7FCC19,
	pink = 0xF2B2CC,
	gray = 0x4C4C4C,
	lightGray = 0x999999,
	cyan = 0x4C99B2,
	purple = 0xB266E5,
	blue = 0x3366CC,
	brown = 0x7F664C,
	green = 0x57A64E,
	red = 0xCC4C4C,
    black = 0x000000
}

----------------------------------------------------------------------------------------------------

--МАСШТАБ МОНИТОРА
function OS.setScale(scale, debug)
	--КОРРЕКЦИЯ МАСШТАБА, ЧТОБЫ ВСЯКИЕ ДАУНЫ НЕ ДЕЛАЛИ ТОГО, ЧЕГО НЕ СЛЕДУЕТ
	if scale > 1 then
		scale = 1
	elseif scale < 0.1 then
		scale = 0.1
	end

	--Просчет пикселей в блоках кароч - забей, так надо
	local function calculateAspect(screens)
	  local abc = 12

	  if screens == 2 then
	    abc = 28
	  elseif screens > 2 then
	    abc = 28 + (screens - 2) * 16
	  end

	  return abc
	end

	--Собсна, арсчет масштаба
	local xScreens, yScreens = component.screen.getAspectRatio()

	local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)

	local proportion = xPixels / yPixels

	local xMax, yMax  = 100, 50

	local newWidth, newHeight

	if proportion >= 1 then
		newWidth = math.floor(xMax * scale)
		newHeight = math.floor(newWidth / proportion / 2)
	else
		newHeight = math.floor(yMax * scale)
		newWidth = math.floor(newHeight * proportion * 2)
	end

	if debug then
		print(" ")
		print("Максимальное разрешение: "..xMax.."x"..yMax)
		print("Пропорция монитора: "..xPixels.."x"..yPixels)
		print(" ")
		print("Новое разрешение: "..newWidth.."x"..newHeight)
		print(" ")
	end

	gpu.setResolution(newWidth, newHeight)
end

--Сделать строку пригодной для отображения в ОпенКомпах
function OS.stringOptimize(sto4ka, indentatonWidth)
	indentatonWidth = indentatonWidth or 2
    sto4ka = string.gsub(sto4ka, "\r\n", "\n")
    sto4ka = string.gsub(sto4ka, "	", string.rep(" ", indentatonWidth))
    return stro4ka
end

--ИЗ ДЕСЯТИЧНОЙ В ШЕСТНАДЦАТИРИЧНУЮ
function OS.decToBase(IN,BASE)
    local hexCode = "0123456789ABCDEFGHIJKLMNOPQRSTUVW"
    OUT = ""
    local ostatok = 0
    while IN>0 do
        ostatok = math.fmod(IN,BASE) + 1
        IN = math.floor(IN/BASE)
        OUT = string.sub(hexCode,ostatok,ostatok)..OUT
    end
    if #OUT == 1 then OUT = "0"..OUT end
    if OUT == "" then OUT = "00" end
    return OUT
end

--ИЗ 16 В РГБ
function OS.HEXtoRGB(color)
  color = math.ceil(color)

  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)

  return rr, gg, bb
end

--ИЗ РГБ В 16
function OS.RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--ИЗ ХСБ В РГБ
function OS.HSBtoRGB(h, s, v)
  local rr, gg, bb = 0, 0, 0
  local const = 255

  s = s/100
  v = v/100
  
  local i = math.floor(h/60)
  local f = h/60 - i
  
  local p = v*(1-s)
  local q = v*(1-s*f)
  local t = v*(1-(1-f)*s)

  if ( i == 0 ) then rr, gg, bb = v, t, p end
  if ( i == 1 ) then rr, gg, bb = q, v, p end
  if ( i == 2 ) then rr, gg, bb = p, v, t end
  if ( i == 3 ) then rr, gg, bb = p, q, v end
  if ( i == 4 ) then rr, gg, bb = t, p, v end
  if ( i == 5 ) then rr, gg, bb = v, p, q end

  return rr*const, gg*const, bb*const
end

--КЛИКНУЛИ ЛИ В ЗОНУ
function OS.clickedAtArea(x,y,sx,sy,ex,ey)
  if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
  return false
end

--ОЧИСТКА ЭКРАНА ЦВЕТОМ
function OS.clearScreen(color)
  if color then gpu.setBackground(color) end
  term.clear()
end

--ПРОСТОЙ СЕТПИКСЕЛЬ, ИБО ЗАЕБАЛО
function OS.setPixel(x,y,color)
  gpu.setBackground(color)
  gpu.set(x,y," ")
end

--ЦВЕТНОЙ ТЕКСТ
function OS.colorText(x,y,textColor,text)
  gpu.setForeground(textColor)
  gpu.set(x,y,text)
end

--ЦВЕТНОЙ ТЕКСТ С ЖОПКОЙ!
function OS.colorTextWithBack(x,y,textColor,backColor,text)
  gpu.setForeground(textColor)
  gpu.setBackground(backColor)
  gpu.set(x,y,text)
end

--ИНВЕРСИЯ HEX-ЦВЕТА
function OS.invertColor(color)
  return 0xffffff - color
end

--АДАПТИВНЫЙ ТЕКСТ, ПОДСТРАИВАЮЩИЙСЯ ПОД ФОН
function OS.adaptiveText(x,y,text,textColor)
  gpu.setForeground(textColor)
  x = x - 1
  for i=1,unicode.len(text) do
    local info = {gpu.get(x+i,y)}
    gpu.setBackground(info[3])
    gpu.set(x+i,y,unicode.sub(text,i,i))
  end
end

--ИНВЕРТИРОВАННЫЙ ПО ЦВЕТУ ТЕКСТ НА ОСНОВЕ ФОНА
function OS.invertedText(x,y,symbol)
  local info = {gpu.get(x,y)}
  OS.adaptiveText(x,y,symbol,OS.invertColor(info[3]))
end

--АДАПТИВНОЕ ОКРУГЛЕНИЕ ЧИСЛА
function OS.adaptiveRound(chislo)
  local celaya,drobnaya = math.modf(chislo)
  if drobnaya >= 0.5 then
    return (celaya + 1)
  else
    return celaya
  end
end

function OS.square(x,y,width,height,color)
  gpu.setBackground(color)
  gpu.fill(x,y,width,height," ")
end

function OS.border(x, y, width, height, back, fore)
	local stringUp = "┌"..string.rep("─", width - 2).."┐"
	local stringDown = "└"..string.rep("─", width - 2).."┘"
	gpu.setForeground(fore)
	gpu.setBackground(back)
	gpu.set(x, y, stringUp)
	gpu.set(x, y + height - 1, stringDown)

	local yPos = 1
	for i = 1, (height - 2) do
		gpu.set(x, y + yPos, "│")
		gpu.set(x + width - 1, y + yPos, "│")
		yPos = yPos + 1
	end
end

function OS.separator(x, y, width, back, fore)
	OS.colorTextWithBack(x, y, fore, back, string.rep("─", width))
end

--АВТОМАТИЧЕСКОЕ ЦЕНТРИРОВАНИЕ ТЕКСТА ПО КООРДИНАТЕ
function OS.centerText(mode,coord,text)
	local dlina = unicode.len(text)
	local xSize,ySize = gpu.getResolution()

	if mode == "x" then
		gpu.set(math.floor(xSize/2-dlina/2),coord,text)
	elseif mode == "y" then
		gpu.set(coord,math.floor(ySize/2),text)
	else
		gpu.set(math.floor(xSize/2-dlina/2),math.floor(ySize/2),text)
	end
end

--
function OS.drawCustomImage(x,y,pixels)
	x = x - 1
	y = y - 1
	local pixelsWidth = #pixels[1]
	local pixelsHeight = #pixels
	local xEnd = x + pixelsWidth
	local yEnd = y + pixelsHeight

	for i=1,pixelsHeight do
		for j=1,pixelsWidth do
			if pixels[i][j][3] ~= "#" then
				gpu.setBackground(pixels[i][j][1])
				gpu.setForeground(pixels[i][j][2])
				gpu.set(x+j,y+i,pixels[i][j][3])
			end
		end
	end

	return (x+1),(y+1),xEnd,yEnd
end

--КОРРЕКТИРОВКА СТАРТОВЫХ КООРДИНАТ
function OS.correctStartCoords(xStart,yStart,xWindowSize,yWindowSize)
	local xSize,ySize = gpu.getResolution()
	if xStart == "auto" then
		xStart = math.floor(xSize/2 - xWindowSize/2)
	end
	if yStart == "auto" then
		yStart = math.floor(ySize/2 - yWindowSize/2)
	end
	return xStart,yStart
end

--ЗАПОМНИТЬ ОБЛАСТЬ ПИКСЕЛЕЙ
function OS.rememberOldPixels(x, y, x2, y2)
	local newPNGMassiv = { ["backgrounds"] = {} }
	newPNGMassiv.x, newPNGMassiv.y = x, y

	--Перебираем весь массив стандартного PNG-вида по высоте
	local xCounter, yCounter = 1, 1
	for j = y, y2 do
		xCounter = 1
		for i = x, x2 do
			local symbol, fore, back = gpu.get(i, j)

			newPNGMassiv["backgrounds"][back] = newPNGMassiv["backgrounds"][back] or {}
			newPNGMassiv["backgrounds"][back][fore] = newPNGMassiv["backgrounds"][back][fore] or {}

			table.insert(newPNGMassiv["backgrounds"][back][fore], {xCounter, yCounter, symbol} )

			xCounter = xCounter + 1
			back, fore, symbol = nil, nil, nil
		end

		yCounter = yCounter + 1
	end

	return newPNGMassiv
end

--НАРИСОВАТЬ ЗАПОМНЕННЫЕ ПИКСЕЛИ ИЗ МАССИВА
function OS.drawOldPixels(massivSudaPihay)

	--Отнимаем разок
	--massivSudaPihay.x, massivSudaPihay.y = massivSudaPihay.x - 1, massivSudaPihay.y - 1

	--Перебираем массив с фонами
	for back, backValue in pairs(massivSudaPihay["backgrounds"]) do
		gpu.setBackground(back)
		for fore, foreValue in pairs(massivSudaPihay["backgrounds"][back]) do
			gpu.setForeground(fore)
			for pixel = 1, #massivSudaPihay["backgrounds"][back][fore] do
				if massivSudaPihay["backgrounds"][back][fore][pixel][3] ~= transparentSymbol then
					gpu.set(massivSudaPihay.x + massivSudaPihay["backgrounds"][back][fore][pixel][1] - 1, massivSudaPihay.y + massivSudaPihay["backgrounds"][back][fore][pixel][2] - 1, massivSudaPihay["backgrounds"][back][fore][pixel][3])
				end
			end
		end
	end
end

--ОГРАНИЧЕНИЕ ДЛИНЫ СТРОКИ
function OS.stringLimit(mode, text, size, noDots)
	if unicode.len(text) <= size then return text end
	local length = unicode.len(text)
	if mode == "start" then
		if noDots then
			return unicode.sub(text, length - size + 1, -1)
		else
			return "…" .. unicode.sub(text, length - size + 2, -1)
		end
	else
		if noDots then
			return unicode.sub(text, 1, size)
		else
			return unicode.sub(text, 1, size - 1) .. "…"
		end
	end
end

--ПОЛУЧИТЬ СПИСОК ФАЙЛОВ ИЗ КОНКРЕТНОЙ ДИРЕКТОРИИ
function OS.getFileList(path)
	local list = fs.list(path)
	local massiv = {}
	for file in list do
		--if string.find(file, "%/$") then file = unicode.sub(file, 1, -2) end
		table.insert(massiv, file)
	end
	list = nil
	return massiv
end

--ПОЛУЧИТЬ ВСЕ ДРЕВО ФАЙЛОВ
function OS.getFileTree(path)
	local massiv = {}
	local list = OS.getFileList(path)
	for key, file in pairs(list) do
		if fs.isDirectory(path.."/"..file) then
			table.insert(massiv, getFileTree(path.."/"..file))
		else
			table.insert(massiv, file)
		end
	end
	list = nil

	return massiv
end

--ПОЛУЧЕНИЕ ФОРМАТА ФАЙЛА
function OS.getFileFormat(path)
	local name = fs.name(path)
	local starting, ending = string.find(name, "(.)%.[%d%w]*$")
	if starting == nil then
		return nil
	else
		return unicode.sub(name,starting + 1, -1)
	end
	name, starting, ending = nil, nil, nil
end

--ПРОВЕРКА, СКРЫТЫЙ ЛИ ФАЙЛ
function OS.isFileHidden(path)
	local name = fs.name(path)
	local starting, ending = string.find(name, "^%.(.*)$")
	if starting == nil then
		return false
	else
		return true
	end
	name, starting, ending = nil, nil, nil
end

--СКРЫТЬ РАСШИРЕНИЕ ФАЙЛА
function OS.hideFileFormat(path)
	local name = fs.name(path)
	local fileFormat = ECSAPI.getFileFormat(name)
	if fileFormat == nil then
		return name
	else
		return unicode.sub(name, 1, unicode.len(name) - unicode.len(fileFormat))
	end
end

function OS.reorganizeFilesAndFolders(massivSudaPihay, showHiddenFiles)
	showHiddenFiles = showHiddenFiles or true
	local massiv = {}
	for i = 1, #massivSudaPihay do
		if OS.isFileHidden(massivSudaPihay[i]) then
			table.insert(massiv, massivSudaPihay[i])
		end
	end
	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka) and OS.getFileFormat(massivSudaPihay[i]) ~= ".app" then
			table.insert(massiv, massivSudaPihay[i])
		end
		cyka = nil
	end
	for i = 1, #massivSudaPihay do
		local cyka = massivSudaPihay[i]
		if (not fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka)) or (fs.isDirectory(cyka) and not ECSAPI.isFileHidden(cyka) and ECSAPI.getFileFormat(massivSudaPihay[i]) == ".app") then
			table.insert(massiv, massivSudaPihay[i])
		end
		cyka = nil
	end

	return massiv
end

--Бесполезна теперь, используй string.gsub()
function OS.stringReplace(stroka, chto, nachto)
	local searchFrom = 1
	while true do
		local starting, ending = string.find(stroka, chto, searchFrom)
		if starting then
			stroka = unicode.sub(stroka, 1, starting - 1) .. nachto .. unicode.sub(stroka, ending + 1, -1)
			searchFrom = ending + unicode.len(nachto) + 1
		else
			break
		end
	end

	return stroka
end

--Ожидание клика либо нажатия какой-либо клавиши
function OS.waitForTouchOrClick()
	while true do
		local e = {event.pull()}
		if e[1] == "key_down" or e[1] == "touch" then break end
	end
end

----------------------------ОКОШЕЧКИ, СУКА--------------------------------------------------


function OS.drawButton(x,y,width,height,text,backColor,textColor)
	x,y = OS.correctStartCoords(x,y,width,height)

	local textPosX = math.floor(x + width / 2 - unicode.len(text) / 2)
	local textPosY = math.floor(y + height / 2)
	OS.square(x,y,width,height,backColor)
	OS.colorText(textPosX,textPosY,textColor,text)

	return x, y, (x + width - 1), (y + height - 1)
end

function OS.drawAdaptiveButton(x,y,offsetX,offsetY,text,backColor,textColor)
	local length = unicode.len(text)
	local width = offsetX*2 + length
	local height = offsetY*2 + 1

	x,y = OS.correctStartCoords(x,y,width,height)

	OS.square(x,y,width,height,backColor)
	OS.colorText(x+offsetX,y+offsetY,textColor,text)

	return x,y,(x+width-1),(y+height-1)
end

function OS.windowShadow(x,y,width,height)
	gpu.setBackground(OS.windowColors.shadow)
	gpu.fill(x+width,y+1,2,height," ")
	gpu.fill(x+1,y+height,width,1," ")
end

--Просто белое окошко безо всего
function OS.blankWindow(x,y,width,height)
	local oldPixels = OS.rememberOldPixels(x,y,x+width+1,y+height)

	OS.square(x,y,width,height,OS.windowColors.background)

	OS.windowShadow(x,y,width,height)

	return oldPixels
end

function OS.emptyWindow(x,y,width,height,title)

	local oldPixels = OS.rememberOldPixels(x,y,x+width+1,y+height)

	--ОКНО
	gpu.setBackground(OS.windowColors.background)
	gpu.fill(x,y+1,width,height-1," ")

	--ТАБ СВЕРХУ
	gpu.setBackground(OS.windowColors.tab)
	gpu.fill(x,y,width,1," ")

	--ТИТЛ
	gpu.setForeground(OS.windowColors.title)
	local textPosX = x + math.floor(width/2-unicode.len(title)/2) -1
	gpu.set(textPosX,y,title)

	--ТЕНЬ
	OS.windowShadow(x,y,width,height)

	return oldPixels

end

function OS.error(...)

	local arg = {...}
	local text = arg[1] or "С твоим компом опять хуйня"
	local buttonText = arg[2] or "ОК"
	local sText = unicode.len(text)
	local xSize, ySize = gpu.getResolution()
	local width = math.ceil(xSize * 3 / 5)
	if (width - 11) > (sText) then width = 11 + sText end
	local textLimit = width - 11

	--Восклицательный знак
	local image = {
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"!"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "}}
	}

	--Парсинг строки ошибки
	local parsedErr = {}
	local countOfStrings = math.ceil(sText / textLimit)
	for i=1, countOfStrings do
		parsedErr[i] = unicode.sub(text, i * textLimit - textLimit + 1, i * textLimit)
	end

	--Расчет высоты
	local height = 6
	if #parsedErr > 1 then height = height + #parsedErr - 1 end

	--Расчет позиции окна
	local xStart,yStart = OS.correctStartCoords("auto","auto",width,height)
	local xEnd,yEnd = xStart + width - 1, yStart + height - 1

	--Рисуем окно
	local oldPixels = OS.emptyWindow(xStart,yStart,width,height," ")

	--Рисуем воскл знак
	OS.drawCustomImage(xStart + 2,yStart + 2,image)

	--Рисуем текст ошибки
	gpu.setBackground(OS.windowColors.background)
	gpu.setForeground(OS.windowColors.usualText)
	local xPos, yPos = xStart + 9, yStart + 2
	for i=1, #parsedErr do
		gpu.set(xPos, yPos, parsedErr[i])
		yPos = yPos + 1
	end

	--Рисуем кнопу
	local xButton = xEnd - unicode.len(buttonText) - 7
	local button = {OS.drawAdaptiveButton(xButton,yEnd - 1,3,0,buttonText,OS.colors.lightBlue,0xffffff)}

	--Ждем
	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if OS.clickedAtArea(e[3],e[4],button[1],button[2],button[3],button[4]) then
				OS.drawAdaptiveButton(button[1],button[2],3,0,buttonText,OS.colors.blue,0xffffff)
				os.sleep(0.4)
				break
			end
		elseif e[1] == "key_down" and e[4] == 28 then
			OS.drawAdaptiveButton(button[1],button[2],3,0,buttonText,OS.colors.blue,0xffffff)
			os.sleep(0.4)
			break	
		end
	end

	--Профит
	OS.drawOldPixels(oldPixels)

end


function OS.prepareToExit(color1, color2)
	OS.clearScreen(color1 or 0x333333)
	gpu.setForeground(color2 or 0xffffff)
	gpu.set(1, 1, "")
end

--А ЭТО КАРОЧ ИЗ ЮНИКОДА В СИМВОЛ - ВРОДЕ РАБОТАЕТ, НО ВСЯКОЕ БЫВАЕТ
function OS.convertCodeToSymbol(code)
	local symbol
	if code ~= 0 and code ~= 13 and code ~= 8 and code ~= 9 and code ~= 200 and code ~= 208 and code ~= 203 and code ~= 205 and not keyboard.isControlDown() then
		symbol = unicode.char(code)
		if keyboard.isShiftPressed then symbol = unicode.upper(symbol) end
	end
	return symbol
end

function OS.progressBar(x, y, width, height, background, foreground, percent)
	local activeWidth = math.ceil(width * percent / 100)
	OS.square(x, y, width, height, background)
	OS.square(x, y, activeWidth, height, foreground)
end

--ВВОД ТЕКСТА ПО ЛИМИТУ ВО ВСЯКИЕ ПОЛЯ - УДОБНАЯ ШТУКА КАРОЧ
function OS.inputText(x, y, limit, cheBiloVvedeno, background, foreground, justDrawNotEvent, maskTextWith)
	limit = limit or 10
	cheBiloVvedeno = cheBiloVvedeno or ""
	background = background or 0xffffff
	foreground = foreground or 0x000000

	gpu.setBackground(background)
	gpu.setForeground(foreground)
	gpu.fill(x, y, limit, 1, " ")

	local text = cheBiloVvedeno

	local function draw()
		term.setCursorBlink(false)

		local dlina = unicode.len(text)
		local xCursor = x + dlina
		if xCursor > (x + limit - 1) then xCursor = (x + limit - 1) end

		if maskTextWith then
			gpu.set(x, y, OS.stringLimit("start", string.rep("●", dlina), limit))
		else
			gpu.set(x, y, OS.stringLimit("start", text, limit))
		end

		term.setCursor(xCursor, y)

		term.setCursorBlink(true)
	end

	draw()

	if justDrawNotEvent then term.setCursorBlink(false); return cheBiloVvedeno end

	while true do
		local e = {event.pull()}
		if e[1] == "key_down" then
			if e[4] == 14 then
				term.setCursorBlink(false)
				text = unicode.sub(text, 1, -2)
				if unicode.len(text) < limit then gpu.set(x + unicode.len(text), y, " ") end
				draw()
			elseif e[4] == 28 then
				term.setCursorBlink(false)
				return text
			else
				local symbol = OS.convertCodeToSymbol(e[3])
				if symbol then
					text = text..symbol
					draw()
				end
			end
		elseif e[1] == "touch" then
			term.setCursorBlink(false)
			return text
		end
	end
end

function OS.selector(x, y, limit, cheBiloVvedeno, varianti, background, foreground, justDrawNotEvent)
	
	local selectionHeight = #varianti
	local oldPixels


	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	local function drawPimpo4ka(color)
		OS.colorTextWithBack(x + limit - 1, y, color, 0xffffff - color, "▼")
	end

	local function drawText(color)
		gpu.setForeground(color)
		gpu.set(x, y, OS.stringLimit("start", cheBiloVvedeno, limit - 1))
	end

	local function drawSelection()
		local yPos = y + 1
		oldPixels = OS.rememberOldPixels(x, yPos, x + limit + 1, yPos + selectionHeight + 1)
		OS.windowShadow(x, yPos, limit, selectionHeight)
		OS.square(x, yPos, limit, selectionHeight, background)

		gpu.setForeground(foreground)
		for i = 1, #varianti do
			gpu.set(x, y + i, varianti[i])
			newObj("selector", varianti[i], x, y + i, x + limit - 1)
		end
	end

	OS.square(x, y, limit, 1, background)
	drawText(foreground)
	drawPimpo4ka(background - 0x555555)

	if justDrawNotEvent then return cheBiloVvedeno end

	drawPimpo4ka(0xffffff)
	drawSelection()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			for key, val in pairs(obj["selector"]) do
				if obj["selector"] and OS.clickedAtArea(e[3], e[4], obj["selector"][key][1], obj["selector"][key][2], obj["selector"][key][3], obj["selector"][key][2]) then
					OS.square(x, obj["selector"][key][2], limit, 1, OS.colors.blue)
					gpu.setForeground(0xffffff)
					gpu.set(x, obj["selector"][key][2], key)
					os.sleep(0.3)
					OS.drawOldPixels(oldPixels)
					cheBiloVvedeno = key
					drawPimpo4ka(background - 0x555555)
					OS.square(x, y, limit - 1, 1, background)
					drawText(foreground)

					return cheBiloVvedeno
				end
			end
		end
	end
end

function OS.input(x, y, limit, title, ...)

	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	local activeData = 1
	local data = {...}

	local sizeOfTheLongestElement = 1
	for i = 1, #data do
		sizeOfTheLongestElement = math.max(sizeOfTheLongestElement, unicode.len(data[i][2]))
	end

	local width = 2 + sizeOfTheLongestElement + 2 + limit + 2
	local height = 2 + #data * 2 + 2

	--ПО ЦЕНТРУ ЭКРАНА, А ТО МАЛО ЛИ ЧЕ
	x, y = OS.correctStartCoords(x, y, width, height)

	local oldPixels = OS.rememberOldPixels(x, y, x + width + 1, y + height)

	OS.emptyWindow(x, y, width, height, title)

	local xPos, yPos

	local function drawElement(i, justDrawNotEvent)
		xPos = x + 2
		yPos = y + i * 2
		local color = 0x666666
		if i == activeData then color = 0x000000 end

		gpu.setBackground(OS.windowColors.background)
		OS.colorText(xPos, yPos, color, data[i][2])

		xPos = (x + width - 2 - limit)

		local data1

		if data[i][1] == "select" or data[i][1] == "selector" or data[i][1] == "selecttion" then
			data1 = OS.selector(xPos, yPos, limit, data[i][3] or "", data[i][4] or {"What?", "Bad API use :("}, 0xffffff, color, justDrawNotEvent)
		else
			data1 = OS.inputText(xPos, yPos, limit, data[i][3] or "", 0xffffff, color, justDrawNotEvent)
		end

		newObj("elements", i, xPos, yPos, xPos + limit - 1)

		return data1
	end

	local coodrs = { OS.drawAdaptiveButton(x + width - 10, y + height - 2, 3, 0, "OK", OS.colors.lightBlue, 0xffffff) }
	newObj("OK", "OK", coodrs[1], coodrs[2], coodrs[3])

	local function pressButton(press, press2)
		if press then
			OS.drawAdaptiveButton(obj["OK"]["OK"][1], obj["OK"]["OK"][2], 3, 0, "OK", press, press2)
		else
			OS.drawAdaptiveButton(obj["OK"]["OK"][1], obj["OK"]["OK"][2], 3, 0, "OK", OS.colors.lightBlue, 0xffffff)
		end
	end

	local function drawAll()
		gpu.setBackground(ECSAPI.windowColors.background)
		for i = 1, #data do
			drawElement(i, true)
		end

		if activeData > #data then
			pressButton(ECSAPI.colors.blue, 0xffffff)
		else
			pressButton(false)
		end
	end

	local function getMassiv()
		local massiv = {}
		for i = 1, #data do
			table.insert(massiv, data[i][3])
		end
		return massiv
	end

	local function drawKaro4()
		if activeData ~= -1 then data[activeData][3] = drawElement(activeData, false) end
	end

	------------------------------------------------------------------------------------------------

	drawAll()
	drawKaro4()
	activeData = activeData + 1
	drawAll()

	while true do

		local e = {event.pull()}
		if e[1] == "key_down" then

			if e[4] == 28 and activeData > #data then pressButton(false); os.sleep(0.2); pressButton(OS.colors.blue, 0xffffff); break end

			if e[4] == 200 and activeData > 1 then activeData = activeData - 1; drawAll() end
			if e[4] == 208 and activeData ~= -1 and activeData <= #data then activeData = activeData + 1; drawAll() end

			if e[4] == 28 then
				drawKaro4()
				if activeData <= #data and activeData ~= -1 then activeData = activeData + 1 end
				drawAll()
			end


			

		elseif e[1] == "touch" then
			for key, val in pairs(obj["elements"]) do
				if OS.clickedAtArea(e[3], e[4], obj["elements"][key][1], obj["elements"][key][2], obj["elements"][key][3], obj["elements"][key][2]) then
					
					if key ~= activeData then activeData = key else drawKaro4(); if activeData <= #data then activeData = activeData + 1 end end

					drawAll()
					
					break
				end
			end

			if OS.clickedAtArea(e[3], e[4], obj["OK"]["OK"][1], obj["OK"]["OK"][2], obj["OK"]["OK"][3], obj["OK"]["OK"][2]) then
				
				if activeData > #data then
					pressButton(false); os.sleep(0.2); pressButton(OS.colors.blue, 0xffffff)
				else
					pressButton(OS.colors.blue, 0xffffff)
					os.sleep(0.3)
				end

				break
			end
		end
	end

	OS.drawOldPixels(oldPixels)

	return getMassiv()
end

function OS.getHDDs()
	local candidates = {}
	for address in component.list("filesystem") do
	  local dev = component.proxy(address)
	  if not dev.isReadOnly() and dev.address ~= computer.tmpAddress() and fs.get(os.getenv("_")).address then
	    table.insert(candidates, dev)
	  end
	end
	return candidates
end

function OS.parseErrorMessage(error, translate)

	local parsedError = {}

	--ПОИСК ЭНТЕРОВ
	local starting, ending, searchFrom = nil, nil, 1
	for i = 1, unicode.len(error) do
		starting, ending = string.find(error, "\n", searchFrom)
		if starting then
			table.insert(parsedError, unicode.sub(error, searchFrom, starting - 1))
			searchFrom = ending + 1
		else
			break
		end
	end

	--На всякий случай, если сообщение об ошибке без энтеров вообще, т.е. однострочное
	if #parsedError == 0 and error ~= "" and error ~= nil and error ~= " " then
		table.insert(parsedError, error)
	end

	--Замена /r/n и табсов
	for i = 1, #parsedError do
		parsedError[i] = string.gsub(parsedError[i], "\r\n", "\n")
		parsedError[i] = string.gsub(parsedError[i], "	", "    ")
	end

	if translate then
		for i = 1, #parsedError do
			parsedError[i] = string.gsub(parsedError[i], "interrupted", "Выполнение программы прервано пользователем")
			parsedError[i] = string.gsub(parsedError[i], " got ", " получена ")
			parsedError[i] = string.gsub(parsedError[i], " expected,", " ожидается,")
			parsedError[i] = string.gsub(parsedError[i], "bad argument #", "Неверный аргумент №")
			parsedError[i] = string.gsub(parsedError[i], "stack traceback", "Отслеживание ошибки")
			parsedError[i] = string.gsub(parsedError[i], "tail calls", "Дочерние функции")
			parsedError[i] = string.gsub(parsedError[i], "in function", "в функции")
			parsedError[i] = string.gsub(parsedError[i], "in main chunk", "в основной программе")
			parsedError[i] = string.gsub(parsedError[i], "unexpected symbol near", "неожиданный символ рядом с")
			parsedError[i] = string.gsub(parsedError[i], "attempt to index", "несуществующий индекс")
			parsedError[i] = string.gsub(parsedError[i], "attempt to get length of", "не удается получить длину")
			parsedError[i] = string.gsub(parsedError[i], ": ", ", ")
			parsedError[i] = string.gsub(parsedError[i], " module ", " модуль ")
			parsedError[i] = string.gsub(parsedError[i], "not found", "не найден")
			parsedError[i] = string.gsub(parsedError[i], "no field package.preload", "не найдена библиотека")
			parsedError[i] = string.gsub(parsedError[i], "no file", "нет файла")
			parsedError[i] = string.gsub(parsedError[i], "local", "локальной")
			parsedError[i] = string.gsub(parsedError[i], "global", "глобальной")
			parsedError[i] = string.gsub(parsedError[i], "no primary", "не найден компонент")
			parsedError[i] = string.gsub(parsedError[i], "available", "в доступе")
			parsedError[i] = string.gsub(parsedError[i], "attempt to concatenate", "не могу присоединить")
		end
	end

	starting, ending = nil, nil

	return parsedError
end

function OS.displayCompileMessage(y, reason, translate, withAnimation)

	local xSize, ySize = gpu.getResolution()

	--Переводим причину в массив
	reason = OS.parseErrorMessage(reason, translate)

	--Получаем ширину и высоту окошка
	local width = math.floor(xSize * 7 / 10)
	local height = #reason + 6
	local textWidth = width - 11

	--Просчет вот этой хуйни, аааахаахах
	local difference = ySize - (height + y)
	if difference < 0 then
		for i = 1, (math.abs(difference) + 1) do
			table.remove(reason, 1)
		end
		table.insert(reason, 1, "…")
		height = #reason + 6
	end

	local x = math.floor(xSize / 2 - width / 2)

	--Иконочка воскл знака на красном фоне
	local errorImage = {
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff,"#"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"!"},{0xff0000,0xffffff," "},{0xff0000,0xffffff,"#"}},
		{{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "},{0xff0000,0xffffff," "}}
	}

	--Запоминаем, че было отображено
	local oldPixels = OS.rememberOldPixels(x, y, x + width + 1, y + height)

	--Типа анимация, ога
	if withAnimation then
		for i = 1, height, 1 do
			OS.square(x, y, width, i, OS.windowColors.background)
			OS.windowShadow(x, y, width, i)
			os.sleep(0.01)
		end
	else
		OS.square(x, y, width, height, OS.windowColors.background)
		OS.windowShadow(x, y, width, height)
	end

	--Рисуем воскл знак
	OS.drawCustomImage(x + 2, y + 1, errorImage)

	--Рисуем текст
	local yPos = y + 1
	local xPos = x + 9
	gpu.setBackground(OS.windowColors.background)

	OS.colorText(xPos, yPos, OS.windowColors.usualText, "Код ошибки:")
	yPos = yPos + 2

	gpu.setForeground( 0xcc0000 )
	for i = 1, #reason do
		gpu.set(xPos, yPos, OS.stringLimit("end", reason[i], textWidth))
		yPos = yPos + 1
	end

	yPos = yPos + 1
	OS.colorText(xPos, yPos, OS.windowColors.usualText, OS.stringLimit("end", "Нажмите любую клавишу, чтобы продолжить", textWidth))

	--Пикаем звуком кароч
	for i = 1, 3 do
		computer.beep(1000)
	end

	--Ждем сам знаешь чего
	OS.waitForTouchOrClick()

	--Рисуем, че было нарисовано
	OS.drawOldPixels(oldPixels)
end

function OS.select(x, y, title, textLines, buttons)

	--Ну обжекты, хули
	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	--Вычисление ширны на основе текста
	local sizeOfTheLongestElement = 0
	for i = 1, #textLines do
		sizeOfTheLongestElement = math.max(sizeOfTheLongestElement, unicode.len(textLines[i][1]))
	end

	local width = sizeOfTheLongestElement + 4

	--Вычисление ширины на основе размера кнопок
	local buttonOffset = 2
	local spaceBetweenButtons = 2

	local sizeOfButtons = 0
	for i = 1, #buttons do
		sizeOfButtons = sizeOfButtons + unicode.len(buttons[i][1]) + buttonOffset * 2 + spaceBetweenButtons
	end

	--Финальное задание ширины и высоты
	width = math.max(width, sizeOfButtons + 2)
	local height = #textLines + 5

	--Рисуем окно
	x, y = OS.correctStartCoords(x, y, width, height)
	local oldPixels = OS.emptyWindow(x, y, width, height, title)

	--Рисуем текст
	local xPos, yPos = x + 2, y + 2
	gpu.setBackground(OS.windowColors.background)
	for i = 1, #textLines do
		OS.colorText(xPos, yPos, textLines[i][2] or OS.windowColors.usualText, textLines[i][1] or "Ну ты че, текст-то введи!")
		yPos = yPos + 1
	end

	--Рисуем кнопочки
	xPos, yPos = x + width - sizeOfButtons, y + height - 2
	for i = 1, #buttons do
		newObj("Buttons", buttons[i][1], OS.drawAdaptiveButton(xPos, yPos, buttonOffset, 0, buttons[i][1], buttons[i][2] or OS.colors.lightBlue, buttons[i][3] or 0xffffff))
		xPos = xPos + buttonOffset * 2 + spaceBetweenButtons + unicode.len(buttons[i][1])
	end

	--Жмякаем на кнопочки
	local action

	while true do
		if action then break end
		local e = {event.pull()}
		if e[1] == "touch" then
			for key, val in pairs(obj["Buttons"]) do
				if OS.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
					OS.drawAdaptiveButton(obj["Buttons"][key][1], obj["Buttons"][key][2], buttonOffset, 0, key, OS.colors.blue, 0xffffff)
					os.sleep(0.3)
					action = key
					break
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				action = buttons[#buttons][1]
				OS.drawAdaptiveButton(obj["Buttons"][action][1], obj["Buttons"][action][2], buttonOffset, 0, action, OS.colors.blue, 0xffffff)
				os.sleep(0.3)
				break
			end
		end
	end

	OS.drawOldPixels(oldPixels)

	return action
end

function OS.askForReplaceFile(path)
	if fs.exists(path) then
		action = OS.select("auto", "auto", " ", {{"Файл \"".. fs.name(path) .. "\" уже имеется в этом месте."}, {"Заменить его перемещаемым объектом?"}}, {{"Оставить оба", 0xffffff, 0x000000}, {"Отмена", 0xffffff, 0x000000}, {"Заменить"}})
		if action == "Оставить оба" then
			return "keepBoth"
		elseif action == "Отмена" then
			return "cancel"
		else
			return "replace"
		end
	end
end

--Переименование файлов для операционки
function OS.rename(mainPath)
	local name = fs.name(mainPath)
	path = fs.path(mainPath)

	--Рисуем окошко ввода нового имени файла
	local inputs = OS.input("auto", "auto", 20, " ", {"input", "Новое имя", name})
	
	--Если ввели в окошко хуйню какую-то
	if inputs[1] == "" or inputs[1] == " " or inputs[1] == nil then
		OS.error("Неверное имя файла.")
	else
		--Получаем новый путь к новому файлу
		local newPath = path..inputs[1]
		--Если файл с новым путем уже существует
		if fs.exists(newPath) then
			OS.error("Файл \"".. name .. "\" уже имеется в этом месте.")
			return
		else
			fs.rename(mainPath, newPath)
		end
	end
end

--Простое информационное окошечко
function OS.info(x, y, title, text)
	x = x or "auto"
	y = y or "auto"
	title = title or " "
	text = text or "Sample text"

	local width = unicode.len(text) + 4
	local height = 4
	x, y = OS.correctStartCoords(x, y, width, height)

	local oldPixels = OS.rememberOldPixels(x, y, x + width + 1, y + height)

	OS.emptyWindow(x, y, width, height, title)
	OS.colorTextWithBack(x + 2, y + 2, OS.windowColors.usualText, OS.windowColors.background, text)

	return oldPixels
end

--Скроллбар вертикальный
function OS.srollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
	local sizeOfScrollBar = math.ceil(1 / countOfAllElements * height)
	local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))

	OS.square(x, y, width, height, backColor)
	OS.square(x, displayBarFrom, width, sizeOfScrollBar, frontColor)

	sizeOfScrollBar, displayBarFrom = nil, nil
end

--Поле с текстом. Сюда пихать массив вида {"строка1", "строка2", "строка3", ...}
function OS.textField(x, y, width, height, lines, displayFrom)
	x, y = OS.correctStartCoords(x, y, width, height)

	local sLines = #lines

	OS.srollBar(x + width - 1, y, 1, height, sLines, displayFrom, OS.windowColors.usualText, OS.colors.lightBlue)

	gpu.setBackground(0xffffff)
	gpu.setForeground(OS.windowColors.usualText)
	local yPos = y
	for i = displayFrom, (displayFrom + height - 1) do
		local line
		if lines[i] then
			local cuttedText = OS.stringLimit("end", lines[i], width - 3)
			line = " " .. cuttedText .. string.rep(" ", width - unicode.len(cuttedText) - 2)
		else
			line = string.rep(" ", width - 1)
		end

		gpu.set(x, yPos, line)

		yPos = yPos + 1
	end

	return sLines
end

function OS.beautifulInput(x, y, width, title, buttonText, back, fore, otherColor, autoRedraw, ...)

	if not width or width < 30 then width = 30 end
	data = {...}
	local sData = #data
	local height = 3 + sData * 3 + 1

	x, y = OS.correctStartCoords(x, y, width, height)
	local xCenter = math.floor(x + width / 2 - 1)

	local oldPixels = OS.rememberOldPixels(x, y, x + width - 1, y + height + 2)
	
	--Рисуем фон
	OS.square(x, y, width, height, back)

	local xText = x + 3
	local inputLimit = width - 6

	--Авторизация
	OS.drawButton(x, y, width, 3, title, back, fore)

	local fields

	local function drawData()
		local i = y + 4

		fields = {}

		for j = 1, sData do
			OS.border(x + 1, i - 1, width - 2, 3, back, fore)

			if data[j][3] == "" or not data[j][3] or data[j][3] == " " then
				OS.colorTextWithBack(xText, i, fore, back, data[j][1])
			else
				if data[j][2] then
					OS.inputText(xText, i, inputLimit, data[j][3], back, fore, true, true)
				else
					OS.inputText(xText, i, inputLimit, data[j][3], back, fore, true)
				end
			end

			table.insert(fields, { x + 1, i - 1, x + inputLimit - 1, i + 1 })

			i = i + 3
		end
	end

	local function getData()
		local massiv = {}
		for i = 1, sData do
			table.insert(massiv, data[i][3])
		end
		return massiv
	end

	drawData()

	--Нижняя кнопа
	local button = { OS.drawButton(x, y + sData * 3 + 4, width, 3, buttonText, otherColor, fore) }

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if OS.clickedAtArea(e[3], e[4], button[1], button[2], button[3], button[4]) then
				OS.drawButton(button[1], button[2], width, 3, buttonText, OS.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then OS.drawOldPixels(oldPixels) end
				return getData()
			end

			for key, val in pairs(fields) do
				if OS.clickedAtArea(e[3], e[4], fields[key][1], fields[key][2], fields[key][3], fields[key][4]) then
					OS.border(fields[key][1], fields[key][2], width - 2, 3, back, otherColor)
					data[key][3] = OS.inputText(xText, fields[key][2] + 1, inputLimit, "", back, fore, false, data[key][2])
					drawData()
					break
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				OS.drawButton(button[1], button[2], width, 3, buttonText, OS.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then OS.drawOldPixels(oldPixels) end
				return getData()
			end
		end
	end

end

function OS.beautifulSelect(x, y, width, title, buttonText, back, fore, otherColor, autoRedraw, ...)
	if not width or width < 30 then width = 30 end
	data = {...}
	local sData = #data
	local height = 3 + sData * 3 + 1

	x, y = OS.correctStartCoords(x, y, width, height)
	local xCenter = math.floor(x + width / 2 - 1)

	local oldPixels = OS.rememberOldPixels(x, y, x + width - 1, y + height + 2)

	--Рисуем фон
	OS.square(x, y, width, height, back)

	local xText = x + 3
	local inputLimit = width - 9

	--Первая кнопа
	OS.drawButton(x, y, width, 3, title, back, fore)

	--Нижняя кнопа
	local button = { OS.drawButton(x, y + sData * 3 + 4, width, 3, buttonText, otherColor, fore) }

	local fields

	local selectedData = 1
	local symbol = "✔"

	--Рисуем данные
	local function drawData()
		local i = y + 4

		fields = {}

		for j = 1, sData do

			--Квадратик для галочки
			OS.border(x + 1, i - 1, 5, 3, back, fore)

			--Галочку рисуем или снимаем
			local text = "  "
			if j == selectedData then text = symbol end
			OS.colorText(x + 3, i, otherColor, text)

			OS.colorText(x + 7, i, fore, OS.stringLimit("end", data[j], inputLimit))

			table.insert(fields, { x + 1, i - 1, x + inputLimit - 1, i + 1 })

			i = i + 3
		end
	end

	drawData()

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then
			if OS.clickedAtArea(e[3], e[4], button[1], button[2], button[3], button[4]) then
				OS.drawButton(button[1], button[2], width, 3, buttonText, OS.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then OS.drawOldPixels(oldPixels) end
				return data[selectedData]
			end

			for key, val in pairs(fields) do
				if OS.clickedAtArea(e[3], e[4], fields[key][1], fields[key][2], fields[key][3], fields[key][4]) then
					selectedData = key
					drawData()
					break
				end
			end
		elseif e[1] == "key_down" then
			if e[4] == 28 then
				OS.drawButton(button[1], button[2], width, 3, buttonText, OS.colors.blue, 0xffffff)
				os.sleep(0.3)
				if autoRedraw then OS.drawOldPixels(oldPixels) end
				return data[selectedData]
			end
		end
	end
end

--Получение верного имени языка. Просто для безопасности.
function OS.getCorrectLangName(pathToLangs)
	local language = _OSLANGUAGE .. ".lang"
	if not fs.exists(pathToLangs .. "/" .. language) then
		language = "English.lang"
	end
	return language
end

--Чтение языкового файла
function OS.readCorrectLangFile(pathToLangs)
	local lang
	
	local language = OS.getCorrectLangName(pathToLangs)

	lang = config.readAll(pathToLangs .. "/" .. language)

	return lang
end

--Описание ниже, ебана
function OS.universalWindow(x, y, width, background, closeWindowAfter, ...)
	local objects = {...}
	local countOfObjects = #objects

	--Задаем высотные константы для объектов
	local objectsHeights = {
		["button"] = 3,
		["centertext"] = 1,
		["emptyline"] = 1,
		["input"] = 3,
	}

	--Считаем высоту этой хуйни
	local height = 0
	for i = 1, countOfObjects do
		local objectType = string.lower(objects[i][1])
		height = height + objectsHeights[objectType]
	end

	--Нужные стартовые прелесссти
	x, y = OS.correctStartCoords(x, y, width, height)
	local oldPixels = OS.rememberOldPixels(x, y, x + width - 1, y + height - 1)

	--Считаем все координаты объектов
	objects[1].y = y
	if countOfObjects > 1 then
		for i = 2, countOfObjects do
			local objectType = string.lower(objects[i - 1][1])
			objects[i].y = objects[i - 1].y + objectsHeights[objectType]
		end
	end

	--Объекты для тача
	local obj = {}
	local function newObj(class, name, ...)
		obj[class] = obj[class] or {}
		obj[class][name] = {...}
	end

	--Отображение объекта по номеру
	local function displayObject(number)
		local objectType = string.lower(objects[number][1])
		if objectType == "button" then
			local back, fore, text = objects[number][2], objects[number][3], objects[number][4]
			newObj("Buttons", text, OS.drawButton(x, objects[number].y, width, objectsHeights.button, text, back, fore))
		elseif objectType == "centertext" then
			local xPos = x + math.floor(width / 2 - unicode.len(objects[number][3]) / 2)
			gpu.setForeground(objects[number][2])
			gpu.set(xPos, objects[number].y, objects[number][3])
		elseif objectType == "input" then
			--Рамочка
			OS.border(x + 1, objects[number].y, width - 2, objectsHeights.input, background, objects[number][2])
			--Текстик
			gpu.set(x + 2, objects[number].y + 1, objects[number][4])
		end
	end

	--Отображение всех объектов
	local function displayAllObjects()
		for i = 1, countOfObjects do
			displayObject(i)
		end
	end

	--Рисуем окно
	OS.square(x, y, width, height, background)
	displayAllObjects()
end
--[[
Функция universalWindow(x, y, width, background, closeWindowAfter, ...)
	Это универсальная модульная функция для максимально удобного и быстрого
	отображения необходимой вам информации. С ее помощью вводить данные
	с клавиатуры, осуществлять выбор из предложенных вариантов, рисовать
	красивые кнопки, отрисовывать обычный текст, отрисовывать текстовые
	поля с возможностью прокрутки, рисовать разделители и прочее.
	Любой объект выделяется с помощью клика мыши, после чего функция
	приступает к работе с этим объектом.

	Аргументы функции:
		x и y:
			Это числа, обозначающие стартовые координаты левого верхнего угла
			данного окна.
			Вместо цифр вы также можете написать "auto" - и программа
			автоматически разместит окно по центру экрана по выбранной
			координате. Или по обеим координатам, если вам угодно.
		
		width:
			Это ширина окна, которую вы можете задать по собственному желанию. 
			Если некторые объекты требуют расширения окна, то окно будет 
			автоматически расширено до нужной ширины. Да, вот такая вот тавтология ;)
		
		background:
			Базовый цвет окна (цвет фона, кому как понятнее).
		
		closeWindowAfter:
			Если true, то окно по завершению функции будет выгружено, а на его месте отрисуются пиксели,
			которые имелись на экране до выполнения функции. Удобно, если не хочешь париться
			с перерисовкой интерфейса.

		...:
			Многоточием тут является перечень объектов, указанных через запятую.
			Каждый объект является массивом и имеет собственный формат.
			Ниже перечислены все типы объектов:
				{"Button", background, foreground, text}
				{"Selector", background, foreground, variant1, variant2, variant3...}
				{"Input", usualColor, selectionColor, textOnStart, maskTextBySymbol}
				{"Select", usualColor, selectionColor, variant1, variant2, variant3...}
				{"TextField", background, foreground, scrollBackColor, scrollFrontColor, strings}
				{"CenterText", textColor, text}
				{"Separator", separatorColor}
				{"EmptyLine"}
			Каждый из объектов рисуется по порядку сверху вниз. Каждый объект автоматически
			увеличивает высоту окна до необходимого значения.

	Что возвращает функция:
		Возвратом является массив, пронумерованный от 1 до <количества объектов>.
		К примеру, 1 индекс данного массива соответствует 1 указанному объекту.
		Каждый индекс данного массива несет в себе какие-то данные, которые вы
		внесли в объект во время работы функции.
		Например, если в 1-ый объект типа "Input" вы ввели фразу "Hello world",
		то первый индекс в возвращенном массиве будет равен "Hello world".
		Конкретнее это будет вот так: massiv[1] = "Hello world".

	Готовые примеры использования функции:
]]

return OS
