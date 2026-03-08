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
        "background.jpg",
        display.actualContentWidth,
        display.actualContentHeight
    )
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    resetButton = display.newImageRect("resetButton.png", 50, 50)
    resetButton.anchorX = 1
    resetButton.anchorY = 0
    resetButton.x = display.safeScreenOriginX + display.safeActualContentWidth
    resetButton.y = display.safeScreenOriginY
    resetButton.isVisible = true
    

    menuBtn = display.newText("Menu", 0, 0,"PixelFont.ttf", 24)
    menuBtn.anchorX = 0
    menuBtn.anchorY = 0
    menuBtn.x = display.safeScreenOriginX + 10
    menuBtn.y = display.safeScreenOriginY + 10
    menuBtn:setFillColor(0,0,0)
    

    gameOver = display.newImageRect("gameOver.png", 300, 300)
    gameOver.x = display.contentCenterX
    gameOver.y = display.contentCenterY + 10
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

    balloon = display.newImageRect("balloon.png", 130, 130)
    balloon.x = display.contentCenterX
    balloon.y = display.contentCenterY

    startBtn = display.newImageRect("startBtn.png", 150, 150)
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

    platform = display.newImageRect("platform.png", 300, 50)
    platform.x = display.contentCenterX
    platform.y = display.contentHeight - 2

    platform2 = display.newImageRect("platform.png", 300, 50)
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

    bgMusic = audio.loadStream("BalloonGameBGMusic.mp3")
    bgMusicChannel = audio.play(bgMusic, {loops=-1, fadein=2000})
    local isMuted = composer.getVariable("isMuted") or false
    if isMuted then
        audio.setVolume(0)
        if bgMusicChannel then audio.pause(bgMusicChannel) end
    else
        audio.setVolume(0.3)
    end

    tapSound = audio.loadSound("tapSound.mp3")
    gameOverSound = audio.loadSound("gameOver.mp3")

    -- =====================================================
    -- INITIALIZATION
    -- =====================================================

    loadHighScore()
    createHighscoreDisplay()
    updateHighScoreDisplay()

    if e and e.params and e.params.timeLimit then
        timeLimit = tonumber(e.params.timeLimit) or nil
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
    -- GAME FUNCTIONS
    -- =====================================================

    local function pushBalloon()
        if gameOverPlayed then return end
        balloon:applyLinearImpulse(0, -0.75, balloon.x, balloon.y)
        tapCount = tapCount + 1
        tapText.text = tapCount
        audio.play(tapSound)
    end

    local function resetGame()
        tapCount = 0
        tapText.text = tapCount
        gameOver.isVisible = false
        resetButton.isVisible = true
        background.alpha = 1

        balloon.x = display.contentCenterX
        gameOverPlayed = false
        stopCountdown()
        timesUpText.isVisible = false
    end

    onCollison = function()
        if gameOverPlayed then return end

        stopCountdown()
        timesUpText.isVisible = false
        gameOverPlayed = true
        gameOver.isVisible = true
        resetButton.isVisible = false
        startBtn.isVisible = true
        background.alpha = 0.5

        balloon:removeEventListener("tap", pushBalloon)
        balloon:removeEventListener("collision", onCollison)

        -- keep physics running so the balloon continues bouncing,
        -- but make sure UI elements are on top so they aren't visually overlapped
        if startBtn and startBtn.toFront then startBtn:toFront() end
        if gameOver and gameOver.toFront then gameOver:toFront() end
        if resetButton and resetButton.toFront then resetButton:toFront() end

        -- keep physics active; do not zero velocity so balloon continues to respond to physics

        audio.play(gameOverSound)

        if bgMusicChannel then
            audio.pause(bgMusicChannel)
        end

        checkHighScore()
    end

    timeUp = function()
        if gameOverPlayed then return end

        gameOverPlayed = true
        stopCountdown()

        timesUpText.x = gameOver.x
        timesUpText.y = gameOver.y
        timesUpText.isVisible = true
        timesUpText:toFront()

        gameOver.isVisible = false
        resetButton.isVisible = false
        startBtn.isVisible = true
        background.alpha = 0.5

        balloon:removeEventListener("tap", pushBalloon)
        balloon:removeEventListener("collision", onCollison)

        if startBtn and startBtn.toFront then startBtn:toFront() end
        if timesUpText and timesUpText.toFront then timesUpText:toFront() end
        if resetButton and resetButton.toFront then resetButton:toFront() end

        audio.play(gameOverSound)

        if bgMusicChannel then
            audio.pause(bgMusicChannel)
        end

        checkHighScore()
    end

    function startGame()
        if physics and physics.start then physics.start() end
        pcall(function() physics.removeBody(balloon) end)
        physics.addBody(balloon, "dynamic", {radius=60, bounce=0.8})

        local isMuted = composer.getVariable("isMuted") or false
        if bgMusicChannel then
            if not isMuted then
                audio.resume(bgMusicChannel)
            else
                audio.pause(bgMusicChannel)
            end
        else
            bgMusicChannel = audio.play(bgMusic, {loops=-1})
            if isMuted and bgMusicChannel then audio.pause(bgMusicChannel) end
        end

        gameOverPlayed = false
        startBtn.isVisible = false
        resetButton.isVisible = true
        gameOver.isVisible = false
        background.alpha = 1

        tapCount = 0
        tapText.text = tapCount

        balloon.y = display.contentCenterY
        balloon:addEventListener("tap", pushBalloon)
        balloon:addEventListener("collision", onCollison)

        timesUpText.isVisible = false

        if timeLimit then
            startCountdown()
        end
    end

    function menuBtn:tap()
       
        if physics and physics.pause then 
            physics.pause() 
        end
       
        pcall (function()
            physics.removeBody(balloon)
        end)

        if bgMusicChannel then
            audio.pause(bgMusicChannel)
        end

        composer.removeScene("game")
        composer.gotoScene("menu", {effect = "fade", time = 400})
    end


    -- =====================================================
    -- EVENT LISTENERS
    -- =====================================================

    resetButton:addEventListener("tap", resetGame)
    balloon:addEventListener("collision", onCollison)
    startBtn:addEventListener("tap", startGame)
    menuBtn:addEventListener("tap", menuBtn)

    -- =====================================================
    -- SCENE GROUP INSERTS
    -- =====================================================

    sceneGroup:insert(background)
    sceneGroup:insert(resetButton)
    sceneGroup:insert(gameOver)
    sceneGroup:insert(timesUpText)
    sceneGroup:insert(startBtn)
    sceneGroup:insert(tapText)
    sceneGroup:insert(timerText)
    sceneGroup:insert(highScoreText)
    sceneGroup:insert(platform)
    sceneGroup:insert(platform2)
    sceneGroup:insert(balloon)
    sceneGroup:insert(menuBtn)  

end

scene:addEventListener("create", scene)
scene:addEventListener("destroy", scene)
return scene