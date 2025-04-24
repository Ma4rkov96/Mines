local component = require("component")
local internet = component.internet
local filesystem = require("filesystem")

-- URL репозитория на GitHub
local repoURL = "https://raw.githubusercontent.com/Ma4rkov96/Mines/main/"

-- Список файлов для загрузки
local files = {
    "config.lua",
    "menuAPI.lua",
    "Mines.lua",
    "serverAPI.lua",
    "lib/AdvancedLua.lua",
    "lib/Color.lua",
    "lib/DoubleBuffering.lua",
    "lib/Image.lua",
    "lib/OCIF.lua"
}

-- Функция для загрузки файла
local function downloadFile(url, path)
    local handle, reason = internet.request(url)
    if not handle then
        error("Failed to connect to " .. url .. ": " .. reason)
    end

    local file, reason = io.open(path, "w")
    if not file then
        error("Failed to open file " .. path .. " for writing: " .. reason)
    end

    local content = ""
    while true do
        local chunk = handle.read(math.huge) -- Чтение данных блоками
        if not chunk then break end
        content = content .. chunk
    end

    file:write(content)
    file:close()
    handle:close() -- Закрытие соединения
end

-- Загрузка всех файлов
for _, file in ipairs(files) do
    local url = repoURL .. file
    local path = filesystem.concat("/", file)

    -- Создание директорий, если их нет
    filesystem.makeDirectory(filesystem.path(path))

    print("Downloading " .. file .. "...")
    downloadFile(url, path) -- Ожидание завершения загрузки текущего файла
end

print("All files downloaded successfully!")