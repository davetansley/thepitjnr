player={
    score=0, -- key for storing score
    highscore=9999, -- key for storing high score
    lives=3, -- key for storing lives

    init=function(self)
        self.x=16 --key for the x variable
        self.y=16 --key for the y variable
        self.dir=0 --key for the direction: 0 right, 1 left, 2 up, 3 down
        self.sprite=0 -- key for the sprite
        self.oldsprite=0 -- key for storing the old sprite
        self.framecount=0 -- key for frame counting
        self.framestomove=0 -- key for frames left in current move
        self.activity=0 -- key for player activity. 0 moving, 1 digging, 2 shooting, 3 squashing
        self.activityframes=0 -- key for frames in current activity
        self.incavern=0 -- key for whether player is in the diamond cavern
        self.inpit=0 -- key for whether player is in the pit
        self.animframes=3 -- key for the number of frames an animation frame has
    end,
    update=function(self)
        update_player()
    end,
    draw=function(self)
        -- draw player
        spr(self.sprite,self.x,self.y)

        -- if player is digging, draw effect
        if self.activity==1 and self.activityframes>0 then flashsquare(self.dir) end

        -- zonk text
        if player.activity==4 then screen:draw_zonk() end

    end
}

-- update the player state
function update_player()

    if player.activity==3 
    then
        -- Player is being squashed
        if player.sprite == 10 then player.sprite=11 else player.sprite=10 end
        player.activityframes-=1
        if player.activityframes==0
            then
                loselife()
            end
        return
    end

    if player.activity==4
    then
        -- Player is being bombed
        player.activityframes-=1
        if player.activityframes==0
            then
                loselife()
            end
        return
    end

    if player.activity==1 
    then
        -- Player is digging, so set that and return
        player.activityframes-=1
        if player.activityframes<0 -- Let it go at 0 for a frame to enable digging
            then
                --trytodig(player.dir) 
                player.activity=0 
                player.sprite=player.oldsprite
            end    
        return
    end

    if player.framestomove!=0
    then
        if player.dir==0 then move(1,0,0,1,0,1) end
        if player.dir==1 then move(-1,0,2,3,1,1) end
        player.framestomove-=1
    else
        -- start new movement
        local moved = 0
        local horiz = 0
        if btn(0) then 
            moved=move(-1,0,2,3,1,0)
            horiz=1                 
        elseif btn(1) and moved==0 then 
            moved=move(1,0,0,1,0,0)
            horiz=1 
        elseif btn(2) and moved==0 then 
            moved=move(0,-1,4,5,2,0) 
        elseif btn(3) and moved==0 then 
            moved=move(0,1,4,5,3,0) 
        end
        
        if moved==1 and horiz==1 then player.framestomove=7 end
    end

    -- update the player's locations
    checklocation()
end

function loselife()
    player.lives-=1

    if player.lives < 0
    then
        -- gameover
        showgameover()
    else
        player:init()
        game.reset()
    end
    

end

-- check for player in the range specified
-- return 1 if found, 0 if not
function checkforplayer(x1,x2,y1,y2)
    if x1 < player.x+8 and player.x <= x2 and y1 < player.y+8 and player.y <= y2
         then
            return 1
        end           
    return 0
end

function killplayer(killedby)
    if player.activity<3
    then
        printh(killedby)
        if killedby==entity_types.rock
        then 
            player.activity=3
            player.activityframes=30      
        end 
        if killedby==entity_types.bomb
        then
            player.activity=4
            player.activityframes=30
        end
    end
end

function checklocation()
    -- check pit
    if game.level.pitcoords[1][1]<=player.x and player.x<game.level.pitcoords[2][1]+8 and game.level.pitcoords[1][2]<=player.y and  player.y<game.level.pitcoords[2][2]+8
    then
        player.inpit=1
    else
        player.inpit=0
    end

    -- check cavern
    if game.level.caverncoords[1][1]<=player.x and player.x<game.level.caverncoords[2][1]+8 and game.level.caverncoords[1][2]<=player.y and  player.y<game.level.caverncoords[2][2]+8
    then
        player.incavern=1
    else
        player.incavern=0
    end
end

-- check a range of pixels that the player is about to move into
-- if can move return 0
-- if can't move return 1
function checkcanmove(dir)
    local result = 0
    local coords = getplayeradjacentspaces(dir, 0)
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
function checkforgem(dir)
    local result = 0
    local coords = getplayeradjacentspaces(dir, 0)
    
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
                    addscore(scores.diamond)
                    sfx(0)
                    return 1
                end            
            end
    end

    return 0
end

-- try to dig a range of pixels
function trytodig(dir)
    local coords = getplayeradjacentspaces(dir, 1)
    if check_for_dirt(coords[1], coords[3], coords[2], coords[4])==1
    then
        dig_dirt(coords[1], coords[3], coords[2], coords[4])
        sfx(1)

        -- Update this later to just set the player state - anims handled in draw
        if player.activity==0 then 
            player.oldsprite=player.sprite
        end
        player.activity=1 
        player.activityframes=10
        player.sprite=6+dir
    end
    
end

function getplayeradjacentspaces(dir,dig)
    return getadjacentspaces(dir,dig,player.x,player.y)
end

-- get range of spaces adjacent to the place in the direction specified
-- if dig is 1, get the square vertically, otherwise just 8 pixels (horiz is always a square)
function getadjacentspaces(dir, dig, x, y)
    local coords = {}
    local ymod1 = -1
    local ymod2 = 8
    if dig == 1
    then
        ymod1=-8
        ymod2=15
    else
    end

    if dir==0 then coords={x+8, x+15, y, y+7} end -- right
    if dir==1 then coords={x-8, x-1, y, y+7} end -- left
    if dir==2 then coords={x, x+7, y+ymod1, y-1} end -- up
    if dir==3 then coords={x, x+7, y+8, y+ymod2} end -- down
    
    return coords
end


-- Move the player
-- x,y = axis deltas
-- s1,s2 = sprites to flip between
-- d = direction
function move(x,y,s1,s2,d,auto)
    
    -- only check movement if this is auto movement
    if auto==0
        then
        local preventmove=0
        preventmove=checkcanmove(d)
        if preventmove!=0 
            then 

                -- Check for gem
                local gem=checkforgem(d)
                if gem==1 then return 0 end
                -- Can't move so try to dig
                trytodig(d)
                player.dir=d
                return 0 
            end
        end
    player.x+=x
    player.y+=y

    -- limit movement
    if player.x<0 then player.x=0 end 
    if player.y<0 then player.y=0 end 
    if player.x>120 then player.x=120 end 
    if player.y>184 then player.y=184 end 

    -- check if direction has changed
    if player.dir!=d 
        then 
            player.framecount=0 
        else 
            -- reset or increment
            if player.framecount==player.animframes then player.framecount = 0 else player.framecount+=1 end 
    end

    -- flip frame if needed
    if player.framecount==0 
        then
            if player.sprite==s1 then player.sprite=s2 else player.sprite=s1 end
    end 
    
    player.dir=d

    return 1
end

function addscore(score)
    player.score+=score
end


-- flash the adjacent square when digging
function flashsquare(dir)
    local coords = getadjacentspaces(dir, 1, player.x, player.y)
    local beamcoords = {}
    if (dir==0) then beamcoords={{player.x+5,player.y+3},{player.x+6,player.y+2},{player.x+6,player.y+3},{player.x+6,player.y+4},{player.x+7,player.y+1},{player.x+7,player.y+2},{player.x+7,player.y+3},{player.x+7,player.y+4},{player.x+7,player.y+5}} end
    if (dir==1) then beamcoords={{player.x+2,player.y+3},{player.x+1,player.y+2},{player.x+1,player.y+3},{player.x+1,player.y+4},{player.x,player.y+1},{player.x,player.y+2},{player.x,player.y+3},{player.x,player.y+4},{player.x,player.y+5}} end
    if (dir==2) then beamcoords={{player.x+3,player.y+2},{player.x+2,player.y+1},{player.x+3,player.y+1},{player.x+4,player.y+1},{player.x+1,player.y+0},{player.x+2,player.y+0},{player.x+3,player.y+0},{player.x+4,player.y+0},{player.x+5,player.y+0}} end
    if (dir==3) then beamcoords={{player.x+3,player.y+5},{player.x+2,player.y+6},{player.x+3,player.y+6},{player.x+4,player.y+6},{player.x+1,player.y+7},{player.x+2,player.y+7},{player.x+3,player.y+7},{player.x+4,player.y+7},{player.x+5,player.y+7}} end
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do
            local pixelc = pget(x,y)
            if pixelc == 10 or pixelc == 0 
            then
                pset(x,y,player.activityframes) 
                for b=1, #beamcoords do 
                    local beamcoord=beamcoords[b]
                    pset(beamcoord[1],beamcoord[2],player.activityframes)
                end
            end
        end
    end
end



