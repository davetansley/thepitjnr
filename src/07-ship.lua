ship_states = {
    landing = 0,
    landed = 1
}

ship = {
    x = 0,
    y = 0,
    sprites = {96,97},
    state = ship_states.landing,
    framesperupdate=4,
    frames=0,
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
    self.frames+=1
    if self.frames==self.framesperupdate
    then
        self.y += 1
        self.frames=0
    end
    if self.y == 8 then self.state = ship_states.landed end    
    if self.frames%2==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function ship:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end
end

