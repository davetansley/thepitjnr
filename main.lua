-- init
function _init()
    game:init()
    screen:init()
end

-- update
function _update()
    
    game:update()

end

-- draw
function _draw()

    game:draw()
    printdebug()
end

scores={
    diamond=10
}

game = {
    level={},
    init = function (self)
        -- config variables
        game.level = levels[1]

        player:init()
        
        -- viewport variables
        view={}
        view.y=0 -- key for tracking the viewport

        self.reset()
    end,
    update = function(self)
        for r in all(rocks) do
            r:update()
        end
    
        for r in all(bombs) do
            r:update()
        end
    
        for r in all(diamonds) do
            r:update()
        end
    
        player:update()
        screen:update()
    end,
    draw = function (self)
        screen:draw()

        for r in all(rocks) do
            r:draw()
        end

        for r in all(bombs) do
            r:draw()
        end

        for r in all(diamonds) do
            r:draw()
        end

        screen:draw_scores()

        player:draw()
    end,
    reset = function ()
        
        view.y=0
    
        -- reload the map
        reload(0x1000, 0x1000, 0x2000)
    
        -- Populate entities
        rocks={}
        bombs={}
        diamonds={}
    
        screen:init()
    
    end

}

-- check for a dirt tile in the range specified
-- return 1 if dirt is found
function check_for_dirt(x1,y1,x2,y2)

    -- convert pixel coords to cells
    local coords = box_coords_to_cells(x1,y1,x2,y2)
    
    -- get the top tile
    local tile1 = screen.tiles[coords[2]][coords[1]]

    local offset1 = y1 % 8
    local offset2 = (y2+1) % 8

    -- if this is dirt and it still has dirt
    if tile1.sprite==70 and has_dirt(tile1,offset1,1)==1 then return 1 end

    -- if this cell doesn't spill over, exit
    if offset1==0 then return 0 end

    -- get the second tile
    local tile2 = screen.tiles[coords[4]][coords[3]]
 
    -- if this is dirt and it still has dirt
    if tile2.sprite==70 and has_dirt(tile2,offset2,0)==1 then return 1 end
    
    return 0
end

-- Check for dirt in the tile 
-- Basically, look for a 1 in the .dirt property after or before the offset
function has_dirt(tile, offset, afteroffset)
    
    for d = 1, #tile.dirt do 
        if sub(tile.dirt,d,d)=="1" and afteroffset==1 and d>offset then return 1 end
        if sub(tile.dirt,d,d)=="1" and afteroffset==0 and d<=offset then return 1 end
    end

    return 0
end

-- clear dirt in range specified
function dig_dirt(x1,y1,x2,y2)
    -- convert pixel coords to cells
    local coords = box_coords_to_cells(x1,y1,x2,y2)
    
    -- get the top tile
    local tile1 = screen.tiles[coords[2]][coords[1]]
    local offset1 = y1 % 8
    local offset2 = (y2+1) % 8
    
    if tile1.sprite==70 
    then
        tile1.dirt=clear_dirt(tile1.dirt,offset1,1)
        tile1.dirty=1
    end 
    
    if offset1==0 then return end 

    -- get the bottom tile
    local tile2 = screen.tiles[coords[4]][coords[3]]
    if tile2.sprite==70 
    then
        tile2.dirt=clear_dirt(tile2.dirt,offset2,0)
        tile2.dirty=1
    end
    
end

-- set dirt to 0 
-- if clearbottom == 1 clear the bottom offset lines
-- if clearbottom == 0 clear the top offset lines
function clear_dirt(dirt,offset,clearbottom)
    local temp = ""
    if clearbottom==1 
    then
        -- get the first part
        temp = sub(dirt, 1, offset)
        -- pad the rest
        for y=offset+1,#dirt do 
            temp=""..temp.."0"
        end
    else
        -- pad the first part
        for y=1,offset do 
            temp=""..temp.."0"
        end
        -- use the rest
        temp=""..temp..sub(dirt,offset+1, #dirt)
    end

    return temp   
end





screen = {
    tiles = {},

    init = function (self)
        populate_map(self)
    end,
    update = function (self)
        checkcamera()
    end,
    draw = function (self)
        cls()

        -- draw map and set camera
        map(0,0,0,0,16,24)
        camera(0,view.y)
        
        -- draw dirt
        draw_dirt()
    end,
    draw_zonk = function(self)
        rectfill(player.x-9,player.y+1,player.x+14,player.y+7,1)
        print("ZONK!!", player.x-8,player.y+2,7)
    end,
    draw_scores = function(self)
        rectfill(1,1+view.y,42,7+view.y,1)
        rectfill(90,1+view.y,126,7+view.y,1)
        print("score "..padnumber(player.score),2,2+view.y,7)
        print("high "..padnumber(player.highscore), 91,2+view.y,7)
    end
}

-- Walk the map and replace any entity sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function populate_map(screen)
    screen.tiles={}
    for y = 0,23 do
        screen.tiles[y]={}
        for x = 0,15 do
            local sprite = mget(x,y)

            local tile = {}
            tile.sprite=sprite
            tile.block=0
            tile.dirty=0
            tile.dirt=""

            if sprite==71 -- rock
            then
                mset(x,y,255)
                create_rock(x,y)
            elseif sprite==73 -- bomb
            then
                mset(x,y,255)
                create_bomb(x,y)
            elseif sprite==75 -- diamond
            then
                mset(x,y,255)
                create_diamond(x,y)
            elseif sprite== 70 -- dirt
            then
                -- initialise a dirt tile
                tile.dirt="11111111" -- each character represents a line of dirt, if 0 it has been removed
            elseif sprite== 64 -- dirt
            then
                tile.block=1
            end 

            screen.tiles[y][x] = tile

        end
    end
end

-- walk the map array
-- if a tile is a dirt tile and is dirty, then walk its dirt value and clear any pixels on rows set to 1
function draw_dirt()
    for y = 0,23 do
        for x = 0,15 do
            local tile=screen.tiles[y][x]
            for d = 1, #tile.dirt do 
                if sub(tile.dirt,d,d)=="0" 
                then 
                    -- set this row to black
                    local x1=x*8
                    local y1=y*8+(d-1) 
                    for p=x1,x1+7 do
                        pset(p,y1,0)
                    end
                end
            end
        end 
    end

end

function checkcamera()

    -- check for need to reset camera
    if player.y>=96 and view.y==0 then view.y=64 end
    if player.y<=88 and view.y==64 then view.y=0 end

end

function showgameover()
    printh("game over")
    cls()
    print("Game over!")
end
levels={
    {
        level=1,
        caverncoords={{40,160},{80,184}},
        pitcoords={{8,72},{32,104}},    
    }
}
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



-- Collections of objects
rocks={}
diamonds={}
gems={}
bombs={}

entity_states={
    idle="idle",
    preparing="preparing",
    falling="falling",
    invisible="invisible"
}

entity_types={
    rock=0,
    bomb=1,
    diamond=2,
    gem=3
}

function create_rock(colx,coly)
    add(rocks, {
        x = colx*8,
        y = coly*8,
        sprite = 71,
        state = entity_states.idle,
        time = 0,
        preparingtime=40,
        type=entity_types.rock,
        draw = function(self)
            spr(self.sprite,self.x,self.y)   
        end,
        update = function(self)
            update_faller(self, self.type)
            check_kill(self, self.type)
        end, 
        anims = {
            framecount=0,
            animindex=1,
            reset = function(self)
                self.framecount=1
                self.animindex=1
            end,
            idle={fr=1,71},
            preparing={fr=1,71,72},
            falling={fr=1,71}
        }
    })

end

function create_bomb(colx,coly)
    add(bombs, {
        x = colx*8,
        y = coly*8,
        sprite = 73,
        state = entity_states.idle,
        time = 0,
        preparingtime=30,
        type=entity_types.bomb,
        draw = function(self)
            spr(self.sprite,self.x,self.y)   
        end,
        update = function(self)
            if player.incavern==0 then return end
            update_faller(self, self.type)
            check_kill(self, self.type)
        end, 
        anims = {
            framecount=0,
            animindex=1,
            reset = function(self)
                self.framecount=1
                self.animindex=1
            end,
            idle={fr=1,73},
            preparing={fr=1,74},
            falling={fr=1,74}
        }
    })

end

function create_diamond(colx,coly)
    add(diamonds, {
        x = colx*8,
        y = coly*8,
        sprite = 75,
        state = entity_states.idle,
        time = 0,
        type=entity_types.diamond,
        draw = function(self)
            spr(self.sprite,self.x,self.y)   
        end,
        update = function(self)
            if self.anims.framecount>=self.anims[self.state].fr
            then
                self.anims.animindex = (self.anims.animindex % #self.anims[self.state]) + 1
                self.sprite =  self.anims[self.state][self.anims.animindex]
                self.anims.framecount=1
            else
                self.anims.framecount+=1
            end            
        end,
        anims = {
            framecount=0,
            animindex=1,
            reset = function(self)
                self.framecount=1
                self.animindex=1
            end,
            idle={fr=2,75,76,77},
            invisible={fr=1,255}
        }
    })

end

function check_kill(faller, type)
    
    if faller.state!=entity_states.falling then return end

    local coords = getadjacentspaces(3, 0, faller.x, faller.y)
    if checkforplayer(coords[1],coords[2],coords[3],coords[4])==1 
    then 
        killplayer(type) 
    end
    
end

function update_faller(faller, type)
    -- check below for space to fall
    local canfall=checkcanfall(faller.x, faller.y) 
--printh(""..faller.state.." "..faller.anims.framecount)
    if type==entity_types.bomb and faller.state==entity_states.idle
    then
        -- for bombs, check random number
        local rand=rnd(100)
        if rand>1 then canfall=0 end
    end

    if canfall==1 and player.activity<3 
    then
        if faller.state==entity_states.falling
        then
            -- actually falling
            faller.y+=1
        elseif faller.state==entity_states.preparing
        then
            faller.time+=1
            if faller.time >= faller.preparingtime 
            then
                faller.state=entity_states.falling
            end
        elseif faller.state==entity_states.idle
        then 
            faller.state=entity_states.preparing
            faller.time=0 
            faller.anims:reset()
        end
        
        -- update sprite
        faller.anims.framecount+=1
        faller.anims.animindex = (faller.anims.animindex % #faller.anims[faller.state]) + 1
        faller.sprite =  faller.anims[faller.state][faller.anims.animindex]
    else
        faller.state=entity_states.idle
        faller.anims:reset()
    end
    
end

-- check a range of pixels that the rock is about to move into
-- if can't fall return 0
-- if can fall return 1
function checkcanfall(x,y) 
    if y>=184 then return 0 end -- prevent out of bounds

    local coords = getadjacentspaces(3, 0, x, y)

    -- check for an overlap with the player top line
    if coords[2] >= player.x and player.x+7 >= coords[1] and player.y == coords[3]
    then
        return 1
    end

    -- check other rocks
    for r=1,#rocks do 
        local rock=rocks[r]
        if rock.y==y+8 and rock.x==x then return 0 end
    end

    -- check dirt array
    local cellcoords = point_coords_to_cells(coords[1], coords[3])
    local offset=coords[3]%8
    local tile = screen.tiles[cellcoords[2]][cellcoords[1]]
    if sub(tile.dirt,offset+1,offset+1)=="1" or tile.block==1 then return 0 end
    
    return 1
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

-- Convert box coords in pixels to cells
-- Returns array of {x1,y1,x2,y2}
function box_coords_to_cells(x1,y1,x2,y2)
    local coords1 = point_coords_to_cells(x1,y1)
    local coords2 = point_coords_to_cells(x2,y2)

    return {coords1[1],coords1[2],coords2[1],coords2[2]}
end

-- Convert a point in pixels to cells
-- Returns {x,y} array
function point_coords_to_cells(x,y)
    -- Subtract one from the y value to account for score panel
    return {flr(x/8),flr(y/8)}
end

function printdebug()
    printh("CPU: "..stat(1))
end
