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

