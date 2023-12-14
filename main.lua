cart_id="suzukobufe"

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
    view={}
    view.y=0 -- key for tracking the viewport

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
    if self.ship.state == ship_states.landing or self.ship.state == ship_states.fleeing or self.ship.state == ship_states.escaping
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
    if (self.demo==1) 
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
            local c = 1
            if (first == 1) c = 8
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
        if sub(tile.dirt,d,d)=="1" and afteroffset==1 and d>offset then return 1 end
        if sub(tile.dirt,d,d)=="1" and afteroffset==0 and d<=offset then return 1 end
    end

    return 0
end

-- clear dirt in range specified
function game:dig_dirt(x1,y1,x2,y2)
    -- convert pixel coords to cells
    local coords = utilities.box_coords_to_cells(x1,y1,x2,y2)
    
    -- get the top tile
    local tile1 = screen.tiles[coords[2]][coords[1]]
    local offset1 = y1 % 8
    local offset2 = (y2+1) % 8
    
    if tile1.sprite==70 
    then
        tile1.dirt=self:clear_dirt(tile1.dirt,offset1,1)
        tile1.dirty=1
    end 
    
    if offset1==0 then return end 

    -- get the bottom tile
    local tile2 = screen.tiles[coords[4]][coords[3]]
    if tile2.sprite==70 
    then
        tile2.dirt=self:clear_dirt(tile2.dirt,offset2,0)
        tile2.dirty=1
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
    if game.state==game_states.waiting or player.y<=72 then view.y=0 end
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
    local linebase = 7
    utilities.print_text("game over", linebase, 12)

end

highscorescreen = {
    scoretext = "",
    scorepos=0,
    initials={"a","a","a"},
    currentinitial=1,
    allchars="a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9,0, ,!,?",
    allcharsarray={},
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

    self.allcharsarray,self.initials,self.currentinitial,self.currentchar,self.scorepos,self.scoretext = 
        split(self.allchars),{"a","a","a"},1,1,scorepos,scoretext
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
        self.allcharsarray=split(self.allchars)

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
    local livestext = "last man"
    if (player.lives != 0) livestext = ""..(player.lives+1).." men left"
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

    if (btn(5)) livesscreen:init()
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
end
