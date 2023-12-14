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

