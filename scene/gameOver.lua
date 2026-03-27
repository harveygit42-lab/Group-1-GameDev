local gameOver = {}

local function safeRemove(obj)
    if obj then pcall(function() display.remove(obj) end) end
end

function gameOver.show(sceneGroup, options)
    options = options or {}

    local group = display.newGroup()
    sceneGroup:insert(group)

    local screenShadow = display.newRect(group, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    screenShadow:setFillColor(0, 0, 0, 0.85)
    screenShadow.isHitTestable = false

    local titleText = display.newText(group,
        "GAME OVER!",
        display.contentCenterX,
        display.contentCenterY - 100,
        options.font or "PressStart2P",
        options.titleFontSize or 40
    )
    titleText:setFillColor(1, 0, 0)

    local highScoreText = display.newText(group,
        "Highest Score: " .. tostring(options.highScore or 0),
        display.contentCenterX,
        display.contentCenterY - 30,
        options.font or "PressStart2P",
        options.highScoreFontSize or 20
    )
    highScoreText:setFillColor(133/255, 204/255, 23/255)

    local scoreText = display.newText(group,
        "Score: " .. tostring(options.score or 0),
        display.contentCenterX,
        display.contentCenterY + 45,
        options.font or "PressStart2P",
        options.scoreFontSize or 28
    )
    scoreText:setFillColor(1, 1, 1)

    local restartButton = display.newImageRect(group, "images/playagainBtn.png", 230, 70)
    restartButton.x = display.contentCenterX
    restartButton.y = display.contentCenterY + 150
    restartButton.isHitTestable = true

    local backButton = display.newImageRect(group, "images/backBtn.png", 230, 70)
    backButton.x = display.contentCenterX
    backButton.y = display.contentCenterY + 250
    backButton.isHitTestable = true

    restartButton:addEventListener("tap", function()
        if options.onRestart then options.onRestart() end
        return true
    end)

    backButton:addEventListener("tap", function()
        if options.onBack then options.onBack() end
        return true
    end)

    return {
        group = group,
        screenShadow = screenShadow,
        titleText = titleText,
        highScoreText = highScoreText,
        scoreText = scoreText,
        restartButton = restartButton,
        backButton = backButton,
        clear = function(self)
            safeRemove(self.group)
        end
    }
end

return gameOver
