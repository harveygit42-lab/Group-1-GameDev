local composer = require("composer")
local scene = composer.newScene()

-- =====================================================
-- VARIABLES
-- =====================================================

local selectedTimer = "None"
local selectedDifficulty = "None"
local myFont = "PressStart2P" 

-- =====================================================
-- SCENE CREATE
-- =====================================================

function scene:create(event)
    local sceneGroup = self.view

    -- Background
    local background = display.newImageRect(sceneGroup, "images/background.jpg", 480, 800)
    background.x = display.contentCenterX
    background.y = display.contentCenterY

    -- Faint screen shadow for better text visibility
    local shadow = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    shadow:setFillColor(0, 0, 0, 0.6)

    -- Title
    local title = display.newImageRect( sceneGroup, "images/gameTitle.png", 380, 170 )
    title.x = display.contentCenterX
    title.y = display.contentCenterY - 180

    -- Timer Selection
    -- local timerLabel = display.newImageRect( sceneGroup, "images/timer.png", 250, 20 )
    -- timerLabel.x = display.contentCenterX
    -- timerLabel.y = display.contentCenterY - 50
    -- timerLabel.anchorX = 0

    local timerText = "Select Timer (minutes):"
    local timerLabel = display.newText(sceneGroup, timerText, 0, display.contentCenterY - 50, myFont, 14)
    timerLabel:setFillColor(1, 1, 1)
    timerLabel.anchorX = 0

    -- Dropdown Button
    local dropdownBtn = display.newRoundedRect(sceneGroup, 0, display.contentCenterY - 50, 60, 30, 10)
    dropdownBtn:setFillColor(1, 1, 1)
    dropdownBtn.strokeWidth = 2
    

    local dropdownText = display.newText(sceneGroup, "None",
        dropdownBtn.x, dropdownBtn.y, myFont, 12)
    dropdownText:setFillColor(0, 0, 0)

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

        local baseY = dropdownBtn.y + dropdownBtn.height/2 + 25
        local timerOptions = {"None", "1", "2", "3", "4", "5"}
        for i = 1, #timerOptions do
            local y = baseY + (i - 1) * 40
            local optBtn = display.newRoundedRect(optionsGroup, dropdownBtn.x, y, 60, 30, 8)
            optBtn:setFillColor(1, 1, 1)
            -- optBtn.strokeWidth = 1
            optBtn:setStrokeColor(0, 0, 0)
            local optText = display.newText(optionsGroup, timerOptions[i], optBtn.x, optBtn.y, myFont, 12)
            optText:setFillColor(0, 0, 0)
            optBtn:addEventListener("tap", function()
                selectedTimer = timerOptions[i]
                dropdownText.text = timerOptions[i]
                dropdownText.x = dropdownBtn.x
                closeDropdown()
                return true
            end)
        end
    end



    -- Play Button
    local playBtn = display.newImageRect( sceneGroup, "images/playBtn.png", 150, 60 )
    playBtn.x = display.contentCenterX
    playBtn.y = display.contentCenterY + 170

    -- Quit Button
    local quitBtn = display.newImageRect( sceneGroup, "images/exitBtn.png", 150, 60 )
    quitBtn.x = display.contentCenterX
    quitBtn.y = display.contentCenterY + 250

    local showCredits

    -- Info Icon (top right)
    local infoIcon = display.newImageRect( sceneGroup, "images/iButton.png", 40, 40 )
    infoIcon.x = 440
    infoIcon.y = 40
    -- local infoIcon = display.newText(sceneGroup, "i", display.safeScreenOriginX + display.safeActualContentWidth - 30, display.safeScreenOriginY + 30, native.systemFontBold, 40)
    -- infoIcon:setFillColor(0, 0, 0)

    infoIcon:addEventListener("tap", function()
        if showCredits then
            showCredits()
        end
        return true
    end)

    -- =====================================================
    -- DIFFICULTY DROPDOWN
    -- =====================================================

    showCredits = function()
        closeDropdown()  -- Close dropdown if open
        -- Create overlay
        local overlay = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
        overlay:setFillColor(0, 0, 0, 0.5)
        overlay:addEventListener("tap", function() return true end)  -- Prevent tapping through

        -- Developer image
        local developersImage = display.newImageRect(sceneGroup, "images/developers.png", 350, 350)
        developersImage.x = display.contentCenterX
        developersImage.y = display.contentCenterY

        -- Close button
        local closeBtn = display.newImageRect(sceneGroup, "images/closeBtn.png", 30, 30)
        closeBtn.x = developersImage.x + developersImage.width/2 - 50
        closeBtn.y = developersImage.y - developersImage.height/2 + 50

        local function closeCredits()
            display.remove(overlay)
            display.remove(developersImage)
            display.remove(closeBtn)
        end

        closeBtn:addEventListener("tap", closeCredits)
    end





    -- =====================================================
    -- EVENTS
    -- =====================================================

    dropdownBtn:addEventListener("tap", function()
        openDropdown()
        return true
    end)

    playBtn:addEventListener("tap", function()
        closeDropdown()
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