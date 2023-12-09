
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

-- game speeds in number of frames before next update
game_speeds = {
    bridge=8
}

game_states = {
    waiting = 0,
    running = 1
}

game = {
    level={},
    currentlevel=1,
    state=game_states.waiting,
    ship={},
    tank={},
    monster={},
    robots={},
    frame=0,
    mountain={10,9,8,7,6,5,4},
    currentmountain=1,
    currentmountaincount=0,
    tickframes=150, -- how many frames before we process the timer?
    bridge=24 -- how much is the bridge extended
}

function game:init()
    self.switchto()

    -- config variables
    self.currentlevel=1
    self.highscore=highscores[1].score
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

    for r in all(rocks) do
        r:update()
    end

    for r in all(bombs) do
        r:update()
    end

    for r in all(diamonds) do
        r:update()
    end

    for r in all(gems) do
        r:update()
    end

    -- if we need a robot, spawn it
    if self.tank.state==tank_states.shooting and #self.robots < self.level.robots and self.frame%150 == 0
    then
        local r = robot:new()
        r:generate_pallete()
        add(self.robots,r)
    end

    for r in all(bullets) do
        r:update()
    end

    for r in all(self.robots) do
        r:update()
    end

    if self.tank.state == tank_states.moving
    then
        self.tank:update()
    end

    self.monster:update()
    if self.ship.state == ship_states.landed
    then
        player:update()
    end

    if player.inpit==1 and game.frame%game_speeds.bridge==0
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

    for r in all(rocks) do
        r:draw()
    end

    for r in all(bombs) do
        r:draw()
    end

    for r in all(diamonds) do
        r:draw()
    end

    for r in all(gems) do
        r:draw()
    end

    for r in all(self.robots) do
        r:draw()
    end

    for r in all(bullets) do
        r:draw()
    end

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

function game:reset()
    
    view.y=0

    self.level = levels[self.currentlevel]

    -- Create a new ship and tank
    self.ship = ship:new()
    self.tank = tank:new()
    self.monster = monster:new()
    self.robots = {}
    self.bridge = 24

    -- reload the map
    reload(0x1000, 0x1000, 0x2000)

    -- Populate entities
    rocks,bombs,diamonds,gems,bullets={},{},{},{},{}

    game.currentmountain=1
    game.currentmountaincount=0

    screen:init()

end

function game:next_level()
    self.currentlevel+=1
    levelendscreen:init()
    player:reset()
    self:reset()
end

function game:update_timer()

    if (self.frame % game.tickframes != 0 or self.tank.state != tank_states.shooting) return

    if self.currentmountain > #self.mountain
    then
        view.y = 0
        self.ship.state = ship_states.fleeing
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
        local sprite = mget(self.mountain[self.currentmountain], 0)
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
    self.state=game_states.waiting
    view.y=0
    camera(0,0)
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

    local offset1 = y1 % 8
    local offset2 = (y2+1) % 8

    if bullet==true
    then
        -- special case for bullets
        if tile1.sprite==70 and sub(tile1.dirt,offset1+1,offset1+1)=="1" then return 1 end
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





levels={
    caverncoords={{40,144},{80,184}},
    pitcoords={{8,64},{24,104}}, 
    {
        robots=2,
        robotspeed=6 -- speed of robots, 1 fastest  
    },
    {
        robots=2,
        robotspeed=5 -- speed of robots, 1 fastest  
    },
    {
        robots=3,
        robotspeed=4 -- speed of robots, 1 fastest  
    },
    {
        robots=3,
        robotspeed=3 -- speed of robots, 1 fastest  
    },
    {
        robots=4,
        robotspeed=3 -- speed of robots, 1 fastest  
    },
    {
        robots=4,
        robotspeed=2 -- speed of robots, 1 fastest  
    },
    { 
        robots=4,
        robotspeed=1 -- speed of robots, 1 fastest  
    },
    {
        robots=2,
        robotspeed=5 -- speed of robots, 1 fastest  
    }
}
-- init
function _init()
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
screen = {
    tiles = {},
    mapx = 0
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
    print("best scores today",30,110+view.y,12)

    for x=1,#highscores do 
        print(highscores[x].name.." "..utilities.pad_number(highscores[x].score),4+40*(x-1),118+view.y,8+(x-1))
    end

end

-- Walk the map and replace any entity sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function screen:populate_map()
    self.tiles={}
    for y = 0,23 do
        self.tiles[y]={}
        for x = 0,15 do
            local sprite = mget(x+self.mapx,y)

            local tile = {}
            tile.sprite=sprite
            tile.block=0
            tile.dirty=0
            tile.dirt=""

            if sprite==71 -- rock
            then
                mset(x+self.mapx,y,255)
                local r = rock:new()
                r:set_coords(x,y)
                add(rocks,r)
            elseif sprite==73 -- bomb
            then
                mset(x+self.mapx,y,255)
                local b = bomb:new()
                b:set_coords(x,y)
                add(bombs,b)
            elseif sprite==75 -- diamond
            then
                mset(x+self.mapx,y,255)
                local d = diamond:new()
                d:set_coords(x,y)
                add(diamonds,d)
            elseif sprite==86 -- gem
            then
                mset(x+self.mapx,y,255)
                local g = gem:new()
                g:set_coords(x,y)
                add(gems,g)
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

function screen:check_camera()
    if game.state==game_states.waiting then view.y = 0 return end

    -- check for need to reset camera
    if player.y>=96 and view.y==0 and player.state!=player_states.falling then view.y=64 end
    if player.y<=88 and view.y==64 then view.y=0 end
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
    local coords1 = utilities.point_coords_to_cells(x1,y1)
    local coords2 = utilities.point_coords_to_cells(x2,y2)

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

-- check a range of pixels that the entity is about to move into
-- if can't move return 0
-- if can move return 1
function utilities:check_can_move(dir, coords, bullet)

    bullet=bullet or false
    local result = 1
    
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

    -- if contains dirt, can't move
    local dirtfound=game:check_for_dirt(coords[1],coords[3],coords[2],coords[4],bullet)
    if (dirtfound==1) return 0
    -- otherwise, can move
    return 1
end

function utilities.print_text(text, line, colour)
    local ydelta=6
    local x = 64 - 4*(#text/2)
    print(text, x, ydelta*line,colour)
end
bullets = {}

bullet = {
    x = 0,
    y = 0,
    dir = 0
}

function bullet:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

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
    local coords1 = {self.x,self.x+7,self.y,self.y+7}
    for r in all(game.robots) do 
        local coords2 = {r.x,r.x+7,r.y,r.y+7}

        if utilities:check_overlap(coords1,coords2) == 1 
        then
            del(bullets, self)
            r:die()
            player:add_score(scores.robot)
            return
        end
    end

    if self.dir == directions.right
    then
        self.x+=8
    else
        self.x-=8
    end
end

function bullet:draw()
    spr(14,self.x,self.y)
end

function bullet:set_coords(x,y,dir)
    self.x,self.y,self.dir = x,y,dir
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

-- default attribute values for an "entity" class
entity = {
    x = 0,
    y = 0,
    sprite = 0,
    state = entity_states.idle,
    time = 0,
    preparingtime=60,
    anims = {
        idle={},
        preparing={},
        falling={}
    },
    framecount=0,
    animindex=1,
    reset = function(self)
        self.framecount=1
        self.animindex=1
    end    
}

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

function entity:set_coords(xcell,ycell)
    self.x=xcell*8
    self.y=ycell*8   
end

function entity:check_kill()
    
    if self.state!=entity_states.falling then return end

    local coords = utilities:get_adjacent_spaces(directions.down, 0, self.x, self.y)
    if player:check_for_player(coords[1],coords[2],coords[3],coords[4])==1 
    then 
        if self.type==entity_types.rock
        then
            player:kill_player(player_states.crushed)
        elseif self.type==entity_types.bomb
        then
            player:kill_player(player_states.bombed)
        end 
    end
    
end

function entity:update_faller()
    -- check below for space to fall
    local canfall=self:check_can_fall() 
    if self.type==entity_types.bomb and self.state==entity_states.idle
    then
        -- for bombs, check random number
        local rand=rnd(300)
        if rand>1 then canfall=0 end
    end
    if canfall==1 and player:is_dying()==0
    then
        if self.state==entity_states.falling
        then
            -- actually falling
            self.y+=1
        elseif self.state==entity_states.preparing
        then
            self.time+=1
            if self.time >= self.preparingtime 
            then
                self.state=entity_states.falling
            end
        elseif self.state==entity_states.idle
        then 
            self.state=entity_states.preparing
            self.time=0 
            self:reset()
        end
        
        -- update sprite
        if (game.frame%3==0)
        then
            self.framecount+=1
            self.animindex = (self.animindex % #self.anims[self.state]) + 1
            self.sprite =  self.anims[self.state][self.animindex]
        end
    else
        if self.state==entity_states.falling then sfx(2) end
        self.state=entity_states.idle
    end
    
end

-- check a range of pixels that the rock is about to move into
-- if can't fall return 0
-- if can fall return 1
function entity:check_can_fall() 
    if self.y>=184 then return 0 end -- prevent out of bounds

    local coords = utilities:get_adjacent_spaces(directions.down, 0, self.x, self.y)

    -- check for an overlap with the player top line
    if coords[2] >= player.x and player.x+7 >= coords[1] and player.y == coords[3]
    then
        return 1
    end

    -- check other rocks
    for r=1,#rocks do 
        local rock=rocks[r]
        if rock.y==self.y+8 and rock.x==self.x then return 0 end
    end

    -- check dirt array
    local cellcoords = utilities.point_coords_to_cells(coords[1], coords[3])
    local offset=coords[3]%8
    local tile = screen.tiles[cellcoords[2]][cellcoords[1]]
    if sub(tile.dirt,offset+1,offset+1)=="1" or tile.block==1 then return 0 end
    
    return 1
end

-- check if a pickup is overlapping the player. If so, collect
function entity:update_pickup(score)
    if self.framecount>=self.anims[self.state].fr
    then
        self.animindex = (self.animindex % #self.anims[self.state]) + 1
        self.sprite =  self.anims[self.state][self.animindex]
        self.framecount=1
    else
        self.framecount+=1
    end 

    local ymod=0
    if (self.type==entity_types.gem) ymod=4

    if player:check_for_player(self.x,self.x+7,self.y+ymod,self.y+7)==1 and self.state == entity_states.idle
    then
        self.state = entity_states.invisible
        player:add_score(score)
        if self.type==entity_types.diamond then player.diamonds+=1 else player.gems+=1 end
        sfx(0)
    end
end


-- subclasses of entity
rock = entity:new(
    {
        type = entity_types.rock,
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
    self:update_faller()
    self:check_kill()
end

function rock:draw()
    spr(self.sprite,self.x,self.y)   
end

bomb = entity:new(
    {
        type = entity_types.bomb,
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
    if player.incavern==0 then return end
    self:update_faller()
    self:check_kill()
end

diamond = entity:new(
    {
        type = entity_types.diamond,
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

gem = entity:new(
    {
        type = entity_types.gem,
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
    colors={8,10,14},
    newcolors={8,10,14},
    possiblecolors={2,3,4,5,6,8,9,10,11,12,13,14,15}
}

function monster:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

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
        self:generate_pallete()
    end 

    -- swap palette
    pal(self.colors[1],self.newcolors[1])
    pal(self.colors[2],self.newcolors[2])
    pal(self.colors[3],self.newcolors[3])
    
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

function monster:generate_pallete()
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1 = flr(rnd(#self.possiblecolors))+1
        i2 = flr(rnd(#self.possiblecolors))+1
        i3 = flr(rnd(#self.possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    self.newcolors={self.possiblecolors[i1],self.possiblecolors[i2],self.possiblecolors[i3]}
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
}

directions = {
    right = 0,
    left = 1,
    up = 2,
    down = 3
}

function player:init()
    self.lives = 2
    self.score = 0
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
        =16,16,directions.right,0,0,0,0,0,0,0,0,10,0,0,0 
end

-- return 1 if the player is dying
function player:is_dying()
    if self.state==player_states.crushed or self.state==player_states.bombed or self.state==player_states.mauled or self.state==player_states.falling then return 1 end 
    return 0
end

-- update the player state
function player:update_player()
    if (self.state==player_states.escaping) return

    if self.state==player_states.falling
    then
        if (game.frame%1 != 0) return
        -- Player is falling
        if self.sprite == 4 then self.sprite=5 else self.sprite=4 end
        if (self.y <= levels.pitcoords[2][2]-1) self.y+=1
        self.stateframes-=1
        if (self.stateframes==60) sfx(4)
        if self.stateframes==0
            then
                self:lose_life()
            end
        return
    end

    if self.state==player_states.mauled
    then
        if (game.frame%4 != 0) return
        -- Player is being mauled
        if self.sprite == 2 then self.sprite=0 else self.sprite=2 end
        self.stateframes-=1
        if self.stateframes==0
            then
                self:lose_life()
            end
        return
    end

    if self.state==player_states.crushed
    then
        -- Player is being squashed
        if game.frame%3==0
        then
            if self.sprite == 10 then self.sprite=11 else self.sprite=10 end
            self.stateframes-=1
        end
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

    -- reduce the shot cooldown
    self.firecooldown-=1
    if (self.firecooldown<0) self.firecooldown=0

    -- check if we've completed the level
    if self:check_win()==1
    then
        return
    end

    -- check if we're falling in the pit
    if (self:check_pit()==1) return;

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
        if self.dir==directions.right then self:move(1,0,0,1,directions.right,1) end
        if self.dir==directions.left then self:move(-1,0,2,3,directions.left,1) end
        self.framestomove-=1
    else
        -- start new movement
        local moved = 0
        local horiz = 0
        if btn(0) then 
            moved=self:move(-1,0,2,3,directions.left,0)
            horiz=1                 
        elseif btn(1) and moved==0 then 
            moved=self:move(1,0,0,1,directions.right,0)
            horiz=1 
        elseif btn(2) and moved==0 then 
            moved=self:move(0,-1,4,5,directions.up,0) 
        elseif btn(3) and moved==0 then 
            if self.inpit==0
            then
                moved=self:move(0,1,4,5,directions.down,0)
            else
                self.sprite=0
                self.dir=directions.right 
            end
        elseif btn(5) then self:fire()
        end
        
        if moved==1 and horiz==1 then self.framestomove=7 end
    end

    -- update the player's location
    self:check_location()
end

function player:check_win()
    if self.diamonds > 0 and self.x==16 and self.y==16 
    then
        self.state=player_states.escaping
        game.ship.state=ship_states.escaping
        return 1
    end

    return 0
end

function player:check_pit()
    if (self.inpit==0) return 0
    
    -- check if the player is falling
    if self.x >= levels.pitcoords[1][1]+game.bridge
    then
        self.state=player_states.falling
        self.stateframes=100
        return 1
    end
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
    sfx(3)
end

function player:lose_life()
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
    local coords1 = {x1,x2,y1,y2}
    local coords2 = {self.x,self.x+8,self.y,self.y+8}

    return utilities:check_overlap(coords1,coords2)
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
        sfx(1)

        -- Update this later to just set the player state - anims handled in draw
        if self.state==player_states.moving then 
            self.oldsprite=self.sprite
        end
        self.state=player_states.digging
        self.stateframes=14
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
    sprites = {132,133,134,135},
    currentframe=1,
    colors={8,11,12},
    newcolors={8,11,12},
    possiblecolors={7,8,9,10,11,12,13,14},
    autoframes=0,
    killed=false, -- has the robot killed the player
    dying=false,
    alldirs=false,
    reversedirections = {
        directions.left,
        directions.right,
        directions.down,
        directions.up
    }
    
}

function robot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function robot:update()

    if self.dying == true 
    then
        -- robot has been shot - update palette, reduce frames, remove
        self.colors = self.newcolors
        self:generate_pallete()
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
    if (game.frame%game.level.robotspeed != 0 and self.dir != directions.down and self.dir != directions.up) return
    
    if self.autoframes == 0
    then
        -- figure out where the player can move
        -- {right, left, up, down}
        local moves = self:get_moves()        
        local reversedir = self.reversedirections[self.dir+1]
        if #moves == 1
        then
            -- just one possibility other than reverse, so take it
            self.dir = moves[1]
            self.alldirs = false
        elseif #moves == 2
        then
            -- chose a random direction
            self.dir = moves[flr(rnd(#moves))+1]
            self.alldirs = false
        
        elseif #moves == 3 and self.alldirs == false
        then
            -- chose a random direction
            self.dir = moves[flr(rnd(#moves))+1]
            self.alldirs = true
        elseif #moves == 0
        then
            -- can't move, so reverse
            self.dir = reversedir
            self.alldirs = false
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
    
    pal(self.colors[1],self.newcolors[1])
    pal(self.colors[2],self.newcolors[2])
    pal(self.colors[3],self.newcolors[3])

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

function robot:generate_pallete()
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1 = flr(rnd(#self.possiblecolors))+1
        i2 = flr(rnd(#self.possiblecolors))+1
        i3 = flr(rnd(#self.possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    self.newcolors={self.possiblecolors[i1],self.possiblecolors[i2],self.possiblecolors[i3]}
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
    sprites = {96,97},
    state = ship_states.landing,
    anims={
        {96,97},{98,99}
    }
}

function ship:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

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
                if self.y < -32
                then
                    game:next_level()
                else
                    self.y-=1
                end
            end
            if game.frame%8==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
        end
        return
    end

    if self.state==ship_states.fleeing
    then
        if game.frame%4==0
        then
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
            if game.frame%8==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
        end
        return
    end

    if game.frame%6==0
    then
        self.y += 1
    end
    if self.y == 8 then self.state = ship_states.lingering end    
    if game.frame%8==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function ship:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end
end

tank_states = {
    offscreen = 0,
    moving = 1,
    shooting=2
}

tank = {
    x = 128,
    y = 8,
    sprites = {100,101},
    fire_sprite = 104,
    bullet_sprite = 105,
    state = tank_states.moving,
    framesperupdate=4,
    frames=0,
    delay=120,
    anims={
        {100,101},{102,103}
    }
}

function tank:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

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
    if self.frames%4==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function tank:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end

    if game.frame % game.tickframes == 0 and self.state == tank_states.shooting and game.ship.state != ship_states.fleeing 
            and game.ship.state != ship_states.escaping
    then
        -- tank is firing
        spr(65,self.x,self.y)
        spr(self.fire_sprite,self.x,self.y)
        spr(self.bullet_sprite, self.x-16,self.y)
    end
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

    self.initials = {"a","a","a"}
    self.currentinitial = 1
    self.currentchar = 1

    -- determine position
    if player.score>highscores[1].score
    then
        self.scorepos, self.scoretext = 1,"greatest"
    elseif player.score>=highscores[2].score
    then
        self.scorepos, self.scoretext = 2,"2nd best"
    else
        self.scorepos, self.scoretext = 3,"3rd best"
    end
end

function highscorescreen:update()

    if self.cooldown > 0
    then 
        self.cooldown-=1
        return
    end

    local chars = split(self.allchars)
    if btn(2)
    then 
        self.currentchar+=1
        if (self.currentchar>#chars) self.currentchar=1
        self.initials[self.currentinitial]=chars[self.currentchar]
        self.cooldown=10
    elseif btn(3) then 
        self.currentchar-=1
        if (self.currentchar<1) self.currentchar=#chars
        self.initials[self.currentinitial]=chars[self.currentchar]
        self.cooldown=10
    elseif btn(5) 
    then
        self.currentinitial+=1
        self.currentchar=1
        self.cooldown=30
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
        gameoverscreen:init()
    end
end

function highscorescreen:draw()
    cls(0)
    screen:draw_scores()
    screen:draw_highscores()
    local linebase = 4
    utilities.print_text("congratulations", linebase, 14)
    utilities.print_text("player 1", linebase+2, 14)
    utilities.print_text("you have earned", linebase+5, 8)
    utilities.print_text("the "..self.scoretext.." score", linebase+7, 8)
    utilities.print_text("record your initials below", linebase+9, 10)

    for x=1,3 do
        local col=10
        if (self.currentinitial==x) col=11
        print(self.initials[x], 50+6*x, 90, col) 
    end
end

instructions = {
    showfor=300,
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
        titlescreen:init() 
    end 
    self.timer+=1
    
    if (btn(5)) livesscreen:init()
end

function instructions:draw()
    cls(0)
    utilities.print_text("the object", 0, 7)
    utilities.print_text("of this game", 1, 7)
    utilities.print_text("is to dig down", 2, 7)
    utilities.print_text("to the bottom pit", 3, 7)
    utilities.print_text("and", 4, 7)
    utilities.print_text("collect at least", 5, 7)
    utilities.print_text("one large jewel", 6, 7)
    utilities.print_text("then", 7, 7)
    utilities.print_text("return to ship", 8, 7)
    utilities.print_text("thru upper pit", 9, 7)
    utilities.print_text("single bonus "..scores.singlebonus.." points", 11, 10)
    utilities.print_text("collect one large jewel", 12, 7)
    utilities.print_text("and return to ship", 13, 7)
    utilities.print_text("double bonus "..scores.doublebonus.." points", 15, 12)
    utilities.print_text("collect all three large jewels", 16, 7)
    utilities.print_text("or all four small jewels", 17, 7)
    utilities.print_text("triple bonus "..scores.triplebonus.." points", 19, 8)
    utilities.print_text("collect all seven large jewels", 20, 7)
     
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
        self.score=scores.triplebonus
        self.fullscore=scores.triplebonus
        self.scoretext="triple bonus"
    elseif player.diamonds==3
    then
        self.score=scores.doublebonus
        self.scoretext="double bonus"
        self.fullscore=scores.doublebonus
    else
        self.score=scores.singlebonus
        self.scoretext="single bonus"
        self.fullscore=scores.singlebonus
    end
end

function levelendscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        game:switchto()   
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
            sfx(5) 
        end
    end

    self.frame+=1
end

function levelendscreen:draw()
    cls(11)

    screen:draw_scores()
    local linebase = 5
    utilities.print_text("congratulations", linebase, 1)
    utilities.print_text("player 1", linebase+2, 1)
    utilities.print_text("you have earned", linebase+5, 2)
    utilities.print_text(self.scoretext, linebase+7, 10)
    utilities.print_text(""..self.fullscore.." points", linebase+9, 2)
    utilities.print_text("have another go", linebase+11, 8)

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
    utilities.print_text("player 1",2,7)

    if player.lives==0 
    then
        utilities.print_text("last man", 5, 10)
    else
        utilities.print_text(""..(player.lives+1).." men left", 5, 10)
    end
    
end

titlescreen = {
    blocks = "1,3,2,3,3,3,4,3,5,3,6,3,9,3,10,3,11,3,12,3,13,3,14,3,"
            .."2,4,6,4,13,4,"
            .."2,5,6,5,13,5,"
            .."2,6,3,6,4,6,5,6,6,6,13,6,"
            .."2,7,9,7,13,7,"
            .."2,8,13,8,"
            .."2,9,9,9,13,9,"
            .."2,10,9,10,13,10,"
            .."2,11,9,11,13,11,"
            .."2,12,9,12,13,12",
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

    local thexbase = 8
    local theybase = 14
    local jnrxbase = 86
    local jnrybase = 106
    
    spr(80,thexbase,theybase)
    spr(81,thexbase+9,theybase)
    spr(82,thexbase+18,theybase)

    spr(83,jnrxbase,jnrybase)
    spr(84,jnrxbase+9,jnrybase)
    spr(85,jnrxbase+18,jnrybase)

    local blockarray=split(titlescreen.blocks)
    for x=1,#blockarray,2 do 
        spr(78,blockarray[x]*8,blockarray[x+1]*8)
    end

    print("press ❎ to start",30,120,7)
end
