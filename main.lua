Class = require 'class'
push = require 'push'

require 'Animation'
require 'Map'
require 'Player'
require 'MovingObj'

-- actual window resolution
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- seed RNG
math.randomseed(os.time())

-- makes upscaling look pixel-y instead of blurry
love.graphics.setDefaultFilter('nearest', 'nearest')

-- an object to contain our map data
map = Map()

-- timer variables
local seconds = 0
local minutes = 0
local centiSeconds = 0
local PB_seconds = 0
local PB_minutes = 0
local PB_centiSeconds = 0

-- performs initialization of all objects and data needed by program
function love.load()

    defaultFont = love.graphics.newFont('fonts/font.ttf', 24)
    congratsFont = love.graphics.newFont('fonts/font.ttf', 56)
    love.graphics.setFont(defaultFont)

    -- import background image
    background = love.graphics.newImage('/graphics/BG.png')

    -- sets up screen resolution
    push:setupScreen(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true
    })

    love.window.setTitle("Escape On Hallow's Eve")

    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}

    startPosition = false
    finishPosition = false
    newPB = false
end

-- called whenever window is resized
function love.resize(w, h)
    push:resize(w, h)
end

-- global key pressed function
function love.keyboard.wasPressed(key)
    if (love.keyboard.keysPressed[key]) then
        return true
    else
        return false
    end
end

-- global key released function
function love.keyboard.wasReleased(key)
    if (love.keyboard.keysReleased[key]) then
        return true
    else
        return false
    end
end

-- called whenever a key is pressed
function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

-- called whenever a key is released
function love.keyreleased(key)
    love.keyboard.keysReleased[key] = true
end

-- called every frame, with dt passed in as delta in time since last frame
function love.update(dt)
    seconds = seconds + 1 * dt
    centiSeconds = 100 * (seconds - math.floor(seconds))

    if seconds >= 60 then
        minutes = minutes + 1
        seconds = 0
    end

    -- resets timer
    if startPosition then
        seconds = 0
        minutes = 0
        newPB = false
        startPosition = false
    end

    -- sets personal best
    if finishPosition then
        if PB_minutes == 0 and PB_seconds == 0 then
            PB_minutes = minutes
            PB_seconds = seconds
            PB_centiSeconds = centiSeconds
            newPB = true
        elseif minutes < PB_minutes then
            PB_minutes = minutes
            PB_seconds = seconds
            PB_centiSeconds = centiSeconds
            newPB = true
        elseif minutes == PB_minutes and seconds < PB_seconds then
            PB_seconds = seconds
            PB_centiSeconds = centiSeconds
        elseif minutes == PB_minutes and seconds == PB_seconds and centiSeconds < PB_centiSeconds then
            PB_centiSeconds = centiSeconds
        end
    end

    map:update(dt)

    -- reset all keys pressed and released this frame
    love.keyboard.keysPressed = {}
    love.keyboard.keysReleased = {}
end

-- called each frame, used to render to the screen
function love.draw()
    push:apply('start')

    -- clear screen using Mario background blue
    love.graphics.clear(1, 1, 1, 1)

    -- set background image and scale
    local sx = WINDOW_WIDTH / background:getWidth()
    local sy = WINDOW_HEIGHT / background:getHeight()
    love.graphics.draw(background, 0, 0, 0, sx, sy) 

    -- renders our map object onto the screen
    love.graphics.translate(math.floor(-map.camX + 0.5), math.floor(-map.camY + 0.5))
    map:render()

    displayFPS()
    displayTime()
    displayNewPB()

    push:apply('end')
end

function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(0, 255, 0, 255)
    -- love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), map.camX + 30, 70)
    love.graphics.print(string.format('FPS: %d', math.floor(1.0 / love.timer.getDelta())), map.camX + 30, 70)
end

function displayTime()
    love.graphics.setFont(defaultFont)
    love.graphics.setColor(255, 100 / 255, 0, 255)
    love.graphics.print(string.format('Personal Best - %d:%d:%d', PB_minutes, PB_seconds, PB_centiSeconds), map.camX + 1010, 70)
    love.graphics.print(string.format('Time passed - %d:%d:%d', minutes, seconds, centiSeconds), map.camX + 1010, 100)
end

function displayNewPB()
    if newPB then
        love.graphics.setFont(congratsFont)
        love.graphics.setColor(136 / 255, 30 / 255, 228 / 255, 255)
        love.graphics.print('Congrats!! New Personal Best!', map.camX + 250, 130)
    end
end