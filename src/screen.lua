
----------------------------------------------------------------
--screen
----------------------------------------------------------------

-- Walk the map and replace any entity sprites
function populate_map()
    for y = 0,23 do
        for x = 0,15 do
            local sprite = mget(x,y)
            if sprite==71 -- rock
            then
                mset(x,y,0)
                add_rock(x,y+1)
            elseif sprite==73 -- bomb
            then
                mset(x,y,0)
                add_bomb(x,y+1)
            elseif sprite==75 -- diamond
            then
                mset(x,y,0)
                add_diamond(x,y+1)
            end 
        end
    end
end

-- Initialises the dig
function initdirtarray()
    for y = 1, 192 do 
        digarray[y]={}
        -- Include an extra on to say that the line has values
        for x = 1, 129 do 
            digarray[y][x]=0
        end
    end
end

function drawzonk()
    if p.activity==4 then print("ZONK!!", p.x-8,p.y,7) end
end

function drawdigs()
    for y = 1+view.y, 120+view.y do 
        if digarray[y][129]==1 
        then
            for x = 8, 120 do 
                if digarray[y][x]==1 then pset(x,y,0) end
            end
        end
    end
end

function drawscorepanel()
    rectfill(0,0+view.y,128,8+view.y,0)

    print("score "..padnumber(p.score),10,2+view.y,7)
    print("high "..padnumber(p.highscore), 85,2+view.y,7)
end

-- flash the adjacent square when digging
function flashsquare(dir)
    local coords = getadjacentspaces(dir, 1, p.x, p.y)
    local beamcoords = {}
    if (dir==0) then beamcoords={{p.x+5,p.y+3},{p.x+6,p.y+2},{p.x+6,p.y+3},{p.x+6,p.y+4},{p.x+7,p.y+1},{p.x+7,p.y+2},{p.x+7,p.y+3},{p.x+7,p.y+4},{p.x+7,p.y+5}} end
    if (dir==1) then beamcoords={{p.x+2,p.y+3},{p.x+1,p.y+2},{p.x+1,p.y+3},{p.x+1,p.y+4},{p.x,p.y+1},{p.x,p.y+2},{p.x,p.y+3},{p.x,p.y+4},{p.x,p.y+5}} end
    if (dir==2) then beamcoords={{p.x+3,p.y+2},{p.x+2,p.y+1},{p.x+3,p.y+1},{p.x+4,p.y+1},{p.x+1,p.y+0},{p.x+2,p.y+0},{p.x+3,p.y+0},{p.x+4,p.y+0},{p.x+5,p.y+0}} end
    if (dir==3) then beamcoords={{p.x+3,p.y+5},{p.x+2,p.y+6},{p.x+3,p.y+6},{p.x+4,p.y+6},{p.x+1,p.y+7},{p.x+2,p.y+7},{p.x+3,p.y+7},{p.x+4,p.y+7},{p.x+5,p.y+7}} end
    for x=coords[1],coords[2] do 
        for y=coords[3], coords[4] do
            local pixelc = pget(x,y)
            if pixelc == 10 or pixelc == 0 
            then
                pset(x,y,p.activityframes) 
                for b=1, #beamcoords do 
                    local beamcoord=beamcoords[b]
                    pset(beamcoord[1],beamcoord[2],p.activityframes)
                end
            end
        end
    end
end


function checkcamera()

    -- check for need to reset camera
    if p.y>=96 and view.y==0 then view.y=72 end
    if p.y<=88 and view.y==72 then view.y=0 end

end

function showgameover()
    printh("game over")
    cls()
    print("Game over!")
end
