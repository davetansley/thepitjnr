-- init
function _init()
    titlescreen:init()
end

-- update
function _update()
    update()
    --utilities:print_debug()
end

-- draw
function _draw()
    draw()
end

scores={
    diamond=10,
    gem=5,
    singlebonus=500,
    doublebonus=1000,
    triplebonus=1500
}

game_states = {
    waiting = 0,
    running = 1
}

game = {
    level={},
    highscore=100,
    state=game_states.waiting,
    ship={},
    tank={},
    frame=0
}

function game:init()
    self.switchto()

    -- config variables
    self.level = levels[1]
    player:init()
    
    -- viewport variables
    view={}
    view.y=0 -- key for tracking the viewport

    self.reset()

    screen:init()

    -- Create a new ship and tank
    self.ship = ship:new()
    self.tank = tank:new()

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
    if (self.frame>30) self.frame=0

    -- update the ship only if needed
    self.ship:update()
    if self.ship.state == ship_states.landing
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

    if self.tank.state == tank_states.moving
    then
        self.tank:update()
    end

    player:update()
    screen:update()
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

    self.ship:draw()

    self.tank:draw()

    if self.ship.state == ship_states.landed
    then
        screen:draw_scores()
        player:draw()
    end
end

function game:reset()
    
    view.y=0

    -- reload the map
    reload(0x1000, 0x1000, 0x2000)

    -- Populate entities
    rocks={}
    bombs={}
    diamonds={}
    gems={}

    screen:init()

end

function game:show_gameover()
    self.state=game_states.waiting
    player:init()
    titlescreen:init()
end

-- check for a dirt tile in the range specified
-- return 1 if dirt is found
function game:check_for_dirt(x1,y1,x2,y2)

    -- convert pixel coords to cells
    local coords = utilities.box_coords_to_cells(x1,y1,x2,y2)
    
    -- get the top tile
    local tile1 = screen.tiles[coords[2]][coords[1]]

    local offset1 = y1 % 8
    local offset2 = (y2+1) % 8

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





screen = {
    tiles = {}
}

function screen:init()
    screen:populate_map()
    camera(0,view.y)  
end

function screen:update()
    screen:check_camera()
end

function screen:draw()
    cls()
    -- draw map and set camera
    map(0,0,0,0,16,24)
    camera(0,view.y)    
    -- draw dirt
    screen:draw_dirt()
end

function screen:draw_zonk()
    rectfill(player.x-9,player.y+1,player.x+14,player.y+7,10)
    print("zonk!!", player.x-8,player.y+2,0)
end

function screen:draw_scores()
    rectfill(1,1+view.y,47,7+view.y,1)
    rectfill(85,1+view.y,126,7+view.y,1)
    print("score "..utilities.pad_number(player.score),2,2+view.y,7)
    print("high "..utilities.pad_number(game.highscore), 86,2+view.y,7)
end

-- Walk the map and replace any entity sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function screen:populate_map()
    self.tiles={}
    for y = 0,23 do
        self.tiles[y]={}
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
                local r = rock:new()
                r:set_coords(x,y)
                add(rocks,r)
            elseif sprite==73 -- bomb
            then
                mset(x,y,255)
                local b = bomb:new()
                b:set_coords(x,y)
                add(bombs,b)
            elseif sprite==75 -- diamond
            then
                mset(x,y,255)
                local d = diamond:new()
                d:set_coords(x,y)
                add(diamonds,d)
            elseif sprite==86 -- gem
            then
                mset(x,y,255)
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
    -- check for need to reset camera
    if player.y>=96 and view.y==0 then view.y=64 end
    if player.y<=88 and view.y==64 then view.y=0 end
end
levels={
    {
        level=1,
        caverncoords={{40,160},{80,184}},
        pitcoords={{8,72},{32,104}},    
    }
}
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

directions = {
    right = 0,
    left = 1,
    up = 2,
    down = 3
}

function player:init()
    self.lives = 3
    self:reset()
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

function player:reset()
    self.x=16 --key for the x variable
    self.y=16 --key for the y variable
    self.dir=directions.right --key for the direction: 0 right, 1 left, 2 up, 3 down
    self.sprite=0 -- key for the sprite
    self.oldsprite=0 -- key for storing the old sprite
    self.framecount=0 -- key for frame counting
    self.framestomove=0 -- key for frames left in current move
    self.state=0 -- key for player activity. 0 moving, 1 digging, 2 shooting, 3 squashing
    self.stateframes=0 -- key for frames in current activity
    self.incavern=0 -- key for whether player is in the diamond cavern
    self.inpit=0 -- key for whether player is in the pit
    self.animframes=10 -- key for the number of frames an animation frame has
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
            moved=self:move(0,1,4,5,directions.down,0) 
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
        game:show_gameover()
    else
        self:reset()
        game.reset()
        livesscreen:init()
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
        self.stateframes=7
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
    preparingtime=30,
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
        local rand=rnd(100)
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
        self.framecount+=1
        self.animindex = (self.animindex % #self.anims[self.state]) + 1
        self.sprite =  self.anims[self.state][self.animindex]

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

    if player:check_for_player(self.x,self.x+8,self.y,self.y+8)==1 and self.state == entity_states.idle
    then
        self.state = entity_states.invisible
        player:add_score(score)
        sfx(0)
    end
end


-- subclasses of entity
rock = entity:new(
    {
        type = entity_types.rock,
        preparingtime = 40,
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
        preparingtime = 30,
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
            idle={fr=2,75,76,77},
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
            idle={fr=2,86,87,88},
            invisible={fr=1,255}
        }
    }
)

function gem:update()
    self:update_pickup(scores.gem)
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
    showfor=150,
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
ship_states = {
    landing = 0,
    landed = 1
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

    if self.state==ship_states.landed 
    then
        if (self.x > 0 and game.frame%2==0) self.x-=1 
        return
    end

    if game.frame%3==0
    then
        self.y += 1
    end
    if self.y == 8 then self.state = ship_states.landed end    
    if game.frame%2==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
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
    sprites = {100,101,102,103},
    state = tank_states.moving,
    framesperupdate=2,
    frames=0,
    delay=60,
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
    if self.frames%2==0 then self.sprites=self.anims[1] else self.sprites=self.anims[2] end
end

function tank:draw()
    for x=1,#self.sprites do 
        spr(self.sprites[x], self.x+(8*x-8), self.y)
    end
end

instructions = {
    showfor=150,
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
        utilities.print_text(""..player.lives.." men left", 5, 10)
    end
    
end

utilities = {
    lowest_pfr = -1
}

function utilities.pad_number(input)
    output=tostr(input)
    local l=#output
    for x=l,4 do 
        output="0"..output
    end
    return output
end


function utilities.copy_array(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utilities.copy_array(orig_key)] = utilities.copy_array(orig_value)
        end
        setmetatable(copy, utilities.copy_array(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
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


function utilities:print_debug()
    if self.lowest_pfr == -1 or stat(9) < utilities.lowest_pfr
    then
        self.lowest_pfr = stat(9)
    end
    printh(" FR: "..stat(7).." TFR: "..stat(8).." PFR: "..stat(9).." LowPFR: "..utilities.lowest_pfr.." CPU: "..stat(1))
end

function utilities.print_text(text, line, colour)
    local ydelta=6
    local x = 64 - 4*(#text/2)
    print(text, x, ydelta*line,colour)
end
