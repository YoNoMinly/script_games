---@diagnostic disable: undefined-global


--5.0 Wersja na iOS lub Android z implementacją touch zamiast klawiatury

local currentPiece = nil
local dropTimer = 0
local dropInterval = 0.5
local gameBoard = {}
local fastDropTimer = 0
local fastDropInterval = 0.05
local playerName = ""
local inputActive = true
local leaderboard = {}
local showLeaderboard = false
local clearedBlocks = {}
local hasSave = false
local askToContinue = false
local boardWidth = 10
local boardHeight = 20
local gameOver = false
local score = 0
local gameTime = 0
local blockClearSound


for y = 1, boardHeight do
    gameBoard[y] = {}
    for x = 1, boardWidth do
        gameBoard[y][x] = 0
    end
end




function table.show(t, name, indent)
    local cart     -- a container
    local autoref  -- for self references

    local function isemptytable(t) return next(t) == nil end

    local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
        local info = debug.getinfo(o, "S")
        -- info.name is nil because o is not a calling level
        if info.what == "C" then
          return string.format("%q", so .. ", C function")
        else 
          -- the information is defined through lines
          return string.format("%q", so .. ", defined in (" ..
              info.linedefined .. "-" .. info.lastlinedefined ..
              ")" .. info.source)
        end
      elseif type(o) == "number" or type(o) == "boolean" then
        return so
      else
        return string.format("%q", so)
      end
    end

    local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
        cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
        if saved[value] then
          cart = cart .. " = {}; -- " .. saved[value] 
                      .. " (self reference)\n"
          autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
        else
          saved[value] = name
          -- If this is an empty table, simply add it and return
          if isemptytable(value) then
            cart = cart .. " = {};\n"
          else
            cart = cart .. " = {\n"
            for k, v in pairs(value) do
              k = basicSerialize(k)
              local fname = string.format("%s[%s]", name, k)
              field = string.format("[%s]", k)
              -- three spaces between levels
              addtocart(v, fname, indent .. "   ", saved, field)
            end
            cart = cart .. indent .. "};\n"
          end
        end
      end
    end

    name = name or "__unnamed__"
    if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
    end
    cart, autoref = "", ""
    addtocart(t, name, indent)
    return cart .. autoref
end


function loadLeaderboard()
    leaderboard = {}
    if love.filesystem.getInfo("leaderboard.txt") then
        for line in love.filesystem.lines("leaderboard.txt") do
            local name, score = line:match("^(.-),(%d+)$")
            table.insert(leaderboard, { name = name, score = tonumber(score) })
        end
        table.sort(leaderboard, function(a, b) return a.score > b.score end)
    end
end

function saveLeaderboard()
    table.insert(leaderboard, { name = playerName, score = score })
    table.sort(leaderboard, function(a, b) return a.score > b.score end)
    local data = ""
    for i, entry in ipairs(leaderboard) do
        if i > 10 then break end
        data = data .. entry.name .. "," .. entry.score .. "\n"
    end
    love.filesystem.write("leaderboard.txt", data)
end

function filter(tbl, func)
    local newTbl = {}
    for i = 1, #tbl do
        if func(tbl[i], i) then
            table.insert(newTbl, tbl[i])
        end
    end
    return newTbl
end

function love.load()
    love.keyboard.setKeyRepeat(true)
    loadLeaderboard()
    blockClearSound = love.audio.newSource("sound_eff.mp3", "static")
    local currentWidth, currentHeight = love.graphics.getDimensions()
    love.window.setMode(currentWidth / 2, currentHeight, {resizable = false})


end

function love.textinput(text)
    if inputActive and #playerName < 12 then
        playerName = playerName .. text
    end
end

function rotatePiece(piece)
    local newShape = {}
    for y = 1, #piece.shape[1] do
        newShape[y] = {}
        for x = 1, #piece.shape do
            newShape[y][x] = piece.shape[#piece.shape - x + 1][y]
        end
    end
    return newShape
end

function createNewPiece()
    local shapes = {
        {{1, 1, 1, 1}},
        {{1, 1}, {1, 1}},
        {{0, 1, 0}, {1, 1, 1}},
        {{1, 1, 0}, {0, 1, 1}},
        {{0, 1, 1}, {1, 1, 0}},
    }
    local shapeWeights = {1, 1, 1, 0.2, 1}
    local shapeIndex = weightedRandom(shapeWeights)
    local shape = shapes[shapeIndex]
    currentPiece = { x = 5, y = 1, shape = shape }
end

function weightedRandom(weights)
    local totalWeight = 0
    for _, w in ipairs(weights) do totalWeight = totalWeight + w end
    local r = math.random() * totalWeight
    local sum = 0
    for i, w in ipairs(weights) do
        sum = sum + w
        if r <= sum then return i end
    end
end

function canMoveDown(piece)
    for y = 1, #piece.shape do
        for x = 1, #piece.shape[y] do
            if piece.shape[y][x] == 1 then
                local newY = piece.y + y
                local newX = piece.x + x - 1
                if newY > boardHeight-1 or gameBoard[newY][newX] == 1 then
                    return false
                end
            end
        end
    end
    return true
end

function canMoveLeft(piece)
    for y = 1, #piece.shape do
        for x = 1, #piece.shape[y] do
            if piece.shape[y][x] == 1 then
                local newX = piece.x + x - 2
                local newY = piece.y + y - 1
                if newX < 1 or gameBoard[newY][newX] == 1 then
                    return false
                end
            end
        end
    end
    return true
end

function canMoveRight(piece)
    for y = 1, #piece.shape do
        for x = 1, #piece.shape[y] do
            if piece.shape[y][x] == 1 then
                local newX = piece.x + x
                local newY = piece.y + y - 1
                if newX > boardWidth or gameBoard[newY][newX] == 1 then
                    return false
                end
            end
        end
    end
    return true
end

function clearFullLines()
    local newBoard = {}
    local linesCleared = 0
    clearedBlocks = {}

    for y = boardHeight, 1, -1 do
        local full = true
        for x = 1, boardWidth do
            if gameBoard[y][x] == 0 then
                full = false
                break
            end
        end
        if not full then
            table.insert(newBoard, 1, gameBoard[y])
        else
            linesCleared = linesCleared + 1
            for x = 1, boardWidth do
                -- Ефект розльоту
                local direction = math.random() < 0.5 and -1 or 1
                table.insert(clearedBlocks, {
                    x = (x - 1) * 30,
                    y = (y - 1) * 30,
                    vx = direction * math.random(100, 300), -- швидкість X
                    vy = -math.random(100, 200),           -- швидкість Y (вгору)
                    alpha = 1,
                    timer = 0
                })
            end
        end
    end

    for _ = 1, linesCleared do
        local emptyLine = {}
        for x = 1, boardWidth do
            emptyLine[x] = 0
        end
        table.insert(newBoard, 1, emptyLine)
    end

    gameBoard = newBoard

    if linesCleared > 0 then
        score = score + 1000 * linesCleared + (linesCleared > 1 and 500 or 0)
        if blockClearSound then blockClearSound:play() end
    end
end


function checkGameOver()
    for x = 1, boardWidth do
        if gameBoard[1][x] == 1 then return true end
    end
    return false
end

function love.update(dt)
    if inputActive or showLeaderboard then return end
    if gameOver then return end

    gameTime = gameTime + dt
    fastDropTimer = fastDropTimer + dt

    if love.keyboard.isDown("down") then
        if fastDropTimer >= fastDropInterval then
            dropPiece()
            fastDropTimer = 0
        end
    else
        dropTimer = dropTimer + dt
        if dropTimer >= dropInterval then
            dropPiece()
            dropTimer = 0
        end
    end
    for _, block in ipairs(clearedBlocks) do
    block.timer = block.timer + dt
    block.x = block.x + block.vx * dt
    block.y = block.y + block.vy * dt
    block.alpha = 1 - block.timer / 1.0 -- плавне зникнення
    end
    clearedBlocks = filter(clearedBlocks, function(b) return b.timer < 1.0 end)

    for i = #clearedBlocks, 1, -1 do
        local b = clearedBlocks[i]
        b.alpha = b.alpha - dt * 2
        if b.alpha <= 0 then
            table.remove(clearedBlocks, i)
        end
    end


end

function dropPiece()
    if currentPiece then
        if canMoveDown(currentPiece) then
            currentPiece.y = currentPiece.y + 1
        else
            for y = 1, #currentPiece.shape do
                for x = 1, #currentPiece.shape[y] do
                    if currentPiece.shape[y][x] == 1 then
                        gameBoard[currentPiece.y + y - 1][currentPiece.x + x - 1] = 1
                    end
                end
            end
            clearFullLines()
            if checkGameOver() then gameOver = true else createNewPiece() end
        end
    else
        createNewPiece()
    end
end

function saveGame()
    -- Створення файлу та відкриття для запису
    local fileName = "savegame.lua"

    -- Перевіряємо, чи існує вже файл, якщо ні - створюємо його
    local file = love.filesystem.newFile(fileName)

    -- Відкриваємо файл для запису
    if file:open('w') then
        -- Основні дані
        file:write((playerName or "Unknown") .. "\n")
        file:write((score or 0) .. "\n")
        file:write((love.timer.getTime() or 0) .. "\n")

        -- Перевірка на існування currentPiece
        if currentPiece then
            -- Позиція блоку та час
            file:write((currentPiece.x or 0) .. "\n")
            file:write((currentPiece.y or 0) .. "\n")
            file:write((gameTime or 0) .. "\n")

            -- Поточна фігура
            if currentPiece.shape then
                for i = 1, #currentPiece.shape do
                    for j = 1, #currentPiece.shape[i] do
                        file:write((currentPiece.shape[i][j] or 0) .. " ")
                    end
                    file:write("\n")
                end
            end
        else
            print("Немає поточної фігури!")
        end

        -- Поле гри
        if gameBoard then
            for i = 1, #gameBoard do
                for j = 1, #gameBoard[i] do
                    file:write((gameBoard[i][j] or 0) .. " ")  -- Запис кожного елементу
                end
                file:write("\n")
            end
        else
            file:write("NO_GAMEBOARD\n")
        end

        file:close()  -- Закриваємо файл після запису
    else
        print("Не вдалося відкрити файл для запису!")
    end
end

function love.keypressed(key)

    if inputActive then
        if key == "backspace" then
            playerName = playerName:sub(1, -2)
        elseif key == "return" and playerName ~= "" then
            inputActive = false
            gameOver = false
            score = 0
            gameTime = 0
            currentPiece = nil
            for y = 1, boardHeight do
                for x = 1, boardWidth do
                    gameBoard[y][x] = 0
                end
            end
            createNewPiece()
        end
        return
    end

    if showLeaderboard then
        if key == "return" then
            showLeaderboard = false
            inputActive = true
            playerName = ""
            score = 0
            gameTime = 0
            gameOver = false
            currentPiece = nil
            for y = 1, boardHeight do
                for x = 1, boardWidth do
                    gameBoard[y][x] = 0
                end
            end
        end
        return
    end

    if gameOver and key == "return" then
        saveLeaderboard()
        showLeaderboard = true
        return
    end

    if currentPiece then
        if key == "left" and canMoveLeft(currentPiece) then currentPiece.x = currentPiece.x - 1 end
        if key == "right" and canMoveRight(currentPiece) then currentPiece.x = currentPiece.x + 1 end
        if key == "space" then currentPiece.shape = rotatePiece(currentPiece) end
    end
end

function drawLeaderboard()
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("LEADERBOARD", 0, 20, love.graphics.getWidth(), "center")
    for i, entry in ipairs(leaderboard) do
        local text = string.format("%d. %s - %d", i, entry.name, entry.score)
        love.graphics.print(text, love.graphics.getWidth() / 2 - 100, 40 + i * 25)
    end
end

function love.quit()
    saveGame()
end

function love.draw()
    if inputActive then
        love.graphics.print("Enter your name:\n " .. playerName, 100, 100)
        return
    end

    if showLeaderboard then
        drawLeaderboard()
        return
    end

    for _, block in ipairs(clearedBlocks) do
    love.graphics.setColor(1, 1, 1, block.alpha)
    love.graphics.rectangle("fill", block.x, block.y, 30, 30)
    end
    love.graphics.setColor(1, 1, 1, 1)

    for y = 1, boardHeight do
        for x = 1, boardWidth do
            if gameBoard[y][x] == 1 then
                love.graphics.rectangle("fill", x * 30, y * 30, 28, 28)
            end
        end
    end

    if currentPiece then
        for y = 1, #currentPiece.shape do
            for x = 1, #currentPiece.shape[y] do
                if currentPiece.shape[y][x] == 1 then
                    love.graphics.rectangle("fill", (currentPiece.x + x - 1) * 30, (currentPiece.y + y - 1) * 30, 28, 28)
                    love.graphics.print("Score:\n " .. score, 320, 10)
                end
            end
        end
    end
    

    if gameOver then
        love.graphics.setColor(1, 0, 0, 1) -- червоний (R=1, G=0, B=0, A=1)
        local font = love.graphics.newFont(48) -- великий розмір шрифту 
        love.graphics.setFont(font)
        love.graphics.printf("GAME OVER\nPress Enter\n Score:"..score, 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1, 1)
    end
end
