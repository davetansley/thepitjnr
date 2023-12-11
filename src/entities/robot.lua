robot = {
    x = 112,
    y = 16,
    dir = directions.down,
    flipx = true,
    sprites = split("132,133,134,135"),
    currentframe=1,
    colors={8,11,12},
    newcolors={8,11,12},
    possiblecolors=split("7,8,9,10,11,12,13,14"),
    autoframes=0,
    killed=false, -- has the robot killed the player
    dying=false,
    alldirs=0,
    reversedirections = {
        directions.left,
        directions.right,
        directions.down,
        directions.up
    }
    
}

robot = entity:new(robot)

function robot:update()

    if self.dying == true 
    then
        -- robot has been shot - update palette, reduce frames, remove
        self.colors = {self.newcolors[1],self.newcolors[2],self.newcolors[3]}
        self.newcolors = utilities.generate_pallete(self.possiblecolors)
        self.autoframes-=1
        if (self.autoframes<0) del(game.robots,self)
        return
    end

    if self.killed == true 
    then
        if (game.frame%4 != 0) return
        if player.sprite != 0 then self.flipx = true else self.flipx = false end -- this is the killer robot
        return
    end

    if (player:is_dying() == 1) return -- freeze all other robots

    -- for down and up, update every frame
    if (game.frame%game.settings[1] != 0 and self.dir != directions.down and self.dir != directions.up) return
    
    if self.autoframes == 0
    then
        -- figure out where the player can move
        -- {right, left, up, down}
        local moves,reversedir = self:get_moves(),self.reversedirections[self.dir+1]  
        if #moves == 1
        then
            -- just one possibility other than reverse, so take it
            self.dir = moves[1]
            self.alldirs = 0
        elseif #moves == 2 or (#moves == 3 and self.alldirs == 0)
        then
            -- chose a random direction
            self.dir = moves[flr(rnd(#moves))+1]
            self.alldirs = #moves == 2 and 0 or 1
        elseif #moves == 0
        then
            -- can't move, so reverse
            self.dir = reversedir
            self.alldirs = 0
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
    elseif self.dir == directions.left
    then
        self.flipx = true 
    end

    if game.frame%15 == 0 and self.dir != directions.up and self.dir != directions.down
    then
        self.currentframe+=1
        if (self.currentframe > 4) self.currentframe = 1
    end

    self:check_kill()
end

function robot:draw()
   
    for x=1,3 do
        pal(self.colors[x],self.newcolors[x])
    end 

    spr(self.sprites[self.currentframe], self.x, self.y, 1, 1, self.flipx )
    
    pal()
end

function robot:die()
    self.dying=true
    self.autoframes=30
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

