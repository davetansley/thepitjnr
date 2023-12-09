ship_states = {
    landing = 0,
    landed = 1,
    fleeing = 2,
    lingering=3,
    escaping=4
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

    if self.state==ship_states.lingering
    then
        if (game.frame%80==0) self.state=ship_states.landed -- hang around for a second
        return
    end

    if self.state==ship_states.escaping
    then
        if game.frame%4==0
        then
            if self.x < 12
            then
                self.x+=1
            else
                if self.y < -32
                then
                    game:next_level()
                else
                    self.y-=1
                end
            end
            if game.frame%8==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
        end
        return
    end

    if self.state==ship_states.fleeing
    then
        if game.frame%4==0
        then
            self.y-=1
            if self.y < -64 -- hang around for a while, to rub it in
            then
                player:lose_life()
            end
        end
        return
    end

    if self.state==ship_states.landed 
    then
        if (self.x > 0) 
        then
            if (game.frame%4==0) self.x-=1 
            if game.frame%8==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
        end
        return
    end

    if game.frame%6==0
    then
        self.y += 1
    end
    if self.y == 8 then self.state = ship_states.lingering end    
    if game.frame%8==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function ship:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end
end

