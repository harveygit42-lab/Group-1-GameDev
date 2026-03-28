-- Bird Manager Module
-- Handles bird spawning and removal based on difficulty level

local birdsModule = {}
local physics = require("physics")

-- =====================================================
-- BIRD CONFIGURATION BY DIFFICULTY
-- =====================================================

local difficultyConfig = {
    None = {
        count = 0,
        initialDelay = 0,           -- ms before first spawn
        spawnInterval = 10000,      -- irrelevant
        displayDuration = 5000,     -- irrelevant
        minSpeed = 150,
        maxSpeed = 150,
    },
    Easy = {
        count = 1,
        initialDelay = 5000,        -- 5 seconds delay
        spawnInterval = 5000,      -- 5 seconds
        displayDuration = 10000,    -- 10 seconds
        minSpeed = 60,              -- slower
        maxSpeed = 120,
    },
    Medium = {
        count = 2,
        initialDelay = 4000,        -- 4 seconds delay
        spawnInterval = 4000,      -- 4 seconds
        displayDuration = 8000,    -- 8 seconds
        minSpeed = 120,             -- normal
        maxSpeed = 200,
    },
    Hard = {
        count = 3,
        initialDelay = 2000,           -- 2 seconds delay
        spawnInterval = 3000,       -- 3 seconds
        displayDuration = math.huge, -- indefinite
        minSpeed = 180,             -- faster
        maxSpeed = 280,
    }
}

-- =====================================================
-- BIRD MANAGER INITIALIZATION
-- =====================================================

function birdsModule.init(sceneGroup, difficulty)
    local self = {}
    
    self.sceneGroup = sceneGroup
    self.difficulty = difficulty or "None"
    self.birds = {}
    self.birdTimers = {}
    self.active = false
    self.spawnTimer = nil
    self.config = difficultyConfig[self.difficulty] or difficultyConfig["None"]
    
    -- =====================================================
    -- HELPER FUNCTIONS
    -- =====================================================
    
    local function getRandomXPosition()
        -- Returns a random X position across the screen width
        return math.random(50, display.actualContentWidth - 50)
    end
    
    local function getRandomYPosition()
        -- Returns a random Y position in the upper half of the screen
        return math.random(50, display.contentCenterY - 100)
    end
    
    local function createBirdObject()
        -- Create a bird object with physics
        print("Creating bird object...")
        local bird
        local birdCreated = pcall(function()
            bird = display.newImageRect(self.sceneGroup, "images/bird.png", 60, 60)
        end)
        
        -- Fallback: create a colored rect if image fails
        if not birdCreated or not bird then
            print("Bird image failed to load, using red rectangle fallback")
            bird = display.newRect(self.sceneGroup, 0, 0, 60, 60)
            bird:setFillColor(1, 0, 0)  -- Red rectangle as fallback
        end
        
        -- Randomly decide if bird comes from left or right
        local fromLeft = math.random() < 0.5
        if fromLeft then
            bird.x = -32  -- Start off-screen on the left
            bird.xScale = -1  -- Flipped (facing right)
            print("Bird spawning from left")
        else
            bird.x = display.actualContentWidth + 32  -- Start off-screen on the right
            bird.xScale = 1  -- Normal direction (facing left)
            print("Bird spawning from right")
        end
        
        -- Randomize Y position more (entire upper half of screen)
        bird.y = math.random(30, display.contentCenterY + 100)
        
        -- Add physics body (make it a sensor so it doesn't interfere with balloon physics)
        pcall(function()
            physics.addBody(bird, "kinematic", {radius = 32, isSensor = true})
        end)
        
        -- Set velocity based on difficulty
        local minSpeed = self.config.minSpeed or 120
        local maxSpeed = self.config.maxSpeed or 200
        local birdSpeed = math.random(minSpeed, maxSpeed)
        print("Bird speed: " .. birdSpeed)
        
        if fromLeft then
            bird:setLinearVelocity(birdSpeed, 0)  -- Move right
        else
            bird:setLinearVelocity(-birdSpeed, 0)  -- Move left
        end
        
        bird.isBird = true  -- Tag it as a bird for collision detection
        print("Bird object created successfully")
        
        return bird
    end
    
    local function removeBird(birdObject)
        if birdObject then
            if self.sceneGroup then
                pcall(function() display.remove(birdObject) end)
            end
            -- Remove from birds list
            for i, b in ipairs(self.birds) do
                if b == birdObject then
                    table.remove(self.birds, i)
                    break
                end
            end
        end
    end
    
    local function scheduleRemoveBird(birdObject, delayMs)
        if self.config.displayDuration ~= math.huge then
            local timerId = timer.performWithDelay(delayMs or self.config.displayDuration, function()
                removeBird(birdObject)
            end)
            table.insert(self.birdTimers, timerId)
        end
    end
    
    local function spawnBirds()
        -- Spawn birds based on the difficulty configuration
        if self.config.count == 0 then
            print("Spawn skipped: config.count is 0")
            return
        end
        
        print("Attempting to spawn " .. self.config.count .. " birds...")
        
        for i = 1, self.config.count do
            local success, bird = pcall(function()
                return createBirdObject()
            end)
            
            if success and bird then
                table.insert(self.birds, bird)
                print("Bird " .. i .. " created successfully at x=" .. bird.x .. ", y=" .. bird.y)
                
                -- Schedule removal if not indefinite
                if self.config.displayDuration ~= math.huge then
                    scheduleRemoveBird(bird, self.config.displayDuration)
                    print("Bird " .. i .. " scheduled for removal in " .. self.config.displayDuration .. "ms")
                end
            else
                print("Error creating bird " .. i .. ": " .. tostring(bird))
            end
        end
    end
    
    -- =====================================================
    -- PUBLIC METHODS
    -- =====================================================
    
    function self:startSpawning()
        if self.active or self.difficulty == "None" then
            print("Not spawning birds. Active: " .. tostring(self.active) .. ", Difficulty: " .. self.difficulty)
            return
        end
        
        print("Starting bird spawning for difficulty: " .. self.difficulty)
        self.active = true
        
        -- Schedule initial spawn with delay based on difficulty
        local initialDelay = self.config.initialDelay or 0
        print("Initial spawn delay: " .. initialDelay .. "ms")
        
        local function scheduleNextSpawn()
            if not self.active then return end
            
            -- Add randomness to spawn interval (80% to 120% of base interval)
            local randomInterval = self.config.spawnInterval * (0.8 + math.random() * 0.4)
            
            self.spawnTimer = timer.performWithDelay(randomInterval, function()
                if self.active then
                    spawnBirds()
                    print("Periodic spawn triggered. Total birds: " .. #self.birds)
                    scheduleNextSpawn()  -- Schedule next spawn with new random interval
                end
            end)
            
            -- Track the timer so it can be cancelled later
            table.insert(self.birdTimers, self.spawnTimer)
        end
        
        local function startPeriodicSpawning()
            if not self.active then return end
            
            spawnBirds()
            print("Initial birds spawned. Total birds: " .. #self.birds)
            
            -- Schedule periodic spawning with random intervals
            if self.config.count > 0 then
                scheduleNextSpawn()
            end
        end
        
        -- Delay initial spawn if needed
        if initialDelay > 0 then
            local initialTimer = timer.performWithDelay(initialDelay, startPeriodicSpawning)
            table.insert(self.birdTimers, initialTimer)
        else
            startPeriodicSpawning()
        end
    end
    
    function self:stopSpawning()
        self.active = false
        
        -- Cancel all timers
        if self.spawnTimer then
            timer.cancel(self.spawnTimer)
            self.spawnTimer = nil
        end
        
        -- Cancel all bird removal timers
        for _, timerId in ipairs(self.birdTimers) do
            if timerId then
                timer.cancel(timerId)
            end
        end
        self.birdTimers = {}
    end
    
    function self:cleanup()
        self:stopSpawning()
        
        -- Remove all birds
        while #self.birds > 0 do
            removeBird(self.birds[1])
        end
    end
    
    function self:getBirds()
        return self.birds
    end
    
    function self:getDifficulty()
        return self.difficulty
    end
    
    function self:isActive()
        return self.active
    end
    
    function self:update()
        -- Remove birds that have flown off-screen
        local birdsToRemove = {}
        for i, bird in ipairs(self.birds) do
            if bird and (bird.x < -100 or bird.x > display.actualContentWidth + 100) then
                table.insert(birdsToRemove, i)
            end
        end
        
        -- Remove birds in reverse order to maintain correct indices
        for i = #birdsToRemove, 1, -1 do
            local birdIndex = birdsToRemove[i]
            removeBird(self.birds[birdIndex])
        end
    end
    
    return self
end

return birdsModule
