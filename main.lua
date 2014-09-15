function love.load()
    love.window.setTitle('Maxwell\'s Demon')
    screenWidth, screenHeight = 800, 600
    heavenHeight = 150
    earthHeight = 450
    hellHeight = 600
    angelHeight = heavenHeight - 25
    sounds = {
        demonAttack = love.audio.newSource('demon_attack.wav', true),
        spiritSave = love.audio.newSource('spirit_save.wav', true),
        victimDeath = love.audio.newSource('victim_death.wav', true),
        spiritTransformBad = love.audio.newSource('spirit_transform_bad.wav', true),
        healthLost = love.audio.newSource('health_lost.wav', true),
    }
    images = {
        angel = love.graphics.newImage('angel.png'),
        shieldImage = love.graphics.newImage('angel_shielded.png'),
        victim = love.graphics.newImage('victim.png'),
        knight = love.graphics.newImage('knight.png'),
        demon = love.graphics.newImage('demon.png'),
        good_spirit = love.graphics.newImage('good_spirit.png'),
        bad_spirit = love.graphics.newImage('bad_spirit.png'),
        heaven = love.graphics.newImage('heaven.png'),
        earth = love.graphics.newImage('earth.png'),
        hell = love.graphics.newImage('hell.png'),
        blockSoulsNotice = love.graphics.newImage('block_souls_notice.png'),
        saveSoulsNotice = love.graphics.newImage('save_souls_notice.png'),
        lifeCounter = love.graphics.newImage('life_counter.png'),
        gameOverNotice = love.graphics.newImage('game_over_notice.png'),
    }
    love.graphics.setNewFont(28)

    Victim.image = images.victim
    Angel.image = images.angel
    Angel.shieldImage = images.shieldImage
    Knight.image = images.knight
    Demon.image = images.demon
    GoodSpirit.image = images.good_spirit
    BadSpirit.image = images.bad_spirit
    LifeCounter.image = images.lifeCounter

    restartGame()
end

function restartGame()
    theGameOverFlag = false
    theVictimSpawner = Spawner.new(function()
        local x
        if math.random(0, 1) == 1 then
            x = 0 - Victim.image:getWidth()
        else
            x = screenWidth
        end
        return Victim.new(x, earthHeight - Victim.image:getHeight(), math.random(90, 150))
    end,
    function()
        return math.random(0.2, 0.55)
    end)
    theVictims = {}

    theAngel = Angel.new((screenWidth / 2) + (Angel.image:getWidth() / 2), angelHeight - Angel.image:getHeight(), 200)

    theKnight = Knight.new(0 - Knight.image:getWidth(), earthHeight - Knight.image:getHeight(), 100)

    theDemon = Demon.new(screenWidth, hellHeight - Demon.image:getHeight(), 100)
    
    theGoodSpirits = {}

    theBadSpirits = {}

    theMultiplier = 1
    theScore = 0

    theBadSpiritSpawnedFlag = false
    theNotices = { Notice.new(images.saveSoulsNotice, 5) }

    theLifeCounter = LifeCounter.new(0, 150, 10)

    theTimers = {
        Timer.new(const(5), function()
            if theKnight.speed < 375 then
                theKnight:increaseSpeed(25)
            end
        end),
        Timer.new(const(5), function()
            if theDemon.speed < 225 then
                theDemon:increaseSpeed(3)
            end
        end),
--TODO make spawner increase
--        Timer.new(const(5), function()
--            if the
    }
end


LifeCounter = {}
LifeCounter.mt = {}

function LifeCounter.new(x, y, initValue)
    local newObj = {
        image = LifeCounter.image,
        x = x,
        y = y,
        value = initValue,
        loseLife = function(self)
            self.value = self.value - 1
            ensurePlay(sounds.healthLost)
        end,
        empty = function(self)
            return self.value == 0
        end,
        draw = function(self)
            for i = 0,(self.value - 1) do
                love.graphics.draw(self.image, x + (i * self.image:getWidth()), y)
            end
        end,
    }
    setmetatable(newObj, LifeCounter.mt)
    return newObj
end

function const(value)
    return function()
        return value
    end
end        

function nop()
    return nil
end

function ensurePlay(sound)
    sound:rewind()
    sound:play()
end

Notice = {}
Notice.mt = {}

function Notice.new(image, duration)
    local newObj = {
        image = image,
        timer = Timer.new(const(duration), nop),
        update = function(self, dt)
            self.timer:update(dt)
        end,
        done = function(self)
            return self.timer:ready()
        end,
        draw = function(self)
            local x = (screenWidth / 2) - (self.image:getWidth() / 2)
            local y = (screenHeight / 2) - (self.image:getHeight() / 2)
            love.graphics.draw(self.image, x, y)
        end,
    }
    setmetatable(newObj, Notice.mt)
    return newObj
end

collider = {
    getLeft = function(self)
        return self.x
    end,
    getRight = function(self)
        return self.x + self.image:getWidth()
    end,
    getCenterX = function(self)
        return self.x + (self.image:getWidth() / 2)
    end,
    getTop = function(self)
        return self.y
    end,
    getBottom = function(self)
        return self.y + self.image:getHeight()
    end,
    getCenterY = function(self)
        return self.y + (self.image:getHeight() / 2)
    end,
    points = function(self)
        local points = {
            { name = 'topLeft', x = self:getLeft(), y = self:getTop() },
            { name = 'topRight', x = self:getRight(), y = self:getTop() },
            { name = 'bottomLeft', x = self:getLeft(), y = self:getBottom() },
            { name = 'bottomRight', x = self:getRight(), y = self:getBottom() },
        }
        return points
    end,
    containsPoint = function(self, x, y)
        containsHorizontal = self:getLeft() <= x and x <= self:getRight()
        containsVertical = self:getTop() <= y and y <= self:getBottom()
        return containsHorizontal and containsVertical
    end,
    collideSide = function(self, other)
        local collides = false
        local noCollide = {}
        for key, value in pairs(self:points()) do
            if other:containsPoint(value.x, value.y) then
                collides = true
            else
                noCollide[value.name] = true
            end
        end
        return collides
    end,
    collideCenter = function(self, other)
        return self:containsPoint(other:getCenterX(), other:getCenterY())
    end,
}

autoWalker = {
    decideDirection = function(self)
        if self:getLeft() < 0 then
            self.direction = 'right'
        elseif self:getRight() > screenWidth then
            self.direction = 'left'
        end
    end,
    move = function(self, dt)
        self:decideDirection()
        if self.direction == 'right' then
            self.x = self.x + (self.speed * dt)
        elseif self.direction == 'left' then
            self.x = self.x - (self.speed * dt)
        end
    end, 
    draw = function(self)
        local directions = { right = -1, left = 1 }
        local direction = directions[self.direction]
        if self.direction == 'right' then
            love.graphics.draw(self.image, self.x + self.image:getWidth(), self.y, 0, direction, 1)
        elseif self.direction == 'left' then
            love.graphics.draw(self.image, self.x, self.y)
        end
    end,
    update = function(self, dt)
        self:move(dt)
    end,
    increaseSpeed = function(self, deltaSpeed)
        self.speed = self.speed + deltaSpeed
    end,
}
setmetatable(autoWalker, {__index = collider })


Victim = {}
Victim.mt = { __index = autoWalker }

function Victim.new(x, y, speed)
    local newObj = {
        image = Victim.image,
        x = x,
        y = y,
        speed = speed,
    }
    setmetatable(newObj, Victim.mt)
    return newObj
end

Angel = {}
Angel.mt = { __index = autoWalker }
function Angel.new(x, y, speed)
    local newObj = {
        image = Angel.image,
        x = x,
        y = y,
        speed = speed,
        direction = 'right',
        moving = false,
        update = function(self, dt)
            if self.moving then
                if self.direction == 'right' then
                    self.x = self.x + (self.speed * dt)
                elseif self.direction == 'left' then
                    self.x = self.x - (self.speed * dt)
                end
            end
        end,
        shield = false,
        setShield = function(self, on)
            if on then
                self.shield = true
                self.image = Angel.shieldImage
                self.speed = self.speed / 2
            else
                self.shield = false
                self.image = Angel.image
                self.speed = self.speed * 2
            end
        end,
    }
    setmetatable(newObj, Angel.mt)
    return newObj
end

Knight = {}
Knight.mt = { __index = autoWalker }

function Knight.new(x, y, speed)
    local newObj = {
        image = Knight.image,
        x = x,
        y = y,
        speed = speed,
    }
    setmetatable(newObj, Knight.mt)
    return newObj
end

Demon = {}
Demon.mt = { __index = autoWalker }

function Demon.new(x, y, speed)
    local newObj = {
        image = Demon.image,
        x = x,
        y = y,
        speed = speed,
    }
    setmetatable(newObj, Demon.mt)
    return newObj
end

GoodSpirit = {}
GoodSpirit.mt = { __index = collider }

function GoodSpirit.new(x, y, speed, waitDuration)
    local newObj = {
        image = GoodSpirit.image,
        x = x,
        y = y,
        waitDuration = waitDuration,
        speed = speed,
        state = 'ascent',
        draw = function(self)
            love.graphics.draw(self.image, self.x, self.y)
        end,
        update = function(self, dt)
            if self.state == 'ascent' then
                local goodSpiritHeight = angelHeight - Angel.image:getHeight() / 2 - GoodSpirit.image:getHeight() / 2
                if self.y > goodSpiritHeight then
                    self.y = self.y - (self.speed * dt)
                elseif self.y < goodSpiritHeight then
                    self.y = goodSpiritHeight 
                elseif self.y == goodSpiritHeight then
                    self.state = 'wait'
                end
            elseif self.state == 'wait' then
                if self.waitDuration > 0 then
                    self.waitDuration = self.waitDuration - dt
                else
                    self.state = 'descent'
                end
            elseif self.state == 'descent' then
                if self:getBottom() < hellHeight then
                    self.y = self.y + (self.speed * dt)
                elseif self:getBottom() > hellHeight then
                    self.y = hellHeight - self.image:getHeight()
                end
            elseif self.state == 'saved' then
                self.y = self.y - (self.speed * dt)
            end
        end,
        dead = function(self)
            return self:getBottom() < 0
        end,
    }
    setmetatable(newObj, GoodSpirit.mt)
    return newObj
end

BadSpirit = {}
BadSpirit.mt = { __index = collider }

function BadSpirit.new(x, y, speed)
    local newObj = {
        image = BadSpirit.image,
        x = x,
        y = y,
        speed = speed,
        dead = false,
        draw = function(self)
            love.graphics.draw(self.image, self.x, self.y)
        end,
        deflect = function(self)
            self.state = 'falling'
        end,
        state = 'rising',
        update = function(self, dt)
            if self.state == 'rising' then
                if self:getBottom() > 0 then
                    self.y = self.y - (self.speed * dt)
                end
            elseif self.state == 'falling' then
                self.y = self.y + (self.speed * dt)
            end
        end,
        dead = function(self)
            if self.state == 'falling' then
                return self:getTop() > screenHeight
            elseif self.state == 'rising' then
                return self:getBottom() < 0
            end
        end,
    }
    setmetatable(newObj, BadSpirit.mt)
    return newObj
end

Spawner = {}
Spawner.mt = {}

function Spawner.new(constructor, spawnDurationFunc)
    local newObj = {
        timer = Timer.new(spawnDurationFunc, constructor),
        update = function (self, dt)
            self.timer:update(dt)
        end,
        ready = function (self)
            return self.timer:ready()
        end,
        spawn = function (self)
            return self.timer:activate()
        end,
    }
    setmetatable(newObj, Spawner.mt)
    return newObj
end

Timer = {}
Timer.mt = {}

function Timer.new(durationFunc, callback)
    local newObj = {
        callback = callback,
        durationFunc = durationFunc,
        timer = durationFunc(),
        update = function(self, dt)
            if not self:ready() then
                self.timer = self.timer - dt
                if self.timer < 0 then
                    self.timer = 0
                end
            end
        end,
        ready = function(self)
            return self.timer == 0
        end,
        activate = function(self)
            self.timer = durationFunc()
            return self.callback()
        end
    }
    setmetatable(newObj, Timer.mt)
    return newObj
end

function love.update(dt)
    if not theGameOverFlag then
        if theScore < 0 then
            theScore = 0
        end
        for _, timer in pairs(theTimers) do
            timer:update(dt)
            if timer:ready() then
                timer:activate()
            end
        end

        for key, notice in pairs(theNotices) do
            notice:update(dt)
            if notice:done() then
                theNotices[key] = nil
            end
        end

        theAngel:update(dt)
        theKnight:update(dt)
        theDemon:update(dt)
        theVictimSpawner:update(dt)
        if theVictimSpawner:ready() then
            table.insert(theVictims, theVictimSpawner:spawn())
        end
        for key, victim in pairs(theVictims) do
            victim:update(dt)
            if theKnight:collideCenter(victim) then
                table.insert(theGoodSpirits, GoodSpirit.new(victim:getCenterX(), victim.y, 100, 1.0))
                theVictims[key] = nil
                ensurePlay(sounds.victimDeath)
            end
        end
        for key, goodSpirit in pairs(theGoodSpirits) do
            goodSpirit:update(dt)
            if theAngel:collideCenter(goodSpirit) then
                goodSpirit.speed = goodSpirit.speed + 10 --TODO Magic Number Constant
                if goodSpirit.state ~= 'saved' then
                    theScore = theScore + (theMultiplier * 100) --TODO Magic Number Constant
                    theMultiplier = theMultiplier + 1
                    ensurePlay(sounds.spiritSave)
                end
                goodSpirit.state = 'saved'
            elseif theDemon:collideCenter(goodSpirit) then
                if not theBadSpiritSpawnedFlag then
                    theBadSpiritSpawnedFlag = true
                    table.insert(theNotices, Notice.new(images.blockSoulsNotice, 5))
                end
                table.insert(theBadSpirits, BadSpirit.new(goodSpirit.x, goodSpirit.y, 100))
                theGoodSpirits[key] = nil
                ensurePlay(sounds.spiritTransformBad)
            elseif goodSpirit:dead() then
                theGoodSpirits[key] = nil
            end
        end
        for key, badSpirit in pairs(theBadSpirits) do
            badSpirit:update(dt)
            if badSpirit:dead() then
                if badSpirit.state == 'rising' then
                    theLifeCounter:loseLife()
                    theScore = theScore - 500
                    theMultiplier = 1
                    if theLifeCounter:empty() then
                        theGameOverFlag = true
                        table.insert(theNotices, Notice.new(images.gameOverNotice, -1))
                    end
                end
                theBadSpirits[key] = nil
            else
                if theAngel.shield and theAngel:collideCenter(badSpirit) then
                    badSpirit.state = 'falling'
                end
            end
            --TODO on death score modify
        end
    end
end

function love.keypressed(key)
    local callbacks = {
        right = function()
            if not theGameOverFlag then
                theAngel.moving = true
                theAngel.direction = 'right'
            end
        end,
        left = function()
            if not theGameOverFlag then
                theAngel.moving = true
                theAngel.direction = 'left'
            end
        end,
        [' '] = function()
            theAngel:setShield(true)
        end,
        ['return'] = function()
            if theGameOverFlag then
                restartGame()
            end
        end,
        r = function()
            restartGame()
        end,
    }
    if callbacks[key] then
        callbacks[key]()
    end
end

function love.keyreleased(key)
    local callbacks = {
        right = function()
            if theAngel.direction == 'right' then
                theAngel.moving = false
            end
        end,
        left = function()
            if theAngel.direction == 'left' then
                theAngel.moving = false
            end
        end,
        [' '] = function()
            theAngel:setShield(false) 
        end,
    }
    if callbacks[key] then
        callbacks[key]()
    end
end

function drawScenery()
    love.graphics.draw(images.heaven, 0, 0)
    love.graphics.draw(images.earth, 0, heavenHeight)
    love.graphics.draw(images.hell, 0, earthHeight)
end

function drawScore()
    love.graphics.print(tostring(theScore) .. '\n' .. tostring(theMultiplier) .. 'x', 0, 0)
end

function love.draw()
    drawScenery()
    for _, victim in pairs(theVictims) do
        victim:draw()
    end
    for _, goodSpirit in pairs(theGoodSpirits) do
        goodSpirit:draw()
    end
    for _, badSpirit in pairs(theBadSpirits) do
        badSpirit:draw()
    end
    theAngel:draw()
    theKnight:draw()
    theDemon:draw()
    for _, notice in pairs(theNotices) do
        notice:draw()
    end
    drawScore()
    theLifeCounter:draw()
end

