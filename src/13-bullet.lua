bullets = {}

bullet = {
    x = 0,
    y = 0,
    dir = 0
}

function bullet:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function bullet:update()

    local coords = utilities:get_adjacent_spaces(self.dir,0,self.x,self.y)
    local canmove = utilities:check_can_move(dir,coords)
    
    if canmove == 0
    then
        del(bullets, self)
        return
    end

    -- check if we've killed a robot
    local coords1 = {self.x,self.x+7,self.y,self.y+7}
    for r in all(game.robots) do 
        local coords2 = {r.x,r.x+7,r.y,r.y+7}

        if utilities:check_overlap(coords1,coords2) == 1 
        then
            del(bullets, self)
            r:die()
            player:add_score(scores.robot)
            return
        end
    end

    if self.dir == directions.right
    then
        self.x+=8
    else
        self.x-=8
    end
end

function bullet:draw()
    spr(14,self.x,self.y)
end

function bullet:set_coords(x,y,dir)
    self.x = x
    self.y = y
    self.dir = dir
end
