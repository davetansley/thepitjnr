tank_states = {
    offscreen = 0,
    moving = 1,
    shooting=2
}

tank = {
    x = 128,
    y = 8,
    sprites = {100,101,102,103},
    state = tank_states.moving,
    framesperupdate=2,
    frames=0,
    delay=60,
    anims={
        {100,101},{102,103}
    }
}

function tank:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function tank:update()
    if self.delay > 0
    then
        self.delay-=1
        return
    end

    if self.state==tank_states.moving
    then
        self.frames+=1
        if self.frames==self.framesperupdate
        then
            self.x-=1
            self.frames=0
        end
        if self.x == 96 then self.state = tank_states.shooting end    
    end
    if self.frames%2==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function tank:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end
end

