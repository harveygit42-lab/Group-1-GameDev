local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")
local settings = require("setting.settings")
local gameOverModule = require("scene.gameOver")
local timeIsUpModule = require("scene.timeIsUp")
local gameDisplay = require("scene.gameDisplay")
local selectedTheme = "Morning"

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
local myFont = "PressStart2P"

-- Display objects
local gameObjs = {}
local screenShadow
local startButtonGroup
local extraButtonGroup
local gameOverText
local timeUpText
local scoreText
local highScoreText
local scoreBadge
local scoreLabel
local totalWidth
local highScoreLabel
local highScoreBadge
local restartButton
local backButton
local quitButton
local menuButtonGroup
local gameOverGroup
local timerText

local gameOverOverlay
local timeUpOverlay

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
        timerText = display.newText(scene.view, "", display.contentCenterX, 120, myFont, 28)
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
    local btnText = display.newText(group, label, btnBg.x, btnBg.y, myFont, 30)
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
    bg:setFillColor(0, 0, 0, 0)
    -- bg.strokeWidth = 2
    -- bg:setStrokeColor(1, 1, 1)
    local icon
    local ok = pcall(function()
        icon = display.newImageRect(group, "images/settings.png", 40, 40)
        icon.x = x
        icon.y = y
    end)
    if not ok then
        local txt = display.newText(group, "≡", x, y, myFont, 25)
        txt:setFillColor(1)
    end
    return group
end

local function clearGameOverOverlay()
    if gameOverOverlay then
        gameOverOverlay:clear()
        gameOverOverlay = nil
    end
    if timeUpOverlay then
        timeUpOverlay:clear()
        timeUpOverlay = nil
    end

    -- keep backwards compatibility with old variable names
    if gameOverGroup then pcall(function() display.remove(gameOverGroup) end); gameOverGroup = nil end
    if screenShadow then pcall(function() display.remove(screenShadow) end); screenShadow = nil end
    if timeUpText then pcall(function() display.remove(timeUpText) end); timeUpText = nil end
    if gameOverText then pcall(function() display.remove(gameOverText) end); gameOverText = nil end
    if highScoreText then pcall(function() display.remove(highScoreText) end); highScoreText = nil end
    if scoreText then pcall(function() display.remove(scoreText) end); scoreText = nil end
    if restartButton then pcall(function() display.remove(restartButton) end); restartButton = nil end
    if backButton then pcall(function() display.remove(backButton) end); backButton = nil end
    if quitButton then pcall(function() display.remove(quitButton) end); quitButton = nil end
    if highScoreLabel then highScoreLabel = nil end
    if highScoreBadge then highScoreBadge = nil end
    if scoreLabel then scoreLabel = nil end
    if scoreBadge then scoreBadge = nil end
end

local function initializeGame(bgFile, balloonFile)
    local sceneGroup = scene.view

    -- Background
    gameObjs.background = display.newImageRect(sceneGroup, bgFile, display.actualContentWidth, display.actualContentHeight)
    gameObjs.background.x = display.contentCenterX
    gameObjs.background.y = display.contentCenterY
    gameObjs.background.isHitTestable = true

    -- Platform
    gameObjs.platform = display.newImageRect(sceneGroup, "images/platform.png", 500, 50)
    gameObjs.platform.x = display.contentCenterX
    gameObjs.platform.y = display.contentHeight - 25
    physics.addBody(gameObjs.platform, "static")

    -- Balloon
    gameObjs.balloon = display.newImageRect(sceneGroup, balloonFile, 112, 112)
    gameObjs.balloon.x = display.contentCenterX
    gameObjs.balloon.y = display.contentCenterY
    physics.addBody(gameObjs.balloon, "dynamic", {radius = 55, bounce = 0.05})

    -- Score Text
    gameObjs.tapText = display.newText(sceneGroup, "0", display.contentCenterX, 60, myFont, 60)
    gameObjs.tapText:setFillColor(0, 1, 0)
    
    -- Start Screen Shadow
    screenShadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    screenShadow:setFillColor(0, 0, 0, 0.6)
    screenShadow:addEventListener("tap", function() startPlaying(); return true end)
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

    clearGameOverOverlay()

    gameOver = true
    physics.pause()

    -- Ensure music is paused when game ends
    if bgChannel then
        pcall(function() audio.stop(bgChannel) end)
        bgChannel = nil
    end

    if tapCount and tapCount > (highScore or 0) then
        highScore = tapCount
        saveHighScore(highScore)
    end

    local sceneGroup = scene.view
    if menuButtonGroup then sceneGroup:insert(menuButtonGroup) end

    local overlayOptions = {
        score = tapCount,
        highScore = highScore,
        font = myFont,
        titleFontSize = 40,
        scoreFontSize = 28,
        highScoreFontSize = 20,
        onRestart = function()
            restartGame()
            startPlaying()
        end,
        onBack = function()
            composer.gotoScene("scene.home", {effect = "fade", time = 500})
        end
    }

    if isTimeUp then
        timeUpOverlay = timeIsUpModule.show(sceneGroup, overlayOptions)
    else
        gameOverOverlay = gameOverModule.show(sceneGroup, overlayOptions)
    end

    -- Ensure the settings/menu icon is on top of dark overlays
    if menuButtonGroup and menuButtonGroup.toFront then
        menuButtonGroup:toFront()
    end
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

    -- extra safety cleanup before starting play
    clearGameOverOverlay()

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

    if not timerCleared then
        if gameObjs.balloon then
            gameObjs.balloon:applyLinearImpulse(0, -0.80, gameObjs.balloon.x, gameObjs.balloon.y)
        end
        startCountdown()
    else
        if gameObjs.balloon then
            gameObjs.balloon:applyLinearImpulse(0, -0.80, gameObjs.balloon.x, gameObjs.balloon.y)
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

    if timerText then 
        pcall(function() display.remove(timerText) end)
        timerText = nil 
    end
    if screenShadow then 
        pcall(function() display.remove(screenShadow) end)
        screenShadow = nil 
    end

    clearGameOverOverlay()

    gameOver = false
    gameStarted = false
    tapCount = 0
    if gameObjs.tapText then
        gameObjs.tapText.text = tapCount
    end
    if gameObjs.balloon then
        gameObjs.balloon.x = display.contentCenterX
        gameObjs.balloon.y = display.contentCenterY
        gameObjs.balloon:setLinearVelocity(0, 0)
        gameObjs.balloon.angularVelocity = 0
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
    startInstructionText = display.newText(sceneGroup, "Tap anywhere to start", display.contentCenterX, display.contentCenterY + 100, myFont, 20)
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
    if gameObjs.balloon then
        gameObjs.balloon:applyLinearImpulse(0, -0.80, gameObjs.balloon.x, gameObjs.balloon.y)
    end
    tapCount = tapCount + 1
    if gameObjs.tapText then
        gameObjs.tapText.text = tapCount
    end
    playPopSound()
    return true
end

local function onCollision(event)
    if event.phase == "began" then
        local obj1 = event.object1
        local obj2 = event.object2
        if (obj1 == gameObjs.platform or obj2 == gameObjs.platform) then
            if not gameOver then
                doGameOver(false)
            end
        end
    end
end

local function checkBounds()
    if gameOver or not gameStarted or not gameObjs.balloon then return end
    if (gameObjs.balloon.y - 65) < 0 then
        doGameOver(false)
    end
end

function scene:create(event)
    local sceneGroup = self.view
    
    -- 1. Get the theme from the composer variable
    local currentTheme = composer.getVariable("theme") or "Morning"
    
    -- 2. Create the file paths based on the theme
    -- We use string.lower() to match your filenames like "sunsetBg.png"
    local bgPath = "images/" .. string.lower(currentTheme) .. "Bg.png"
    local balloonPath = "images/" .. string.lower(currentTheme) .. "Balloon.png"

    -- 3. Pass these to your initializeGame function
    -- (Update your initializeGame to accept these as arguments)
    

    
    -- Load all settings
    highScore = loadHighScore()
    musicOn = loadMusicSetting()
    timerMinutes = loadTimerSetting()
    sfxOn = loadSfxSetting()

    -- Override timer if passed from home (via composer variable)
    local composerTimer = composer.getVariable("timerMinutes")
    if composerTimer then
        if composerTimer == "None" then
            timerCleared = true
        else
            timerMinutes = math.max(1, math.min(tonumber(composerTimer) or 1, 5))
            timerCleared = false
            saveTimerSetting(timerMinutes)
        end
        composer.setVariable("timerMinutes", nil)  -- Clear it
    elseif event.params and event.params.timeLimit then
        local timerValue = tonumber(event.params.timeLimit)
        if timerValue then
            timerMinutes = math.max(1, math.min(math.floor(timerValue / 60), 5))
            saveTimerSetting(timerMinutes)
        end
    end

    local currentTheme = composer.getVariable("theme") or "Morning"
    
    -- logic to pick filenames
    local bgFile = "images/morningBg.png"
    local balloonFile = "images/morningBalloon.png"
    if currentTheme == "Sunset" then
        bgFile = "images/sunsetBg.png"
        balloonFile = "images/sunsetBalloon.png"
    elseif currentTheme == "Night" then
        bgFile = "images/nightBg.png"
        balloonFile = "images/nightBalloon.png"
    end

    initializeGame(bgFile, balloonFile)
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
        physics.pause()
    
    -- 2. Call showMenu and provide a callback for when it closes
    settingsModule.showMenu({
        onClose = function()
            -- This code runs when the user closes the settings menu
            if not gameStarted and not gameOver then
                -- Re-run restartGame to restore the shadow and tap listener
                restartGame()
            elseif gameStarted and not gameOver then
                -- If they were mid-game, just resume physics
                physics.start()
            end
        end
    })
        return true
    end)

    restartGame()

    if musicOn then
        loadBackgroundMusic()
        playMusic()
    end

    if gameObjs.balloon then
        gameObjs.balloon:addEventListener("tap", pushBalloon)
    end
    Runtime:addEventListener("collision", onCollision)
    Runtime:addEventListener("enterFrame", checkBounds)
end

function scene:destroy(event)
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
    -- if ( event.phase == "did" ) then
    --     -- This ensures that if the scene was already loaded, 
    --     -- it updates visuals to the new theme
    --     local currentTheme = composer.getVariable("theme") or "Morning"

    --     -- Update the background image specifically
    --     if gameObjs.background then
    --         gameObjs.background.fill = { 
    --             type = "image", 
    --             filename = "images/" .. string.lower(currentTheme) .. "Bg.png" 
    --         }
    --     end
    -- end

    if ( event.phase == "did" ) then
        local currentTheme = composer.getVariable("theme") or "Morning"
        local themeLower = string.lower(currentTheme)

        -- Update the background image
        if gameObjs.background then
            gameObjs.background.fill = { 
                type = "image", 
                filename = "images/" .. themeLower .. "Bg.png" 
            }
        end

        -- ADD THIS: Update the balloon image
        if gameObjs.balloon then
            gameObjs.balloon.fill = {
                type = "image",
                filename = "images/" .. themeLower .. "Balloon.png"
            }
        end
    end

    if event.phase == "will" then
        -- Check for timer selection from home (via composer variable)
        local composerTimer = composer.getVariable("timerMinutes")
        if composerTimer then
            if composerTimer == "None" then
                timerCleared = true
            else
                timerMinutes = math.max(1, math.min(tonumber(composerTimer) or 1, 5))
                timerCleared = false
                saveTimerSetting(timerMinutes)
            end
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
