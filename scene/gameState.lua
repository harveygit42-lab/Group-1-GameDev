--[[
    Game State Module
    Handles loading and saving game state (high scores, settings, etc.)
]]

local gameState = {}

-- =====================================================
-- HIGH SCORE FUNCTIONS
-- =====================================================

function gameState.loadHighScore()
    local path = system.pathForFile("highscore.txt", system.DocumentsDirectory)
    local file = io.open(path, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        local n = tonumber(contents)
        return n or 0
    end
    return 0
end

function gameState.saveHighScore(value)
    if not value then value = 0 end
    local path = system.pathForFile("highscore.txt", system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        file:write(tostring(value))
        io.close(file)
        return true
    end
    return false
end

-- =====================================================
-- MUSIC SETTING FUNCTIONS
-- =====================================================

function gameState.loadMusicSetting()
    local path = system.pathForFile("music_setting.txt", system.DocumentsDirectory)
    local file = io.open(path, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        if contents == "false" then return false end
        return true
    end
    return true
end

function gameState.saveMusicSetting(value)
    if value == nil then value = true end
    local path = system.pathForFile("music_setting.txt", system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        file:write(tostring(value))
        io.close(file)
        return true
    end
    return false
end

-- =====================================================
-- TIMER SETTING FUNCTIONS
-- =====================================================

function gameState.loadTimerSetting()
    local path = system.pathForFile("timer_setting.txt", system.DocumentsDirectory)
    local file = io.open(path, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        local n = tonumber(contents)
        if n and n >= 1 and n <= 5 then return n end
    end
    return 1
end

function gameState.saveTimerSetting(value)
    if not value or value < 1 or value > 5 then value = 1 end
    local path = system.pathForFile("timer_setting.txt", system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        file:write(tostring(value))
        io.close(file)
        return true
    end
    return false
end

-- =====================================================
-- SFX SETTING FUNCTIONS
-- =====================================================

function gameState.loadSfxSetting()
    local path = system.pathForFile("sfx_setting.txt", system.DocumentsDirectory)
    local file = io.open(path, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        if contents == "false" then return false end
        return true
    end
    return true
end

function gameState.saveSfxSetting(value)
    if value == nil then value = true end
    local path = system.pathForFile("sfx_setting.txt", system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        file:write(tostring(value))
        io.close(file)
        return true
    end
    return false
end

return gameState
