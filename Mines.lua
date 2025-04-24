local component     = require("component")
local event         = require("event")
local fs            = require("filesystem")
local serialization = require("serialization")

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

function startButton(bcg, frg)
  local cb,cf = gpu.getBackground(), gpu.getForeground()
  gpu.setBackground(bcg); gpu.setForeground(frg)
  gpu.set(13,39, "                    ")
  gpu.set(13,40, "    Начать игру!    ")
  gpu.set(13,41, "                    ")
  gpu.setBackground(cb); gpu.setForeground(cf)
end

function payoutButton(k)
  local cb = gpu.getBackground()
  gpu.setBackground(colors.button)
  if k == "lose" then
    gpu.set(13,34, "                    ")
    gpu.set(13,35, "         ВЫ         ")
    gpu.set(13,36, "     ПРОИГРАЛИ!     ")
    gpu.set(13,37, "                    ")
  else
    gpu.set(13,34, "                    ")
    gpu.set(13,35, "       Забрать      ")
    gpu.set(13,36, "                    ")
    gpu.set(13,37, "                    ")
    gpu.set(17,36, "x" .. tostring(k))
  end
  gpu.setBackground(cb)
end

local dataFile="/user_data.cfg"
local accounts={}
if fs.exists(dataFile) then local f=io.open(dataFile); accounts=serialization.unserialize(f:read("*a")) or {}; f:close() end
local function saveAccounts() local f=io.open(dataFile,"w"); f:write(serialization.serialize(accounts)); f:close() end

function login(name)
  if not accounts[name] then accounts[name]={balance={EMERALD=1000}}; saveAccounts() end
  return {userName=name,userBalanceEMERALD=accounts[name].balance.EMERALD}
end

function balanceWork(name,bet,status,profit,curr,balance,typ,mines)
  accounts[name].balance[curr]=balance; saveAccounts()
end

local function setNil() for i=1,5 do for j=1,5 do squares[i][j][5]=nil; squares[i][j][6]="untouched" end end end
setNil()

local function Square(x,y,col) os.sleep(0); local p=gpu.getForeground(); gpu.setForeground(col); for dy=0,7 do gpu.set(x,y+dy,string.rep("█",16)) end; gpu.setForeground(p) end
local function drawSquares() os.sleep(0); for i=1,5 do for j=1,5 do local s=squares[i][j]; Square(s[1],s[2],colors.button) end end end
local function drawChances(m,ch) os.sleep(0); local cb,cf=gpu.getBackground(),gpu.getForeground(); if m=="draw" then gpu.setForeground(colors.black); for i=1,#ch do gpu.set(50,i*2,"x"..tostring(ch[i])) end else gpu.setBackground(colors.bg); gpu.fill(50,2,8,47," ") end; gpu.setBackground(cb);gpu.setForeground(cf) end
local function mainFrame()
  os.sleep(0);gpu.setResolution(160,50);gpu.setBackground(colors.bg);gpu.fill(1,1,160,50," ");gpu.setForeground(colors.black);
  gpu.fill(48,1,1,50,"█");gpu.fill(1,1,1,50,"█");gpu.fill(159,1,1,50,"█");gpu.fill(1,1,160,1,"█");gpu.fill(1,50,160,1,"█");
  gpu.set(3,3,"Игрок:");gpu.set(3,6,"Баланс EMERALD:");gpu.set(19,23,"Ставка:");gpu.setBackground(colors.button);
  gpu.set(13,24,"┌──┐  ┌──────┐  ┌──┐");gpu.set(13,25,"│-1│  │  2   │  │+1│");gpu.set(13,26,"└──┘  └──────┘  └──┘");
  gpu.setBackground(colors.bg);gpu.set(16,28,"Количество мин:");gpu.setBackground(colors.button);
  gpu.set(13,29,"┌──┐  ┌──────┐  ┌──┐");gpu.set(13,30,"│-1│  │  2   │  │+1│");gpu.set(13,31,"└──┘  └──────┘  └──┘");
  gpu.setBackground(0x99af96);gpu.set(9,43,"                            ");gpu.set(9,44,"      Пополнить/Вывести      ");
  gpu.set(9,45,"                            ");startButton(colors.button,colors.black);drawSquares()
end
local function shuffle(cnt) for _=1,cnt do ::again::; local r,c=math.random(1,5),math.random(1,5); if squares[r][c][5]==nil then squares[r][c][5]=true else goto again end end end

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

player={name="",mode="EMERALD",balance={EMERALD=0}}
helloMenu()
while true do
  local ok,err=pcall(loop)
  if not ok then os.execute("clear");print("Error:",err);os.sleep(5) end
  os.sleep(0)
end