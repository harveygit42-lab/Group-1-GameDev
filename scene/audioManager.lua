--[[
    Audio Manager Module
    Handles all audio operations (music and sound effects)
]]

local audioManager = {}

local backgroundMusic = nil
local bgChannel = nil
local popSound = nil
local gameOverSound = nil
local musicOn = true
local sfxOn = true

-- =====================================================
-- INITIALIZATION
-- =====================================================

function audioManager.init(musicSetting, sfxSetting)
    musicOn = musicSetting or true
    sfxOn = sfxSetting or true
    -- Reserve one channel for background music and one for SFX
    pcall(function() audio.reserveChannels(4) end)
end

-- =====================================================
-- MUSIC CONTROL
-- =====================================================

function audioManager.stopMusic()
    if bgChannel then
        audio.stop(bgChannel)
        bgChannel = nil
    end
end

function audioManager.playMusic()
    audioManager.stopMusic()
    if musicOn and backgroundMusic then
        bgChannel = audio.play(backgroundMusic, {loops = -1, channel = 1})
        return true
    end
    return false
end

-- =====================================================
-- LOAD AUDIO FILES
-- =====================================================

function audioManager.loadBackgroundMusic()
    -- Always reload if disposed or not loaded
    if not backgroundMusic then
        local ok, m = pcall(function() return audio.loadStream("bgmusic/bgmusic.mp3") end)
        if ok and m then
            backgroundMusic = m
            return true
        end
        return false
    end
    return true
end

function audioManager.loadPopSound()
    if popSound then return true end
    local ok, sound = pcall(function() return audio.loadSound("bgmusic/pop.mp3") end)
    if ok and sound then
        popSound = sound
        return true
    end
    return false
end

function audioManager.loadGameOverSound()
    if gameOverSound then return true end
    local ok, sound = pcall(function() return audio.loadSound("bgmusic/gameOver.mp3") end)
    if ok and sound then
        gameOverSound = sound
        return true
    end
    return false
end

-- =====================================================
-- PLAY SOUND EFFECTS
-- =====================================================

function audioManager.playPopSound()
    if sfxOn and popSound then
        pcall(function() audio.play(popSound, {channel = 2}) end)
    end
end

function audioManager.playGameOverSound()
    if sfxOn and gameOverSound then
        pcall(function() audio.play(gameOverSound, {channel = 2}) end)
    end
end

-- =====================================================
-- SETTERS
-- =====================================================

function audioManager.setMusicOn(value)
    musicOn = value
end

function audioManager.setSfxOn(value)
    sfxOn = value
end

function audioManager.getBackgroundMusic()
    return backgroundMusic
end

-- =====================================================
-- CLEANUP
-- =====================================================

function audioManager.cleanup()
    audioManager.stopMusic()
    -- Don't dispose backgroundMusic here - it should persist across games
    if popSound then
        pcall(function() audio.dispose(popSound) end)
        popSound = nil
    end
    if gameOverSound then
        pcall(function() audio.dispose(gameOverSound) end)
        gameOverSound = nil
    end
end

return audioManager
