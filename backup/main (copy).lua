-- init
function _init()
    initgame()
end

-- draw
function _draw()
    drawscreen()
end

-- update
function _update()
    checkrocks()
    checkbombs()
    checkplayer()
    checklocation()
    checkcamera()
end

----------------------------------------------------------------
--screen
----------------------------------------------------------------
function drawscreen()
    cls()

    -- draw map and set camera
    map(0,0,0,8,16,24)
    camera(0,view.y)

    -- draw digs
    drawdigs()

    -- draw rocks
    drawrocks()

    -- draw bombs
    drawbombs()

    -- draw diamonds
    drawdiamonds()

    -- draw player
    spr(p.sprite,p.x,p.y)

    -- if player is digging, draw effect
    if p.activity==1 and p.activityframes>0 then flashsquare(p.dir) end

    -- score panel
    drawscorepanel()

    -- zonk text
    drawzonk()

    --printdebug()
end

-- Initialises the dig
function initdirtarray()
    for y = 1, 192 do 
        digarray[y]={}
        for x = 1, 128 do 
            digarray[y][x]=0
        end
    end
end

function drawzonk()
    if p.activity==4 then print("ZONK!!", p.x-8,p.y,7) end
end

function drawrocks()
    local count=#currentrockarray
    for x=1,count do 
        local rock=currentrockarray[x]        
        
        rectfill(rock[1], rock[2], rock[1]+7, rock[2]+7, 0)    

        spr(rock[4],rock[1],rock[2])        
    end
end

function drawbombs()
    local count=#currentbombarray
    for x=1,count do 
        local bomb=currentbombarray[x]
        
        spr(bomb[4],bomb[1],bomb[2])
        
    end
end

function drawdiamonds()
    local count=#currentdiamondarray
    for x=1,count do 
        local diamond=currentdiamondarray[x]
        
        if diamond[6] == 0
            then
            spr(diamond[4]+diamond[5],diamond[1],diamond[2])

            currentdiamondarray[x][5]+=1
            if currentdiamondarray[x][5]>2 then currentdiamondarray[x][5]=0 end
            end
    end
end

function drawdigs()
    for y = 1+view.y, 120+view.y do 
        for x = 8, 120 do 
            if digarray[y][x]==1 then pset(x,y,0) end
        end
    end
end

function drawscorepanel()
    rectfill(0,0+view.y,128,8+view.y,0)

    print("score "..padnumber(p.score),10,2+view.y,7)
    print("high "..padnumber(p.highscore), 85,2+view.y,7)
end

-- flash the adjacent square when digging
function flashsquare(dir)
    local coords = getadjacentspaces(dir, 1, p.x, p.y)
    local beamcoords = {}
    if (dir==0) then beamcoords={{p.x+5,p.y+3},{p.x+6,p.y+2},{p.x+6,p.y+3},{p.x+6,p.y+4},{p.x+7,p.y+1},{p.x+7,p.y+2},{p.x+7,p.y+3},{p.x+7,p.y+4},{p.x+7,p.y+5}} end
    if (dir==1) then beamcoords={{p.x+2,p.y+3},{p.x+1,p.y+2},{p.x+1,p.y+3},{p.x+1,p.y+4},{p.x,p.y+1},{p.x,p.y+2},{p.x,p.y+3},{p.x,p.y+4},{p.x,p.y+5}} end
    if (dir==2) then beamcoords={{p.x+3,p.y+2},{p.x+2,p.y+1},{p.x+3,p.y+1},{p.x+4,p.y+1},{p.x+1,p.y+0},{p.x+2,p.y+0},{p.x+3,p.y+0},{p.x+4,p.y+0},{p.x+5,p.y+0}} end
    if (dir==3) then beamcoords={{p.x+3,p.y+5},{p.x+2,p.y+6},{p.x+3,p.y+6},{p.x+4,p.y+6},{p.x+1,p.y+7},{p.x+2,p.y+7},{p.x+3,p.y+7},{p.x+4,p.y+7},{p.x+5,p.y+7}} end
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do
            local pixelc = pget(x,y)
            if pixelc == 10 or pixelc == 0 
            then
                pset(x,y,p.activityframes) 
                for b=1, #beamcoords do 
                    local beamcoord=beamcoords[b]
                    pset(beamcoord[1],beamcoord[2],p.activityframes)
                end
            end
        end
    end
end


function checkcamera()

    -- check for need to reset camera
    if p.y>=88 and view.y==0 then view.y=72 end
    if p.y<=80 and view.y==72 then view.y=0 end

end

function showgameover()
    cls()
    print("Game over!")
end

----------------------------------------------------------------
--fall management
----------------------------------------------------------------
function checkrocks()
    checkfallers(currentrockarray,1)
end

function checkbombs()
    if p.incavern==0 then return end

    checkfallers(currentbombarray,2)
end

-- checks an array of fallers to see if they should fall
-- type: 1 rock, 2 bomb
function checkfallers(fallerarray,type)
    local count=#fallerarray
    for x=1,count do 
        local faller=fallerarray[x]    
        -- check below for space to fall
        local cantfall=checkcanfall(faller[1], faller[2]) 

        if type==2 and faller[3]==0
        then
            -- for bombs, check random number
            local rand=rnd(100)
            if rand>1 then cantfall=2 end
        end

        if cantfall==1 and faller[3]==1 -- has struck a player and faller is falling
            then
                if type==1 
                then 
                    p.activity=3
                    p.activityframes=30      
                else
                    p.activity=4
                    p.activityframes=30
                end
            end

        if cantfall<2 and p.activity<3 
            then
                if faller[3]==0 
                then 
                    if type==1 then faller[3]=30 end
                    if type==2 then faller[3]=15 end 
                end 

                if faller[3]==1 
                    then
                        -- actually falling
                        faller[2]+=1

                    else
                        faller[3]-=1 -- decrease state by one
                        if type==1
                        then
                            if faller[4]==71 then faller[4]=72 else faller[4]=71 end
                        end 

                        if type==2
                        then
                            faller[4]=74
                        end 

                    end
            else
                faller[3]=0
            end
        
    end
end

-- check for player in the range specified
-- return 1 if found, 0 if not
function checkforplayer(x1,x2,y1,y2)
    --printh(""..x1..","..y1.." "..x2..","..y2)
    --printh(""..p.x..","..p.y)
    if x1 < p.x+8 and p.x <= x2 and y1 < p.y+8 and p.y <= y2
         then
            return 1
        end           
    return 0
end

-- check a range of pixels that the rock is about to move into
-- if can fall return 0
-- if can't fall return 2
-- if can fall onto a player return 1
function checkcanfall(x,y)
    local result = 0
    -- only check if rock is visible
    if view.y == 0 and y > 120 then return 2 end
    if view.y > 0 and y < 72 then return 2 end

    local coords = getadjacentspaces(3, 0, x, y)
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do 
            local pixelc = pget(x,y)
            -- Not blank or dirt, so can't fall
            if pixelc != 0 
                then
                    result=2
                end
        end
    end

    if result==2 
    then
        --printh(x..","..y)
        if checkforplayer(coords[1],coords[2],coords[3],coords[4])==1 then result=1 end
    end

    return result
end

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

------------------------------------------
-- Utilities
------------------------------------------
function padnumber(input)
    output=tostr(input)
    local l=#output
    for x=l,3 do 
        output="0"..output
    end
    return output
end


function copyarray(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyarray(orig_key)] = copyarray(orig_value)
        end
        setmetatable(copy, copyarray(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function printdebug()
    printh("CPU: "..stat(1))
end

-------------------------------------------
-- inits
-------------------------------------------
function initgame()

    -- config variables
    score={}
    score.diamond=10

    -- player variables
    p={}   --the player table
    p.score=0 -- key for storing score
    p.highscore=9999 -- key for storing high score
    p.lives=3 -- key for storing lives

    -- viewport variables
    view={}
    view.y=0 -- key for tracking the viewport

    -- general variables
    animframes=6

    -- dig array
    digarray={}

    -- rockarrays - {x, y, falling state, sprite}
    rockarray={{32,32,0,71},{48,48,0,71},{48,64,0,71},{48,72,0,71},{56,80,0,71}
        ,{80,80,0,71},{88,80,0,71},{72,72,0,71},{88,56,0,71},{56,104,0,71},{40,112,0,71},{72,120,0,71}
        ,{24,168,0,71},{8,160,0,71}}
    --    rockarray={{32,32,0,71}}
    currentrockarray={}

    -- bombarrays - {x, y, falling state, sprite}
    bombarray={{40,160,0,73},{48,160,0,73},{56,160,0,73},{64,160,0,73},{72,160,0,73},{80,160,0,73},}

    currentbombarray={}

    -- diamondarrays - {x, y, sprite, offset}
    diamondarray={{40,184,0,75,0,0},{56,184,0,75,1,0},{64,184,0,75,2,0},{80,184,0,75,0,0}}

    currentdiamondarray={}

    caverncoords={{40,160},{80,184}}
    pitcoords={{8,72},{32,104}}

    initlife()
end

-- Reset after life is lost
function initlife()
    p.x=16 --key for the x variable
    p.y=24 --key for the y variable
    p.dir=0 --key for the direction: 0 right, 1 left, 2 up, 3 down
    p.sprite=0 -- key for the sprite
    p.oldsprite=0 -- key for storing the old sprite
    p.framecount=0 -- key for frame counting
    p.framestomove=0 -- key for frames left in current move
    p.activity=0 -- key for player activity. 0 moving, 1 digging, 2 shooting, 3 squashing
    p.activityframes=0 -- key for frames in current activity
    p.incavern=0 -- key for whether player is in the diamond cavern
    p.inpit=0 -- key for whether player is in the pit

    view.y=0

    digarray={}
    initdirtarray()

    currentbombarray=copyarray(bombarray)
    currentdiamondarray=copyarray(diamondarray)
    currentrockarray=copyarray(rockarray)
end