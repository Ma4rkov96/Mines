local component     = require("component")
local event         = require("event")
local fs            = require("filesystem")
local serialization = require("serialization")
local doubleBuffering = require("lib.DoubleBuffering")
local image = require("lib.Image")
local color = require("lib.Color")

local gpu       = component.gpu
local pim       = component.pim
local interface = component.me_interface

dofile("config.lua")
dofile("menuAPI.lua")

local function minesCount(bcg, frg, count)
  local cb,cf = gpu.getBackground(), gpu.getForeground()
  gpu.setBackground(bcg); gpu.setForeground(frg)
  gpu.set(22,30, tostring(count) .. " ")
  gpu.setBackground(cb); gpu.setForeground(cf)
end

local function betCount(bcg, frg, count)
  local cb,cf = gpu.getBackground(), gpu.getForeground()
  gpu.setBackground(bcg); gpu.setForeground(frg)
  gpu.set(22,25, tostring(count) .. " ")
  gpu.setBackground(cb); gpu.setForeground(cf)
end

-- Исправление кнопки "Начать игру" и ошибки drawChances
function startButton(bcg, frg)
  doubleBuffering.drawRectangle(13, 39, 20, 3, bcg, 0x000000, " ")
  doubleBuffering.drawText(15, 40, frg, "Начать игру!")
end

local function drawChances(mode, chances)
  if mode == "draw" then
    for i, chance in ipairs(chances) do
      doubleBuffering.drawText(50, i * 2, colors.white, "x" .. tostring(chance))
    end
  elseif mode == "clean" then
    doubleBuffering.drawRectangle(50, 2, 8, 47, colors.bg, 0x000000, " ")
  end
end

-- Установить значения по умолчанию для ставки и количества мин
local count, bet = 2, 2

local function setNil() for i=1,5 do for j=1,5 do squares[i][j][5]=nil; squares[i][j][6]="untouched" end end end
setNil()

local diamondImage = image.load("/images/diamond.pic")
local bombImage = image.load("/images/boomb.pic")

-- Исправление отрисовки клеток
local function Square(x, y, state)
  os.sleep(0)
  if state == "untouched" then
    doubleBuffering.drawRectangle(x, y, 16, 8, colors.button, 0x000000, " ")
  elseif state == "touched_no_mine" then
    doubleBuffering.drawImage(x, y, diamondImage)
  elseif state == "touched_mine" then
    doubleBuffering.drawImage(x, y, bombImage)
  end
end

local function drawSquares()
  os.sleep(0)
  for i = 1, 5 do
    for j = 1, 5 do
      local s = squares[i][j]
      local state = s[6] == "untouched" and "untouched" or (s[5] and "touched_mine" or "touched_no_mine")
      Square(s[1], s[2], state)
    end
  end
end

-- Исправление интерфейса
local function enhancedMainFrame()
  doubleBuffering.setResolution(160, 50)
  doubleBuffering.clear(colors.bg)

  -- Нарисовать границы
  doubleBuffering.drawRectangle(1, 1, 160, 50, colors.bg, 0x000000, " ")

  -- Нарисовать заголовки
  doubleBuffering.drawText(3, 3, colors.white, "Игрок:")
  doubleBuffering.drawText(3, 4, colors.text_alt, player.name)
  doubleBuffering.drawText(3, 6, colors.white, "Баланс EMERALD:")
  doubleBuffering.drawText(3, 7, colors.text_alt, tostring(player.balance[player.mode]))

  -- Подписи для ставок и количества мин
  doubleBuffering.drawText(13, 22, colors.white, "Ставка:")
  doubleBuffering.drawText(13, 27, colors.white, "Кол-во мин:")

  -- Нарисовать кнопки ставок
  doubleBuffering.drawRectangle(13, 24, 5, 3, colors.button, 0x000000, " ")
  doubleBuffering.drawText(15, 25, colors.black, "-1")
  doubleBuffering.drawRectangle(18, 24, 10, 3, colors.bg, 0x000000, " ")
  doubleBuffering.drawText(22, 25, colors.white, tostring(bet))
  doubleBuffering.drawRectangle(28, 24, 5, 3, colors.button, 0x000000, " ")
  doubleBuffering.drawText(30, 25, colors.black, "+1")

  -- Нарисовать кнопки количества мин
  doubleBuffering.drawRectangle(13, 29, 5, 3, colors.button, 0x000000, " ")
  doubleBuffering.drawText(15, 30, colors.black, "-1")
  doubleBuffering.drawRectangle(18, 29, 10, 3, colors.bg, 0x000000, " ")
  doubleBuffering.drawText(22, 30, colors.white, tostring(count))
  doubleBuffering.drawRectangle(28, 29, 5, 3, colors.button, 0x000000, " ")
  doubleBuffering.drawText(30, 30, colors.black, "+1")

  -- Нарисовать нижнюю панель
  doubleBuffering.drawRectangle(9, 43, 40, 3, colors.button, 0x000000, " ")
  doubleBuffering.drawText(11, 44, colors.black, "Пополнить/Вывести")

  -- Кнопка начать игру
  startButton(colors.button, colors.black)

  -- Отрисовать клетки
  drawSquares()

  doubleBuffering.drawChanges()
end

mainFrame = enhancedMainFrame

-- Восстановление функции payoutButton
function payoutButton(k)
  local cb = gpu.getBackground()
  gpu.setBackground(colors.button)
  if k == "lose" then
    gpu.set(13, 34, "                    ")
    gpu.set(13, 35, "         ВЫ         ")
    gpu.set(13, 36, "     ПРОИГРАЛИ!     ")
    gpu.set(13, 37, "                    ")
  else
    gpu.set(13, 34, "                    ")
    gpu.set(13, 35, "       Забрать      ")
    gpu.set(13, 36, "                    ")
    gpu.set(13, 37, "                    ")
    gpu.set(17, 36, "x" .. tostring(k))
  end
  gpu.setBackground(cb)
end

local function shuffle(cnt)
  tbl = chances(cnt) -- Убедиться, что tbl корректно инициализирована
  for _ = 1, cnt do
    ::again::
    local r, c = math.random(1, 5), math.random(1, 5)
    if squares[r][c][5] == nil then
      squares[r][c][5] = true
    else
      goto again
    end
  end
end

function loop()
  local count, inGame, tbl, wins, bet = 2,false,{},0,2
  while true do
    local ev={event.pull()}
    if ev[1]=="player_on" then
      local r=login(ev[2])
      player.name=r.userName
      player.balance.EMERALD=r.userBalanceEMERALD
      inGame=false
      wins=0
      bet=2
      count=2
      mainFrame()
      gpu.set(3,4,player.name)
      gpu.set(3,7,tostring(player.balance[player.mode]))
    elseif ev[1]=="touch" and ev[6]==player.name then
      local x,y=ev[3],ev[4]
      if inGame then
        local col=math.floor((x-68)/18)+1
        local row=math.floor((y-4)/9)+1
        if x>=13 and x<=33 and y>=34 and y<=37 then
          gpu.set(3,7,"        ")
          player.balance[player.mode]=player.balance[player.mode]+bet*tbl[wins]
          gpu.set(3,7,tostring(player.balance[player.mode]))
          balanceWork(player.name,bet,"win",bet*(tbl[wins]-1),player.mode,player.balance[player.mode],"game"..player.mode,count)
          inGame=false
          wins=0
          setNil()
          drawChances("clean")
          startButton(colors.button,colors.black)
        elseif col>=1 and col<=5 and row>=1 and row<=5 and squares[row][col][6]=="untouched" then
          if squares[row][col][5]==nil then
            Square(squares[row][col][1],squares[row][col][2],colors.win)
            if wins~=0 then gpu.set(50,wins*2," ") end
            gpu.set(50,(wins+1)*2,"→")
            wins=wins+1
            squares[row][col][6]="touched"
            payoutButton(tbl[wins])
          else
            Square(squares[row][col][1],squares[row][col][2],colors.lose)
            payoutButton("lose")
            wins=0
            setNil()
            inGame=false
            drawChances("clean")
            gpu.set(3,7,"        ")
            player.balance[player.mode]=player.balance[player.mode]-bet
            gpu.set(3,7,tostring(player.balance[player.mode]))
            balanceWork(player.name,bet,"lose",0,player.mode,player.balance[player.mode],"game"..player.mode,count)
            startButton(colors.button,colors.black)
          end
        end
      else
        if x>=13 and x<=33 and y>=39 and y<=41 and player.balance[player.mode]>=bet then
          startButton(colors.button_clicked,colors.text_alt)
          shuffle(count)
          drawSquares()
          tbl=chances(count)
          drawChances("draw",tbl)
          inGame=true
        elseif x>=13 and x<=17 and y>=29 and y<=31 and count>2 then
          count=count-1
          minesCount(colors.button,colors.black,count)
        elseif x>=30 and x<=34 and y>=29 and y<=31 and count<24 then
          count=count+1
          minesCount(colors.button,colors.black,count)
        elseif x>=30 and x<=34 and y>=24 and y<=26 and bet<10 then
          bet=bet+1
          betCount(colors.button,colors.black,bet)
        elseif x>=13 and x<=17 and y>=24 and y<=26 and bet>1 then
          bet=bet-1
          betCount(colors.button,colors.black,bet)
        elseif x>=16 and x<=44 and y>=43 and y<=45 then
          paySystem()
          inGame=false
          bet=2
          wins=0
          count=2
          mainFrame()
          gpu.set(3,4,player.name)
          gpu.set(3,7,tostring(player.balance[player.mode]))
        end
      end
    elseif ev[1]=="player_off" then
      helloMenu()
    end
  end
end

-- Восстановление функции login
local dataFile = "/user_data.cfg"
local accounts = {}
if fs.exists(dataFile) then
  local f = io.open(dataFile, "r")
  accounts = serialization.unserialize(f:read("*a")) or {}
  f:close()
end

local function saveAccounts()
  local f = io.open(dataFile, "w")
  f:write(serialization.serialize(accounts))
  f:close()
end

function login(name)
  if not accounts[name] then
    accounts[name] = {balance = {EMERALD = 1000}}
    saveAccounts()
  end
  return {userName = name, userBalanceEMERALD = accounts[name].balance.EMERALD}
end

player={name="",mode="EMERALD",balance={EMERALD=0}}
helloMenu()
while true do
  local ok,err=pcall(loop)
  if not ok then os.execute("clear");print("Error:",err);os.sleep(5) end
  os.sleep(0)
end