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
    sprite = 96,
    state = ship_states.landing,
    anims=split "96,98"
}

ship=entity:new(ship)

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
                if (self.y==8) utilities:sfx(8)
                if self.y < -32
                then
                    game:next_level()
                else
                    self.y-=1
                end
            end
            if game.frame%8==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
        end
        return
    end

    if self.state==ship_states.fleeing
    then
        if game.frame%4==0
        then
            if (self.y==8) utilities:sfx(8)
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
            if game.frame%8==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
        end
        return
    end

    if game.frame%6==0
    then

        -- play ship landing
        if (self.y==0) utilities:sfx(7)
        self.y += 1
    end
    if self.y == 8 then self.state = ship_states.lingering end    
    if game.frame%8==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
end

function ship:draw()
    spr(self.sprite, self.x, self.y,2,1)
end

