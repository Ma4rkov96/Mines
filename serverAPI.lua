local internet = require("component").internet
local serverAddress = "212.118.38.128:3030"
local privateKey = "1234"

function customError(err)
    gpu.set(70, 25, "Все пошло по пизде! Ошибка" .. err)
    return nil
end

local function socketReConnectWrite(msg)
    
    if socket ~= nil then
        if socket.write("") == nil then socket = nil end
    end
    local i = 0
    ::reCon::
    if socket == nil or i <= 2 and i ~= 0 then socket = internet.connect(serverAddress) end
    socket.read() 
    socket.read() 
    if socket.read() == nil then
        if i >= 2 then
            socket = nil
            return nil, "Socket connection init fail"
        end
        if i >= 1 then sleep(6) end
        i = i + 1
        goto reCon
    end

    i = 0
    repeat
        local bW = socket.write(msg)
        if not bW then
            socket = nil
            return nil, "Err to write msg, connection lost"
        elseif bW > 0 then
            break
        elseif i >= 5 then
            socket = nil
            return nil, "Err to write msg, die timeout"
        end
        i = i + 1
    until bW > 0
    return "", ""
end

local socketRequest = function(msg)
    local status, errMsg = socketReConnectWrite(msg)
    if status == nil then
        return status, errMsg
    end
    local i = 0
    local bR = ""
    repeat
        bR = socket.read()
        if bR ~= nil and bR ~= "" then
            break
        end
        if bR == nil then
            socket = nil
            return nil, "Lost connection while read answer"
        end
        i = i + 1
    until i >= 600
    if i >= 600 then return nil, "Err to read msg, die timeout" else return bR end
end

local function execute(data, stdin)
    local c, err = load(data, stdin, "t")

    if not c and err then
        customError(err)
    else
        local result = table.pack(xpcall(c, debug.traceback))
        local success = table.remove(result, 1)
        result.n = result.n - 1

        if not success then
            customError(result[1])
        elseif result.n > 0 then
            return table.unpack(result, 1, result.n)
        end
    end
end

login = function(name)
    if name ~= nil and name ~= "no such component" then
        
        local socketRespone, errMsg = socketRequest('{"key": "1234", "method": "login", "where": "server", "terminalID": "casino", "userName": "'..name..'"}')

        if socketRespone == nil then

            gpu.set(70, 25, "Ошибка соединения с сервером!")
            return nil

        end

        local response = execute(socketRespone, "login")
        return response
    end
end

balanceWork = function(name, bet, status, profit, currency, balance, type, mines)
    return socketRequest(
        '{"key": "1234", "method": "updateUserBalance_cas", "where": "server", "userName": "' .. name ..
        '", "userBalance": "'  .. tostring(balance) .. 
        '", "type": "' .. type ..
        '", "currency": "' .. currency ..
        '", "bet": "' .. tostring(bet) ..
        '", "status": "' .. status ..
        '", "mines": "' .. tostring(mines) ..
        '", "profit": "' .. tostring(profit) .. '"}')
end