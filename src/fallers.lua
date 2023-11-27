
----------------------------------------------------------------
--fall management
----------------------------------------------------------------
function checkrocks()
    checkfallers(currentrockarray,1)
end

function checkbombs()
    if p.incavern==0 then return end

    checkfallers(currentbombarray,2)
end

-- checks an array of fallers to see if they should fall
-- type: 1 rock, 2 bomb
function checkfallers(fallerarray,type)
    local count=#fallerarray
    for x=1,count do 
        local faller=fallerarray[x]    
        -- check below for space to fall
        local cantfall=checkcanfall(faller[1], faller[2]) 

        if type==2 and faller[3]==0
        then
            -- for bombs, check random number
            local rand=rnd(100)
            if rand>1 then cantfall=2 end
        end

        if cantfall==1 and faller[3]==1 -- has struck a player and faller is falling
            then
                if type==1 
                then 
                    p.activity=3
                    p.activityframes=30      
                else
                    p.activity=4
                    p.activityframes=30
                end
            end

        if cantfall<2 and p.activity<3 
            then
                if faller[3]==0 
                then 
                    if type==1 then faller[3]=30 end
                    if type==2 then faller[3]=15 end 
                end 

                if faller[3]==1 
                    then
                        -- actually falling
                        faller[2]+=1

                    else
                        faller[3]-=1 -- decrease state by one
                        if type==1
                        then
                            if faller[4]==71 then faller[4]=72 else faller[4]=71 end
                        end 

                        if type==2
                        then
                            faller[4]=74
                        end 

                    end
            else
                faller[3]=0
            end
        
    end
end

-- check for player in the range specified
-- return 1 if found, 0 if not
function checkforplayer(x1,x2,y1,y2)
    --printh(""..x1..","..y1.." "..x2..","..y2)
    --printh(""..p.x..","..p.y)
    if x1 < p.x+8 and p.x <= x2 and y1 < p.y+8 and p.y <= y2
         then
            return 1
        end           
    return 0
end

-- check a range of pixels that the rock is about to move into
-- if can fall return 0
-- if can't fall return 2
-- if can fall onto a player return 1
function checkcanfall(x,y) 
    local result = 0
    -- only check if rock is visible
    if view.y == 0 and y > 120 then return 2 end
    if view.y > 0 and y < 72 then return 2 end

    local coords = getadjacentspaces(3, 0, x, y)
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do 
            local pixelc = pget(x,y)
            -- Not blank or dirt, so can't fall
            if pixelc != 0 
                then
                    result=2
                end
        end
    end

    if result==2 
    then
        --printh(x..","..y)
        if checkforplayer(coords[1],coords[2],coords[3],coords[4])==1 then result=1 end
    end

    return result
end
