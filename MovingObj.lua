--[[
    Represents moving objects in the game
]]
MovingObj = Class{}

-- moving object speed
local OBJ_SPEED = 115

function MovingObj:init(map, x, y, width, height, tile)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.tile = tile

    -- velocity
    self.dx = 0
    self.dy = 0

    -- previous position
    self.last = {}
    self.last.x = self.x
    self.last.y = self.y

    -- graveyard tiles, this makes up the platforms
    self.graveyardTiles = love.graphics.newImage('/graphics/graveyardTiles.png')
    self.graveyardTileSprites = generateQuads(self.graveyardTiles, 128, 128)
end

-- Set the coordinates between which the moving object will move between
function MovingObj:moveX(pointA, pointB)
    if self.x <= pointA then
        self.dx = OBJ_SPEED
    elseif self.x >= pointB then
        self.dx = -OBJ_SPEED
    end
end

function MovingObj:moveY(pointA, pointB)
    if self.y <= pointA then
        self.dy = OBJ_SPEED
    elseif self.y >= pointB then
        self.dy = -OBJ_SPEED
    end
end

function MovingObj:update(dt)

    -- -- used to test platform movement, the 'else' condition prevented the platform from moving byitself
    -- -- comment this out when testing self-movement
    -- -- also need to change dx or dy of player when player collides with platforms
    -- if love.keyboard.isDown('a') then
    --     movingObj1.dx = -OBJ_SPEED 
    -- elseif love.keyboard.isDown('d') then
    --     movingObj1.dx = OBJ_SPEED
    -- else
    --     movingObj1.dx = 0
    -- end

    self.last.x = self.x
    self.last.y = self.y

    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function MovingObj:render()
    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[self.tile],
        self.x, self.y, 0, 0.25, 0.25)
end