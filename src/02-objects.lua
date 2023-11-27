-- Collections of objects
rocks={}
diamonds={}
gems={}
bombs={}

function add_rock(colx,coly)
    add(rocks, {
        x = colx*8,
        y = coly*8,
        sprite = 71,
        state = "idle",
        time = 0,
        preparingtime=30,
        draw = function(self)
            rectfill(self.x, self.y, self.x+7, self.y+7, 0)    
            spr(self.sprite,self.x,self.y)   
        end,
        update = function(self)
            update_faller(self, "rock")
            check_kill(self, "rock")
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

function check_kill(faller, type)
    
    if faller.state!="falling" then return end

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
    if type=="bomb" and faller.state=="falling"
    then
        -- for bombs, check random number
        local rand=rnd(100)
        if rand>1 then cantfall=2 end
    end

    if canfall==1 and p.activity<3 
    then
        if faller.state=="falling"
        then
            -- actually falling
            faller.y+=1
        elseif faller.state=="preparing"
        then
            faller.time+=1
            if faller.time >= faller.preparingtime 
            then
                faller.state="falling"
            end
        elseif faller.state=="idle" 
        then 
            faller.state="preparing"
            faller.time=0 
            faller.anims:reset()
        end
        
        -- update sprite
        faller.anims.framecount+=1
        faller.anims.animindex = (faller.anims.animindex % #faller.anims[faller.state]) + 1
        faller.sprite =  faller.anims[faller.state][faller.anims.animindex]
    else
        faller.state="idle"
        faller.anims:reset()
    end
    
end

-- check a range of pixels that the rock is about to move into
-- if can't fall return 0
-- if can fall return 1
function checkcanfall(x,y) 
    -- only check if faller is visible
    if view.y == 0 and y >= 120 then return 0 end
    if view.y > 0 and y < 72 then return 0 end

    local coords = getadjacentspaces(3, 0, x, y)

    -- check for an overlap with the player top line
    if coords[2] >= p.x and p.x+7 >= coords[1] and p.y == coords[3]
    then
        return 1
    end

    for x=coords[1],coords[2] do 
        local pixelc = pget(x,coords[3])
        -- Not blank or dirt, so can't fall
        if pixelc != 0 then return 0 end        
    end

    return 1
end

