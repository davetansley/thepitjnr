player_states = {
    moving = 0,
    digging = 1,
    shooting = 2,
    squashed = 3,
    bombed = 4
}

player={
    score=0, -- key for storing score
    lives=3, -- key for storing lives
}


function player:init()
    self.x=16 --key for the x variable
    self.y=16 --key for the y variable
    self.dir=0 --key for the direction: 0 right, 1 left, 2 up, 3 down
    self.sprite=0 -- key for the sprite
    self.oldsprite=0 -- key for storing the old sprite
    self.framecount=0 -- key for frame counting
    self.framestomove=0 -- key for frames left in current move
    self.state=0 -- key for player activity. 0 moving, 1 digging, 2 shooting, 3 squashing
    self.stateframes=0 -- key for frames in current activity
    self.incavern=0 -- key for whether player is in the diamond cavern
    self.inpit=0 -- key for whether player is in the pit
    self.animframes=3 -- key for the number of frames an animation frame has
end

function player:update()
    self:update_player()
end

function player:draw()
    -- draw player
    spr(self.sprite,self.x,self.y)

    -- if player is digging, draw effect
    if self.state==player_states.digging and self.stateframes>0 then self:flash_square() end

    -- zonk text
    if player.state==player_states.bombed then screen:draw_zonk() end

end

-- return 1 if the player is dying
function player:is_dying()
    if self.state==player_states.crushed or self.state==player_states.bombed then return 1 end 
    return 0
end

-- update the player state
function player:update_player()

    if self.state==player_states.crushed
    then
        -- Player is being squashed
        if self.sprite == 10 then self.sprite=11 else self.sprite=10 end
        self.stateframes-=1
        if self.stateframes==0
            then
                self:lose_life()
            end
        return
    end

    if self.state==player_states.bombed
    then
        -- Player is being bombed
        self.stateframes-=1
        if self.stateframes==0
            then
                self:lose_life()
            end
        return
    end

    if self.state==player_states.digging 
    then
        -- Player is digging, so set that and return
        self.stateframes-=1
        if self.stateframes<0 -- Let it go at 0 for a frame to enable digging
            then
                self.state=player_states.moving
                self.sprite=player.oldsprite
            end    
        return
    end

    if self.framestomove!=0
    then
        if self.dir==0 then self:move(1,0,0,1,0,1) end
        if self.dir==1 then self:move(-1,0,2,3,1,1) end
        self.framestomove-=1
    else
        -- start new movement
        local moved = 0
        local horiz = 0
        if btn(0) then 
            moved=self:move(-1,0,2,3,1,0)
            horiz=1                 
        elseif btn(1) and moved==0 then 
            moved=self:move(1,0,0,1,0,0)
            horiz=1 
        elseif btn(2) and moved==0 then 
            moved=self:move(0,-1,4,5,2,0) 
        elseif btn(3) and moved==0 then 
            moved=self:move(0,1,4,5,3,0) 
        end
        
        if moved==1 and horiz==1 then self.framestomove=7 end
    end

    -- update the player's location
    self:check_location()
end

function player:lose_life()
    self.lives-=1

    if self.lives < 0
    then
        -- gameover
        screen:show_gameover()
    else
        self:init()
        game.reset()
    end
end

-- check for player in the range specified
-- return 1 if found, 0 if not
function player:check_for_player(x1,x2,y1,y2)
    if x1 < self.x+8 and self.x <= x2 and y1 < self.y+8 and self.y <= y2
         then
            return 1
        end           
    return 0
end

function player:kill_player(state)
    self.state=state
    self.stateframes=30  
end

function player:check_location()
    -- check pit
    if game.level.pitcoords[1][1]<=self.x and self.x<game.level.pitcoords[2][1]+8 and game.level.pitcoords[1][2]<=self.y and  self.y<game.level.pitcoords[2][2]+8
    then
        self.inpit=1
    else
        self.inpit=0
    end

    -- check cavern
    if game.level.caverncoords[1][1]<=self.x and self.x<game.level.caverncoords[2][1]+8 and game.level.caverncoords[1][2]<=self.y and  self.y<game.level.caverncoords[2][2]+8
    then
        self.incavern=1
    else
        self.incavern=0
    end
end

-- check a range of pixels that the player is about to move into
-- if can move return 0
-- if can't move return 1
function player:check_can_move(dir)
    local result = 0
    local coords = self:get_player_adjacent_spaces(dir,0)
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do 
            local pixelc = pget(x,y)
            -- Not blank or dirt, so can't move
            if pixelc != 0 then return 1 end
        end
    end

    return result
end

-- check a range of pixels that the player is about to move into
-- return 1 if found
function player:check_for_gem(dir)
    local result = 0
    local coords = self:get_player_adjacent_spaces(dir,0)
    
    local count=#diamonds
    for x=1,count do 
        local diamond=diamonds[x]
        
        if diamond.state == entity_states.idle
            then
            
            -- check if coords of diamond are inside the box
            if diamond.x >= coords[1] and diamond.x <= coords[2]
                and diamond.y >= coords[3] and diamond.y <= coords[4]
                then
                    diamond.state = entity_states.invisible
                    player:add_score(scores.diamond)
                    sfx(0)
                    return 1
                end            
            end
    end

    return 0
end

-- try to dig a range of pixels
function player:try_to_dig(dir)
    local coords = self:get_player_adjacent_spaces(dir,1)
    if game:check_for_dirt(coords[1], coords[3], coords[2], coords[4])==1
    then
        game:dig_dirt(coords[1], coords[3], coords[2], coords[4])
        sfx(1)

        -- Update this later to just set the player state - anims handled in draw
        if self.state==player_states.moving then 
            self.oldsprite=self.sprite
        end
        self.state=player_states.digging
        self.stateframes=10
        self.sprite=6+dir
    end
    
end

function player:get_player_adjacent_spaces(dir,dig)
    return utilities:get_adjacent_spaces(dir,dig,self.x,self.y)
end

-- Move the player
-- x,y = axis deltas
-- s1,s2 = sprites to flip between
-- d = direction
function player:move(x,y,s1,s2,d,auto)
    
    -- only check movement if this is auto movement
    if auto==0
    then
        local preventmove=0
        preventmove=self:check_can_move(d)
        if preventmove!=0 
        then 
            -- Check for gem
            local gem=self:check_for_gem(d)
            if gem==1 then return 0 end
            -- Can't move so try to dig
            self:try_to_dig(d)
            self.dir=d
            return 0 
        end
    end
    self.x+=x
    self.y+=y

    -- limit movement
    if self.x<0 then self.x=0 end 
    if self.y<0 then self.y=0 end 
    if self.x>120 then self.x=120 end 
    if self.y>184 then self.y=184 end 

    -- check if direction has changed
    if self.dir!=d 
        then 
            self.framecount=0 
        else 
            -- reset or increment
            if self.framecount==self.animframes then self.framecount = 0 else self.framecount+=1 end 
    end

    -- flip frame if needed
    if self.framecount==0 
        then
            if self.sprite==s1 then self.sprite=s2 else self.sprite=s1 end
    end 
    
    self.dir=d

    return 1
end

function player:add_score(score)
    self.score+=score
    if self.score > game.highscore then game.highscore = self.score end
end

-- flash the adjacent square when digging
function player:flash_square()
    local coords = utilities:get_adjacent_spaces(self.dir, 1, self.x, self.y)
    local beamcoords = {}
    if (self.dir==0) then beamcoords={{self.x+5,self.y+3},{self.x+6,self.y+2},{self.x+6,self.y+3},{self.x+6,self.y+4},{self.x+7,self.y+1},{self.x+7,self.y+2},{self.x+7,self.y+3},{self.x+7,self.y+4},{self.x+7,self.y+5}} end
    if (self.dir==1) then beamcoords={{self.x+2,self.y+3},{self.x+1,self.y+2},{self.x+1,self.y+3},{self.x+1,self.y+4},{self.x,self.y+1},{self.x,self.y+2},{self.x,self.y+3},{self.x,self.y+4},{self.x,self.y+5}} end
    if (self.dir==2) then beamcoords={{self.x+3,self.y+2},{self.x+2,self.y+1},{self.x+3,self.y+1},{self.x+4,self.y+1},{self.x+1,self.y+0},{self.x+2,self.y+0},{self.x+3,self.y+0},{self.x+4,self.y+0},{self.x+5,self.y+0}} end
    if (self.dir==3) then beamcoords={{self.x+3,self.y+5},{self.x+2,self.y+6},{self.x+3,self.y+6},{self.x+4,self.y+6},{self.x+1,self.y+7},{self.x+2,self.y+7},{self.x+3,self.y+7},{self.x+4,self.y+7},{self.x+5,self.y+7}} end
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do
            local pixelc = pget(x,y)
            if pixelc == 10 or pixelc == 0 
            then
                pset(x,y,self.stateframes) 
                for b=1, #beamcoords do 
                    local beamcoord=beamcoords[b]
                    pset(beamcoord[1],beamcoord[2],self.stateframes)
                end
            end
        end
    end
end



