robot = {
    x = 112,
    y = 16,
    dir = directions.down,
    flipx = true,
    sprites = split "132,133,134,135",
    currentframe=1,
    colors=split "8,11,12",
    newcolors=split "8,11,12",
    possiblecolors=split "7,8,9,10,11,12,13,14",
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
        self.colors,self.newcolors = {self.newcolors[1],self.newcolors[2],self.newcolors[3]},utilities.generate_pallete(self.possiblecolors)
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
            self.dir,self.alldirs = moves[1],0
        elseif #moves == 2 or (#moves == 3 and self.alldirs == 0)
        then
            -- favour up down
            if utilities:contains(moves,directions.down) and rnd(10)>5
            then
                self.dir = directions.down 
            elseif utilities:contains(moves,directions.up) and rnd(10)>3
            then
                self.dir = directions.up 
            else
                -- chose a random direction
                self.dir = moves[flr(rnd(#moves))+1]
            end
            self.alldirs = #moves == 2 and 0 or 1
        elseif #moves == 0
        then
            -- can't move, so reverse
            self.dir,self.alldirs = reversedir,0
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
    self.dying,self.autoframes=true,30
end

function robot:check_kill()
    
    if player:check_for_player(self.x+2,self.x+5,self.y+2,self.y+5)==1 
    then 
        player:kill_player(player_states.mauled) 
        self.x,self.y,self.currentframe,self.killed = player.x,player.y,1,true
    end
    
end

function robot:get_robot_adjacent_spaces(dir)
    return utilities:get_adjacent_spaces(dir,0,self.x,self.y)
end

-- get the directions that the robot can move in
function robot:get_moves()
    local reversedir,moves = self.reversedirections[self.dir+1],{}

    for x=0,3 do
        moves = self:check_can_move(x, reversedir, moves)
    end

    return moves
end

function robot:check_can_move(dir, reversedir, moves)

    if (dir == reversedir) return moves

    local coords = self:get_robot_adjacent_spaces(dir)
    local canmove = utilities:check_can_move(dir,coords)
    if (canmove == 1) add(moves, dir)

    return moves
end

