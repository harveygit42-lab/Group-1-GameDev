--yasmien final
local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")
local settings = require("setting.settings")

physics.start()
physics.pause()

-- =====================================================
-- GLOBAL VARIABLES
-- =====================================================

local backgroundMusic
local bgChannel
local popSound
local tapCount = 0
local gameOver = false
local gameStarted = false
local timerMinutes = 1
local timerSeconds = 0
local timerHandle
local timerCleared = false
local highScore = 0
local musicOn = true
local sfxOn = true

-- Difficulty and bird spawning variables
local difficulty = "None"
local birds = {}
local spawnHandle = nil
local birdSpeed = 150

-- Display objects
local background
local platform
local tapText
local balloon
local screenShadow
local startButtonGroup
local extraButtonGroup
local gameOverText
local timeUpText
local scoreText
local highScoreText
local restartButton
local backButton
local quitButton
local menuButtonGroup
local timerText

-- forward-declare restartGame for callback scope
local restartGame
local startPlaying
local startInstructionText
local startTapListener

-- =====================================================
-- LOAD AND SAVE FUNCTIONS
-- =====================================================

local function loadHighScore()
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

local function saveHighScore(value)
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

local function loadMusicSetting()
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

local function saveMusicSetting(value)
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

local function loadTimerSetting()
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

local function saveTimerSetting(value)
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

local function loadSfxSetting()
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

local function saveSfxSetting(value)
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

-- =====================================================
-- AUDIO MANAGEMENT
-- =====================================================

local function stopMusic()
    if bgChannel then
        audio.stop(bgChannel)
        bgChannel = nil
    end
end

local function playMusic()
    stopMusic()
    if musicOn and backgroundMusic then
        bgChannel = audio.play(backgroundMusic, {loops = -1, channel = 1})
        return true
    end
    return false
end

local function loadBackgroundMusic()
    if backgroundMusic then return true end
    local ok, m = pcall(function() return audio.loadStream("bgmusic/bgmusic.mp3") end)
    if ok and m then
        backgroundMusic = m
        return true
    end
    return false
end

local function loadPopSound()
    if popSound then return true end
    local ok, sound = pcall(function() return audio.loadSound("bgmusic/pop.mp3") end)
    if ok and sound then
        popSound = sound
        return true
    end
    return false
end

local function playPopSound()
    if sfxOn and popSound then
        pcall(function() audio.play(popSound) end)
    end
end

-- =====================================================
-- BIRD SPAWNING FUNCTIONS
-- =====================================================

local function removeBird(bird)
    if bird then
        pcall(function()
            if bird.body then physics.removeBody(bird.body) end
            display.remove(bird)
        end)
    end
end

local function clearAllBirds()
    for i = 1, #birds do
        removeBird(birds[i])
    end
    birds = {}
end

local function spawnBird()
    if gameOver or not gameStarted then return end
    
    local sceneGroup = scene.view
    local side = math.random(1, 2)
    local startX = (side == 1) and -50 or (display.contentWidth + 50)
    local startY = math.random(100, display.contentHeight - 100)
    
    -- Create bird (using a simple circle for now, can be replaced with image)
    local bird = display.newCircle(sceneGroup, startX, startY, 20)
    bird:setFillColor(0.8, 0.2, 0.2)
    
    -- Add physics body
    physics.addBody(bird, "dynamic", {radius = 20, bounce = 0.5})
    bird.linearDamping = 0.5
    
    -- Move bird across screen
    local targetX = (side == 1) and (display.contentWidth + 100) or -100
    local duration = math.abs(targetX - startX) / birdSpeed * 1000
    
    transition.to(bird, {
        x = targetX,
        time = duration,
        onComplete = function()
            removeBird(bird)
            -- Remove from birds table
            for i = 1, #birds do
                if birds[i] == bird then
                    table.remove(birds, i)
                    break
                end
            end
        end
    })
    
    table.insert(birds, bird)
    
    return bird
end

local function startBirdSpawning()
    if spawnHandle then return end
    if difficulty == "None" then return end
    
    local spawnInterval
    local birdsPerSpawn
    
    if difficulty == "Easy" then
        spawnInterval = 5000  -- 5 seconds
        birdsPerSpawn = 1
    elseif difficulty == "Medium" then
        spawnInterval = 10000  -- 10 seconds
        birdsPerSpawn = 2
    elseif difficulty == "Hard" then
        spawnInterval = 2000  -- 2 seconds (very fast)
        birdsPerSpawn = 2
    end
    
    spawnHandle = timer.performWithDelay(spawnInterval, function()
        if not gameOver and gameStarted then
            for i = 1, birdsPerSpawn do
                spawnBird()
            end
        end
    end, 0)
end

local function stopBirdSpawning()
    if spawnHandle then
        timer.cancel(spawnHandle)
        spawnHandle = nil
    end
    clearAllBirds()
end

-- =====================================================
-- DISPLAY FUNCTIONS
-- =====================================================

local function updateTimerDisplay()
    if timerCleared then
        if timerText then 
            pcall(function() display.remove(timerText) end)
            timerText = nil 
        end
        return
    end
    if not timerText then
        timerText = display.newText(scene.view, "", display.contentCenterX, 120, native.systemFontBold, 28)
        timerText:setFillColor(1)
    end
    local m = math.floor(math.max(timerSeconds, 0) / 60)
    local s = math.floor(math.max(timerSeconds, 0) % 60)
    if timerText then
        timerText.text = string.format("%02d:%02d", m, s)
    end
end

local function stopCountdown()
    if timerHandle then 
        timer.cancel(timerHandle)
        timerHandle = nil 
    end
end

local function removeTimerText()
    if timerText then 
        pcall(function() display.remove(timerText) end)
        timerText = nil 
    end
end

local function createCustomButton(label, yPos, color, onTap)
    local group = display.newGroup()
    scene.view:insert(group)
    local btnBg = display.newRoundedRect(group, display.contentCenterX, yPos, 300, 80, 12)
    btnBg:setFillColor(unpack(color))
    btnBg:setStrokeColor(1, 1, 1)
    btnBg.strokeWidth = 4
    btnBg.isHitTestable = true
    local btnText = display.newText(group, label, btnBg.x, btnBg.y, native.systemFontBold, 30)
    btnText:setFillColor(1, 1, 1)

    local function handleTap(event)
        if onTap then
            return onTap(event)
        end
        return true
    end

    btnBg:addEventListener("tap", handleTap)
    btnText:addEventListener("tap", handleTap)
    return group
end

local function createMenuIcon(x, y)
    local group = display.newGroup()
    scene.view:insert(group)
    local size = 40
    local bg = display.newRect(group, x, y, size, size)
    bg:setFillColor(0, 0, 0, 0.4)
    bg.strokeWidth = 2
    bg:setStrokeColor(1, 1, 1)
    local icon
    local ok = pcall(function()
        icon = display.newImageRect(group, "images/menu.png", 34, 34)
        icon.x = x
        icon.y = y
    end)
    if not ok then
        local txt = display.newText(group, "≡", x, y, native.systemFontBold, 25)
        txt:setFillColor(1)
    end
    return group
end

local function initializeGame()
    local sceneGroup = scene.view
    pcall(function()
        background = display.newImageRect(sceneGroup, "images/background.jpg", 480, 800)
        background.x = display.contentCenterX
        background.y = display.contentCenterY
        background.isHitTestable = true
    end)

    pcall(function()
        platform = display.newImageRect(sceneGroup, "images/platform.png", 500, 50)
        platform.x = display.contentCenterX
        platform.y = display.contentHeight - 25
        physics.addBody(platform, "static")
    end)

    pcall(function()
        tapText = display.newText(sceneGroup, tapCount, display.contentCenterX, 60, native.systemFont, 100)
        tapText:setFillColor(0, 1, 0)
    end)

    pcall(function()
        balloon = display.newImageRect(sceneGroup, "images/balloon.png", 112, 112)
        balloon.x = display.contentCenterX
        balloon.y = display.contentCenterY
        physics.addBody(balloon, "dynamic", {radius = 55, bounce = 0.05})
    end)
end

-- =====================================================
-- GAME FUNCTIONS
-- =====================================================

local function doGameOver(isTimeUp)
    if gameOver then return end
    if timerHandle then 
        timer.cancel(timerHandle)
        timerHandle = nil 
    end
    
    -- Stop bird spawning when game ends
    stopBirdSpawning()
    
    gameOver = true
    physics.pause()

    -- Ensure music is paused when game ends
    if bgChannel then
        pcall(function() audio.stop(bgChannel) end)
        bgChannel = nil
    end

    local sceneGroup = scene.view
    pcall(function()
        screenShadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
        screenShadow:setFillColor(0, 0, 0, 0.85)
        -- overlay is just visual, buttons are inserted after so they remain clickable
        screenShadow.isHitTestable = false
    end)

    if menuButtonGroup then sceneGroup:insert(menuButtonGroup) end

    if isTimeUp then
        pcall(function()
            timeUpText = display.newText(sceneGroup, "TIME IS UP!", display.contentCenterX, display.contentCenterY - 120, native.systemFontBold, 60)
            timeUpText:setFillColor(1, 1, 0)
        end)

        pcall(function()
            scoreText = display.newText(sceneGroup, "Score: " .. tostring(tapCount), display.contentCenterX, display.contentCenterY - 20, native.systemFontBold, 50)
            scoreText:setFillColor(1, 1, 1)
        end)

        pcall(function()
            highScoreText = display.newText(sceneGroup, "High Score: " .. tostring(highScore), display.contentCenterX, display.contentCenterY - 60, native.systemFontBold, 35)
            highScoreText:setFillColor(0, 1, 0)
        end)
    else
        pcall(function()
            gameOverText = display.newText(sceneGroup, "GAME OVER!", display.contentCenterX, display.contentCenterY - 100, native.systemFontBold, 60)
            gameOverText:setFillColor(1, 0, 0)
        end)

        pcall(function()
            scoreText = display.newText(sceneGroup, "Score: " .. tostring(tapCount), display.contentCenterX, display.contentCenterY + 30, native.systemFontBold, 40)
            scoreText:setFillColor(1, 1, 1)
        end)

        pcall(function()
            highScoreText = display.newText(sceneGroup, "High Score: " .. tostring(highScore), display.contentCenterX, display.contentCenterY - 30, native.systemFontBold, 35)
            highScoreText:setFillColor(0, 1, 0)
        end)
    end

    -- Update high score
    if tapCount and tapCount > (highScore or 0) then
        highScore = tapCount
        saveHighScore(highScore)
    end

    pcall(function()
        restartButton = createCustomButton("PLAY AGAIN", display.contentCenterY + 120, {0, 0.6, 0}, function()
            restartGame()
            startPlaying()
            return true
        end)
        backButton = createCustomButton("BACK", display.contentCenterY + 230, {0.2, 0.4, 0.8}, function()
            composer.gotoScene("scene.home", {effect = "fade", time = 500})
            return true
        end)
        if restartButton then restartButton:toFront() end
        if backButton then backButton:toFront() end
    end)
end

local function startCountdown(remaining)
    stopCountdown()
    timerCleared = false
    if remaining and type(remaining) == "number" then
        timerSeconds = math.max(remaining, 0)
    else
        -- Ensure timerMinutes is valid before using
        local effectiveTimer = (timerMinutes and timerMinutes > 0) and timerMinutes or 1
        timerSeconds = effectiveTimer * 60
    end
    
    -- Ensure we never have 0 or negative timer
    if timerSeconds <= 0 then
        timerSeconds = 60
    end
    
    updateTimerDisplay()
    timerHandle = timer.performWithDelay(1000, function()
        if timerSeconds and timerSeconds > 0 then
            timerSeconds = timerSeconds - 1
            updateTimerDisplay()
            if timerSeconds <= 0 then
                stopCountdown()
                doGameOver(true)
            end
        end
    end, 0)
end

startPlaying = function()
    gameStarted = true
    if screenShadow then 
        pcall(function() display.remove(screenShadow) end)
        screenShadow = nil 
    end
    if startInstructionText then
        pcall(function() display.remove(startInstructionText) end)
        startInstructionText = nil
    end
    if startTapListener then
        Runtime:removeEventListener("tap", startTapListener)
        startTapListener = nil
    end

    physics.start()
    
    -- Restart music when game starts
    if musicOn then
        playMusic()
    end

    -- Start bird spawning based on difficulty
    startBirdSpawning()

    if not timerCleared then
        if balloon then
            balloon:applyLinearImpulse(0, -0.80, balloon.x, balloon.y)
        end
        startCountdown()
    else
        if balloon then
            balloon:applyLinearImpulse(0, -0.80, balloon.x, balloon.y)
        end
        updateTimerDisplay()
    end
    return true
end

restartGame = function()
    if timerHandle then 
        timer.cancel(timerHandle)
        timerHandle = nil 
    end
    
    -- Clear all birds when restarting
    stopBirdSpawning()
    
    if timerText then 
        pcall(function() display.remove(timerText) end)
        timerText = nil 
    end
    if screenShadow then 
        pcall(function() display.remove(screenShadow) end)
        screenShadow = nil 
    end
    if gameOverText then 
        pcall(function() display.remove(gameOverText) end)
        gameOverText = nil 
    end
    if timeUpText then 
        pcall(function() display.remove(timeUpText) end)
        timeUpText = nil 
    end
    if scoreText then 
        pcall(function() display.remove(scoreText) end)
        scoreText = nil 
    end

    if highScoreText then 
        pcall(function() display.remove(highScoreText) end)
        highScoreText = nil 
    end
    
    if restartButton then 
        pcall(function() display.remove(restartButton) end)
        restartButton = nil 
    end
    if backButton then
        pcall(function() display.remove(backButton) end)
        backButton = nil
    end
    if quitButton then 
        pcall(function() display.remove(quitButton) end)
        quitButton = nil 
    end

    gameOver = false
    gameStarted = false
    tapCount = 0
    if tapText then
        tapText.text = tapCount
    end
    if balloon then
        balloon.x = display.contentCenterX
        balloon.y = display.contentCenterY
        balloon:setLinearVelocity(0, 0)
        balloon.angularVelocity = 0
    end
    physics.pause()

    local sceneGroup = scene.view
    pcall(function()
        screenShadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
        screenShadow:setFillColor(0, 0, 0, 0.6)
        screenShadow.isHitTestable = true
    end)

    if menuButtonGroup then sceneGroup:insert(menuButtonGroup) end

    -- Show player instruction instead of START/QUIT buttons.
    startInstructionText = display.newText(sceneGroup, "Tap anywhere to start", display.contentCenterX, display.contentCenterY + 100, native.systemFontBold, 30)
    startInstructionText:setFillColor(1, 1, 1)
    startInstructionText:toFront()

    -- capture tap to start game
    if screenShadow then
        screenShadow:addEventListener("tap", function()
            if not gameStarted and not gameOver then
                startPlaying()
                return true
            end
            return false
        end)
    end

    return true
end

local function pushBalloon()
    if not gameStarted or gameOver then return true end
    if balloon then
        balloon:applyLinearImpulse(0, -0.80, balloon.x, balloon.y)
    end
    tapCount = tapCount + 1
    if tapText then
        tapText.text = tapCount
    end
    playPopSound()
    return true
end

local function onCollision(event)
    if event.phase == "began" then
        local obj1 = event.object1
        local obj2 = event.object2
        if (obj1 == platform or obj2 == platform) then
            if not gameOver then
                doGameOver(false)
            end
        end
    end
end

local function checkBounds()
    if gameOver or not gameStarted or not balloon then return end
    if (balloon.y - 65) < 0 then
        doGameOver(false)
    end
end

function scene:create(event)
    local sceneGroup = self.view

    -- Load all settings
    highScore = loadHighScore()
    musicOn = loadMusicSetting()
    timerMinutes = loadTimerSetting()
    sfxOn = loadSfxSetting()

    -- Override timer if passed from home (via composer variable)
    local composerTimer = composer.getVariable("timerMinutes")
    if composerTimer then
        timerMinutes = math.max(1, math.min(tonumber(composerTimer) or 1, 5))
        saveTimerSetting(timerMinutes)
        composer.setVariable("timerMinutes", nil)  -- Clear it
    elseif event.params and event.params.timeLimit then
        local timerValue = tonumber(event.params.timeLimit)
        if timerValue then
            timerMinutes = math.max(1, math.min(math.floor(timerValue / 60), 5))
            saveTimerSetting(timerMinutes)
        end
    end

    -- Load difficulty from home scene
    local composerDifficulty = composer.getVariable("difficulty")
    if composerDifficulty then
        difficulty = composerDifficulty
        composer.setVariable("difficulty", nil)  -- Clear it
    end

    initializeGame()
    loadBackgroundMusic()
    loadPopSound()

    -- Initialize settings
    local settingsModule = settings.init(sceneGroup, display, native, timer)

    -- Create callbacks for settings module
    local callbacks = {
        saveMusicSetting = function(value)
            musicOn = value
            saveMusicSetting(value)
            if value then
                loadBackgroundMusic()
                playMusic()
            else
                stopMusic()
            end
        end,
        saveSfxSetting = function(value)
            sfxOn = value
            saveSfxSetting(value)
        end,
        saveTimerSetting = function(value)
            value = tonumber(value) or 1
            if value < 1 then value = 1 end
            if value > 5 then value = 5 end
            timerMinutes = value
            saveTimerSetting(value)
        end,
        startCountdown = startCountdown,
        stopCountdown = stopCountdown,
        updateTimerDisplay = updateTimerDisplay,
        removeTimerText = removeTimerText,
        physicsPause = function() physics.pause() end,
        physicsStart = function() physics.start() end,
        getHighScore = function() return highScore end,
        getTimerMinutes = function() return timerMinutes end,
        getTimerSeconds = function() return timerSeconds end,
        setTimerSeconds = function(value) timerSeconds = value end,
        getTimerCleared = function() return timerCleared end,
        setTimerCleared = function(value) timerCleared = value end,
        getMusicOn = function() return musicOn end,
        getSfxOn = function() return sfxOn end,
        getGameStarted = function() return gameStarted end,
        getGameOver = function() return gameOver end
    }

    -- Pass game state and callbacks to settings module
    settingsModule.setCallbacks(callbacks)

    --Menu initial
    menuButtonGroup = createMenuIcon(40, 40)
    menuButtonGroup:addEventListener("tap", function()
        settingsModule.showMenu()
        return true
    end)

    restartGame()

    if musicOn then
        loadBackgroundMusic()
        playMusic()
    end

    if balloon then
        balloon:addEventListener("tap", pushBalloon)
    end
    Runtime:addEventListener("collision", onCollision)
    Runtime:addEventListener("enterFrame", checkBounds)
end

function scene:destroy(event)
    -- Stop bird spawning and clear all birds
    stopBirdSpawning()
    
    if bgChannel then 
        pcall(function() audio.stop(bgChannel) end)
        bgChannel = nil 
    end
    if backgroundMusic then 
        pcall(function() audio.dispose(backgroundMusic) end)
        backgroundMusic = nil 
    end
end

function scene:show(event)
    if event.phase == "will" then
        -- Check for timer selection from home (via composer variable)
        local composerTimer = composer.getVariable("timerMinutes")
        if composerTimer then
            timerMinutes = math.max(1, math.min(tonumber(composerTimer) or 1, 5))
            saveTimerSetting(timerMinutes)
            composer.setVariable("timerMinutes", nil)  -- Clear it
        elseif event.params and event.params.timeLimit then
            local timerValue = tonumber(event.params.timeLimit)
            if timerValue then
                timerMinutes = math.max(1, math.min(math.floor(timerValue / 60), 5))
                saveTimerSetting(timerMinutes)
            end
        end
    elseif event.phase == "did" then
        -- Reset game when returning to the scene
        if gameOver or gameStarted then
            restartGame()
        end
        -- Resume music when scene comes back into view
        if musicOn and not gameStarted and not gameOver then
            loadBackgroundMusic()
            playMusic()
        end
    end
end

function scene:hide(event)
    if event.phase == "will" then
        -- Keep music playing when menu is open
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene