local composer = require("composer")
local scene = composer.newScene()

local background
local startBtn

function scene:create(event)
    local sceneGroup = self.view

    local clickSound = audio.loadSound("clickSound.mp3")

    background = display.newImageRect("background.jpg", display.actualContentWidth, display.actualContentHeight)
    background.x = display.contentCenterX
    background.y = display.contentCenterY
    sceneGroup:insert(background)

    playBtn = display.newImageRect("playBtn.png", 170, 90)
    playBtn.x = display.contentCenterX
    playBtn.y = display.contentCenterY + 60
    sceneGroup:insert(playBtn)

    settingBtn = display.newImageRect("settingBtn.png",100, 60)
    settingBtn.x = display.contentCenterX
    settingBtn.y = display.contentCenterY + 180
    sceneGroup:insert(settingBtn)

    -- settings overlay / mute toggle
    local function showSettingsOverlay()
        if scene._settingsOverlay then return end

        local isMuted = composer.getVariable("isMuted") or false

        local overlayGroup = display.newGroup()

        local overlayBg = display.newRect(display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
        overlayBg:setFillColor(0,0,0,0.5)
        overlayGroup:insert(overlayBg)
        local function swallow() return true end
        overlayBg:addEventListener("tap", swallow)
        overlayBg:addEventListener("touch", swallow)

        local box = display.newRoundedRect(display.contentCenterX, display.contentCenterY, 320, 220, 12)
        box:setFillColor(1,1,1)
        overlayGroup:insert(box)

        local title = display.newText("Settings", display.contentCenterX, display.contentCenterY - 80, "PixelFont.ttf", 28)
        title:setFillColor(0)
        overlayGroup:insert(title)

        local muteLabel = display.newText("Mute:", display.contentCenterX - 60, display.contentCenterY - 20, "PixelFont.ttf", 24)
        muteLabel:setFillColor(0)
        overlayGroup:insert(muteLabel)

        local muteStateText = display.newText(isMuted and "On" or "Off", display.contentCenterX + 60, display.contentCenterY - 20, "PixelFont.ttf", 24)
        muteStateText:setFillColor(0)
        overlayGroup:insert(muteStateText)

        local muteBtn = display.newRect(display.contentCenterX + 60, display.contentCenterY - 20, 80, 36)
        muteBtn:setFillColor(0.9)
        overlayGroup:insert(muteBtn)

        -- visual mute icon (speaker + slash when muted)
        local muteIconGroup = display.newGroup()
        local iconX = display.contentCenterX + 60 - 70
        local iconY = display.contentCenterY - 20

        local speaker = display.newRect(0, 0, 12, 12)
        speaker.anchorX = 0
        speaker.anchorY = 0.5
        speaker.x = -6
        speaker.y = 0
        speaker:setFillColor(0)
        muteIconGroup:insert(speaker)

        local cone = display.newPolygon(10, 0, {0,-8, 20,0, 0,8})
        cone:setFillColor(0)
        muteIconGroup:insert(cone)

        local slash = display.newLine(-12, -10, 12, 10)
        slash.strokeWidth = 3
        slash:setStrokeColor(1, 0, 0)
        slash.isVisible = isMuted
        muteIconGroup:insert(slash)

        muteIconGroup.x = iconX
        muteIconGroup.y = iconY
        overlayGroup:insert(muteIconGroup)

        local function toggleMute()
            audio.play(clickSound)
            isMuted = not isMuted
            composer.setVariable("isMuted", isMuted)

            -- animate button press
            transition.to(muteBtn, {time=80, xScale=0.95, yScale=0.95, onComplete=function()
                transition.to(muteBtn, {time=80, xScale=1, yScale=1})
            end})

            -- update audio state
            if isMuted then
                audio.setVolume(0)
                muteBtn:setFillColor(0.6, 0.2, 0.2)
                muteStateText.text = "Muted"
                slash.isVisible = true
            else
                audio.setVolume(0.3)
                muteBtn:setFillColor(0.9)
                muteStateText.text = "On"
                slash.isVisible = false
            end

            return true
        end
        muteBtn:addEventListener("tap", toggleMute)

        local closeBtn = display.newText("Close", display.contentCenterX, display.contentCenterY + 70, "PixelFont.ttf", 22)
        closeBtn:setFillColor(0)
        overlayGroup:insert(closeBtn)

        local function closeOverlay()
            audio.play(clickSound)
            display.remove(overlayGroup)
            scene._settingsOverlay = nil
            return true
        end
        closeBtn:addEventListener("tap", closeOverlay)

        scene._settingsOverlay = overlayGroup
        sceneGroup:insert(overlayGroup)
    end

    
    local selectedTime = nil -- default: no timer

    local timeLabel = display.newText("Timer: Off", display.contentCenterX, display.contentCenterY - 40, "PixelFont.ttf", 28)
    timeLabel:setFillColor(0,0,0)
    sceneGroup:insert(timeLabel)

    local function updateSelectionDisplay()
        if selectedTime then
            timeLabel.text = "Time: " .. selectedTime .. "s"
        else
            timeLabel.text = "Timer: Off"
        end
    end

    -- local function settings ()

    local function selectTime(t, playSound)
        if selectedTime == t then return end
       
        selectedTime = t
        updateSelectionDisplay()

        if playSound then
            audio.play(clickSound)
        end

        -- highlight selection colors
        if timeOff then timeOff:setFillColor(0,0,0) end
        if time30 then time30:setFillColor(0,0,0) end
        if time60 then time60:setFillColor(0,0,0) end
        if time90 then time90:setFillColor(0,0,0) end
        if t == nil and timeOff then timeOff:setFillColor(0,1,0)
        elseif t == 30 and time30 then time30:setFillColor(0,1,0)
        elseif t == 60 and time60 then time60:setFillColor(0,1,0)
        elseif t == 90 and time90 then time90:setFillColor(0,1,0) end
    end

    local timeOff = display.newText("Off", display.contentCenterX - 120, display.contentCenterY - 10, "PixelFont.ttf", 22)
    local time30 = display.newText("30s", display.contentCenterX - 40, display.contentCenterY - 10, "PixelFont.ttf", 22)
    local time60 = display.newText("60s", display.contentCenterX + 40, display.contentCenterY - 10, "PixelFont.ttf", 22)
    local time90 = display.newText("90s", display.contentCenterX + 120, display.contentCenterY - 10, "PixelFont.ttf", 22)
    
    timeOff:setFillColor(0,0,0)
    time30:setFillColor(0,0,0)
    time60:setFillColor(0,0,0)
    
    time90:setFillColor(0,0,0)
    sceneGroup:insert(timeOff)
    sceneGroup:insert(time30)
    sceneGroup:insert(time60)
    sceneGroup:insert(time90)

    local function onOff() selectTime(nil, true) end
    local function on30() selectTime(30, true) end
    local function on60() selectTime(60, true) end
    local function on90() selectTime(90, true) end

    timeOff:addEventListener("tap", onOff)
    time30:addEventListener("tap", on30)
    time60:addEventListener("tap", on60)
    time90:addEventListener("tap", on90)

    -- set initial display
    selectTime(nil, false)

    local function goToGame()
        if selectedTime then
            composer.gotoScene("game", { effect = "fade", time = 400, params = { timeLimit = selectedTime } })
        else
            composer.gotoScene("game", { effect = "fade", time = 400 })
        end
    end

    playBtn:addEventListener("tap", goToGame)
    self._goToGame = goToGame

    local function onSettings()
        showSettingsOverlay()
    end

    settingBtn:addEventListener("tap", onSettings)
    self._onSettings = onSettings
end



function scene:destroy(event)
    if playBtn and self._goToGame then
        playBtn:removeEventListener("tap", self._goToGame)
    end
end


scene:addEventListener("create", scene)
scene:addEventListener("destroy", scene)
return scene