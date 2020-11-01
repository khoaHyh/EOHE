--[[
    Represents our player in the game, with its own sprite.
]]

Player = Class{}

local WALKING_SPEED = 115
local JUMP_VELOCITY = 450

function Player:init(map)
    
    self.x = 0
    self.y = 0
    self.width = 48
    self.height = 60

    -- offset from top left to center to support sprite flipping
    self.xOffset = 0
    self.yOffset = 0

    -- reference to map for checking tiles
    self.map = map

    -- Tiny Zombie One
    self.tz1 = love.graphics.newImage('/graphics/TinyZombie1.png')

    -- sound effects
    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
    }

    -- animation frames
    self.tz1Frames = generateQuads(self.tz1, 245, 285)

    -- current animation frame
    self.currentFrame = nil

    -- used to determine behavior and animations
    self.state = 'idle'

    -- determines sprite flipping
    self.direction = 'left'

    -- x and y velocity
    self.dx = 0
    self.dy = 0

    -- position sprite on top of map tiles
    self.y = map.tileHeight * ((map.mapHeight - 2) / 2 + 10) - self.height
    self.x = map.tileWidth * 3

    self.last = {}
    self.last.x = self.x
    self.last.y = self.y

    -- initialize all player animations
    self.animations = {
        ['idle'] = Animation({
            texture = self.tz1,
            frames = {
                self.tz1Frames[1], self.tz1Frames[2], self.tz1Frames[3], self.tz1Frames[4], self.tz1Frames[5], 
                self.tz1Frames[6], self.tz1Frames[7], self.tz1Frames[8], self.tz1Frames[9], self.tz1Frames[10], 
                self.tz1Frames[11], self.tz1Frames[12]
            }
        }),
        ['walking'] = Animation({
            texture = self.tz1,
            frames = {
                self.tz1Frames[19], self.tz1Frames[20], self.tz1Frames[21], self.tz1Frames[22], self.tz1Frames[23], 
                self.tz1Frames[24], self.tz1Frames[25], self.tz1Frames[26], self.tz1Frames[27]
            },
            interval = 0.15
        }),
        ['jumping'] = Animation({
            texture = self.texture,
            frames = {
                self.tz1Frames[13], self.tz1Frames[14], self.tz1Frames[15], self.tz1Frames[16], self.tz1Frames[17], 
                self.tz1Frames[18]
            }
        })
    }

    -- initialize animation and current frame we should render
    self.animation = self.animations['idle']
    self.currentFrame = self.animation:getCurrentFrame()

    -- behavior map we can call based on player state
    self.behaviors = {
        ['idle'] = function(dt)
            
            -- add spacebar functionality to trigger jump state
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            else
                self.dx = 0
            end

            -- while we're idle, check if there's a tile directly beneath us (such as a gap)
            -- if there is a gap then set a falling animation which is the same jumping
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
            end
        end,
        ['walking'] = function(dt)
            
            -- keep track of input to switch movement while walking, or reset
            -- to idle if we're not moving
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()

            -- check for Flag collision
            self:checkFlagCollision()
            
            -- while we're walking, check if there's a tile directly beneath us (such as a gap)
            -- if there is a gap then set a falling animation which is the same jumping
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end
        end,
        ['jumping'] = function(dt)
            -- break if we go below the surface
            if self.y > WINDOW_HEIGHT then
                return
            end

            if love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            end

            -- apply map's gravity before y velocity
            self.dy = self.dy + self.map.gravity

            -- check if there's a tile directly beneath us
            for coordX = self.x, self.x + self.width - 1 do
                if self.map:collides(self.map:tileAt(coordX, self.y + self.height)) then

                    -- if so, reset velocity and position and change state
                    self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
                    self.dy = 0
                    self.state = 'idle'
                    self.animation = self.animations['idle']
                end
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()

            -- check for Flag collision
            self:checkFlagCollision()
        end
    }
end

function Player:update(dt)
    -- set current position to be the previous position
    self.last.x = self.x
    self.last.y = self.y

    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.currentFrame = self.animation:getCurrentFrame()
    self.x = self.x + self.dx * dt

    self:calculateJumps()

    -- apply velocity
    self.y = self.y + self.dy * dt

    self:startPositionCheck()
    self:finishPositionCheck()
end

-- jumping and block hitting logic
function Player:calculateJumps()
    
    -- if we have negative y velocity (jumping), check if we collide
    -- with any blocks above us
    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width / 2 - 1, self.y).id ~= TILE_EMPTY then

            -- reset y velocity
            self.dy = 0
            local playHit = false
            playHit = true 

            if playHit then
                self.sounds['hit']:play()
            end
        end
    end
end

-- check for Flag collision
function Player:checkFlagCollision()
    if self.map:tileAt(self.x, self.y).id == FLAG_TOP or self.map:tileAt(self.x, self.y).id == FLAG_MIDDLE or 
        self.map:tileAt(self.x, self.y).id == FLAG_BOTTOM then
        touchedFlag = true
    end
end

-- checks two tiles to our left to see if a collision occurred
function Player:checkLeftCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) or 
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height / 2 - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

-- checks two tiles to our right to see if a collision occurred
function Player:checkRightCollision()
    if self.dx > 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) or 
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height / 2 - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
end

-- code adapted from Sheepolution
-- check for collision
function Player:checkCollision(collidable)
    return self.x + self.width > collidable.x
    and self.x < collidable.x + collidable.width
    and self.y + self.height > collidable.y
    and self.y < collidable.y + collidable.height
end

-- code adapted from Sheepolution
function Player:wasVerticallyAligned(collidable)
    -- basically collisionCheck function but with the x and width part removed.
    -- it uses last.y because we want to know this from the previous position
    return self.last.y < collidable.last.y + collidable.height and self.last.y + self.height > collidable.last.y
end

-- code adapted from Sheepolution
function Player:wasHorizontallyAligned(collidable)
    -- collisionCheck function but with the y and height part removed
    -- uses last.x because we wantto know this from the previous position
    return self.last.x < collidable.last.x + collidable.width and self.last.x + self.width > collidable.last.x
end

-- code adapted from Sheepolution
-- resolves collisions
function Player:resolveCollision(collidable)
    if self:checkCollision(collidable) then
        if self:wasVerticallyAligned(collidable) then
            -- setting velocity to 0 makes it so that the player appears to lose all momentum when coming into contact
            -- with an object. This is best shown in the top collision when dy is 0 and gravity takes over.
            -- if the velocity is set to the collidable's the collidable was the effect of 'overwhelming force' which
            -- moves the player
            if self.x + self.width / 2 < collidable.x + collidable.width / 2 then
                -- player right collision
                self.dx = collidable.dx
                self.x = collidable.x - self.width
            else
                -- player left collision
                self.dx = collidable.dx
                self.x = collidable.x + collidable.width
            end
        elseif self:wasHorizontallyAligned(collidable) then
            local playHit = false

            if self.y + self.height / 2 < collidable.y + collidable.height / 2 then
                -- player bottom collision
                -- self.dy is crucial in keeping the player on the platform
                self.dy = collidable.dy
                self.dx = collidable.dx
                self.y = collidable.y - self.height

                -- allows us to move on the platform by tapping direction keys.
                -- could be improved because it gives a treadmill effect of inertia when going the same direction
                -- as the platform
                if love.keyboard.wasPressed('space') then
                    self.dx = 0

                    if collidable.dy < 0 then
                        self.dy = -JUMP_VELOCITY * 1.4
                    else
                        self.dy = -JUMP_VELOCITY
                    end

                    self.state = 'jumping'
                    self.animation = self.animations['jumping']
                    self.sounds['jump']:play()
                elseif love.keyboard.isDown('left') then
                    self.direction = 'left'
                    if collidable.dx ~= 0 then
                        self.dx = -WALKING_SPEED * 2
                    end
                elseif love.keyboard.isDown('right') then
                    self.direction = 'right'
                    if collidable.dx ~= 0 then
                        self.dx = WALKING_SPEED * 2
                    end
                else
                    self.animation = self.animations['idle']
                end
            else
                -- player top collision
                self.y = collidable.y + collidable.height
                playHit = true
            end

            -- play hit sound
            if playHit then
                self.sounds['hit']:play()
            end
        end
    end
end

function Player:startPositionCheck()
    if self.x >= 145 and self.x <= 240 and self.y == 612 and 
        love.keyboard.wasPressed('q') then

        startPosition = true
    end
end

function Player:finishPositionCheck()
    if self.x >= 2246 and self.x <= 2349 and self.y == 292 then
        finishPosition = true
    else
        finishPosition = false
    end
end

function Player:render()
    local scaleX

    -- set negative x scale factor if facing left, which will flip the sprite
    -- when applied
    -- if self.direction == 'right' then
    --     scaleX = 1
    -- else
    --     scaleX = -1
    -- end
    scaleX = 1

    -- draw sprite with scale factor and offsets
    love.graphics.draw(self.tz1, self.currentFrame, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, 0.21 * scaleX, 0.21, self.xOffset, self.yOffset)

    -- See where character model box is
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

    -- Player coordinates
    -- love.graphics.print('Player X: ' .. tostring(self.x), map.camX + 100, 210)
    -- love.graphics.print('Player Y: ' .. tostring(self.y), map.camX + 100, 190)
end