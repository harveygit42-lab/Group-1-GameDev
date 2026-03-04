local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")
local settings = require("setting.settings")

physics.start()
physics.pause()

local backgroundMusic
local bgChannel

function scene:create(event)
    local sceneGroup = self.view

    --All Variables
    local screenShadow
    local startButtonGroup
    local extraButtonGroup
    local tapCount = 0
    local gameOver = false
    local gameStarted = false
    local gameOverText
    local timeUpText
    local scoreText
    local restartButton
    local quitButton
    local menuButtonGroup
    local musicOn = true
    local popSound
    local sfxOn = true
    local timerMinutes = 1
    local timerSeconds = 0
    local timerText
    local timerHandle
    local timerCleared = false
    local highScore = 0

    -- Display objects
    local background
    local platform
    local tapText
    local balloon

    --Load and Save Functions
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

    -- Load all settings
    highScore = loadHighScore()
    musicOn = loadMusicSetting()
    timerMinutes = loadTimerSetting()
    sfxOn = loadSfxSetting()

    --Audio Management
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

    --Display functions
    local function updateTimerDisplay()
        if timerCleared then
            if timerText then 
                pcall(function() display.remove(timerText) end)
                timerText = nil 
            end
            return
        end
        if not timerText then
            timerText = display.newText(sceneGroup, "", display.contentCenterX, 120, native.systemFontBold, 28)
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
        sceneGroup:insert(group)
        local btnBg = display.newRoundedRect(group, display.contentCenterX, yPos, 300, 80, 12)
        btnBg:setFillColor(unpack(color))
        btnBg:setStrokeColor(1, 1, 1)
        btnBg.strokeWidth = 4
        local btnText = display.newText(group, label, btnBg.x, btnBg.y, native.systemFontBold, 30)
        btnText:setFillColor(1, 1, 1)
        group:addEventListener("tap", onTap)
        return group
    end

    local function createMenuIcon(x, y)
        local group = display.newGroup()
        sceneGroup:insert(group)
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

    --Create display opbejcts
    local function initializeGame()
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

    initializeGame()
    loadBackgroundMusic()
    loadPopSound()

    --Forward declarations
    local restartGame, startPlaying, doGameOver, startCountdown

    --Game functions
    doGameOver = function(isTimeUp)
        if gameOver then return end
        if timerHandle then 
            timer.cancel(timerHandle)
            timerHandle = nil 
        end
        gameOver = true
        physics.pause()

        -- Ensure music is paused when game ends
        if bgChannel then
            pcall(function() audio.stop(bgChannel) end)
            bgChannel = nil
        end

        pcall(function()
            screenShadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
            screenShadow:setFillColor(0, 0, 0, 0.6)
            screenShadow:addEventListener("tap", function() return true end)
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
        else
            pcall(function()
                gameOverText = display.newText(sceneGroup, "GAME OVER!", display.contentCenterX, display.contentCenterY - 100, native.systemFontBold, 60)
                gameOverText:setFillColor(1, 0, 0)
            end)

            pcall(function()
                scoreText = display.newText(sceneGroup, "Score: " .. tostring(tapCount), display.contentCenterX, display.contentCenterY + 30, native.systemFontBold, 40)
                scoreText:setFillColor(1, 1, 1)
            end)
        end

        -- Update high score
        if tapCount and tapCount > (highScore or 0) then
            highScore = tapCount
            saveHighScore(highScore)
        end

        pcall(function()
            restartButton = createCustomButton("PLAY AGAIN", display.contentCenterY + 120, {0, 0.6, 0}, restartGame)
            quitButton = createCustomButton("QUIT", display.contentCenterY + 220, {0.8, 0, 0}, function() native.requestExit(); return true end)
        end)
    end

    startCountdown = function(remaining)
        stopCountdown()
        timerCleared = false
        if remaining and type(remaining) == "number" then
            timerSeconds = math.max(remaining, 0)
        else
            timerSeconds = (timerMinutes or 1) * 60
        end
        
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
        if startButtonGroup then 
            pcall(function() display.remove(startButtonGroup) end)
            startButtonGroup = nil 
        end
        if extraButtonGroup then 
            pcall(function() display.remove(extraButtonGroup) end)
            extraButtonGroup = nil 
        end
        physics.start()
        
        -- Restart music when game starts
        if musicOn then
            playMusic()
        end
        
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
        if restartButton then 
            pcall(function() display.remove(restartButton) end)
            restartButton = nil 
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

        pcall(function()
            screenShadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
            screenShadow:setFillColor(0, 0, 0, 0.6)
            screenShadow:addEventListener("tap", function() return true end)
        end)

        if menuButtonGroup then sceneGroup:insert(menuButtonGroup) end
        pcall(function()
            startButtonGroup = createCustomButton("START PLAYING", display.contentCenterY + 100, {0, 0.6, 0}, startPlaying)
            extraButtonGroup = createCustomButton("QUIT", display.contentCenterY + 200, {0.8, 0, 0}, function() native.requestExit(); return true end)
        end)
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

    if balloon then
        balloon:addEventListener("tap", pushBalloon)
    end
    Runtime:addEventListener("collision", onCollision)
    Runtime:addEventListener("enterFrame", checkBounds)

    -- Initialize settings
    local settingsModule = settings.init(sceneGroup, display, native, timer)

    -- Create game state object that references actual variables
    local function getGameState()
        return {
            gameStarted = gameStarted,
            gameOver = gameOver,
            timerCleared = timerCleared,
            timerMinutes = timerMinutes,
            timerSeconds = timerSeconds,
            timerHandle = timerHandle,
            musicOn = musicOn,
            bgChannel = bgChannel,
            backgroundMusic = backgroundMusic,
            sfxOn = sfxOn,
            highScore = highScore
        }
    end

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
    if event.phase == "did" then
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