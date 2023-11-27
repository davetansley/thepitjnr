
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
