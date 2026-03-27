local composer = require("composer")
local scene = composer.newScene()
local selectedTheme = "Morning"

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
    
    local closeDropdown
    local closeThemeDropdown

    -- Background
    local background = display.newImageRect(sceneGroup, "images/" .. selectedTheme:lower() .. "Bg.png", 480, 800)
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

     function closeDropdown()
        if optionsGroup then
            display.remove(optionsGroup)
            optionsGroup = nil
            dropdownOpen = false
        end
    end

    local function openDropdown()
        closeThemeDropdown() 

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

    -- Theme Selection Label
local themeLabel = display.newText(sceneGroup, "Select Theme:", 0, display.contentCenterY, myFont, 14)
themeLabel:setFillColor(1, 1, 1)
themeLabel.anchorX = 0

-- Theme Dropdown Button
local themeBtn = display.newRoundedRect(sceneGroup, 0, display.contentCenterY, 80, 30, 10)
themeBtn:setFillColor(1, 1, 1)
themeBtn.strokeWidth = 2

local themeBtnText = display.newText(sceneGroup, "Morning", themeBtn.x, themeBtn.y, myFont, 10)
themeBtnText:setFillColor(0, 0, 0)

-- Align Theme Label and Button
local themeTotalWidth = themeLabel.contentWidth + 15 + themeBtn.width
local themeStartX = display.contentCenterX - themeTotalWidth / 2
themeLabel.x = themeStartX
themeBtn.x = themeStartX + themeLabel.contentWidth + 15 + themeBtn.width/2
themeBtnText.x = themeBtn.x

-- Dropdown Logic for Theme
local themeOptionsGroup
local themeDropdownOpen = false

 function closeThemeDropdown()
    if themeOptionsGroup then
        display.remove(themeOptionsGroup)
        themeOptionsGroup = nil
        themeDropdownOpen = false
    end
end

 function openThemeDropdown()
        closeDropdown() 

        if themeDropdownOpen then closeThemeDropdown() return end
        
        themeDropdownOpen = true
        themeOptionsGroup = display.newGroup()
        sceneGroup:insert(themeOptionsGroup)

    local baseY = themeBtn.y + themeBtn.height/2 + 25
    local themes = {"Morning", "Sunset", "Night"}
    
    for i = 1, #themes do
        local y = baseY + (i - 1) * 40
        local optBtn = display.newRoundedRect(themeOptionsGroup, themeBtn.x, y, 80, 30, 8)
        optBtn:setFillColor(1, 1, 1)
        
        local optText = display.newText(themeOptionsGroup, themes[i], optBtn.x, optBtn.y, myFont, 10)
        optText:setFillColor(0, 0, 0)
        
        optBtn:addEventListener("tap", function()
            selectedTheme = themes[i]
            themeBtnText.text = themes[i]
            
            -- OPTIONAL: Change Home Screen BG immediately
            if selectedTheme == "Morning" then background.fill = { type="image", filename="images/morningBg.png" }
            elseif selectedTheme == "Sunset" then background.fill = { type="image", filename="images/sunsetBg.png" }
            elseif selectedTheme == "Night" then background.fill = { type="image", filename="images/nightBg.png" }
            end
            
            closeThemeDropdown()
            return true
        end)
    end
end

themeBtn:addEventListener("tap", openThemeDropdown)

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
    -- EVENTS
    -- =====================================================

    dropdownBtn:addEventListener("tap", function()
        openDropdown()
        return true
    end)

    playBtn:addEventListener("tap", function()
        if closeDropdown then closeDropdown() end
    if closeThemeDropdown then closeThemeDropdown() end
        composer.setVariable("timerMinutes", selectedTimer)
        composer.setVariable("difficulty", selectedDifficulty)
        composer.setVariable("theme", selectedTheme) -- Add this line before gotoScene
        composer.gotoScene("scene.game", {effect = "fade", time = 500})
        return true
    end)

    quitBtn:addEventListener("tap", function()
        native.requestExit()
        return true
    end)
end

scene:addEventListener("create", scene)

return scene