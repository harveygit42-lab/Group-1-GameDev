--yasmien
local composer = require("composer")
local scene = composer.newScene()

-- =====================================================
-- GLOBAL VARIABLES
-- =====================================================

local selectedTimer = 1  -- Default to 1 minute

-- =====================================================
-- SCENE CREATE
-- =====================================================

function scene:create(event)
    local sceneGroup = self.view

    -- =====================================================
    -- DISPLAY OBJECTS
    -- =====================================================

    -- Background
    local background = display.newImageRect(sceneGroup, "images/background.jpg", 480, 800)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    -- Title
    local title = display.newText(sceneGroup, "Tap the Balloon", display.contentCenterX, display.contentCenterY - 150, native.systemFontBold, 50)
    title:setFillColor(0, 0, 0)

    -- Timer Selection
    local timerText = "Select Timer (minutes):"
    local timerLabel = display.newText(sceneGroup, timerText, 0, display.contentCenterY - 50, native.systemFontBold, 25)
    timerLabel:setFillColor(0, 0, 0)
    timerLabel.anchorX = 0

    -- Dropdown Button
    local dropdownBtn = display.newRoundedRect(sceneGroup, 0, display.contentCenterY - 50, 60, 50, 10)
    dropdownBtn:setFillColor(0.8, 0.8, 0.8)
    dropdownBtn.strokeWidth = 2
    dropdownBtn:setStrokeColor(0, 0, 0)
    local dropdownText = display.newText(sceneGroup, selectedTimer, dropdownBtn.x, dropdownBtn.y, native.systemFontBold, 20)
    dropdownText:setFillColor(0, 0, 0)

    -- Centering both as a group
    local totalWidth = timerLabel.contentWidth + 15 + dropdownBtn.width
    local startX = display.contentCenterX - totalWidth / 2
    timerLabel.x = startX
    dropdownBtn.x = startX + timerLabel.contentWidth + 15 + dropdownBtn.width/2
    dropdownText.x = dropdownBtn.x

    -- Dropdown Options Group
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
        if dropdownOpen then closeDropdown(); return end
        dropdownOpen = true
        optionsGroup = display.newGroup()
        sceneGroup:insert(optionsGroup)

        local baseY = dropdownBtn.y + dropdownBtn.height/2 + 10
        for i = 1, 5 do
            local y = baseY + (i - 1) * 35
            local optBtn = display.newRoundedRect(optionsGroup, dropdownBtn.x, y, 60, 30, 8)
            optBtn:setFillColor(0.9, 0.9, 0.9)
            optBtn.strokeWidth = 1
            optBtn:setStrokeColor(0, 0, 0)
            local optText = display.newText(optionsGroup, tostring(i), optBtn.x, optBtn.y, native.systemFontBold, 18)
            optText:setFillColor(0, 0, 0)
            optBtn:addEventListener("tap", function()
                selectedTimer = i
                dropdownText.text = tostring(i)
                closeDropdown()
                return true
            end)
        end
    end

    -- Play Button
    local playBtn = display.newRoundedRect(sceneGroup, display.contentCenterX, display.contentCenterY + 100, 200, 60, 15)
    playBtn:setFillColor(0, 0.8, 0)
    playBtn.strokeWidth = 3
    playBtn:setStrokeColor(0, 0, 0)
    local playText = display.newText(sceneGroup, "PLAY", playBtn.x, playBtn.y, native.systemFontBold, 30)
    playText:setFillColor(1, 1, 1)

    -- Quit Button
    local quitBtn = display.newRoundedRect(sceneGroup, display.contentCenterX, display.contentCenterY + 180, 200, 60, 15)
    quitBtn:setFillColor(0.8, 0, 0)
    quitBtn.strokeWidth = 3
    quitBtn:setStrokeColor(0, 0, 0)
    local quitText = display.newText(sceneGroup, "QUIT", quitBtn.x, quitBtn.y, native.systemFontBold, 30)
    quitText:setFillColor(1, 1, 1)

    -- Info Icon (top right)
    local infoIcon = display.newText(sceneGroup, "i", display.safeScreenOriginX + display.safeActualContentWidth - 30, display.safeScreenOriginY + 30, native.systemFontBold, 40)
    infoIcon:setFillColor(0, 0, 0)

    -- =====================================================
    -- FUNCTIONS
    -- =====================================================

    local function showCredits()
        closeDropdown()  -- Close dropdown if open
        -- Create overlay
        local overlay = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
        overlay:setFillColor(0, 0, 0, 0.5)
        overlay:addEventListener("tap", function() return true end)  -- Prevent tapping through

        -- White rounded box
        local boxWidth, boxHeight = 300, 200
        local creditsBox = display.newRoundedRect(sceneGroup, display.contentCenterX, display.contentCenterY, boxWidth, boxHeight, 20)
        creditsBox:setFillColor(1, 1, 1)
        creditsBox.strokeWidth = 3
        creditsBox:setStrokeColor(0, 0, 0)

        -- Developer text
        local creditsText = display.newText(sceneGroup, "Developed by\nYasmien", display.contentCenterX, display.contentCenterY, native.systemFontBold, 30)
        creditsText:setFillColor(0, 0, 0)

        -- Exit icon (X)
        local exitIcon = display.newText(sceneGroup, "X", creditsBox.x + boxWidth/2 - 20, creditsBox.y - boxHeight/2 + 20, native.systemFontBold, 30)
        exitIcon:setFillColor(1, 0, 0)

        local function closeCredits()
            display.remove(overlay)
            display.remove(creditsBox)
            display.remove(creditsText)
            display.remove(exitIcon)
        end

        exitIcon:addEventListener("tap", closeCredits)
    end

    -- =====================================================
    -- EVENT LISTENERS
    -- =====================================================

    dropdownBtn:addEventListener("tap", function() openDropdown(); return true end)

    playBtn:addEventListener("tap", function()
        closeDropdown()  -- Ensure dropdown is closed
        composer.setVariable("timerMinutes", selectedTimer)
        composer.gotoScene("scene.menu", {effect = "fade", time = 500})
        return true
    end)

    quitBtn:addEventListener("tap", function()
        closeDropdown()  -- Ensure dropdown is closed
        native.requestExit()
        return true
    end)

    infoIcon:addEventListener("tap", function()
        showCredits()
        return true
    end)
end

scene:addEventListener("create", scene)

return scene