
----------------------------------------------------------------
--player 
----------------------------------------------------------------

function loselife()
    p.lives-=1

    if p.lives < 0
    then
        -- gameover
        showgameover()
    else
        initlife()

        --New stuff
        initialise_game()
    end
    

end

-- check for player in the range specified
-- return 1 if found, 0 if not
function checkforplayer(x1,x2,y1,y2)
    if x1 < p.x+8 and p.x <= x2 and y1 < p.y+8 and p.y <= y2
         then
            return 1
        end           
    return 0
end

function killplayer(killedby)
    if p.activity<3
    then
        if killedby=="rock"
        then 
            p.activity=3
            p.activityframes=30      
        end 
        if killedby=="bomb"
        then
            p.activity=4
            p.activityframes=30
        end
    end
end

--check what the player is doing
function checkplayer()

    if p.activity==3 
    then
        -- Player is being squashed
        if p.sprite == 10 then p.sprite=11 else p.sprite=10 end
        p.activityframes-=1
        if p.activityframes==0
            then
                loselife()
            end
        return
    end

    if p.activity==4
    then
        -- Player is being bombed
        p.activityframes-=1
        if p.activityframes==0
            then
                loselife()
            end
        return
    end

    if p.activity==1 
    then
        -- Player is digging, so set that and return
        p.activityframes-=1
        if p.activityframes<0 -- Let it go at 0 for a frame to enable digging
            then
                trytodig(p.dir,0) 
                p.activity=0 
                p.sprite=p.oldsprite
            end    
        return
    end

    if p.framestomove!=0
        then
            if p.dir==0 then move(1,0,0,1,0,1) end
            if p.dir==1 then move(-1,0,2,3,1,1) end
            p.framestomove-=1
        else
            -- start new movement
            local moved = 0
            local horiz = 0
            if btn(0) then 
                moved=move(-1,0,2,3,1,0)
                horiz=1                 
            end
            if btn(1) and moved==0 then 
                moved=move(1,0,0,1,0,0)
                horiz=1 
            end
            if btn(2) and moved==0 then 
                moved=move(0,-1,4,5,2,0) 
            end
            if btn(3) and moved==0 then 
                moved=move(0,1,4,5,3,0) 
            end
            
            if moved==1 and horiz==1 then p.framestomove=7 end
        end
end

function checklocation()
    -- check pit
    if pitcoords[1][1]<=p.x and p.x<pitcoords[2][1]+8 and pitcoords[1][2]<=p.y and  p.y<pitcoords[2][2]+8
    then
        p.inpit=1
    else
        p.inpit=0
    end

    -- check cavern
    if caverncoords[1][1]<=p.x and p.x<caverncoords[2][1]+8 and caverncoords[1][2]<=p.y and  p.y<caverncoords[2][2]+8
    then
        p.incavern=1
    else
        p.incavern=0
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
    
    local count=#currentdiamondarray
    for x=1,count do 
        local diamond=currentdiamondarray[x]
        
        if diamond[6] == 0
            then
            
            -- check if coords of diamond are inside the box
            if diamond[1] >= coords[1] and diamond[1] <= coords[2]
                and diamond[2] >= coords[3] and diamond[2] <= coords[4]
                then
                    diamond[6] = 1
                    addscore(score.diamond)
                    return 1
                end            
            end
    end

    return 0
end

-- try to dig a range of pixels
function trytodig(dir,checkonly)
    local coords = getplayeradjacentspaces(dir, 1)
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do 
            local pixelc = pget(x,y)
            if pixelc == 10 
                then 
                    -- If player is not already marked as digging, mark and return
                    if checkonly==1 
                        then 
                            if p.activity==0 then 
                                p.oldsprite=p.sprite
                            end
                            p.activity=1 
                            p.activityframes=10
                            p.sprite=6+dir
                        else
                            -- Otherwise, this is a dirt pixel, so set it to 1 in the dirt array
                            digarray[y][x]=1
                            -- Mark the line as dirty
                            digarray[y][129]=1
                        end
                end
        end
    end

end

function getplayeradjacentspaces(dir,dig)
    return getadjacentspaces(dir,dig,p.x,p.y)
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
                trytodig(d,1)
                p.dir=d
                return 0 
            end
        end
    p.x+=x
    p.y+=y

    -- limit movement
    if p.x<0 then p.x=0 end 
    if p.y<0 then p.y=0 end 
    if p.x>120 then p.x=120 end 
    if p.y>184 then p.y=184 end 

    -- check if direction has changed
    if p.dir!=d 
        then 
            p.framecount=0 
        else 
            -- reset or increment
            if p.framecount==animframes then p.framecount = 0 else p.framecount+=1 end 
    end

    -- flip frame if needed
    if p.framecount==0 
        then
            if p.sprite==s1 then p.sprite=s2 else p.sprite=s1 end
    end 
    
    p.dir=d

    return 1
end

function addscore(score)
    p.score+=score
end
