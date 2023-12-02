ship_states = {
    landing = 0,
    landed = 1
}

ship = {
    x = 12,
    y = 0,
    sprites = {96,97},
    state = ship_states.landing,
    anims={
        {96,97},{98,99}
    }
}

function ship:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ship:update()

    if self.state==ship_states.landed 
    then
        if (self.x > 0 and game.frame%2==0) self.x-=1 
        return
    end

    if game.frame%3==0
    then
        self.y += 1
    end
    if self.y == 8 then self.state = ship_states.landed end    
    if game.frame%2==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function ship:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end
end

