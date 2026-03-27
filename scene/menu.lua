local composer = require('composer')
local scene = composer.newScene()

function scene:create(event)
    composer.gotoScene('scene.game', {effect = 'fade', time = 300})
end

scene:addEventListener('create', scene)
return scene
