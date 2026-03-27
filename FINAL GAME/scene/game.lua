local composer = require("composer")
local scene = composer.newScene()

-- =====================================================
-- GLOBAL VARIABLES
-- =====================================================

local tapCount = 0

local background, resetButton, gameOver, startBtn, tapText
local platform, platform2, balloon
local bgMusic, bgMusicChannel
local tapSound, gameOverSound
local menuBtn, highScoreText, onCollison, timesUpText, timeUp

local gameOverPlayed = false

-- =====================================================
-- SCENE CREATE
-- =====================================================

function scene:create(e)

    local sceneGroup = self.view

    -- =====================================================
    -- LOCAL GAME STATE
    -- =====================================================

    local highScore = 0
    local highScoreFile = "highscore.txt"

    local timeLimit = nil
    local timeRemaining = nil
    local timerHandle = nil
    local timerText = nil

    -- Red dot spawning variables
    local difficulty = "None"
    local red_dots = {}
    local spawnHandle = nil
    local red_dotSpeed = 200
    local red_dotRadius = 15

    -- =====================================================
    -- HIGH SCORE FUNCTIONS
    -- =====================================================

    local function loadHighScore()
        local path = system.pathForFile(highScoreFile, system.DocumentsDirectory)
        local file = io.open(path, "r")

        if file then
            local contents = file:read("*a")
            io.close(file)
            highScore = tonumber(contents) or 0
        else
            highScore = 0
        end
    end

    local function saveHighScore()
        local path = system.pathForFile(highScoreFile, system.DocumentsDirectory)
        local file = io.open(path, "w")

        if file then
            file:write(tostring(highScore))
            io.close(file)
        end
    end

    local function createHighscoreDisplay()
        local topY = (display.screenOriginY + 75)
        highScoreText = display.newText(
            "Highscore: "..highScore,
            display.contentCenterX,
            topY,
            "PixelFont.ttf",
            20
        )
        highScoreText.anchorY = 0
        highScoreText:setFillColor(0, 100, 0)
    end

    local function updateHighScoreDisplay()
        if highScoreText then
            highScoreText.text = "Highscore: "..highScore
        end
    end

    local function checkHighScore()
        if tapCount > highScore then
            highScore = tapCount
            saveHighScore()
            updateHighScoreDisplay()
        end
    end

    -- =====================================================
    -- DISPLAY OBJECTS
    -- =====================================================

    background = display.newImageRect(
        "images/background.jpg",
        display.actualContentWidth,
        display.actualContentHeight
    )
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    resetButton = display.newRoundedRect(display.contentWidth - 60, 30, 100, 50, 8)
    resetButton:setFillColor(0.2, 0.8, 1)
    resetButton:setStrokeColor(0, 0, 0)
    resetButton.strokeWidth = 2
    resetButton.isVisible = true
    
    local resetBtnText = display.newText("RESET", resetButton.x, resetButton.y, native.systemFontBold, 18)
    resetBtnText:setFillColor(1, 1, 1)
    

    menuBtn = display.newText("Menu", 0, 0,"PixelFont.ttf", 48)
    menuBtn.anchorX = 0
    menuBtn.anchorY = 0
    menuBtn.x = display.safeScreenOriginX + 10
    menuBtn.y = display.safeScreenOriginY + 10
    menuBtn:setFillColor(0,0,0)
    

    gameOver = display.newRoundedRect(display.contentCenterX, display.contentCenterY, 300, 200, 12)
    gameOver:setFillColor(0.9, 0.1, 0.1)
    gameOver:setStrokeColor(0, 0, 0)
    gameOver.strokeWidth = 3
    
    local gameOverLabel = display.newText("GAME OVER", gameOver.x, gameOver.y - 40, native.systemFontBold, 40)
    gameOverLabel:setFillColor(1, 1, 1)
    
    gameOver.isVisible = false

    timesUpText = display.newText(
        "Time's Up!",
        display.contentCenterX,
        display.contentCenterY,
        "PixelFont.ttf",
        48
    )
    timesUpText:setFillColor(1, 0, 0)
    timesUpText.isVisible = false

    balloon = display.newImageRect("images/balloon.png", 130, 130)
    balloon.x = display.contentCenterX
    balloon.y = display.contentCenterY

    startBtn = display.newImageRect("images/startBtn.png", 150, 150)
    startBtn.x = display.contentCenterX
    startBtn.y = display.contentCenterY + 100
    startBtn.isVisible = true

    tapText = display.newText(
        tapCount,
        display.contentCenterX,
        100,
        "PixelFont.ttf",
        80
    )
    tapText:setFillColor(0, 100, 0)

    timerText = display.newText(
        "",
        display.contentCenterX,
        160,
        "PixelFont.ttf",
        36
    )
    timerText:setFillColor(1, 0, 0)
    timerText.isVisible = false

    platform = display.newImageRect("images/platform.png", 300, 50)
    platform.x = display.contentCenterX
    platform.y = display.contentHeight - 2

    platform2 = display.newImageRect("images/platform.png", 300, 50)
    platform2.x = display.contentCenterX
    platform2.y = display.screenOriginY + 130
    platform2.rotation = 180

    -- =====================================================
    -- PHYSICS
    -- =====================================================

    physics = require("physics")
    physics.start()
    physics.pause()

    physics.addBody(platform, "static", {radius=10})
    physics.addBody(platform2, "static", {radius=10})
    physics.addBody(balloon, "dynamic", {radius=60, bounce=0.8})

    -- =====================================================
    -- AUDIO
    -- =====================================================

    bgMusic = audio.loadStream("bgmusic/BalloonGameBGMusic.mp3")
    bgMusicChannel = audio.play(bgMusic, {loops=-1, fadein=2000})
    local isMuted = composer.getVariable("isMuted") or false
    if isMuted then
        audio.setVolume(0)
        if bgMusicChannel then audio.pause(bgMusicChannel) end
    else
        audio.setVolume(0.3)
    end

    tapSound = audio.loadSound("bgmusic/bgtapSound.mp3")
    gameOverSound = audio.loadSound("bgmusic/gameOver.mp3")

    -- =====================================================
    -- INITIALIZATION
    -- =====================================================

    loadHighScore()
    createHighscoreDisplay()
    updateHighScoreDisplay()

    if e and e.params and e.params.timeLimit then
        timeLimit = tonumber(e.params.timeLimit) or nil
    end

    -- Load timer minutes from home scene
    local composerTimerMinutes = composer.getVariable("timerMinutes")
    if composerTimerMinutes then
        local timerMin = tonumber(composerTimerMinutes) or 1
        timeLimit = math.max(1, math.min(timerMin, 5)) * 60  -- Convert to seconds
        composer.setVariable("timerMinutes", nil)  -- Clear it
    end

    -- Load difficulty from home scene
    local composerDifficulty = composer.getVariable("difficulty")
    if composerDifficulty then
        difficulty = composerDifficulty
        composer.setVariable("difficulty", nil)  -- Clear it
    end

    -- =====================================================
    -- TIMER FUNCTIONS
    -- =====================================================

    local function stopCountdown()
        if timerHandle then
            timer.cancel(timerHandle)
            timerHandle = nil
        end
        timeRemaining = nil
        timerText.isVisible = false
    end

    local function startCountdown()
        if not timeLimit then return end

        timeRemaining = timeLimit
        timerText.text = timeRemaining
        timerText.isVisible = true

        timerHandle = timer.performWithDelay(1000, function()
            timeRemaining = timeRemaining - 1
            timerText.text = timeRemaining

            if timeRemaining <= 0 then
                stopCountdown()
                if timeUp then timeUp() end
            end
        end, 0)
    end

    -- =====================================================
    -- RED DOT SPAWNING FUNCTIONS
    -- =====================================================

local function removeRedDot(red_dot)
    if red_dot then
        pcall(function()
            if red_dot.body then physics.removeBody(red_dot) end
            display.remove(red_dot)
        end)
    end
end

    local function clearAllRedDots()
        for i = 1, #red_dots do
            removeRedDot(red_dots[i])
        end
        red_dots = {}
    end

local function spawnRedDot()
    if gameOverPlayed then return end
    
    local side = math.random(1, 2)
    local startX = (side == 1) and -40 or (display.contentWidth + 40)
    local startY = math.random(150, display.contentHeight - 150)
    
    local red_dot = display.newImageRect("images/red_dot.png", 10, 10)
    red_dot.x = startX
    red_dot.y = startY
    sceneGroup:insert(red_dot)
    red_dot.name = "red_dot"
    
physics.addBody(red_dot, "dynamic", {
    radius = 5,
    isSensor = true   -- 👈 IMPORTANT
})
    
    local targetX = (side == 1) and (display.contentWidth + 10) or -10
    local duration = math.abs(targetX - startX) / red_dotSpeed * 80
    
    transition.to(red_dot, {
        x = targetX,
        time = duration,
        onComplete = function()
            for i = #red_dots, 1, -1 do
                if red_dots[i] == red_dot then
                    table.remove(red_dots, i)
                    break
                end
            end
            removeRedDot(red_dot)
        end
    })
    
table.insert(red_dots, red_dot)
end  -- closes spawnRedDot

local function startRedDotSpawning()
    if spawnHandle then return end
    if difficulty == "None" then return end
    
    local spawnInterval
    local red_dotsPerSpawn
    
    if difficulty == "Easy" then
        spawnInterval = 5000  -- 5 seconds
        red_dotsPerSpawn = 1
    elseif difficulty == "Medium" then
        spawnInterval = 10000  -- 10 seconds
        red_dotsPerSpawn = 2
    elseif difficulty == "Hard" then
        spawnInterval = 2000  -- 2 seconds (very fast)
        red_dotsPerSpawn = 2
    else
        return
    end
    
    spawnHandle = timer.performWithDelay(spawnInterval, function()
        if not gameOverPlayed then
            for i = 1, red_dotsPerSpawn do
                spawnRedDot()
            end
        end
    end, 0)
end

local function stopRedDotSpawning()
    if spawnHandle then
        timer.cancel(spawnHandle)
        spawnHandle = nil
    end
    clearAllRedDots()
end
