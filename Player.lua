--[[
    Represents our player in the game, with its own sprite.
]]

Player = Class{}

local WALKING_SPEED = 115
local JUMP_VELOCITY = 460
local showing = false

function Player:init(map)
    
    self.x = 0
    self.y = 0
    self.width = 48
    self.height = 60

    -- offset from top left to center to support sprite flipping
    -- tz1
    self.xOffset = 245 / 2
    self.yOffset = 0

    -- reference to map for checking tiles
    self.map = map

    -- source for Zombie sprites 'https://tokegameart.net/item/tiny-zombies/'
    -- Tiny Zombie One 'Timmy'
    self.tz1 = love.graphics.newImage('/graphics/TinyZombie1.png')

    -- Tiny Zombie Two 'Georgie'
    self.tz2 = love.graphics.newImage('/graphics/TinyZombie2.png')

    -- Tiny Zombie Three 'Bill'
    self.tz3 = love.graphics.newImage('/graphics/TinyZombie3.png')

    -- sound effects
    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static')
    }

    -- animation frames
    self.tz1Frames = generateQuads(self.tz1, 245, 285)
    self.tz2Frames = generateQuads(self.tz2, 218, 269)
    self.tz3Frames = generateQuads(self.tz3, 231, 286)

    -- current animation frame
    self.currentFrame = nil

    -- used to determine behavior and animations
    self.state = 'idle'

    -- determines sprite flipping
    self.direction = 'left'

    -- x and y velocity
    self.dx = 0
    self.dy = 0
    platformDx = 0

    -- state for moving on moving platform on x axis
    onMovingX = false

    -- position sprite on top of map tiles
    self.y = map.tileHeight * ((map.mapHeight - 2) / 2 + 10) - self.height
    self.x = map.tileWidth * 3

    self.last = {}
    self.last.x = self.x
    self.last.y = self.y

    -- tables containing animation frames
    idleTz1 = {
        self.tz1Frames[1], self.tz1Frames[2], self.tz1Frames[3], self.tz1Frames[4], self.tz1Frames[5], 
        self.tz1Frames[6], self.tz1Frames[7], self.tz1Frames[8], self.tz1Frames[9], self.tz1Frames[10], 
        self.tz1Frames[11], self.tz1Frames[12]
    }

    walkTz1 = {
        self.tz1Frames[19], self.tz1Frames[20], self.tz1Frames[21], self.tz1Frames[22], self.tz1Frames[23], 
        self.tz1Frames[24], self.tz1Frames[25], self.tz1Frames[26], self.tz1Frames[27], self.tz1Frames[28], 
        self.tz1Frames[29], self.tz1Frames[30], self.tz1Frames[31], self.tz1Frames[32], self.tz1Frames[33], 
        self.tz1Frames[34], self.tz1Frames[35], self.tz1Frames[36]
    }

    jumpTz1 = {
        self.tz1Frames[13], self.tz1Frames[14], self.tz1Frames[15], self.tz1Frames[16], self.tz1Frames[17], 
        self.tz1Frames[18]
    }

    spriteTexture = self.tz1
    idleFrames = idleTz1
    walkFrames = walkTz1
    jumpFrames = jumpTz1

    -- initialize all player animations
    self.animations = {
        ['idle'] = Animation({
            texture = spriteTexture,
            frames = idleFrames
        }),
        ['walking'] = Animation({
            texture = spriteTexture,
            frames = walkFrames,       
            interval = 0.15
        }),
        ['jumping'] = Animation({
            texture = spriteTexture,
            frames = jumpFrames
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
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) and 
                not self.map:collides(self.map:tileAt(self.x + self.width / 2 - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
            else
                self.map.gravity = 0
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
            
            -- while we're walking, check if there's a tile directly beneath us (such as a gap)
            -- if there is a gap then set a falling animation which is the same jumping
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) and 
                not self.map:collides(self.map:tileAt(self.x + self.width / 2 - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            else
                self.map.gravity = 0
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

            -- check if there's a tile directly beneath us
            for coordX = self.x, self.x + self.width - 1 do
                if self.map:collides(self.map:tileAt(coordX, self.y + self.height)) then

                    -- if so, reset velocity and position and change state
                    self.map.gravity = 0
                    self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
                    self.dy = 0
                    self.state = 'idle'
                    self.animation = self.animations['idle']
                end
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()
        end
    }
end

function Player:selectSprite()

    if love.keyboard.wasPressed('1') then
        -- select 'Timmy'
        spriteTexture = self.tz1
    elseif love.keyboard.wasPressed('2') then
        -- select 'Georgie'
        if unlock1stSkin then
            spriteTexture = self.tz2
        end
    elseif love.keyboard.wasPressed('3') then
        -- select 'Bill'
        if unlock2ndSkin then
            spriteTexture = self.tz3
        end
    end
end

function Player:update(dt)
    self:selectSprite()

    -- set current position to be the previous position
    self.last.x = self.x
    self.last.y = self.y

    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.currentFrame = self.animation:getCurrentFrame()

    self.x = self.x + (self.dx + platformDx) * dt

    -- detects if the player is on a platform that moves on the X axis
    if onMovingX == false then
        platformDx = 0
    end

    -- soft application of physics to represent relative velocity with inertia
    if self.dx + platformDx == WALKING_SPEED or self.dx + platformDx == -WALKING_SPEED then
        self.dx = 0
    end

    self:calculateJumps()

    -- apply velocity
    self.y = self.y + (self.dy + self.map.gravity) * dt

    self:startPositionCheck()
    self:finishPositionCheck()

    self:showHide()
    self.sounds['jump']:setVolume(0.5)
    self.sounds['hit']:setVolume(0.5)
end

-- jumping and block hitting logic
function Player:calculateJumps()
    
    -- if we have negative y velocity (jumping), check if we collide
    -- with any blocks above us
    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width / 2 - 1, self.y).id ~= TILE_EMPTY or 
            self.y <= 52 then

            -- reset y velocity
            self.dy = 0
            self.y = self.map:tileAt(self.x, self.y).y * self.map.tileWidth
            local playHit = false
            playHit = true 

            if playHit then
                self.sounds['hit']:play()
            end
        end
    end
end

-- checks two tiles to our left to see if a collision occurred
function Player:checkLeftCollision()
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) or 
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height / 2 - 1)) or 
            self.x <= 0 then
            
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
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height / 2 - 1)) or 
            self.x >= map.mapWidth * map.tileWidth - self.width then
            
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
function Player:resolveCollision(collidable, dt)
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
                self.map.gravity = 0
                self.dy = collidable.dy
                self.y = collidable.y - self.height
                platformDx = collidable.dx
                onMovingX = true

                -- allows us to move on the platform by tapping direction keys.
                -- could be improved because it gives a treadmill effect of inertia when going the same direction
                -- as the platform
                if love.keyboard.wasPressed('space') then
                    if collidable.dy < 0 then
                        self.dy = -JUMP_VELOCITY * 1.3
                    else
                        self.dy = -JUMP_VELOCITY
                    end

                    self.state = 'jumping'
                    self.animation = self.animations['jumping']
                    self.sounds['jump']:play()
                elseif love.keyboard.wasPressed('left') then
                    self.direction = 'left'
                    self.dx = -WALKING_SPEED
                    self.animation = self.animations['walking']
                elseif love.keyboard.wasPressed('right') then
                    self.direction = 'right'
                    self.dx = WALKING_SPEED
                    self.animation = self.animations['walking']
                else
                    self.animation = self.animations['idle']
                end
            else
                -- player top collision
                self.dy = 0
                self.y = collidable.y + collidable.height
                playHit = true
            end

            -- play hit sound
            if playHit then
                self.sounds['hit']:play()
            end
        end
    end

    onMovingX = false
end

-- check if the player is at the start position to allow timer reset
function Player:startPositionCheck()
    if self.x >= 145 and self.x <= 240 and self.y == 612 and 
        love.keyboard.wasPressed('q') then

        startPosition = true
    end
end

-- check if the player is at the finish to potentially log personal best
function Player:finishPositionCheck()
    if self.x >= 2246 and self.x <= 2349 and self.y == 292 then
        finishPosition = true
    else
        finishPosition = false
    end
end

-- draw character box
function Player:drawBox()
    -- hides rectangle by changing opacity
    if showing then
        love.graphics.setColor(255, 100 / 255, 0, 255)
    else
        love.graphics.setColor(255, 100 / 255, 0, 0)
    end
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

-- show/hide function
function Player:showHide()
    if love.keyboard.wasPressed('h') then
        if showing then
            showing = false
        else
            showing = true
        end
    end
end

function Player:render()
    local scaleX

    -- set negative x scale factor if facing left, which will flip the sprite
    -- when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    -- draw sprite with scale factor and offsets
    if spriteTexture == self.tz1 then
        love.graphics.draw(spriteTexture, self.currentFrame, math.floor(self.x + self.width / 2),
            math.floor(self.y + self.yOffset), 0, 0.21 * scaleX, 0.21, self.xOffset, self.yOffset)
    elseif spriteTexture == self.tz2 then
        love.graphics.draw(spriteTexture, self.currentFrame, math.floor(self.x + self.width / 2),
            math.floor(self.y + self.yOffset), 0, 0.21 * scaleX, 0.21, self.xOffset, self.yOffset)
    elseif spriteTexture == self.tz3 then
        love.graphics.draw(spriteTexture, self.currentFrame, math.floor(self.x + self.width / 2),
            math.floor(self.y + self.yOffset), 0, 0.21 * scaleX, 0.21, self.xOffset, self.yOffset)
    end

    self:drawBox()

    -- Player coordinates
    -- love.graphics.print('Player X: ' .. tostring(self.x), map.camX + 100, 210)
    -- love.graphics.print('Player Y: ' .. tostring(self.y), map.camX + 100, 190)

    -- Player velocity
    -- love.graphics.print('Player dx + platDx: ' .. tostring(self.dx + platformDx), map.camX + 150, 200)
    -- love.graphics.print('Player dx: ' .. tostring(self.dx), map.camX + 150, 220)
    -- love.graphics.print('Platform dx: ' .. tostring(platformDx), map.camX + 150, 240)
end