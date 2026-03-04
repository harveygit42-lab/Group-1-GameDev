--yasmien
local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")

local background, platform, tapText, balloon, timeText, sceneGroup
local tapCount = 0
local gameOverShown = false
local gameStarted = false
local countdownTimer
local sfxOn = true
local musicOn = true
local popSound
local timerSeconds = 0
local highScore = 0

local function showGameOver()
    if gameOverShown then return end
    gameOverShown = true
    
    physics.pause()
    
    local shadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    shadow:setFillColor(0, 0, 0, 0.6)
    shadow:addEventListener("tap", function() return true end)

    local overText = display.newText({
        parent = sceneGroup,
        text = "Game Over",
        x = display.contentCenterX,
        y = display.contentCenterY - 30,
        font = native.systemFontBold,
        fontSize = 48
    })
    overText:setFillColor(1, 0, 0)

    local scoreText = display.newText({
        parent = sceneGroup,
        text = "Score: " .. tostring(tapCount),
        x = display.contentCenterX,
        y = display.contentCenterY + 30,
        font = native.systemFont,
        fontSize = 36
    })
    scoreText:setFillColor(1, 1, 1)

    timer.performWithDelay(3000, function()
        composer.gotoScene("scene.menu")
    end)
end

local function updateCountdown()
    timerSeconds = timerSeconds - 1
    if timeText then
        local minutes = math.floor(timerSeconds / 60)
        local seconds = timerSeconds % 60
        timeText.text = string.format("%02d:%02d", minutes, seconds)
    end
    if timerSeconds <= 0 then
        if countdownTimer then
            timer.cancel(countdownTimer)
            countdownTimer = nil
        end
        showGameOver()
    end
end

local function playPopSound()
    if sfxOn and popSound then
        audio.play(popSound)
    end
end

local function pushBalloon()
    if not gameStarted or gameOverShown then return true end
    balloon:applyLinearImpulse(0, -0.80, balloon.x, balloon.y)
    tapCount = tapCount + 1
    tapText.text = tostring(tapCount)
    playPopSound()
    return true
end

local function onCollision(event)
    if event.phase == "began" and not gameOverShown then
        local obj1 = event.object1
        local obj2 = event.object2
        if (obj1 == platform or obj2 == platform) then
            showGameOver()
        end
    end
end

local function checkBounds()
    if gameOverShown then return end
    if (balloon.y - 65) < 0 then
        showGameOver()
    end
end

function scene:create(event)
    sceneGroup = self.view
    
    -- Load settings from saved files
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

    musicOn = loadMusicSetting()
    sfxOn = loadSfxSetting()
    local timerMinutes = loadTimerSetting()
    highScore = loadHighScore()
    timerSeconds = timerMinutes * 60

    background = display.newImageRect(sceneGroup, "images/background.jpg", 480, 800)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    platform = display.newImageRect(sceneGroup, "images/platform.png", 500, 50)
    platform.x = display.contentCenterX
    platform.y = display.contentHeight - 25

    balloon = display.newImageRect(sceneGroup, "images/balloon.png", 112, 112)
    balloon.x = display.contentCenterX
    balloon.y = display.contentCenterY

    tapText = display.newText({
        parent = sceneGroup,
        text = tostring(tapCount),
        x = display.contentCenterX,
        y = 60,
        font = native.systemFontBold,
        fontSize = 40
    })
    tapText:setFillColor(0, 1, 0)

    timeText = display.newText({
        parent = sceneGroup,
        text = string.format("%02d:%02d", math.floor(timerSeconds / 60), timerSeconds % 60),
        x = display.contentWidth - 40,
        y = 30,
        font = native.systemFontBold,
        fontSize = 32
    })
    timeText:setFillColor(1, 1, 0)

    -- Initialize physics
    physics.addBody(platform, "static")
    physics.addBody(balloon, "dynamic", {radius = 55, bounce = 0.05})

    -- Load pop sound
    local ok, sound = pcall(function() return audio.loadSound("bgmusic/pop.mp3") end)
    if ok then popSound = sound end

    -- Add listeners
    balloon:addEventListener("tap", pushBalloon)
    Runtime:addEventListener("collision", onCollision)
    Runtime:addEventListener("enterFrame", checkBounds)
end

function scene:show(event)
    if event.phase == "did" then
        gameStarted = true
        gameOverShown = false
        tapCount = 0
        tapText.text = tostring(tapCount)
        
        -- Reset balloon position
        balloon.x = display.contentCenterX
        balloon.y = display.contentCenterY
        balloon:setLinearVelocity(0, 0)
        balloon.angularVelocity = 0
        
        physics.start()
        balloon:applyLinearImpulse(0, -0.80, balloon.x, balloon.y)
        
        if countdownTimer then timer.cancel(countdownTimer) end
        countdownTimer = timer.performWithDelay(1000, function() updateCountdown() end, 0)
    end
end

function scene:hide(event)
    if event.phase == "will" then
        if countdownTimer then
            timer.cancel(countdownTimer)
            countdownTimer = nil
        end
        physics.pause()
    end
end

function scene:destroy(event)
    if countdownTimer then
        timer.cancel(countdownTimer)
        countdownTimer = nil
    end
    if balloon then
        balloon:removeEventListener("tap", pushBalloon)
    end
    Runtime:removeEventListener("collision", onCollision)
    Runtime:removeEventListener("enterFrame", checkBounds)
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene