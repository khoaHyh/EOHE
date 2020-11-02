--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]]

require 'Util'

Map = Class{}

TILE_EMPTY = -1

GROUND_LEFT = 5
GROUND_MIDDLE = 6
GROUND_RIGHT = 7

DIRT_LEFT = 8
DIRT = 9
DIRT_RIGHT = 10

BOT_LEFT = 16
BOT_MID = 13
BOT_RIGHT = 17

-- Platform tiles
PLAT_LEFT = 18
PLAT_MID = 19
PLAT_RIGHT = 20

-- Bones
SKULL_ONE = 1
SKULL_TWO = 2
BONES_ONE = 3
BONES_TWO = 4

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- constructor for our map object
function Map:init()

    -- graveyard tiles
    self.graveyardTiles = love.graphics.newImage('/graphics/graveyardTiles.png')
    self.graveyardTileSprites = generateQuads(self.graveyardTiles, 128, 128)

    -- graveyard objects
    self.graveyardObjects = love.graphics.newImage('/graphics/graveyardObjects.png')

    self.tileWidth = 32
    self.tileHeight = 32
    self.mapWidth = 80
    self.mapHeight = 24
    self.tiles = {}

    -- applies positive Y influence on anything affected
    self.gravity = 20

    -- Y-coordinate of the ground
    GROUND_LEVEL = self.mapHeight / 2 + 10

    -- associate player with map
    self.player = Player(self)

    -- initiale moving object and associate with map
    -- -1 on x and y coordinates 
    movingObj1 = MovingObj(self, 53 * self.tileWidth, (GROUND_LEVEL - 10) * self.tileHeight, 32, 32, GROUND_MIDDLE)
    movingObj2 = MovingObj(self, 56 * self.tileWidth, (GROUND_LEVEL - 4) * self.tileHeight, 32, 32, GROUND_MIDDLE)
    movingObj3 = MovingObj(self, 59 * self.tileWidth, (GROUND_LEVEL - 10) * self.tileHeight, 32, 32, GROUND_MIDDLE)
    movingObj4 = MovingObj(self, 62 * self.tileWidth, (GROUND_LEVEL - 4) * self.tileHeight, 32, 32, GROUND_MIDDLE)
    movingObj5 = MovingObj(self, 65 * self.tileWidth, (GROUND_LEVEL - 10) * self.tileHeight, 32, 32, GROUND_MIDDLE)
    movingObj6 = MovingObj(self, 68 * self.tileWidth, (GROUND_LEVEL - 4) * self.tileHeight, 32, 32, GROUND_MIDDLE)
    movingObj7 = MovingObj(self, 68 * self.tileWidth, (GROUND_LEVEL - 11) * self.tileHeight, 32, 32, GROUND_MIDDLE)

    -- graveyard objects
    tree = love.graphics.newQuad(106, 167, 306, 239, self.graveyardObjects:getDimensions())
    round_tombstone = love.graphics.newQuad(102, 0, 54, 56, self.graveyardObjects:getDimensions())
    start_sign = love.graphics.newQuad(53, 65, 85, 95, self.graveyardObjects:getDimensions())
    skeleton = love.graphics.newQuad(0, 0, 102, 48, self.graveyardObjects:getDimensions())

    -- camera offsets
    self.camX = 0
    self.camY = 48

    -- moving platform state
    self.platDirection = 'right'

    -- cache width and height of map in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- first, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- begin generating the terrain using vertical scan lines
    local x = 1
    while x <= self.mapWidth do

        -- long platforms
        if x == 10 then
            self:setTile(x, GROUND_LEVEL - 2, PLAT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 2, PLAT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 2, PLAT_RIGHT)

            self:setTile(x, GROUND_LEVEL - 6, PLAT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 6, PLAT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 6, PLAT_RIGHT)

            self:setTile(x, GROUND_LEVEL - 10, PLAT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 10, PLAT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 10, PLAT_RIGHT)
        end

        if x == 16 then
            self:setTile(x, GROUND_LEVEL - 4, PLAT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 4, PLAT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 4, PLAT_RIGHT)

            self:setTile(x, GROUND_LEVEL - 8, PLAT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 8, PLAT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 8, PLAT_RIGHT)

            self:setTile(x, GROUND_LEVEL - 12, PLAT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 12, PLAT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 12, PLAT_RIGHT)
        end

        -- short platforms
        if x == 24 then
            self:setTile(x, GROUND_LEVEL - 4, GROUND_MIDDLE)
        end

        if x == 27 then
            self:setTile(x, GROUND_LEVEL - 4, GROUND_MIDDLE)

            self:setTile(x, GROUND_LEVEL - 8, GROUND_MIDDLE)

            self:setTile(x, GROUND_LEVEL - 12, GROUND_MIDDLE)
        end

        if x == 30 then
            self:setTile(x, GROUND_LEVEL - 6, GROUND_MIDDLE)

            self:setTile(x, GROUND_LEVEL - 10, GROUND_MIDDLE)

            self:setTile(x, GROUND_LEVEL - 14, GROUND_MIDDLE)
        end

        -- horizontal zig-zag
        if x == 33 then
            self:setTile(x, GROUND_LEVEL - 12, GROUND_MIDDLE)
        end

        if x == 36 then
            self:setTile(x, GROUND_LEVEL - 14, GROUND_MIDDLE)
        end

        if x == 39 then
            self:setTile(x, GROUND_LEVEL - 12, GROUND_MIDDLE)
        end

        if x == 42 then
            self:setTile(x, GROUND_LEVEL - 14, GROUND_MIDDLE)
        end

        if x == 45 then
            self:setTile(x, GROUND_LEVEL - 12, GROUND_MIDDLE)
        end

        if x == 48 then
            self:setTile(x, GROUND_LEVEL - 14, GROUND_MIDDLE)
        end

        if x == 51 then
            self:setTile(x, GROUND_LEVEL - 6, GROUND_MIDDLE)
        end

        -- draw ending platform
        if x == 72 then
            self:setTile(x, GROUND_LEVEL - 10, GROUND_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 10, GROUND_MIDDLE)
            self:setTile(x + 2, GROUND_LEVEL - 10, GROUND_RIGHT)

            self:setTile(x, GROUND_LEVEL - 9, DIRT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 9, DIRT)
            self:setTile(x + 2, GROUND_LEVEL - 9, DIRT_RIGHT)

            self:setTile(x, GROUND_LEVEL - 8, BOT_LEFT)
            self:setTile(x + 1, GROUND_LEVEL - 8, BOT_MID)
            self:setTile(x + 2, GROUND_LEVEL - 8, BOT_RIGHT)
        end

        -- generate the floor tiles
        self:setTile(x, GROUND_LEVEL, GROUND_MIDDLE)

        -- generate column of dirt beneath floor tiles
        for y = self.mapHeight / 2 + 11, self.mapHeight do
            self:setTile(x, y, DIRT)
        end

        -- advance to the next vertical scan line
        x = x + 1
    end
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        GROUND_LEFT, GROUND_MIDDLE, GROUND_RIGHT, DIRT_LEFT, DIRT, DIRT_RIGHT, 
        BOT_LEFT, BOT_MID, BOT_RIGHT, PLAT_LEFT, PLAT_MID, PLAT_RIGHT
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)
    self.player:resolveCollision(movingObj1)
    self.player:resolveCollision(movingObj2)
    self.player:resolveCollision(movingObj3)
    self.player:resolveCollision(movingObj4)
    self.player:resolveCollision(movingObj5)
    self.player:resolveCollision(movingObj6)
    self.player:resolveCollision(movingObj7)
    
    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - WINDOW_WIDTH / 2,
        math.min(self.mapWidthPixels - WINDOW_WIDTH, self.player.x)))

    -- update our moving object based on its DX and DY
    -- scale the velocity by dt so movement is framerate-independent
    -- remember that x and y values need a -1 and on top of the value you desire
    movingObj1:moveY((GROUND_LEVEL - 10) * self.tileHeight, (GROUND_LEVEL - 4) * self.tileHeight)
    movingObj2:moveY((GROUND_LEVEL - 10) * self.tileHeight, (GROUND_LEVEL - 4) * self.tileHeight)
    movingObj3:moveY((GROUND_LEVEL - 10) * self.tileHeight, (GROUND_LEVEL - 4) * self.tileHeight)
    movingObj4:moveY((GROUND_LEVEL - 10) * self.tileHeight, (GROUND_LEVEL - 4) * self.tileHeight)
    movingObj5:moveY((GROUND_LEVEL - 10) * self.tileHeight, (GROUND_LEVEL - 4) * self.tileHeight)
    movingObj6:moveY((GROUND_LEVEL - 10) * self.tileHeight, (GROUND_LEVEL - 4) * self.tileHeight)
    movingObj7:moveX(53 * self.tileWidth, 68 * self.tileWidth)

    movingObj1:update(dt)
    movingObj2:update(dt)
    movingObj3:update(dt)
    movingObj4:update(dt)
    movingObj5:update(dt)
    movingObj6:update(dt)
    movingObj7:update(dt)
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- renders our map to the screen, to be called by main's render
function Map:render()

    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight, 0, 0.25, 0.25)
            end
        end
    end

    -- draw bones in the ground
    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[SKULL_TWO], 
        3 * self.tileWidth, (GROUND_LEVEL) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[BONES_TWO], 
        10 * self.tileWidth, (GROUND_LEVEL - 1) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[SKULL_TWO], 
        24 * self.tileWidth, (GROUND_LEVEL - 1) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[BONES_ONE], 
        35 * self.tileWidth, (GROUND_LEVEL) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[BONES_TWO], 
        45 * self.tileWidth, (GROUND_LEVEL - 1) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[SKULL_TWO], 
        50 * self.tileWidth, (GROUND_LEVEL) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[BONES_ONE], 
        63 * self.tileWidth, (GROUND_LEVEL) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[BONES_ONE], 
        71 * self.tileWidth, (GROUND_LEVEL) * self.tileHeight, 0, 0.5, 0.5)

    love.graphics.draw(self.graveyardTiles, self.graveyardTileSprites[SKULL_ONE], 
        78 * self.tileWidth, (GROUND_LEVEL - 1) * self.tileHeight, 0, 0.5, 0.5)

    -- draw tree
    love.graphics.draw(self.graveyardObjects, tree, 35 * self.tileWidth, 
        (GROUND_LEVEL - 8) * self.tileHeight, 0, 0.94, 0.94)

    -- draw round tombstone
    love.graphics.draw(self.graveyardObjects, round_tombstone, 71.7 * self.tileWidth, 
        (GROUND_LEVEL - 12) * 29.7, 0, 1, 1)

    -- draw start sign
    love.graphics.draw(self.graveyardObjects, start_sign, 6 * self.tileWidth, 
        (GROUND_LEVEL - 4) * self.tileHeight, 0, 1, 1)

    -- draw skeleton
    love.graphics.draw(self.graveyardObjects, skeleton, 71.7 * self.tileWidth,
        (GROUND_LEVEL - 10) * self.tileHeight, 0, 0.5, 0.5)

    -- render player onto map
    self.player:render()

    -- render moving objects onto map
    movingObj1:render()
    movingObj2:render()
    movingObj3:render()
    movingObj4:render()
    movingObj5:render()
    movingObj6:render()
    movingObj7:render()
end