-- yasmien 
local composer = require("composer")
local scene = composer.newScene()

-- =====================================================
-- VARIABLES
-- =====================================================

local selectedTimer = 1
local selectedDifficulty = "None"

-- =====================================================
-- SCENE CREATE
-- =====================================================

function scene:create(event)
    local sceneGroup = self.view

    -- Background
    local background = display.newImageRect(sceneGroup, "images/background.jpg", 480, 800)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    -- Title
    local title = display.newText(sceneGroup, "Tap the Balloon",
        display.contentCenterX, display.contentCenterY - 150,
        native.systemFontBold, 50)
    title:setFillColor(0, 0, 0)

    -- =====================================================
    -- TIMER DROPDOWN
    -- =====================================================

    local timerLabel = display.newText(sceneGroup, "Select Timer (minutes):",
        0, display.contentCenterY - 50, native.systemFontBold, 25)
    timerLabel:setFillColor(0, 0, 0)
    timerLabel.anchorX = 0

    local dropdownBtn = display.newRoundedRect(sceneGroup, 0,
        display.contentCenterY - 50, 60, 50, 10)
    dropdownBtn:setFillColor(0.2, 0.6, 1) -- FIXED (softer blue)
    dropdownBtn:setStrokeColor(0, 0, 0)
    dropdownBtn.strokeWidth = 2

    local dropdownText = display.newText(sceneGroup, "1",
        dropdownBtn.x, dropdownBtn.y, native.systemFontBold, 20)
    dropdownText:setFillColor(1, 1, 1) -- white text

    local totalWidth = timerLabel.contentWidth + 15 + dropdownBtn.width
    local startX = display.contentCenterX - totalWidth / 2

    timerLabel.x = startX
    dropdownBtn.x = startX + timerLabel.contentWidth + 15 + dropdownBtn.width/2
    dropdownText.x = dropdownBtn.x

    local optionsGroup
    local dropdownOpen = false

    local function closeDropdown()
        if optionsGroup then
            display.remove(optionsGroup)
            optionsGroup = nil
            dropdownOpen = false
        end
    end

    local function openDropdown()
        if dropdownOpen then closeDropdown() return end

        dropdownOpen = true
        optionsGroup = display.newGroup()
        sceneGroup:insert(optionsGroup)

        local baseY = dropdownBtn.y + dropdownBtn.height/2 + 10

        for i = 1, 5 do
            local y = baseY + (i - 1) * 35

            local btn = display.newRoundedRect(optionsGroup, dropdownBtn.x, y, 60, 30, 8)
            btn:setFillColor(0.9, 0.9, 0.9) -- FIXED (light gray)
            btn:setStrokeColor(0, 0, 0)
            btn.strokeWidth = 1

            local txt = display.newText(optionsGroup, tostring(i), btn.x, btn.y, native.systemFontBold, 18)
            txt:setFillColor(0, 0, 0) -- black text

            btn:addEventListener("tap", function()
                selectedTimer = i
                dropdownText.text = tostring(i)
                dropdownText.x = dropdownBtn.x
                closeDropdown()
                return true
            end)
        end
    end

    -- =====================================================
    -- DIFFICULTY DROPDOWN
    -- =====================================================

    local diffLabel = display.newText(sceneGroup, "Level of Difficulty:",
        0, display.contentCenterY + 20, native.systemFontBold, 25)
    diffLabel:setFillColor(0, 0, 0)
    diffLabel.anchorX = 0

    local diffBtn = display.newRoundedRect(sceneGroup, 0,
        display.contentCenterY + 20, 120, 50, 10)
    diffBtn:setFillColor(1, 0.5, 0.5) -- FIXED (softer red)
    diffBtn:setStrokeColor(0, 0, 0)
    diffBtn.strokeWidth = 2

    local diffText = display.newText(sceneGroup, "None",
        diffBtn.x, diffBtn.y, native.systemFontBold, 18)
    diffText:setFillColor(1, 1, 1) -- white text

    local totalWidth2 = diffLabel.contentWidth + 15 + diffBtn.width
    local startX2 = display.contentCenterX - totalWidth2 / 2

    diffLabel.x = startX2
    diffBtn.x = startX2 + diffLabel.contentWidth + 15 + diffBtn.width/2
    diffText.x = diffBtn.x

    local diffOptionsGroup
    local diffOpen = false

    local function closeDiffDropdown()
        if diffOptionsGroup then
            display.remove(diffOptionsGroup)
            diffOptionsGroup = nil
            diffOpen = false
        end
    end

    local function openDiffDropdown()
        if diffOpen then closeDiffDropdown() return end

        diffOpen = true
        diffOptionsGroup = display.newGroup()
        sceneGroup:insert(diffOptionsGroup)

        local options = {"None", "Easy", "Medium", "Hard"}
        local baseY = diffBtn.y + diffBtn.height/2 + 10

        for i = 1, #options do
            local y = baseY + (i - 1) * 40

            local btn = display.newRoundedRect(diffOptionsGroup, diffBtn.x, y, 140, 35, 8)
            btn:setFillColor(0.9, 0.9, 0.9) -- FIXED
            btn:setStrokeColor(0, 0, 0)
            btn.strokeWidth = 1

            local txt = display.newText(diffOptionsGroup, options[i], btn.x, btn.y, native.systemFontBold, 16)
            txt:setFillColor(0, 0, 0) -- black text

            btn:addEventListener("tap", function()
                selectedDifficulty = options[i]
                diffText.text = options[i]
                diffText.x = diffBtn.x

                -- OPTIONAL color change per difficulty
                if options[i] == "Easy" then
                    diffBtn:setFillColor(0, 0.8, 0)
                elseif options[i] == "Medium" then
                    diffBtn:setFillColor(1, 0.7, 0)
                elseif options[i] == "Hard" then
                    diffBtn:setFillColor(0.8, 0, 0)
                else
                    diffBtn:setFillColor(0.6, 0.6, 0.6)
                end

                closeDiffDropdown()
                return true
            end)
        end
    end

    -- =====================================================
    -- BUTTONS
    -- =====================================================

    local playBtn = display.newRoundedRect(sceneGroup,
        display.contentCenterX, display.contentCenterY + 120, 200, 60, 15)
    playBtn:setFillColor(0, 0.8, 0)

    local playText = display.newText(sceneGroup, "PLAY",
        playBtn.x, playBtn.y, native.systemFontBold, 30)
    playText:setFillColor(1,1,1)

    local quitBtn = display.newRoundedRect(sceneGroup,
        display.contentCenterX, display.contentCenterY + 200, 200, 60, 15)
    quitBtn:setFillColor(0.8, 0, 0)

    local quitText = display.newText(sceneGroup, "QUIT",
        quitBtn.x, quitBtn.y, native.systemFontBold, 30)
    quitText:setFillColor(1,1,1)

    -- =====================================================
    -- EVENTS
    -- =====================================================

    dropdownBtn:addEventListener("tap", function()
        closeDiffDropdown()
        openDropdown()
        return true
    end)

    diffBtn:addEventListener("tap", function()
        closeDropdown()
        openDiffDropdown()
        return true
    end)

    playBtn:addEventListener("tap", function()
        closeDropdown()
        closeDiffDropdown()

        composer.setVariable("timerMinutes", selectedTimer)
        composer.setVariable("difficulty", selectedDifficulty)

        composer.gotoScene("scene.menu", {effect = "fade", time = 500})
        return true
    end)

    quitBtn:addEventListener("tap", function()
        native.requestExit()
        return true
    end)
end

scene:addEventListener("create", scene)

return scene