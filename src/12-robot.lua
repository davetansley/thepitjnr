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
    killed=false, -- has the robot killed the player
    alldirs=false,
    reversedirections = {
        directions.left,
        directions.right,
        directions.down,
        directions.up
    }
    
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

    -- for down and up, update every frame
    if (game.frame%game.level.robotspeed != 0 and self.dir != directions.down and self.dir != directions.up) return
    
    if self.autoframes == 0
    then
        -- figure out where the player can move
        -- {right, left, up, down}
        local moves = self:get_moves()        
        local reversedir = self.reversedirections[self.dir+1]
        if #moves == 1
        then
            -- just one possibility other than reverse, so take it
            self.dir = moves[1]
            self.alldirs = false
        elseif #moves == 2
        then
            -- chose a random direction
            self.dir = moves[flr(rnd(#moves))+1]
            self.alldirs = false
        
        elseif #moves == 3 and self.alldirs == false
        then
            -- chose a random direction
            self.dir = moves[flr(rnd(#moves))+1]
            self.alldirs = true
        elseif #moves == 0
        then
            -- can't move, so reverse
            self.dir = reversedir
            self.alldirs = false
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

-- get the directions that the robot can move in
function robot:get_moves()
    local reversedir = self.reversedirections[self.dir+1]
    local moves = {}

    moves = self:check_can_move(directions.up, reversedir, moves)
    moves = self:check_can_move(directions.down, reversedir, moves)
    moves = self:check_can_move(directions.right, reversedir, moves)
    moves = self:check_can_move(directions.left, reversedir, moves)

    return moves
end

function robot:check_can_move(dir, reversedir, moves)

    if (dir == reversedir) return moves

    local coords = self:get_robot_adjacent_spaces(dir)

    local canmove = utilities:check_can_move(dir,coords)
    if (canmove == 1) add(moves, dir)

    return moves
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

