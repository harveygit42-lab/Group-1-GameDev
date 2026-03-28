local gameDisplay = {}

function gameDisplay.create(sceneGroup)
    local displayObjs = {}

    local ok, background = pcall(function()
        local bg = display.newImageRect(sceneGroup, "images/morningBg.png", 480, 800)
        bg.x = display.contentCenterX
        bg.y = display.contentCenterY
        bg.isHitTestable = true
        return bg
    end)
    displayObjs.background = ok and background or nil

    ok, displayObjs.platform = pcall(function()
        local p = display.newImageRect(sceneGroup, "images/platform.png", 450, 50)
        p.x = display.contentCenterX
        p.y = display.contentHeight - 25
        return p
    end)

    ok, displayObjs.tapText = pcall(function()
        local t = display.newText(sceneGroup, "0", display.contentCenterX, 60, "PressStart2P", 60)
        t:setFillColor(0, 1, 0)
        return t
    end)

    ok, displayObjs.balloon = pcall(function()
        local b = display.newImageRect(sceneGroup, "images/morningBalloon.png", 20, 20)
        b.x = display.contentCenterX
        b.y = display.contentCenterY
        return b
    end)

    return displayObjs
end

function gameDisplay.addPhysics(displayObjs, physics)
    if not displayObjs or not physics then return end
    if displayObjs.platform then
        physics.addBody(displayObjs.platform, "static")
    end
    if displayObjs.balloon then
        physics.addBody(displayObjs.balloon, "dynamic", {radius = 55, bounce = 0.05})
    end
end

function gameDisplay.cleanup(displayObjs)
    if not displayObjs then return end
    local remove = function(v) if v then pcall(function() display.remove(v) end) end end
    remove(displayObjs.background)
    remove(displayObjs.platform)
    remove(displayObjs.tapText)
    remove(displayObjs.balloon)
    displayObjs.background = nil
    displayObjs.platform = nil
    displayObjs.tapText = nil
    displayObjs.balloon = nil
end

return gameDisplay
