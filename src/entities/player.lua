player_states = {
    moving = 0,
    digging = 1,
    shooting = 2,
    squashed = 3,
    bombed = 4,
    mauled = 5,
    falling = 6,
    escaping = 7
}

player={
    score=0, -- key for storing score
    lives=3, -- key for storing lives
    demo = {},
    demopos = 1
}

directions = {
    right = 0,
    left = 1,
    up = 2,
    down = 3
}

demo = "18,3,6,0,36,3,8,0,80,3,8,2,12,1,40,3,4,1,18,3,6,0,12,2,4,0,24,3,16,2,12,0,18,2,4,1,24,2,2,1,32,2,3,1,32,2,5,1,8,3,4,1,18,2,2,1,27,2,1,0,8,2,0,-1"
function player:init()
    self.lives,self.score,self.demo,self.demopos = 3,0,split(demo),1
    self:reset()
end

function player:update()
    self:update_player()
end

function player:draw()
    if (player.state==player_states.escaping) return

    -- draw player
    spr(self.sprite,self.x,self.y)

    -- if player is digging, draw effect
    if self.state==player_states.digging and self.stateframes>0 then self:flash_square() end

    -- zonk text
    if player.state==player_states.bombed then screen:draw_zonk() end

end

function player:reset()
    self.x, self.y, self.dir, self.sprite, self.oldsprite, self.framecount, self.framestomove, self.state,
        self.stateframes, self.incavern, self.inpit, self.animframes, self.firecooldown, self.diamonds, self.gems
        = 16,16,directions.right,0,0,0,0,0,0,0,0,10,0,0,0 
end

-- return 1 if the player is dying
function player:is_dying()
    if self.state==player_states.crushed or self.state==player_states.bombed or self.state==player_states.mauled or self.state==player_states.falling then return 1 end 
    return 0
end

-- update the player state
function player:update_player()

    if (self.state==player_states.escaping) return

    if self.stateframes==0 and self:is_dying()==1
    then
        self:lose_life()
        return
    end

    if self.state==player_states.falling
    then
        if (game.frame%1 != 0) return
        -- Player is falling
        if self.sprite == 4 then self.sprite=5 else self.sprite=4 end
        if (self.y <= levels.pitcoords[2][2]-1) self.y+=1
        self.stateframes-=1
        if (self.stateframes==60) utilities:sfx(4)
        return
    end

    if self.state==player_states.mauled
    then
        if (game.frame%4 != 0) return
        -- Player is being mauled
        if self.sprite == 2 then self.sprite=0 else self.sprite=2 end
        self.stateframes-=1
        return
    end

    if self.state==player_states.crushed
    then
        -- Player is being squashed
        if game.frame%3==0
        then
            if self.stateframes < 10
            then
                self.sprite=71
            else
                if self.sprite == 10 then self.sprite=11 else self.sprite=10 end
            end
            self.stateframes-=1
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

    -- reduce the shot cooldown
    self.firecooldown-=1
    if (self.firecooldown<0) self.firecooldown=0

    -- check if we've completed the level
    if (self:check_win()==1) return

    -- check if we're falling in the pit
    if (self:check_pit()==1) return;

    if self.state==player_states.digging 
    then
        -- Player is digging, so set that and return
        self.stateframes-=1
        if self.stateframes<0 -- Let it go at 0 for a frame to enable digging
            then
                self.state,self.sprite=player_states.moving,player.oldsprite
            end    
        return
    end

    if self.framestomove!=0
    then
        if self.dir==directions.right then self:move(1,0,0,1,directions.right,1) else self:move(-1,0,2,3,directions.left,1) end
        self.framestomove-=1
    else
        -- start new movement
        local moved,horiz,dir = 0,0,-1

        if (game.demo==1) 
        then
            dir=self.demo[self.demopos+1]
            self.demo[self.demopos]-=1
            if (self.demo[self.demopos]==0 and self.demopos<#self.demo-1) self.demopos+=2
            if (btn(4)) titlescreen:init()
        else
            if btn(0) 
            then    
                dir=directions.left
            elseif btn(1) 
            then    
                dir=directions.right
            elseif btn(2) 
            then    
                dir=directions.up
            elseif btn(3) 
            then    
                dir=directions.down
            elseif btn(5) then self:fire()
            end
        end

        if (dir==0) moved,horiz=self:move(1,0,0,1,directions.right),1
        if (dir==1 and moved==0) moved,horiz=self:move(-1,0,2,3,directions.left),1
        if (dir==2 and moved==0) moved=self:move(0,-1,4,5,directions.up) 
        if (dir==3 and moved==0) 
        then 
            if self.inpit==0
            then
                moved=self:move(0,1,4,5,directions.down)
            else
                self.sprite,self.dir=0,directions.right
            end
        end
        if moved==1 and horiz==1 then self.framestomove=7 end
    end

    -- update the player's location
    self:check_location()
end

function player:check_win()
    if (self.diamonds > 0 or self.gems == 4) and self.x==16 and self.y==16 
    then
        self.state,game.ship.state=player_states.escaping,ship_states.escaping
        return 1
    end

    return 0
end

function player:check_pit()
    -- check if the player is falling
    if self.inpit==1 and self.x >= levels.pitcoords[1][1]+game.bridge 
    then 
        self.state,self.stateframes=player_states.falling,100
        return 1
    end
    return 0
end

function player:fire()
    if self.dir==directions.up or self.dir==directions.down or self.firecooldown > 0 then return end 

    -- add bullet to the list
    local b = bullet:new()
    local xmod=-8
    if (self.dir==directions.right) xmod=8
    b:set_coords(self.x+xmod,self.y,self.dir)
    add(bullets,b)
    self.firecooldown=15
    utilities:sfx(3)
end

function player:lose_life()
    if (game.demo==1) 
    then
        titlescreen:init()
        return
    end 

    self.lives-=1

    if self.lives < 0
    then
        -- gameover
        game:show_gameover()
    else
        self:reset()
        game:reset()
        livesscreen:init()
    end
end

-- check for player in the range specified
-- return 1 if found, 0 if not
function player:check_for_player(x1,x2,y1,y2)
    return utilities:check_overlap({x1,x2,y1,y2},{self.x,self.x+8,self.y,self.y+8})
end

function player:kill_player(state)
    self.state=state
    self.stateframes=30  
end

function player:check_location()
    -- check pit
    if levels.pitcoords[1][1]<=self.x and self.x<=levels.pitcoords[2][1] and levels.pitcoords[1][2]<=self.y and  self.y<levels.pitcoords[2][2]+8
    then
        self.inpit=1
    else
        self.inpit=0
    end

    -- check cavern
    if levels.caverncoords[1][1]<=self.x and self.x<levels.caverncoords[2][1]+8 and levels.caverncoords[1][2]<=self.y and  self.y<levels.caverncoords[2][2]+8
    then
        self.incavern=1
    else
        self.incavern=0
    end
end

-- check a range of pixels that the player is about to move into
-- if can't move return 0
-- if can move return 1
function player:check_can_move(dir)
    local result = 1
    local coords = self:get_player_adjacent_spaces(dir,0)
    
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
    if mget(cellcoords[1]+screen.mapx, cellcoords[2])==64 or mget(cellcoords[3]+screen.mapx,cellcoords[4])==64 or 
        mget(cellcoords[1]+screen.mapx, cellcoords[2])==65 or mget(cellcoords[3]+screen.mapx,cellcoords[4])==65
    then
        return 0
    end

    -- if contains dirt, can't move - will dig
    local dirtfound=game:check_for_dirt(coords[1],coords[3],coords[2],coords[4])
    if (dirtfound==1) return 0

    -- otherwise, can move
    return 1
end

-- try to dig a range of pixels
function player:try_to_dig(dir)
    local coords = self:get_player_adjacent_spaces(dir,1)
    if game:check_for_dirt(coords[1], coords[3], coords[2], coords[4])==1
    then
        game:dig_dirt(coords[1], coords[3], coords[2], coords[4])
        utilities:sfx(1)

        -- Update this later to just set the player state - anims handled in draw
        if self.state==player_states.moving then 
            self.oldsprite=self.sprite
        end
        self.state,self.stateframes,self.sprite=player_states.digging,14,6+dir
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
    if auto!=1
    then
        local canmove=self:check_can_move(d)
        if canmove!=1
        then 
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
end

-- flash the adjacent square when digging
function player:flash_square()
    local coords = utilities:get_adjacent_spaces(self.dir, 1, self.x, self.y)
    local beamcoords = {}
    if (self.dir==directions.right) then beamcoords={{self.x+5,self.y+3},{self.x+6,self.y+2},{self.x+6,self.y+3},{self.x+6,self.y+4},{self.x+7,self.y+1},{self.x+7,self.y+2},{self.x+7,self.y+3},{self.x+7,self.y+4},{self.x+7,self.y+5}} end
    if (self.dir==directions.left) then beamcoords={{self.x+2,self.y+3},{self.x+1,self.y+2},{self.x+1,self.y+3},{self.x+1,self.y+4},{self.x,self.y+1},{self.x,self.y+2},{self.x,self.y+3},{self.x,self.y+4},{self.x,self.y+5}} end
    if (self.dir==directions.up) then beamcoords={{self.x+3,self.y+2},{self.x+2,self.y+1},{self.x+3,self.y+1},{self.x+4,self.y+1},{self.x+1,self.y+0},{self.x+2,self.y+0},{self.x+3,self.y+0},{self.x+4,self.y+0},{self.x+5,self.y+0}} end
    if (self.dir==directions.down) then beamcoords={{self.x+3,self.y+5},{self.x+2,self.y+6},{self.x+3,self.y+6},{self.x+4,self.y+6},{self.x+1,self.y+7},{self.x+2,self.y+7},{self.x+3,self.y+7},{self.x+4,self.y+7},{self.x+5,self.y+7}} end
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



