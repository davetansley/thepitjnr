robot = {
    x = 112,
    y = 16,
    dir = directions.down,
    flipx = true,
    sprites = {132,133,134,135},
    currentframe=1,
    colors={8,11,12},
    newcolors={8,11,12},
    possiblecolors={7,8,9,10,11,12,13,14},
    autoframes=0,
    killed=false -- has the robot killed the player
}

function robot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function robot:update()

    if self.killed == true 
    then
        if (game.frame%2 != 0) return
        if player.sprite != 0 then self.flipx = true else self.flipx = false end -- this is the killer robot
        return
    end

    if (player:is_dying() == 1) return -- freeze all other robots

    if (game.frame%game.level.robotspeed != 0) return
    
    if self.autoframes == 0
    then
        -- figure out where the player can move
        -- {right, left, up, down}
        local moves = {self:check_can_move(0),self:check_can_move(1),self:check_can_move(2),self:check_can_move(3)}
        local reversedirs={directions.left,directions.right,directions.down,directions.up}
        local reversedir = reversedirs[self.dir+1]
        local moved = 0
        for m=1,4 do
            -- if this isn't the current direction and direction is movable and random check
            local prob = 7

            if self.dir != m-1 and moves[m] == 1 and rnd(10) < prob and reversedir != m-1
            then
                moved = 1
                self.dir = m-1
            end 
        end
        -- if hasn't moved, reverse
        if moved == 0 and moves[self.dir+1]==0
        then
            self.dir = reversedir
        end

        if self.dir == 0 or self.dir == 1 then self.autoframes = 7 end
    else
        self.autoframes-=1
    end

    -- move
    if (self.dir == directions.right) self.x+=1
    if (self.dir == directions.left) self.x-=1
    if (self.dir == directions.up) self.y-=1
    if (self.dir == directions.down) self.y+=1
    
    if self.dir == directions.right
    then
        self.flipx = false 
    else
        self.flipx = true 
    end

    if game.frame%15 == 0
    then
        self.currentframe+=1
        if (self.currentframe > 4) self.currentframe = 1
    end

    self:check_kill()
end

function robot:draw()
    
    pal(self.colors[1],self.newcolors[1])
    pal(self.colors[2],self.newcolors[2])
    pal(self.colors[3],self.newcolors[3])

    spr(self.sprites[self.currentframe], self.x, self.y, 1, 1, self.flipx )
    
    pal()
end

function robot:check_kill()
    
    if player:check_for_player(self.x,self.x+7,self.y,self.y+7)==1 
    then 
        player:kill_player(player_states.mauled) 
        self.x = player.x
        self.y = player.y
        self.currentframe = 1
        self.killed = true
    end
    
end


function robot:get_robot_adjacent_spaces(dir)
    return utilities:get_adjacent_spaces(dir,0,self.x,self.y)
end

-- check a range of pixels that the robot is about to move into
-- if can't move return 0
-- if can move return 1
function robot:check_can_move(dir)
    local result = 1
    local coords = self:get_robot_adjacent_spaces(dir)
    
    if (self.y <= 32 and (dir == directions.right or dir == directions.up)) return 0

    -- if rock, can't move
    for r in all(rocks) do
        local coords2 = {r.x,r.x+8,r.y,r.y+8}
        local overlap = utilities:check_overlap(coords,coords2)
        if (overlap==1) return 0
    end

    -- if bomb, can't move
    for b in all(bombs) do
        local coords2 = {b.x,b.x+8,b.y,b.y+8}
        local overlap = utilities:check_overlap(coords,coords2)
        if (overlap==1) return 0
    end

    -- if contains block or sky, can't move
    local cellcoords = utilities.box_coords_to_cells(coords[1],coords[3],coords[2],coords[4])
    if mget(cellcoords[1], cellcoords[2])==64 or mget(cellcoords[3],cellcoords[4])==64 or 
        mget(cellcoords[1], cellcoords[2])==65 or mget(cellcoords[3],cellcoords[4])==65
    then
        return 0
    end

    -- if contains dirt, can't move - will dig
    local dirtfound=game:check_for_dirt(coords[1],coords[3],coords[2],coords[4])
    if (dirtfound==1) return 0

    -- otherwise, can move
    return 1
end

function robot:generate_pallete()
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1 = flr(rnd(#self.possiblecolors))+1
        i2 = flr(rnd(#self.possiblecolors))+1
        i3 = flr(rnd(#self.possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    self.newcolors={self.possiblecolors[i1],self.possiblecolors[i2],self.possiblecolors[i3]}
end

