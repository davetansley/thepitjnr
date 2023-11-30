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

