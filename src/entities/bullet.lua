bullets = {}

bullet = {
    sprite = 14
}

bullet=entity:new(bullet)

function bullet:update()

    local coords = utilities:get_adjacent_spaces(self.dir,0,self.x,self.y)
    -- limit coords
    coords={coords[1],coords[2],coords[3]+3,coords[4]-4}
    local canmove = utilities:check_can_move(dir,coords, true)
    
    if canmove == 0
    then
        del(bullets, self)
        return
    end

    -- check if we've killed a robot
    local coords1 = {self.x,self.x+7,self.y+3,self.y+3}
    for r in all(game.robots) do 
        if not(r.dying)
        then 
            local coords2 = {r.x,r.x+7,r.y,r.y+7}

            if utilities:check_overlap(coords1,coords2) == 1 
            then
                del(bullets, self)
                r:die()
                player:add_score(scores.robot)
                return
            end
        end
    end

    local xmod = self.dir == directions.right and 8 or -8
    self.x+=xmod
end

function bullet:draw()
    if(self.x!=player.x) spr(self.sprite,self.x,self.y)
end

function bullet:set_coords(x,y,dir)
    self.x,self.y,self.dir = x,y,dir
end
