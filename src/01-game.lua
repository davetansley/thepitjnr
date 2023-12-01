
scores={
    diamond=10,
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
    tank={}
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

    -- update the ship only if needed
    if self.ship.state == ship_states.landing
    then
        self.ship:update()
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





