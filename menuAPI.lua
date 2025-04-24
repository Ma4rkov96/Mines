local component = require("component")
local gpu       = component.gpu
local pim       = component.pim
local interface = component.me_interface
local event     = require("event")

function payNode(mode, sum)
  local fp, coef = {id="customnpcs:npcMoney", dmg=0}, 1
  local inv = pim.getAllStacks(0)
  if mode=="give" then
    local qty = interface.getItemDetail(fp).basic().qty
    local to  = sum*coef; local g=0
    if qty>=to and 36-#inv>=math.ceil(to/64) then
      if to>64 then
        g = g + interface.exportItem(fp,"UP",to%64).size
        for _=1,math.floor(to/64) do g = g + interface.exportItem(fp,"UP",64).size end
      else
        g = interface.exportItem(fp,"UP",math.floor(to)).size
      end
    end
    return g
  else
    for i=1,pim.getInventorySize() do
      local it = inv[i]
      if it and it.id==fp.id then local t=pim.pushItem("DOWN",i); if t then return t*coef end end
    end
    return 0
  end
end

function drwSelect(btn, on)
  os.sleep(0)
  local cb,cf=gpu.getBackground(),gpu.getForeground()
  if on then gpu.setBackground(colors.win); gpu.setForeground(colors.bg)
  else gpu.setBackground(colors.text_alt); gpu.setForeground(colors.white) end
  gpu.set(32,4,"┌──────────┐"); gpu.set(32,5,"| EMERALDS |"); gpu.set(32,6,"└──────────┘")
  gpu.setBackground(cb); gpu.setForeground(cf)
end

function redirect()
  os.sleep(0)
  local cb,cf=gpu.getBackground(),gpu.getForeground()
  gpu.fill(1,1,60,20," ")
  gpu.set(26,14,"Успешно!")
  gpu.set(21,16,"Перенаправление...")
  gpu.setBackground(cb); gpu.setForeground(cf)
end

function paySystemGUI()
  os.sleep(0)
  local cb,cf=gpu.getBackground(),gpu.getForeground()
  gpu.setResolution(60,20); gpu.setBackground(colors.bg); gpu.setForeground(colors.black)
  gpu.fill(1,1,60,20," ")
  gpu.set(23,2,"Платёжный шлюз")
  gpu.set(27,8,"Сумма:")
  gpu.setBackground(colors.text_alt)
  gpu.set(15,9,"┌────────────────────────────┐")
  gpu.set(15,10,"| 100                        |")
  gpu.set(15,11,"└────────────────────────────┘")
  gpu.setBackground(cb); gpu.setForeground(colors.black)
  gpu.set(8,13,"      Пополнить      ")
  gpu.set(32,13,"      Вывести       ")
  gpu.setBackground(cb); gpu.setForeground(cf)
end

function paySystem()
  local sum="100"; paySystemGUI()
  while true do
    local ev={event.pull()}; local x,y=ev[3],ev[4]
    if ev[1]=="touch" and ev[6]==player.name then
      if x>=8 and x<=28 and y>=13 and y<=15 then
        local t=payNode("take",tonumber(sum))
        if t>0 then
          redirect()
          player.balance[player.mode]=player.balance[player.mode]+t
          balanceWork(player.name,0,"add",t,player.mode,player.balance[player.mode],"payment",0)
          return
        end
      elseif x>=32 and x<=52 and y>=13 and y<=15 then
        local g=payNode("give",tonumber(sum))
        if g>0 then
          redirect()
          player.balance[player.mode]=player.balance[player.mode]-g
          balanceWork(player.name,0,"sub",g,player.mode,player.balance[player.mode],"payment",0)
          return
        end
      elseif x>=24 and x<=37 and y>=17 and y<=19 then
        redirect()
        return
      end
    elseif ev[1]=="player_off" then
      helloMenu()
      loop()
    end
  end
end

function helloMenu()
  os.sleep(0)
  gpu.setResolution(50,6); os.execute("clear")
  gpu.setBackground(colors.black); gpu.setForeground(colors.win)
  gpu.fill(1,1,50,6," ")
  gpu.set(20,2,"МинноеПоле"); gpu.set(16,4,"Чтобы игру начать,"); gpu.set(17,5,"встаньте на PIM!")
end