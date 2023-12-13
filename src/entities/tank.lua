tank_states = {
    offscreen = 0,
    moving = 1,
    shooting=2
}

tank = {
    x = 128,
    y = 8,
    sprite = 100,
    fire_sprite = 104,
    bullet_sprite = 105,
    state = tank_states.moving,
    framesperupdate=4,
    frames=0,
    delay=120,
    anims=split "100,102"
}

tank=entity:new(tank)

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
    if self.frames%4==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
end

function tank:draw()
    spr(self.sprite, self.x, self.y,2,1)

    if game.frame % game.settings[3] == 0 and self.state == tank_states.shooting and game.ship.state != ship_states.fleeing 
            and game.ship.state != ship_states.escaping
    then
        -- tank is firing
        spr(65,self.x,self.y)
        spr(self.fire_sprite,self.x,self.y)
        spr(self.bullet_sprite, self.x-16,self.y)
        utilities:sfx(9)
    end
end

