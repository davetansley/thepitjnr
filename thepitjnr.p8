pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- the pit jr.
-- by dave tansley
cart_id="thepitjrv01"

-- init
function _init()
    cartdata(cart_id)

    highscorescreen:load_scores()

    titlescreen:init()
end

-- update
function _update60()
    update()
    --utilities:print_debug()
end

-- draw
function _draw()
    draw()
end

scores={
    diamond=100, -- 2000
    gem=50, -- 1000
    singlebonus=500, -- 5000
    doublebonus=1000, -- 10000
    triplebonus=1500, -- 15000
    robot=10, -- 100
}

highscores={
    {
        score=0,
        name="gam"
    },
    {
        score=0,
        name="gam"
    },
    {
        score=0,
        name="gam"
    }
}

game_states = {
    waiting = 0,
    running = 1
}

game = {
    state=game_states.waiting,
    demo=0,
    cheat=0,
    mountain=split "10,9,8,7,6,5,4",
    bridge=24 -- how much is the bridge extended
}
function game:init_demo()
    self.demo=1
    self:start()
end

function game:init()
    self.demo=0
    self:start()
end

function game:start()
    self.switchto()

    -- config variables
    self.currentlevel,self.highscore=1,highscores[1].score
    player:init()
    
    -- viewport variables
    view={
        y=0
    }
    
    self:reset()

    screen:init()

    self.state = game_states.running
end

function game:switchto()
    -- set state functions
    update=function ()
        game:update()
    end
    draw=function ()
        game:draw()
    end
end

function game:update()

    self.frame+=1
    if (self.frame>3000) self.frame=0

    -- update the ship only if needed
    self.ship:update()
    if self.ship.state != ship_states.lingering and self.ship.state != ship_states.landed
    then
        return;
    end

    self:update_array(self.objects)

    -- if we need a robot, spawn it
    if self.tank.state==tank_states.shooting and #self.robots < self.settings[2] and self.frame%game.settings[6] == 0
    then
        local r = robot:new()
        r.newcolors = utilities.generate_pallete(r.possiblecolors)
        add(self.robots,r)
    end

    self:update_array(bullets)

    self:update_array(self.robots)

    if self.tank.state == tank_states.moving
    then
        self.tank:update()
    end

    self.monster:update()
    if self.ship.state == ship_states.landed
    then
        player:update()
    end

    if player.inpit==1 and game.frame%game.settings[5]==0
    then
        -- reduce pit bridge by 1
        game.bridge-=1
        if (game.bridge<0) game.bridge=0
    end

    screen:update()
    game:update_timer()
end

function game:draw()
    screen:draw()

    self:draw_array(self.objects)
    self:draw_array(self.robots)
    self:draw_array(bullets)

    self.ship:draw()

    self.tank:draw()

    self:draw_timer()

    if self.ship.state == ship_states.landed
    then
        screen:draw_scores()
        player:draw()
    end

    self.monster:draw()
end

function game:update_array(array)
    for r in all(array) do
        r:update()
    end
end

function game:draw_array(array)
    for r in all(array) do
        r:draw()
    end
end

function game:reset()
    
    self.level = levels[self.currentlevel]
    self.settings = split(self.level.settings)

    -- Reset everything
    self.ship, self.tank,self.monster,self.robots,self.bridge, self.objects,view.y,self.frame,rocks,bombs,diamonds,gems,bullets,game.currentmountain,game.currentmountaincount
        = ship:new(),tank:new(), monster:new(),{},24,{},0,0,{},{},{},{},{},1,0
   
    -- reload the map
    reload(0x1000, 0x1000, 0x2000)

    screen:init()

end

function game:next_level()
    if self.demo==1 
    then
        titlescreen:init()
        return
    end

    self.currentlevel+=1
    levelendscreen:init()
end

function game:update_timer()

    if (self.frame % game.settings[3] != 0 or self.tank.state != tank_states.shooting) return

    if self.currentmountain > #self.mountain
    then
        view.y,self.ship.state = 0,ship_states.fleeing
        return
    end

    -- update count 
    self.currentmountaincount+=1

    local currentsprite = mget(self.mountain[self.currentmountain]+screen.mapx, 1)
    
    -- if this is the last count, check tile above current
    if self.currentmountaincount % 4 == 0 or currentsprite == 66 or currentsprite == 67 -- the slope tiles only take a single hit
    then
        self.currentmountaincount=0
        -- get the sprite above current
        local sprite = mget(self.mountain[self.currentmountain]+screen.mapx, 0)
        if sprite==65
        then
            -- is empty, so move to next mountain
            mset(self.mountain[self.currentmountain]+screen.mapx, 1, 65)
            self.currentmountain+=1
        else
            -- is not empty, so copy current sprite down and clear above
            mset(self.mountain[self.currentmountain]+screen.mapx, 1, sprite)
            mset(self.mountain[self.currentmountain]+screen.mapx, 0, 65)
        end
    end

end

function game:draw_timer()
    if self.currentmountaincount > 0
    then
        local first = 1
        for x=8-self.currentmountaincount*2, 8, 2 do 
            local c = first==1 and 8 or 1
            for y=8,15 do 
                pset(x+8*self.mountain[self.currentmountain],y,c)
                pset(x+8*self.mountain[self.currentmountain]+1,y,c)
            end
            first = 0            
        end
    end
end

function game:show_gameover()
    self.state,view.y=game_states.waiting,0
    camera()
    if player.score > 0 and player.score >= highscores[3].score
    then
        highscorescreen:init()
    else
        gameoverscreen:init()
    end
end 

-- check for a dirt tile in the range specified
-- return 1 if dirt is found
function game:check_for_dirt(x1,y1,x2,y2,bullet)

    bullet=bullet or false
    
    -- convert pixel coords to cells
    local coords = utilities.box_coords_to_cells(x1,y1,x2,y2)
    
    -- get the top tile
    local tile1 = screen.tiles[coords[2]][coords[1]]

    local offset1,offset2 = y1 % 8,(y2+1) % 8

    if bullet==true
    then
        -- special case for bullets
        if tile1 and tile1.sprite==70 and sub(tile1.dirt,offset1+1,offset1+1)=="1" then return 1 end
        return 0
    end

    -- if this is dirt and it still has dirt
    if tile1.sprite==70 and self:has_dirt(tile1,offset1,1)==1 then return 1 end

    -- if this cell doesn't spill over, exit
    if offset1==0 then return 0 end

    -- get the second tile
    local tile2 = screen.tiles[coords[4]][coords[3]]
 
    -- if this is dirt and it still has dirt
    if tile2.sprite==70 and self:has_dirt(tile2,offset2,0)==1 then return 1 end
    
    return 0
end

-- Check for dirt in the tile 
-- Basically, look for a 1 in the .dirt property after or before the offset
function game:has_dirt(tile, offset, afteroffset)
    
    for d = 1, #tile.dirt do 
        if sub(tile.dirt,d,d)=="1" 
        then
            if (afteroffset==1 and d>offset) or (afteroffset==0 and d<=offset)
            then
                return 1
            end
        end
    end

    return 0
end

-- clear dirt in range specified
function game:dig_dirt(x1,y1,x2,y2)
    -- convert pixel coords to cells
    local coords = utilities.box_coords_to_cells(x1,y1,x2,y2)
    
    -- get the top tile
    local tile1,offset1,offset2 = screen.tiles[coords[2]][coords[1]],y1 % 8,(y2+1) % 8
    
    if tile1.sprite==70 
    then
        tile1.dirt,tile1.dirty=self:clear_dirt(tile1.dirt,offset1,1),1
    end 
    
    if offset1==0 then return end 

    -- get the bottom tile
    local tile2 = screen.tiles[coords[4]][coords[3]]
    if tile2.sprite==70 
    then
        tile2.dirt,tile2.dirty=self:clear_dirt(tile2.dirt,offset2,0),1
    end
    
end

-- set dirt to 0 
-- if clearbottom == 1 clear the bottom offset lines
-- if clearbottom == 0 clear the top offset lines
function game:clear_dirt(dirt,offset,clearbottom)
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





-- robotspeed,robots,tankspeed,missilespeed,bridgespeed,robotspawnrate,rockwobbletime
-- robotspeed - 1 fastest
-- robots - number spawned at one time
-- tankspeed - frames before next shot (divide by 60 for seconds, 28 total shots - tankspeed 60 = 28 seconds)
-- missilespeed - chance of falling per frame, out of 60
-- bridgespeed - 1 fastest
-- robotspawnrate - frames till next spawn
-- rock wobble time - frames that rock will wobble
levels={
    caverncoords={{40,144},{80,184}},
    pitcoords={{8,64},{24,104}}, 
    {
        settings="6,2,180,0.5,3,300,80,first dig"  
    },
    {
        settings="5,3,180,0.5,2,300,80,greed trap"  
    },
    {
        settings="4,3,150,1,2,200,80,dark shaft"  
    },
    {
        settings="3,3,150,1,2,200,90,rock run"  
    },
    {
        settings="4,2,150,3,2,200,80,unstable"  
    },
    {
        settings="4,2,150,3,2,150,80,plan ahead"  
    },
    { 
        settings="3,3,150,4,2,350,80,dirt maze"  
    },
    {
        settings="2,2,150,8,2,150,80,robo shrine" 
    }
}
screen = {
    tiles = {},
    mapx = 0
}

view = {
    y = 0
}

function screen:init()
    self.mapx=16*(game.currentlevel-1)
    screen:populate_map()
    camera(0,view.y)  
end

function screen:update()
    screen:check_camera()
end

function screen:draw()
    cls()
    -- draw map and set camera
    map(self.mapx,0,0,0,16,24)
    camera(0,view.y)    
    -- draw dirt
    screen:draw_dirt()
    screen:draw_bridge()
    local name=game.demo==1 and "demo" or game.settings[8]
    utilities.print_text(name,3.5,12,1)
end

function screen:draw_bridge()
    for x=0, game.bridge-1 do
        pset(levels.pitcoords[1][1]+x,levels.pitcoords[1][2]+8,8)
        pset(levels.pitcoords[1][1]+x,levels.pitcoords[1][2]+9,8)
    end
end

function screen:draw_zonk()
    rectfill(player.x-9,player.y+1,player.x+14,player.y+7,10)
    print("zonk!!", player.x-8,player.y+2,0)
end

function screen:draw_scores()
    rectfill(1,1+view.y,47,7+view.y,1)
    rectfill(85,1+view.y,126,7+view.y,1)
    local highscore = highscores[1].score
    if (player.score > highscore) highscore = player.score
    print("score "..utilities.pad_number(player.score),2,2+view.y,7)
    print("high "..utilities.pad_number(highscore), 86,2+view.y,7)
end

function screen:draw_highscores()
    print("best scores",40,110+view.y,12)

    for x=1,#highscores do 
        print(highscores[x].name.." "..utilities.pad_number(highscores[x].score),4+40*(x-1),118+view.y,8+(x-1))
    end

end

-- Walk the map and replace any object sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function screen:populate_map()
    self.tiles={}
    for y = 0,23 do
        self.tiles[y]={}
        for x = 0,15 do
            local sprite,tile = mget(x+self.mapx,y),{}
            tile.sprite,tile.block,tile.dirty,tile.dirt=sprite,0,0,""
            
            if sprite==71 -- rock
            then
                mset(x+self.mapx,y,255)
                local r = rock:new()
                r:set_coords(x,y)
                add(rocks,r)
                add(game.objects,r)
            elseif sprite==73 -- bomb
            then
                mset(x+self.mapx,y,255)
                local b = bomb:new()
                b:set_coords(x,y)
                add(bombs,b)
                add(game.objects,b)
            elseif sprite==75 -- diamond
            then
                mset(x+self.mapx,y,255)
                local d = diamond:new()
                d:set_coords(x,y)
                add(diamonds,d)
                add(game.objects,d)
            elseif sprite==86 -- gem
            then
                mset(x+self.mapx,y,255)
                local g = gem:new()
                g:set_coords(x,y)
                add(gems,g)
                add(game.objects,g)
            elseif sprite== 70 -- dirt
            then
                -- initialise a dirt tile
                tile.dirt="11111111" -- each character represents a line of dirt, if 0 it has been removed
            elseif sprite== 64 -- dirt
            then
                tile.block=1
            end 

            self.tiles[y][x] = tile

        end
    end
end

-- walk the map array
-- if a tile is a dirt tile and is dirty, then walk its dirt value and clear any pixels on rows set to 1
function screen:draw_dirt()
    for y = 0,23 do
        for x = 0,15 do
            local tile=self.tiles[y][x]
            for d = 1, #tile.dirt do 
                if sub(tile.dirt,d,d)=="0" 
                then 
                    -- set this row to black
                    local x1,y1=x*8,y*8+(d-1)
                    for p=x1,x1+7 do
                        pset(p,y1,0)
                    end
                end
            end
        end 
    end

end

function screen:check_camera()
    -- check for need to reset camera
    if player.y>=112 and player.state!=player_states.falling then view.y=64 end
    if game.state==game_states.waiting or player.y<=80 then view.y=0 end
end
utilities = {}

function utilities.pad_number(input)
    output=tostr(input)
    local l=#output
    for x=l,4 do 
        output="0"..output
    end
    return output
end

-- Convert box coords in pixels to cells
-- Returns array of {x1,y1,x2,y2}
function utilities.box_coords_to_cells(x1,y1,x2,y2)
    local coords1,coords2 = utilities.point_coords_to_cells(x1,y1),utilities.point_coords_to_cells(x2,y2)
    return {coords1[1],coords1[2],coords2[1],coords2[2]}
end

-- Convert a point in pixels to cells
-- Returns {x,y} array
function utilities.point_coords_to_cells(x,y)
    -- Subtract one from the y value to account for score panel
    return {flr(x/8),flr(y/8)}
end

-- get range of spaces adjacent to the place in the direction specified
-- if dig is 1, get the square vertically, otherwise just 8 pixels (horiz is always a square)
function utilities:get_adjacent_spaces(dir, dig, x, y)
    local coords,ymod1,ymod2 = {},-1,8
    if dig == 1
    then
        ymod1,ymod2=-8,15
    else
    end

    if dir==0 then coords={x+8, x+15, y, y+7} end -- right
    if dir==1 then coords={x-8, x-1, y, y+7} end -- left
    if dir==2 then coords={x, x+7, y+ymod1, y-1} end -- up
    if dir==3 then coords={x, x+7, y+8, y+ymod2} end -- down
    
    return coords
end

-- get range of spaces adjacent to the place in the direction specified
function utilities:get_adjacent_or_current_space(dir, x, y)
    local coords = {}

    if dir==0 then coords={x+1, y} end -- right
    if dir==1 then coords={x-1, y} end -- left
    if dir==2 then coords={x, y-1} end -- up
    if dir==3 then coords={x, y+8} end -- down
    
    return coords
end

-- checks for an overlap of two boxes
-- coords = {x1,x2,y1,y2} describing a shape with corners at x1,y1 and x2,y2
-- return 1 if overlap
function utilities:check_overlap(coords1,coords2)
    if coords1[1] < coords2[2] and coords2[1] <= coords1[2] and coords1[3] < coords2[4] and coords2[3] <= coords1[4]
    then
        return 1
    end           
    return 0
end

-- check a range of pixels that the object is about to move into
-- if can't move return 0
-- if can move return 1
function utilities:check_can_move(dir, coords, bullet)

    bullet=bullet or false
    
    -- if rock, can't move
    for r in all(rocks) do
        local coords2,overlap = {r.x,r.x+8,r.y,r.y+8}
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
    local s1,s2=mget(cellcoords[1]+screen.mapx, cellcoords[2]),mget(cellcoords[3]+screen.mapx,cellcoords[4])
    if s1==64 or s2==64 or s1==65 or s2==65
    then
        return 0
    end

    -- if contains dirt, can't move
    local dirtfound=game:check_for_dirt(coords[1],coords[3],coords[2],coords[4],bullet)
    if (dirtfound==1) return 0
    -- otherwise, can move
    return 1
end

function utilities.print_text(text, line, colour, bgcolor)
    local ydelta,x,w=6,64 - 4*(#text/2),4*#text
    local y=ydelta*line
    if bgcolor
    then
        rectfill(x-1,y-1,x+w-1,y+5,bgcolor)
    end
    print(text,x,y,colour)
end

function utilities.print_texts(text)
    local items=split(text)
    for x=1,#items,3 do 
        utilities.print_text(items[x],tonum(items[x+1]),tonum(items[x+2]))
    end
end

-- generates a palette of three random colours from a selection passed as a parameter
function utilities.generate_pallete(possiblecolors)
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1,i2,i3 = flr(rnd(#possiblecolors))+1,flr(rnd(#possiblecolors))+1,flr(rnd(#possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    return {possiblecolors[i1],possiblecolors[i2],possiblecolors[i3]}
end

function utilities:sfx(sound)
    if (game.demo==0) sfx(sound)
end

function utilities:contains (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
    

entity = {} 

-- the entity class constructor
function entity:new(o) 
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function entity:draw()
    spr(self.sprite,self.x,self.y)
end
bullets = {}

bullet = {
    sprite = 14
}

bullet=entity:new(bullet)

function bullet:update()

    local coords = utilities:get_adjacent_spaces(self.dir,0,self.x,self.y)
    -- limit coords
    coords={coords[1],coords[2],coords[3]+3,coords[4]-4}
    local canmove = utilities:check_can_move(dir,coords, true)
    
    if canmove == 0
    then
        del(bullets, self)
        return
    end

    -- check if we've killed a robot
    local coords1 = {self.x,self.x+7,self.y+3,self.y+3}
    for r in all(game.robots) do 
        if not(r.dying)
        then 
            local coords2 = {r.x,r.x+7,r.y,r.y+7}

            if utilities:check_overlap(coords1,coords2) == 1 
            then
                del(bullets, self)
                r:die()
                player:add_score(scores.robot)
                return
            end
        end
    end

    local xmod = self.dir == directions.right and 8 or -8
    self.x+=xmod
end

function bullet:draw()
    if(self.x!=player.x) spr(self.sprite,self.x,self.y)
end

function bullet:set_coords(x,y,dir)
    self.x,self.y,self.dir = x,y,dir
end
monster = {
    x = 12,
    y = 96,
    sprites = {128,130},
    delay=60,
    currentcolor=1,
    frames=12,
    currentframe=1,
    xmod=-1,
    ymod=-1,
    colors=split "8,10,14",
    newcolors=split "8,10,14",
    possiblecolors=split "2,3,4,5,6,8,9,10,11,12,13,14,15"
}

monster=entity:new(monster)

function monster:update()
    if self.delay > 0
    then
        self.delay-=1
        return
    end

    if game.frame%2==0
    then
        -- work out new coords here
        if game.frame%4==0
        then
            self.x+=self.xmod
            if self.x<=levels.pitcoords[1][1] or self.x>=levels.pitcoords[2][1]-8
            then
                self.xmod=-1*self.xmod
            end
        end
        -- slow down rise above certain point
        if self.y<=levels.pitcoords[1][2]+15 then self.y += self.ymod else self.y+=self.ymod*3 end

        if self.y<=levels.pitcoords[1][2]+10 or self.y>=levels.pitcoords[2][2]-4
        then
            self.ymod=-1*self.ymod
        end
    end
    if game.frame%self.frames==0 
    then 
        self.currentframe=self.currentframe%2+1 
    end

    if (game.frame%30==0) self.currentcolor+=1
    if (self.currentcolor>4) self.currentcolor=1
end

function monster:draw()
    local height=1

    -- generate new colors
    if self.y >= levels.pitcoords[2][2]-8 and self.delay == 0
    then
        self.newcolors = utilities.generate_pallete(self.possiblecolors)
    end 

    -- swap palette
    for x=1,3 do
        pal(self.colors[x],self.newcolors[x])
    end
    
    if self.y < levels.pitcoords[2][2]-8
    then
        height=2
    end

    spr(self.sprites[self.currentframe],self.x,self.y,2,height)

    -- draw the green gunge over the sprite
    local cellcoords=utilities.point_coords_to_cells(levels.pitcoords[2][1],levels.pitcoords[2][2])

    for x=1,3 do
        spr(68,levels.pitcoords[2][1]-24+x*8,levels.pitcoords[2][2]) 
    end
    pal()
    
end


-- Collections of objects
rocks={}
diamonds={}
gems={}
bombs={}

object_states={
    idle="idle",
    preparing="preparing",
    falling="falling",
    invisible="invisible"
}

object_types={
    rock=0,
    bomb=1,
    diamond=2,
    gem=3
}

-- default attribute values for an "object" class
object = {
    state = object_states.idle,
    time = 0,
    preparingtime=60,
    anims = {
        idle={},
        preparing={},
        falling={}
    },
    framecount=0,
    animindex=1,
    killed=false,
    reset = function(self)
        self.framecount=1
        self.animindex=1
    end    
}

-- the object class constructor
function object:new(o) 
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function object:draw()
    spr(self.sprite,self.x,self.y)   
end

function object:set_coords(xcell,ycell)
    self.x,self.y=xcell*8,ycell*8
end

function object:check_kill()
    
    if self.state!=object_states.falling then return end

    local coords = utilities:get_adjacent_spaces(directions.down, 0, self.x, self.y)
    if player:check_for_player(coords[1],coords[2],coords[3],coords[4])==1 
    then 
        if self.type==object_types.rock
        then
            player:kill_player(player_states.crushed)
        elseif self.type==object_types.bomb
        then
            player:kill_player(player_states.bombed)
        end 
        self.killed=true
    end
    
end

function object:update_faller()
    -- check below for space to fall
    local canfall=self:check_can_fall() 
    if self.type==object_types.bomb and self.state==object_states.idle
    then
        -- for bombs, check random number
        local rand,faller=rnd(60),0
        for b in all(bombs) do 
            if (b.state!=object_states.idle) faller+=1
        end
        if rand>game.settings[4] or faller==2 then canfall=0 end
    end
    if canfall==1 and player:is_dying()==0
    then
        if self.state==object_states.falling
        then
            -- actually falling
            self.y+=1
        elseif self.state==object_states.preparing
        then
            self.time+=1
            if self.time >= self.preparingtime 
            then
                self.state=object_states.falling
            end
        elseif self.state==object_states.idle
        then 
            self.state,self.time=object_states.preparing,0
            self:reset()
        end
        
        -- update sprite
        if (game.frame%3==0)
        then
            self.framecount+=1
            self.animindex,self.sprite = (self.animindex % #self.anims[self.state]) + 1,self.anims[self.state][self.animindex]
        end
    else
        if player:is_dying()==1
        then
            if player.stateframes==9 then utilities:sfx(2) end 
        else
            if self.state==object_states.falling then utilities:sfx(2) end
        end
        self.state=object_states.idle
    end
    
end

-- check a range of pixels that the rock is about to move into
-- if can't fall return 0
-- if can fall return 1
function object:check_can_fall() 
    if (self.y>=184) return 0  -- prevent out of bounds

    local coords = utilities:get_adjacent_spaces(directions.down, 0, self.x, self.y)

    -- check for an overlap with the player top line
    if coords[2]-1 >= player.x and player.x+7 >= coords[1]+1 and player.y == coords[3]
    then
        return 1
    end

    -- check other rocks
    for r=1,#rocks do 
        local rock=rocks[r]
        if rock.y==self.y+8 and rock.x==self.x then return 0 end
    end

    -- check dirt array
    local cellcoords,offset = utilities.point_coords_to_cells(coords[1], coords[3]),coords[3]%8
    local tile = screen.tiles[cellcoords[2]][cellcoords[1]]
    if sub(tile.dirt,offset+1,offset+1)=="1" or tile.block==1 then return 0 end
    
    return 1
end

-- check if a pickup is overlapping the player. If so, collect
function object:update_pickup(score)
    if self.framecount>=self.anims[self.state].fr
    then
        self.animindex,self.sprite,self.framecount = (self.animindex % #self.anims[self.state]) + 1,self.anims[self.state][self.animindex],1
    else
        self.framecount+=1
    end 

    local ymod=0
    if (self.type==object_types.gem) ymod=4

    if player:check_for_player(self.x,self.x+7,self.y+ymod,self.y+7)==1 and self.state == object_states.idle
    then
        self.state = object_states.invisible
        player:add_score(score)
        if self.type==object_types.diamond then player.diamonds+=1 else player.gems+=1 end
        utilities:sfx(0)
    end

    -- check for collision with rocks and bombs
    for r in all(rocks) do
        if (r.x == self.x and r.y >= self.y and r.y < self.y+7) self.state = object_states.invisible
    end
    for b in all(bombs) do
        if (b.x == self.x and b.y >= self.y and b.y < self.y+7) self.state = object_states.invisible
    end
end


-- subclasses of object
rock = object:new(
    {
        type = object_types.rock,
        preparingtime = 80,
        sprite = 71, 
        anims = {
            idle={fr=1,71},
            preparing={fr=1,71,72},
            falling={fr=1,71}
        }
    }
)

function rock:update()
    rock.preparingtime=game.settings[7]
    self:update_faller()
    self:check_kill()
end

function rock:draw()
    if (self.killed==true and player.stateframes<10) return
    spr(self.sprite,self.x,self.y)   
end

bomb = object:new(
    {
        type = object_types.bomb,
        preparingtime = 60,
        sprite = 73, 
        anims = {
            idle={fr=1,73},
            preparing={fr=1,74},
            falling={fr=1,74}
        }
    }
)

function bomb:update()
    if player.incavern==0 and self.state==object_states.idle then return end
    self:update_faller()
    self:check_kill()
end

diamond = object:new(
    {
        type = object_types.diamond,
        sprite = 75, 
        anims = {
            idle={fr=4,75,76,77},
            invisible={fr=1,255}
        }
    }
)

function diamond:update()
    self:update_pickup(scores.diamond)
end

gem = object:new(
    {
        type = object_types.gem,
        sprite = 86, 
        anims = {
            idle={fr=4,86,87,88,89},
            invisible={fr=1,255}
        }
    }
)

function gem:update()
    self:update_pickup(scores.gem)
end

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
        self.sprite = self.sprite == 4 and 5 or 4
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
            if (btn(5)) titlescreen:init()
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
    b:set_coords(self.x,self.y,self.dir)
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

    if (game.cheat==0) self.lives-=1

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
    self.state,self.stateframes=state,30
end

function player:check_location()
    -- check pit
    self.inpit,self.incavern=0,0
    if levels.pitcoords[1][1]<=self.x and self.x<=levels.pitcoords[2][1] and levels.pitcoords[1][2]<=self.y and  self.y<levels.pitcoords[2][2]+8
    then
        self.inpit=1
    end

    -- check cavern
    if levels.caverncoords[1][1]<=self.x and self.x<levels.caverncoords[2][1]+8 and levels.caverncoords[1][2]<=self.y and  self.y<levels.caverncoords[2][2]+8
    then
        self.incavern=1
    end
end

-- check a range of pixels that the player is about to move into
-- if can't move return 0
-- if can move return 1
-- if can dig return 2
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
    if (dirtfound==1) return 2

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
        if canmove==2
        then 
            self:try_to_dig(d)
            self.dir=d
            return 0 
        elseif canmove==0
        then
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

ship_states = {
    landing = 0,
    landed = 1,
    fleeing = 2,
    lingering=3,
    escaping=4
}

ship = {
    x = 12,
    y = 0,
    sprite = 96,
    state = ship_states.landing,
    anims=split "96,98"
}

ship=entity:new(ship)

function ship:update()

    if self.state==ship_states.lingering
    then
        if (game.frame%80==0) self.state=ship_states.landed -- hang around for a second
        return
    end

    if self.state==ship_states.escaping
    then
        if game.frame%4==0
        then
            if self.x < 12
            then
                self.x+=1
            else
                if (self.y==8) utilities:sfx(8)
                if self.y < -32
                then
                    game:next_level()
                else
                    self.y-=1
                end
            end
            if game.frame%8==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
        end
        return
    end

    if self.state==ship_states.fleeing
    then
        if game.frame%4==0
        then
            if (self.y==8) utilities:sfx(8)
            self.y-=1
            if self.y < -64 -- hang around for a while, to rub it in
            then
                player:lose_life()
            end
        end
        return
    end

    if self.state==ship_states.landed 
    then
        if (self.x > 0) 
        then
            if (game.frame%4==0) self.x-=1 
            if game.frame%8==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
        end
        return
    end

    if game.frame%6==0
    then

        -- play ship landing
        if (self.y==0) utilities:sfx(7)
        self.y += 1
    end
    if self.y == 8 then self.state = ship_states.lingering end    
    if game.frame%8==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
end

function ship:draw()
    spr(self.sprite, self.x, self.y,2,1)
end

tank_states = {
    offscreen = 0,
    moving = 1,
    shooting=2
}

tank = {
    x = 128,
    y = 8,
    sprite = 100,
    fire_sprite = 104,
    bullet_sprite = 105,
    state = tank_states.moving,
    framesperupdate=4,
    frames=0,
    delay=120,
    anims=split "100,102"
}

tank=entity:new(tank)

function tank:update()
    if self.delay > 0
    then
        self.delay-=1
        return
    end

    if self.state==tank_states.moving
    then
        self.frames+=1
        if self.frames==self.framesperupdate
        then
            self.x-=1
            self.frames=0
        end
        if self.x == 96 then self.state = tank_states.shooting end    
    end
    if self.frames%4==0 then self.sprite=self.anims[1] else self.sprite=self.anims[2] end
end

function tank:draw()
    spr(self.sprite, self.x, self.y,2,1)

    if game.frame % game.settings[3] == 0 and self.state == tank_states.shooting and game.ship.state != ship_states.fleeing 
            and game.ship.state != ship_states.escaping
    then
        -- tank is firing
        spr(65,self.x,self.y)
        spr(self.fire_sprite,self.x,self.y)
        spr(self.bullet_sprite, self.x-16,self.y)
        utilities:sfx(9)
    end
end

congratulationsscreen = {
    showfor=300,
    timer=0
}

function congratulationsscreen:init()
    -- set state functions
    update=function ()
        congratulationsscreen:update()
    end
    draw=function ()
        congratulationsscreen:draw()
    end
end

function congratulationsscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        if player.score > 0 and player.score >= highscores[3].score
        then
            highscorescreen:init()
        else
            gameoverscreen:init()
        end  
    end 
    self.timer+=1
end

function congratulationsscreen:draw()
    cls(0)

    screen:draw_scores()
    screen:draw_highscores()
    utilities.print_texts("congratulations!,7,12,you beat the pit,9,10,try again for a higher score,11,8")

end

gameoverscreen = {
    showfor=300,
    timer=0
}

function gameoverscreen:init()
    -- set state functions
    update=function ()
        gameoverscreen:update()
    end
    draw=function ()
        gameoverscreen:draw()
    end
end

function gameoverscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        titlescreen:init()   
    end 
    self.timer+=1
    
end

function gameoverscreen:draw()
    cls(0)

    screen:draw_scores()
    screen:draw_highscores()
    utilities.print_text("game over", 7, 12)

end

highscorescreen = {
    scoretext = "",
    scorepos=0,
    initials={"a","a","a"},
    currentinitial=1,
    allcharsarray=split "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9,0, ,!,?",
    currentchar=1,
    cooldown=0
}

function highscorescreen:init()
    -- set state functions
    update=function ()
        highscorescreen:update()
    end
    draw=function ()
        highscorescreen:draw()
    end
    
    -- determine position
    local scorepos,scoretext=3,"3rd best"
    if player.score>highscores[1].score
    then
        scorepos, scoretext = 1,"greatest"
    elseif player.score>=highscores[2].score
    then
        scorepos, scoretext = 2,"2nd best"
    end

    self.initials,self.currentinitial,self.currentchar,self.scorepos,self.scoretext = 
        {"a","a","a"},1,1,scorepos,scoretext
end

function highscorescreen:update()

    if self.cooldown > 0
    then 
        self.cooldown-=1
        return
    end

    if btn(2)
    then 
        self.currentchar+=1
        if (self.currentchar>#self.allcharsarray) self.currentchar=1
        self.initials[self.currentinitial],self.cooldown=self.allcharsarray[self.currentchar],10
    elseif btn(3) then 
        self.currentchar-=1
        if (self.currentchar<1) self.curre,ntchar=#self.allcharsarray
        self.initials[self.currentinitial],self.cooldown=self.allcharsarray[self.currentchar],10
    elseif btn(5) 
    then
        self.currentinitial+=1
        self.currentchar,self.cooldown=1,30
    end

    if self.currentinitial > 3
    then
        local score = {
            name = self.initials[1]..self.initials[2]..self.initials[3],
            score = player.score
        }
        if self.scorepos == 1
        then
            highscores[3]=highscores[2]
            highscores[2]=highscores[1]
            highscores[1]=score
        elseif self.scorepos == 2
        then
            highscores[3]=highscores[2]
            highscores[2]=score
        else
            highscores[3]=score
        end
        -- save scores
        self:save_scores()
        gameoverscreen:init()
    end
end

function highscorescreen:load_scores()
    -- load high score table
    local savedscores = dget(0)
    if (savedscores!=0)
    then
        for x=0,8,4 do
            highscores[(x+4)/4]={
                score=dget(x),
                name=self.allcharsarray[dget(x+1)]..self.allcharsarray[dget(x+2)]..self.allcharsarray[dget(x+3)]
            } 
        end
    end
end

function highscorescreen:save_scores()
    local mem=0
    for r in all(highscores) do 
        dset(mem,r.score)
        local namearray=self:encode_name(r.name)
        for x=1,3 do 
            dset(mem+x,namearray[x])
        end
        mem+=4
    end
end

function highscorescreen:encode_name(name)
    local result = {}
    for x=1, 3 do 
        for y=1,#self.allcharsarray do 
            if (self.allcharsarray[y]==sub(name,x,x)) add(result,y)
        end
    end
    return result
end

function highscorescreen:draw()
    cls(0)
    screen:draw_scores()
    screen:draw_highscores()

    utilities.print_texts("congratulations,4,14,player 1,6,14,you have earned,9,8,the "..self.scoretext.." score,11,8,record your initials below,13,10")
    for x=1,3 do
        local col=10
        if (self.currentinitial==x) col=11
        print(self.initials[x], 50+6*x, 90, col) 
    end
end

instructions = {
    showfor=600,
    timer=0
}

function instructions:init()
    -- set state functions
    update=function ()
        instructions:update()
    end
    draw=function ()
        instructions:draw()
    end
end

function instructions:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        game:init_demo() 
    end 
    self.timer+=1
    
    if (btn(5)) livesscreen:init()
end

function instructions:draw()
    cls(0)

    utilities.print_texts("the objective of this, 0, 7,game is to dig down, 1, 7,to the bottom pit and, 2, 7,collect at least, 3, 7,one large jewel, 4, 7,then return to ship, 5, 7,thru the upper pit, 6, 7,single bonus "..scores.singlebonus.." points, 8, 10,collect one large jewel, 9, 7,double bonus "..scores.doublebonus.." points, 11, 12,collect all three large jewels, 12, 7,or all four small jewels, 13, 7,triple bonus "..scores.triplebonus.." points, 15, 8,collect all seven large jewels, 16, 7")
    screen:draw_highscores()
end

levelendscreen = {
    showfor=180,
    timer=0,
    score=0,
    scoretext="",
    fullscore=0,
    frame=0
}

function levelendscreen:init()
    -- set state functions
    update=function ()
        levelendscreen:update()
    end
    draw=function ()
        levelendscreen:draw()
    end

    -- work out score to give
    if player.diamonds==3 and player.gems==4
    then
        self.score,self.scoretext,self.fullscore=scores.triplebonus,"triple bonus",scores.triplebonus
    elseif player.diamonds==3 or player.gems==4
    then
        self.score,self.scoretext,self.fullscore=scores.doublebonus,"double bonus",scores.doublebonus
    else
        self.score,self.scoretext,self.fullscore=scores.singlebonus,"single bonus",scores.singlebonus
    end
end

function levelendscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        if game.currentlevel>8
        then
            congratulationsscreen:init()
        else
            player:reset()
            game:reset()
            game:switchto()  
        end 
    end 
    if self.score==0
    then
        self.timer+=1
    else
        -- allocate score
        if self.frame%20==0 
        then
            local toadd=0
            if self.score<100 then toadd=self.score else toadd=100 end
            player.score+=toadd
            self.score-=toadd
            utilities:sfx(5) 
        end
    end

    self.frame+=1
end

function levelendscreen:draw()
    cls(11)

    screen:draw_scores()
    utilities.print_texts("congratulations,5,1,player 1,7,1,you have earned,10,2,"..self.scoretext..",12,10,"..self.fullscore.." points,14,2,have another go,16, 8")

end

livesscreen = {
    showfor=90,
    timer=0
}

function livesscreen:init()
    -- set state functions
    update=function ()
        livesscreen:update()
    end
    draw=function ()
        livesscreen:draw()
    end
    if game.state==game_states.waiting
    then
        player:init()
    end
    utilities:sfx(6)
end

function livesscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        if game.state==game_states.waiting
        then
            game:init()
        else
            game:switchto()     
        end 
    end
    self.timer+=1
end

function livesscreen:draw()
    cls(1)

    rectfill(46,11,79,17,0)
    local livestext =  player.lives == 0 and "last man" or ""..(player.lives+1).." men left"
    utilities.print_texts("player 1,2,7,"..livestext..",5,10")
    
end

titlescreen = {
    blocks = "1,3,2,3,3,3,4,3,5,3,6,3,9,3,10,3,11,3,12,3,13,3,14,3,2,4,6,4,13,4,2,5,6,5,13,5,2,6,3,6,4,6,5,6,6,6,13,6,2,7,9,7,13,7,2,8,13,8,2,9,9,9,13,9,2,10,9,10,13,10,2,11,9,11,13,11,2,12,9,12,13,12",
    showfor=300,
    timer=0 
}

function titlescreen:init()
    -- set state functions
    update=function ()
        titlescreen:update()
    end
    draw=function ()
        titlescreen:draw()
    end
    camera()
    game.state=game_states.waiting
end

function titlescreen:update()
    
    if self.timer >= self.showfor 
    then
        self.timer=0 
        instructions:init() 
    end 
    self.timer+=1

    if btn(3)
    then
        if btnp(4)
        then
            game.cheat = game.cheat==1 and 0 or 1
        end
    end
    if (btnp(5)) livesscreen:init()
end

function titlescreen:draw()
    cls(1)

    local thexbase, theybase, jnrxbase, jnrybase = 8,14,95,106
    
    for x=0,2 do 
        spr(80+x,thexbase+9*x,theybase)
    end
    for x=0,2 do 
        spr(83+x,jnrxbase+9*x,jnrybase)
    end

    local blockarray=split(titlescreen.blocks)
    for x=1,#blockarray,2 do 
        spr(78,blockarray[x]*8,blockarray[x+1]*8)
    end

    print("press ❎ to start",30,120,7)
    if (game.cheat==1) print("cheat active",40,0,7)
end




__gfx__
000f0000000f00000000f0000000f000000f00000000f0000f000000000000f000000000f88aa0f0f00f00f00f00f00f022200f00f0022200000000000000000
00fff00000fff000000fff00000fff0000fff00ff00fff00fff0000000000fff00000000f08aaffff0fff0f00f0fff0f02720ffffff027200000000000000000
000f0000000f00000000f0000000f000f00f00a00a00f00f0f000000000000f000000000008aa0f00a0f0a0000a0f0f0022200f00f0022200000000000000000
00aaa88800aaa888888aaa00888aaa00faaaaa0000aaaaafaaa8800000088aaa000800f00f8a80000aaaa000000aaaa002200aaaaaa002200980098000000000
00aaaa0000aaaa0000aaaa0000aaaa0000aaa000000aaa00aaaa00000000aaaa0008a8f00f00800000aaa000000aaa0002288aaaaaa882200000000000000000
008880000088880000088800008888000088880ff088880088880000000088880f0aa80000000000088880000008888002000888888000200000000000000000
0f80800000800ff0000808f00ff00800f800008ff800008f800ff000000ff008fffaa80f00000000080008000080008022208008800802220000000000000000
0f00ff0000ff000000ff00f00000ff00f00000000000000fff000000000000ff0f0aa88f00000000ff0000ffff0000ff200ff0ffff0ff0020000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc111111111111111cc1111111bbbbbbbb88888888a0a0a0a00088880008888880800aa008800aa0080077700000777000007770008888888800000000
cccccccc11111111111111cccc111111bbbbbbbb888888880a0a0a0a0888888088888888880aa088880aa08807a7c7000767a70007c767008888888800000000
cccccccc1111111111111cccccc11111bbbbbbbb00000000a0a0a0a08888888808888888088aa880088aa8807aa7cc707667aa707cc766708888888800000000
cccccccc111111111111cccccccc1111bbbbbbbb000000000a0a0a0a0888888808888888008aa800008aa8000aa7cc000667aa000cc766008888888800000000
cccccccc11111111111cccccccccc111bbbbbbbb00000000a0a0a0a08888888088888880eeeeeeee8888888800a7c0000067a00000c760008888888800000000
cccccccc1111111111cccccccccccc11bbbbbbbb000000000a0a0a0a88888880888888880eeeeee0088888800007000000070000000700008888888800000000
cccccccc111111111cccccccccccccc1bbbbbbbb00000000a0a0a0a0888888880888888000eeee00008888000000000000000000000000008888888800000000
cccccccc11111111ccccccccccccccccbbbbbbbb000000000a0a0a0a0888888000888800000ee000000880000000000000000000000000008888888800000000
88888888880000888888888888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888880000888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008800880000888800000000008800880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008800888888888888880000008800880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008800888888888888880000008800888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008800880000888800000088008800888888800000000000aaaa000066aa000066660000aa6600000000000000000000000000000000000000000000000000
000088008800008888888888888888008800888088000000066aa66006677aa00aa66aa00aa77660000000000000000000000000000000000000000000000000
00008800880000888888888808888000880008888800000000c77c000066aa0000c77c0000aa6600000000000000000000000000000000000000000000000000
00000aacc88000000000088ccaa00000000000088888800000000008888880000000000800000000000000000000000000000000000000000000000000000000
000cccccccccc000000cccccccccc0008888888aaaaaa8808888888aaaaaa8800088888a8888cccc000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc000008811111188000000881111118800000088100000000000000000000000000000000000000000000000000000000
8a88a888a888a88aa88a888a888a88a8000000888888800000000088888880000000008800000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa088888888888888008888888888888800888888800000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaa0000aaaaaaaaaaaa008a1a1a1a1a1a1a188aaaaaaaaaaaaaa88a1a1a1a00000000000000000000000000000000000000000000000000000000
008aaaaaaaaaa800008aaaaaaaaaa8008aaaaaaaaaaaaaa881a1a1a1a1a1a1a88aaaaaaa00000000000000000000000000000000000000000000000000000000
0cc00008c0000cc00cc0000c80000cc0088888888888888008888888888888800888888800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000a0a0000000000000a0a00000000ccc00000ccc00000ccc00000ccc00000000000000000000000000000000000000000000000000000000000000000000
00000aa8aa00000000000aa8aa0000000c8c00000c8c00000c8c00000c8c00000000000000000000000000000000000000000000000000000000000000000000
0000aa8e8aa000000000aa8e8aa000000cc800880cc800800cc800800cc800880000000000000000000000000000000000000000000000000000000000000000
000aa8eee8aa0000000aa8eee8aa00000cccc8000cccc8880cccc8880cccc8000000000000000000000000000000000000000000000000000000000000000000
000a8eaeae8a0000000a8eaeae8a00000ccc00880ccc00800ccc00800ccc00880000000000000000000000000000000000000000000000000000000000000000
0008eeeeeee800000008eeeeeee800000c0c00000c00c0000c00cc000c0c00000000000000000000000000000000000000000000000000000000000000000000
0088eeeeeee880008888eeeeeee888880c00c00000c00c00b0000bb0c00c00000000000000000000000000000000000000000000000000000000000000000000
08aa8eaaae8aa800aaaa8eaaae8aaaaa0bb0bb0000bb0bb0bb000000bb0bb0000000000000000000000000000000000000000000000000000000000000000000
8aa0a8eee8a0aa80a0a0a8eee8a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0008888888000a00000888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0008000008000a00000800000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000080000080000000aaa00000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa00000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
1111111111111111111111111111111111111111111111111111111cccccccccc111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111cccccccccccc11111111111111111111111111111111111111111111111111111111111111
11177117711771777177711111777177717771777177711111111cccccccccccccc1111111111111111111717177711771717111117771777177717771777111
1171117111717171717111111171717171717171717171111111cccccccccccccccc111111111111111111717117117111717111117171717171717171717111
117771711171717711771111117171717171717171717111111cccccccccccccccccc11111111111111111777117117111777111117171717171717171717111
11117171117171717171111111717171717171717171711111cccccccccccccccccccc1111111111111111717117117171717111117171717171717171717111
1177111771771171717771111177717771777177717771111cccccccccccccccccccccc111111111111111717177717771717111117771777177717771777111
111111111111111111111111111111111111111111111111cccccccccccccccccccccccc11111111111111111111111111111111111111111111111111111111
11111aacc881111111111111111111111111111cccccccccccccccccccccccccccccccccccccccccc11111111111111111111118888881111111111111111111
111cccccccccc1111111111111111111111111cccccccccccccccccccccccccccccccccccccccccccc111111111111118888888aaaaaa8811111111111111111
cccccccccccccccc111111111111111111111cccccccccccccccccccccccccccccccccccccccccccccc111111111111111111881111118811111111111111111
8a88a888a888a88a11111111111111111111cccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111188888881111111111111111111
aaaaaaaaaaaaaaaa1111111111111111111cccccccccccccccccccccccccccccccccccccccccccccccccc1111111111118888888888888811111111111111111
11aaaaaaaaaaaa11111111111111111111cccccccccccccccccccccccccccccccccccccccccccccccccccc11111111118a1a1a1a1a1a1a181111111111111111
118aaaaaaaaaa81111111111111111111cccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111118aaaaaaaaaaaaaa81111111111111111
1cc11118c1111cc11111111111111111cccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111118888888888888811111111111111111
cccccccccccccccc000f0000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc00fff000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc000f0000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc00aaa888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc00aaaa00ccccccccccccccccccccc1111111111111111111111111111111111111cccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc00888000ccccccccccccccccccccc1ccc1ccc1ccc11cc1ccc11111cc11ccc11cc1cccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc0f808000ccccccccccccccccccccc1c1111c11c1c1c1111c111111c1c11c11c111cccccccccccccccccccccccccccccc00000000cccccccc
cccccccccccccccc0f00ff00ccccccccccccccccccccc1cc111c11cc11ccc11c111111c1c11c11c111cccccccccccccccccccccccccccccc00000000cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a000888800ccccc1c1111c11c1c111c11c111111c1c11c11c1c1cccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a08888880ccccc1c111ccc1c1c1cc111c111111ccc1ccc1ccc1cccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a088888888ccccc1111111111111111111111111111111111111cccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a08888888cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a088888880cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a88888880cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a088888888cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a08888880cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccccccccccccccccccc000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a0a0a0a0a000888800a0a0a0a000000000a0a0a0a000888800a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a0a0a0a0a088888800a0a0a0a000000000a0a0a0a088888800a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a0a0a0a0a088888888a0a0a0a000000000a0a0a0a088888888a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a0a0a0a0a088888880a0a0a0a000000000a0a0a0a088888880a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a0a0a0a0a088888880a0a0a0a000000000a0a0a0a088888880a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a0a0a0a0a888888800a0a0a0a000000000a0a0a0a888888800a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a0a0a0a0a088888888a0a0a0a000000000a0a0a0a088888888a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a0a0a0a0a088888800a0a0a0a000000000a0a0a0a088888800a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a0000000000000000000888800a0a0a0a000888800a0a0a0a000888800cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a0000000000000000088888800a0a0a0a088888800a0a0a0a08888880cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a0000000000000000088888888a0a0a0a088888888a0a0a0a088888888cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a0000000000000000088888880a0a0a0a088888880a0a0a0a08888888cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a0000000000000000088888880a0a0a0a088888880a0a0a0a088888880cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a0000000000000000888888800a0a0a0a888888800a0a0a0a88888880cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a0000000000000000088888888a0a0a0a088888888a0a0a0a088888888cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a0000000000000000088888800a0a0a0a088888800a0a0a0a08888880cccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a000888800a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a088888800a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a088888888a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a088888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a088888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a888888800a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a088888888a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a088888800a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000000888800a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000088888800a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000088888888a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000088888880a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000088888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000888888800a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000088888888a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a00000000088888800a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc888888888888888888888888cccccccc00888800a0a0a0a0a0a0a0a00000000000888800a0a0a0a0a0a0a0a0000000000088880000000000cccccccc
cccccccc888888888888888888888888cccccccc088888800a0a0a0a0a0a0a0a00000000088888800a0a0a0a0a0a0a0a000000000888888000000000cccccccc
cccccccc000000000000000000000000cccccccc88888888a0a0a0a0a0a0a0a00000000088888888a0a0a0a0a0a0a0a0000000008888888800000000cccccccc
cccccccc000000000000000000000000cccccccc088888880a0a0a0a0a0a0a0a00000000088888880a0a0a0a0a0a0a0a000000000888888800000000cccccccc
cccccccc000000000000000000000000cccccccc88888880a0a0a0a0a0a0a0a00000000088888880a0a0a0a0a0a0a0a0000000008888888000000000cccccccc
cccccccc000000000000000000000000cccccccc888888800a0a0a0a0a0a0a0a00000000888888800a0a0a0a0a0a0a0a000000008888888000000000cccccccc
cccccccc000000000000000000000000cccccccc88888888a0a0a0a0a0a0a0a00000000088888888a0a0a0a0a0a0a0a0000000008888888800000000cccccccc
cccccccc000000000000000000000000cccccccc088888800a0a0a0a0a0a0a0a00000000088888800a0a0a0a0a0a0a0a000000000888888000000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000888800a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc00000000000000000000000000000000000000000000000000000000088888800a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000088888888a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc00000000000000000000000000000000000000000000000000000000088888880a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000088888880a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc00000000000000000000000000000000000000000000000000000000888888800a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000088888888a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc00000000000000000000000000000000000000000000000000000000088888800a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc00000000a0a0a0a00088880000000000a0a0a0a00088880000000000a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc000000000a0a0a0a08888880000000000a0a0a0a08888880000000000a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbb2b2bbbbbbbbbbbcccccccc00000000a0a0a0a08888888800000000a0a0a0a08888888800000000a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbb22b22bbbbbbbbbbcccccccc000000000a0a0a0a08888888000000000a0a0a0a08888888000000000a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbb22bdb22bbbbbbbbbcccccccc00000000a0a0a0a08888888000000000a0a0a0a08888888000000000a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbb22bdddb22bbbbbbbbcccccccc000000000a0a0a0a88888880000000000a0a0a0a88888880000000000a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbb2bd2d2db2bbbbbbbbcccccccc00000000a0a0a0a08888888800000000a0a0a0a08888888800000000a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbdddddddbbbbbbbbbcccccccc000000000a0a0a0a08888880000000000a0a0a0a08888880000000000a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0000000000888800a0a0a0a00000000000888800a0a0a0a000000000a0a0a0a00088880000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc00000000088888800a0a0a0a00000000088888800a0a0a0a000000000a0a0a0a0888888000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0000000088888888a0a0a0a00000000088888888a0a0a0a000000000a0a0a0a08888888800000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc00000000088888880a0a0a0a00000000088888880a0a0a0a000000000a0a0a0a0888888800000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0000000088888880a0a0a0a00000000088888880a0a0a0a000000000a0a0a0a08888888000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc00000000888888800a0a0a0a00000000888888800a0a0a0a000000000a0a0a0a888888800066aa00cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0000000088888888a0a0a0a00000000088888888a0a0a0a000000000a0a0a0a08888888806677aa0cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc00000000088888800a0a0a0a00000000088888800a0a0a0a000000000a0a0a0a088888800066aa00cccccccc
cccccccccccccccccccccccccccccccccccccccc00000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000888800cccccccc
cccccccccccccccccccccccccccccccccccccccc000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a08888880cccccccc
cccccccccccccccccccccccccccccccccccccccc00000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a088888888cccccccc
cccccccccccccccccccccccccccccccccccccccc000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a08888888cccccccc
cccccccccccccccccccccccccccccccccccccccc00000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a088888880cccccccc
cccccccccccccccccccccccccccccccccccccccc000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a88888880cccccccc
cccccccccccccccccccccccccccccccccccccccc00000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a088888888cccccccc
cccccccccccccccccccccccccccccccccccccccc000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a08888880cccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0000000000000000000000000a0a0a0acccccccc

__map__
4141414141414240434141414141414141414141414142404341414141414141414141414141424043414141414141414141414141414240434141414141414141414141414142404341414141414141414141414141424043414141414141414141414141414240434141414141414141414141414142404341414141414141
4141414142404040404043414141414141414141424040404040434141414141414141414240404040404341414141414141414142404040404043414141414141414141424040404040434141414141414141414240404040404341414141414141414142404040404043414141414141414141424040404040434141414141
4040ff4040404040404040404040ff404040ff4040404040404040404040ff404040ff4040404040404040404040ff404040ff4040404040404040404040ff404040ff4040404040404040404040ff404040ff4040404040404040404040ff404040ff4040404040404040404040ff404040ff4040404040404040404040ff40
4046464647404040404040ffffffff404046464647404040404040ffffffff404047464647404040404040ffffffff404047464647404040404040ffffffff404046464647404040404040ffffffff404046464647404040404040ffffffff404047464647404040404040ffffffff404047464647404040404040ffffffff40
404646464646404040ffffff404040404046464646464040404646ff404040404046464646464040404746ff404040404046464646464040404746ff404040404046464646ff4040404747ff404040404046464646464040404746ff40404040404646464646474040ffffff404040404046464646464040404646ff40404040
404640404046464746ff4647464646404046404040464646464647ff464747404046404040464646474646ff474646404046404040464047464646ff474646404046404040ff4747464646ff474646404046404040464646464646ffff464740404640404046464640474040404656404046474040464646ffffffffff475640
4046464640464646ffff4746474647404046464640464647404040ff46464640404646464046474646ffffff464646404046464640464646404747ff464646404046464640ff4646ffffffff46474640404646464047404046474646ff464640404646474046404646464646464640404046464640464646ff404040ff464640
4040464040464746ff464646464646404040464040474646404740ff404656404040464040464646464646ffffffff404040464040474046404646ffffff46404040464040ffffffff4647ffff464640404046404047564046464646ff464640404046404046474040ff4040464047404040464040ffff46ff404740ff464640
4000000046464646ff474646ffffff404000000046464646404640ff404040404000000046464747464746ff4646474040000000464646464046464646ff4640400000004646404747474646ff46474040000000464746ffffffffffff47464040000000464646ff40ff40464640464040000000464747ffff474040ff464740
40ffffff40474646ff474646ff47ff4040ffffff40464646405640ff4747464040ffffff40474646464046ff4646464040ffffff40464047404646ffffff474040ffffff404047464646ffffff47464040ffffff4047464046464647ff46464040ffffff404640ff40ff40464040564040ffffff4046464740404040ff474640
40ffffff40464646ff464646ff46ff4040ffffff40474646464746ff4646464040ffffff40464647464046ff4746464040ffffff40464646404647ff4646464040ffffff404746ffffffff474746464040ffffff4047464046474746ff46474040ffffff404640ff40ff40464046464040ffffff4047474646404040ff464640
4000000040ffffffffffffff4746ff404000000040474746464646ff464647404000000040464646474046ff464046404000000040404046404646ffffff4640400000004046ffff4747474646474740400000004047464046464646ff47464040000000404740ffffff404646464040400000004046464656405640ff474640
4044444440ff4647ff4647ff4646ff404044444440474646464646ff464646404044444440464746464046ff4640464040444444404646464056464646ff4640404444444046ff47474646464646464040444444404746ffffffffffff46464040444444404640404040404640404740404444444046464640464640ff464740
4044444440ff4746004746ff46475640404444444046ffffffffffffffffff404044444440474646564046ff464056404044444440464040404746ffffff4640404444444046ff4646ffffffff465640404444444047464046474646ff4646404044444440464046464646464646464040444444404646474746474746464640
4040404040ff4646004646ff464647404040404040ff47464646474646ff46404040404040404740404046ff464040404040404040464040404646ff46464640404040404047ffffffff4747ff474640404040404047464046464746ff4647404040404040464046404040404040464040404040404040464640464640404640
4046464646ff464600464600000046404047404646ff47464646464746ff46404056464746464646464646ff464646404047464646464646ffffffffffff4640404746474646ff4746464646ff464640405646474646464646464646ff4646404046474646464646464047404740464040474646474740464640464646ffff40
4046000000ff4647564746464700464040464046ffff46464646464646ff464040464646ffffffffffffffffff474640404646ffffffffff5647464646ff464040564646ffffff4656464646ffff464040474646ffffffffffff47ff47ffff404046464640564040464646464640404040464646464646464646464646464640
4047004640404040404040404600464040564046404040404040404046ff46404047464640404040404040404646464040464647404040404040404046ff46404047464640404040404040404646464040464646404040404040404046464640404640464040404040404040ff40564040564746404040404040404046474640
4046004640494949494949404756464040464646404949494949494046ff4640404647ff404949494949494047464640404646564049494949494940464746404046464640494949494949404746464040464646404949494949494047464640404640464049494949494940ff40464040464646404949494949494046464640
4046564740ffffffffffff40464746404046464740ffffffffffff4047ff4640405647ff40ffffffffffff40464647404046474740ffffffffffff40474646404046464740ffffffffffff40464646404047464740ffffffffffff40464646404046404740ffffffffffff40ff4046404046464740ffffffffffff4047464740
40464746ff000000000000ff4646464040464646ff000000000000ff4647464040464646ff000000000000ffffff464040464646ff000000000000ff4646474040464646ff000000000000ff4646474040464646ff000000000000ff4646474040464646ff000000000000ffff46474040464646ff000000000000ff46ff4640
4046464640000000000000404646464040464647400000000000004046464640404646474000000000000040464647404047464640000000000000404746464040464647400000000000004046474640404647464000000000000040474646404047464640000000000000404646464040474647400000000000004046ffff40
4047ffff404b404bff404b404646464040474646404b404bff404b405646464040464646404b404bff404b404747474040464647404b404bff404b405646464040474646404b404bff404b404646564040564646404b404bff404b404646564040474747404b404bff404b404746464040474746404b404bff404b4046474640
4040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040404040
__sfx__
000100002332031320333203032029320313002c3000030000300003001e700007000020031200003000030000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000002f7103471036710307102771021710177100c7100070000700007000070000700007000070000700007000070000700000000000000000000000000000000000000000000000000000000000000
000100000d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000032420304202d4202b420304002c4002b4002f5002f5003050030500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002a05029000000002505000000000002105000000000001b05000000000001705000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00002f0302f0202f0102f01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d000024050280502b0502d05024050280502b0502d05024050280502b0502d0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001f9501d9501b9501a9501895016950159501495012950109500e9500d9400d9300d9200d9100f9000f9000f9001a9001a900199000b7000a700097000870007700067000670006700067000670006700
00080000049500595007950099500a9500b9500c9500e950109501195015950189501b9501e95024950299500f9000f9001a9001a900199000b7000a700097000870007700067000670006700067000670006700
000400002763022630206201b6201661015610116100d6100b6100761005610036100261002610026100261001610016100000000000000000000000000000000000000000000000000000000000000000000000
