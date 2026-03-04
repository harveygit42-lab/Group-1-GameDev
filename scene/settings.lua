--yasmien
local settings = {}

function settings.init(sceneGroup, display, native, timer)
    local menuPanelGroup
    local menuOpen = false
    local pausedTimerSeconds = nil
    local menuMusicLabel
    local mtIcon
    local menuSfxLabel
    local stIcon
    local timerDropdown
    local timerDropdownIcon
    local menuTimerLabel

    -- Store reference to callbacks
    local callbacks = {}

    function settings.setCallbacks(cb)
        callbacks = cb
    end

    local function addHoverEffect(rect)
        if not rect then return end
        local origColor = {rect.fill.r, rect.fill.g, rect.fill.b, rect.fill.a}
        local isHovered = false
        rect:addEventListener("mouse", function(event)
            if event.target ~= rect then return false end
            if event.isSecondaryButtonDown then return false end
            if event.type == "move" then
                local x, y = event.x, event.y
                local bounds = rect.contentBounds
                if x >= bounds.xMin and x <= bounds.xMax and y >= bounds.yMin and y <= bounds.yMax then
                    if not isHovered then
                        isHovered = true
                        pcall(function() rect:setFillColor(0.25, 1, 0.25) end)
                    end
                else
                    if isHovered then
                        isHovered = false
                        pcall(function() rect:setFillColor(unpack(origColor)) end)
                    end
                end
            elseif event.type == "leave" or event.type == "up" then
                if isHovered then
                    isHovered = false
                    pcall(function() rect:setFillColor(unpack(origColor)) end)
                end
            end
            return false
        end)
        rect:addEventListener("touch", function(event)
            if event.phase == "began" then
                pcall(function() rect:setFillColor(0.25, 1, 0.25) end)
            elseif event.phase == "ended" or event.phase == "cancelled" then
                pcall(function() rect:setFillColor(unpack(origColor)) end)
            end
            return false
        end)
    end

    local function addRedHoverEffect(rect)
        if not rect then return end
        local origColor = {rect.fill.r, rect.fill.g, rect.fill.b, rect.fill.a}
        local isHovered = false
        rect:addEventListener("mouse", function(event)
            if event.target ~= rect then return false end
            if event.isSecondaryButtonDown then return false end
            if event.type == "move" then
                local x, y = event.x, event.y
                local bounds = rect.contentBounds
                if x >= bounds.xMin and x <= bounds.xMax and y >= bounds.yMin and y <= bounds.yMax then
                    if not isHovered then
                        isHovered = true
                        pcall(function() rect:setFillColor(1, 0.5, 0.5) end)
                    end
                else
                    if isHovered then
                        isHovered = false
                        pcall(function() rect:setFillColor(unpack(origColor)) end)
                    end
                end
            elseif event.type == "leave" or event.type == "up" then
                if isHovered then
                    isHovered = false
                    pcall(function() rect:setFillColor(unpack(origColor)) end)
                end
            end
            return false
        end)
        rect:addEventListener("touch", function(event)
            if event.phase == "began" then
                pcall(function() rect:setFillColor(1, 0.5, 0.5) end)
            elseif event.phase == "ended" or event.phase == "cancelled" then
                pcall(function() rect:setFillColor(unpack(origColor)) end)
            end
            return false
        end)
    end

    local function toggleMusic()
        if not callbacks.getMusicOn then return end
        local currentMusicOn = callbacks.getMusicOn()
        callbacks.saveMusicSetting(not currentMusicOn)
        
        if menuMusicLabel and menuMusicLabel.text then
            menuMusicLabel.text = "Music: " .. (not currentMusicOn and "On" or "Off")
        end
        if mtIcon and mtIcon.text then
            mtIcon.text = (not currentMusicOn and "♪" or "⦻")
        end
    end

    local function toggleSfx()
        if not callbacks.getSfxOn then return end
        local currentSfxOn = callbacks.getSfxOn()
        callbacks.saveSfxSetting(not currentSfxOn)
        
        if menuSfxLabel and menuSfxLabel.text then
            menuSfxLabel.text = "SFX: " .. (not currentSfxOn and "On" or "Off")
        end
        if stIcon and stIcon.text then
            stIcon.text = (not currentSfxOn and "★" or "⦻")
        end
    end

    local function closeTimerDropdown()
        if timerDropdown then 
            pcall(function() display.remove(timerDropdown) end)
            timerDropdown = nil 
        end
        if timerDropdownIcon then 
            pcall(function() display.remove(timerDropdownIcon) end)
            timerDropdownIcon = nil 
        end
    end

    local function openTimerDropdown(timerBtn)
        if timerDropdown then closeTimerDropdown(); return end
        timerDropdown = display.newGroup()
        menuPanelGroup:insert(timerDropdown)
        local optsW, optsH = 110, 15
        local baseX = timerBtn.x
        local baseY = timerBtn.y - 25 + optsH / 2 + 8

        for i = 1, 5 do
            local y = baseY + (i - 1) * (optsH + 6)
            pcall(function()
                local optBg = display.newRoundedRect(timerDropdown, baseX, y, optsW, optsH, 6)
                optBg:setFillColor(0, 0.5, 0)
                addHoverEffect(optBg)
                local txt = display.newText(timerDropdown, tostring(i) .. " min", baseX, y, native.systemFont, 18)
                txt:setFillColor(1)
                optBg:addEventListener("tap", function()
                    callbacks.saveTimerSetting(i)
                    if menuTimerLabel and menuTimerLabel.text then
                        menuTimerLabel.text = "Timer: " .. tostring(i) .. " min"
                    end
                    
                    -- Update timer if game is running
                    if callbacks.getGameStarted() and not callbacks.getGameOver() then
                        local newSeconds = i * 60
                        callbacks.setTimerSeconds(newSeconds)
                        callbacks.updateTimerDisplay()
                        if callbacks.getGameStarted() then
                            callbacks.startCountdown(newSeconds)
                        end
                    end
                    
                    closeTimerDropdown()
                    return true
                end)
            end)
        end

        -- Add clear option
        local clearY = baseY + 5 * (optsH + 6)
        pcall(function()
            local clearBg = display.newRoundedRect(timerDropdown, baseX, clearY, optsW, optsH, 6)
            clearBg:setFillColor(0.6, 0, 0)
            addRedHoverEffect(clearBg)
            local clearTxt = display.newText(timerDropdown, "Clear timer", baseX, clearY, native.systemFontBold, 17)
            clearTxt:setFillColor(1)
            clearBg:addEventListener("tap", function()
                callbacks.setTimerCleared(true)
                if menuTimerLabel and menuTimerLabel.text then
                    menuTimerLabel.text = "Timer: (cleared)"
                end
                callbacks.removeTimerText()
                callbacks.stopCountdown()
                closeTimerDropdown()
                return true
            end)
        end)
    end

    function settings.closeMenu()
        if menuPanelGroup then
            pcall(function() display.remove(menuPanelGroup) end)
            menuPanelGroup = nil
            menuMusicLabel = nil
            mtIcon = nil
            menuSfxLabel = nil
            stIcon = nil
            menuTimerLabel = nil
        end
        closeTimerDropdown()
        if menuOpen then
            menuOpen = false
            if callbacks.getGameStarted() and not callbacks.getGameOver() then
                callbacks.physicsStart()
                if pausedTimerSeconds and not callbacks.getTimerCleared() then
                    callbacks.startCountdown(pausedTimerSeconds)
                    pausedTimerSeconds = nil
                end
            end
        end
    end

    function settings.showMenu()
        if menuPanelGroup then settings.closeMenu(); return end
        menuPanelGroup = display.newGroup()
        sceneGroup:insert(menuPanelGroup)

        pcall(function()
            local shadow = display.newRect(menuPanelGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
            shadow:setFillColor(0, 0, 0, 0.5)
            shadow:addEventListener("tap", function() settings.closeMenu(); return true end)
        end)

        pcall(function()
            local panelW, panelH = 320, 350
            local panel = display.newRoundedRect(menuPanelGroup, display.contentCenterX, display.contentCenterY, panelW, panelH, 12)
            panel:setFillColor(0.1, 0.1, 0.1)
            panel.strokeWidth = 3
            panel:setStrokeColor(1, 1, 1)

            if callbacks.getGameStarted() and not callbacks.getGameOver() then
                callbacks.physicsPause()
                menuOpen = true
                if callbacks.getGameStarted() then
                    pausedTimerSeconds = callbacks.getTimerSeconds()
                    callbacks.stopCountdown()
                end
            end

            -- Music row
            local musicLabel = display.newText(menuPanelGroup, "Music: " .. (callbacks.getMusicOn() and "On" or "Off"), display.contentCenterX - 20, display.contentCenterY - 120, native.systemFontBold, 25)
            musicLabel:setFillColor(1)
            menuMusicLabel = musicLabel

            local musicBtn = display.newRoundedRect(menuPanelGroup, display.contentCenterX, display.contentCenterY - 150, 240, 55, 8)
            musicBtn:setFillColor(0, 0, 0, 0)
            musicBtn:addEventListener("tap", function() toggleMusic(); return true end)

            mtIcon = display.newText(menuPanelGroup, (callbacks.getMusicOn() and "♪" or "⦻"), musicBtn.x + 80, musicBtn.y+20, native.systemFontBold, 40)
            mtIcon:setFillColor(1)
            mtIcon:addEventListener("tap", function() toggleMusic(); return true end)

            -- SFX row
            local sfxLabel = display.newText(menuPanelGroup, "SFX: " .. (callbacks.getSfxOn() and "On" or "Off"), display.contentCenterX - 20, display.contentCenterY - 65, native.systemFontBold, 25)
            sfxLabel:setFillColor(1)
            menuSfxLabel = sfxLabel

            local sfxBtn = display.newRoundedRect(menuPanelGroup, display.contentCenterX, display.contentCenterY - 100, 240, 55, 8)
            sfxBtn:setFillColor(0, 0, 0, 0)
            sfxBtn:addEventListener("tap", function() toggleSfx(); return true end)

            stIcon = display.newText(menuPanelGroup, (callbacks.getSfxOn() and "★" or "⦻"), sfxBtn.x + 80, sfxBtn.y + 33, native.systemFontBold, 40)
            stIcon:setFillColor(1)
            stIcon:addEventListener("tap", function() toggleSfx(); return true end)

            -- Timer row (dropdown)
            local menuTimerLabelText = (callbacks.getTimerCleared() and "Timer: (cleared)" or ("Timer: " .. tostring(callbacks.getTimerMinutes()) .. " min"))
            menuTimerLabel = display.newText(menuPanelGroup, menuTimerLabelText, display.contentCenterX - 25, display.contentCenterY - 15, native.systemFontBold, 25)
            menuTimerLabel:setFillColor(1)

            local timerBtn = display.newRoundedRect(menuPanelGroup, display.contentCenterX, display.contentCenterY +20, 240, 55, 8)
            timerBtn:setFillColor(0, 0, 0, 0)
            timerBtn:addEventListener("tap", function() openTimerDropdown(timerBtn); return true end)

            local timerDropdownIcon = display.newText(menuPanelGroup, "▾", timerBtn.x + 80, timerBtn.y - 30, native.systemFontBold, 40)
            timerDropdownIcon:setFillColor(1)
            timerDropdownIcon:addEventListener("tap", function() openTimerDropdown(timerBtn); return true end)

            -- High Score
            local hsText = display.newText(menuPanelGroup, "High Score: " .. tostring(callbacks.getHighScore()), display.contentCenterX, display.contentCenterY + 45, native.systemFontBold, 24)
            hsText:setFillColor(0,1,0)

            -- Close Button
            local closeBtn = display.newRoundedRect(menuPanelGroup, display.contentCenterX, display.contentCenterY + 130, 180, 35, 10)
            closeBtn:setFillColor(0, 0.6, 0)
            local closeTxt = display.newText(menuPanelGroup, "Close", closeBtn.x, closeBtn.y, native.systemFontBold, 24)
            closeTxt:setFillColor(1)
            closeBtn:addEventListener("tap", function() settings.closeMenu(); return true end)
        end)
    end

    return settings
end

return settings