
scores={
    diamond=100, -- 2000
    gem=50, -- 1000
    singlebonus=500, -- 5000
    doublebonus=1000, -- 10000
    triplebonus=1500, -- 15000
    robot=10, -- 100
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
    highscore=100,
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
    rocks={}
    bombs={}
    diamonds={}
    gems={}
    bullets={}

    game.currentmountain=1
    game.currentmountaincount=0

    screen:init()

end

function game:next_level()
    self.currentlevel+=1
    player:reset()
    self:reset()
    levelendscreen:init()
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





